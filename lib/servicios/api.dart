import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../modelos/item_carrito.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/usuario.dart';

// Error que se le puede mostrar tal cual al usuario
class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  const ApiException(this.mensaje, {this.codigo});

  @override
  String toString() => mensaje;
}

// Respuesta de la confirmación de un pedido
class PedidoCreado {
  final int id;
  final double total;
  final String mensaje;

  const PedidoCreado({
    required this.id,
    required this.total,
    required this.mensaje,
  });
}

class SesionGuardada {
  final String token;
  final Usuario usuario;

  const SesionGuardada({required this.token, required this.usuario});
}

// Cliente HTTP pequeño: un método por cada operación de la API de Django
class Api {
  Api({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  String? token;

  static const Duration tiempoEspera = Duration(seconds: 20);

  Map<String, String> _headers({bool conToken = true}) {
    final encabezados = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (conToken) {
      final t = token;
      if (t != null && t.isNotEmpty) {
        encabezados['Authorization'] = 'Token $t';
      }
    }
    return encabezados;
  }

  // ------------------------------------------------------------ respuestas

  dynamic _procesar(http.Response respuesta) {
    final cuerpo = _decodificar(respuesta.body);

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo;
    }

    // Django manda el mensaje en {"error": "..."} o {"detail": "..."}.
    // Si viene, se le muestra tal cual al usuario (está en español).
    final mensaje = mensajeDeError(cuerpo);
    final sinSesion = token == null || token!.isEmpty;

    if ((respuesta.statusCode == 401 || respuesta.statusCode == 403) &&
        sinSesion) {
      throw ApiException(
          _mensajePropio(cuerpo) ?? 'Debes iniciar sesión para continuar.',
          codigo: respuesta.statusCode);
    }
    if (respuesta.statusCode == 401) {
      throw ApiException(
          _mensajePropio(cuerpo) ??
              'Tu sesión ha expirado. Inicia sesión de nuevo.',
          codigo: 401);
    }

    throw ApiException(
      mensaje ?? 'El servidor respondió con un error (${respuesta.statusCode}).',
      codigo: respuesta.statusCode,
    );
  }

  dynamic _decodificar(String cuerpo) {
    if (cuerpo.isEmpty) return null;
    try {
      return jsonDecode(cuerpo);
    } catch (_) {
      return null;
    }
  }

  // Busca el mensaje de error en la respuesta de Django. DRF puede devolver
  // {"detail": "..."}, {"error": "..."} o {"errores": ["...", "..."]}
  static String? mensajeDeError(dynamic cuerpo) {
    if (cuerpo == null) return null;
    if (cuerpo is String) return cuerpo.isEmpty ? null : cuerpo;
    if (cuerpo is! Map) return null;

    final datos = Map<String, dynamic>.from(cuerpo);

    for (final clave in ['error', 'detail', 'mensaje']) {
      final valor = datos[clave];
      if (valor is String && valor.isNotEmpty) return valor;
    }

    final errores = datos['errores'];
    if (errores is List && errores.isNotEmpty) {
      return errores.map((e) => e.toString()).join('\n');
    }

    for (final entrada in datos.entries) {
      final valor = entrada.value;
      if (valor is String && valor.isNotEmpty) return valor;
      if (valor is List && valor.isNotEmpty) {
        return valor.map((e) => e.toString()).join('\n');
      }
    }

    return null;
  }

  // Solo los mensajes que la propia aplicación escribe ("error" o "mensaje").
  // Los "detail" de Django pueden venir en inglés y no conviene mostrarlos.
  static String? _mensajePropio(dynamic cuerpo) {
    if (cuerpo is! Map) return null;
    final datos = Map<String, dynamic>.from(cuerpo);
    for (final clave in ['error', 'mensaje']) {
      final valor = datos[clave];
      if (valor is String && valor.isNotEmpty) return valor;
    }
    return null;
  }

  String _errorDeRed() =>
      'No se pudo conectar con el servidor. Verifica que Django esté '
      'corriendo (${ApiConfig.baseUrl}) y que el teléfono esté en la misma red.';

  Future<dynamic> _pedir(
    String metodo,
    String ruta, {
    Map<String, dynamic>? datos,
    bool conToken = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.urlApi}/$ruta');
      final encabezados = _headers(conToken: conToken);
      final cuerpo = datos == null ? null : jsonEncode(datos);

      final Future<http.Response> futuro;
      switch (metodo) {
        case 'GET':
          futuro = _cliente.get(url, headers: encabezados);
        case 'POST':
          futuro = _cliente.post(url, headers: encabezados, body: cuerpo);
        case 'PATCH':
          futuro = _cliente.patch(url, headers: encabezados, body: cuerpo);
        case 'PUT':
          futuro = _cliente.put(url, headers: encabezados, body: cuerpo);
        default:
          futuro = _cliente.delete(url, headers: encabezados);
      }

      final respuesta = await futuro.timeout(tiempoEspera);
      return _procesar(respuesta);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
          'El servidor tardó demasiado en responder. Revisa tu conexión.');
    } catch (_) {
      throw ApiException(_errorDeRed());
    }
  }

  // ------------------------------------------------------------- autenticación

  Future<SesionGuardada> login(String correo, String password) async {
    final datos = await _pedir(
      'POST',
      'auth/login/',
      datos: {'correo': correo, 'password': password},
      conToken: false,
    );
    return _guardada(datos);
  }

  Future<SesionGuardada> registro({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
    required String veriPassword,
  }) async {
    final datos = await _pedir(
      'POST',
      'auth/registro/',
      datos: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'password': password,
        'veriPassword': veriPassword,
      },
      conToken: false,
    );
    return _guardada(datos);
  }

  SesionGuardada _guardada(dynamic datos) {
    final mapa = Map<String, dynamic>.from(datos as Map);
    return SesionGuardada(
      token: (mapa['token'] ?? '') as String,
      usuario: Usuario.fromJson(Map<String, dynamic>.from(mapa['usuario'])),
    );
  }

  Future<void> logout() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/logout/');
    final encabezados = _headers();
    try {
      await _cliente
          .post(url, headers: encabezados)
          .timeout(tiempoEspera);
    } catch (_) {
      // Aunque falle la petición, la app borra la sesión igualmente
    }
  }

  // ---------------------------------------------------------------- productos

  Future<List<Producto>> productos() async {
    final datos = await _pedir('GET', 'productos/');
    return _lista(datos, Producto.fromJson);
  }

  Future<Producto> producto(int id) async {
    final datos = await _pedir('GET', 'productos/$id/');
    return Producto.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  // ------------------------------------------------------------------ carrito

  Future<List<ItemCarrito>> carrito() async {
    final datos = await _pedir('GET', 'carritos/');
    return _lista(datos, ItemCarrito.fromJson);
  }

  Future<ItemCarrito> agregarAlCarrito({
    required int usuarioId,
    required int productoId,
    required int cantidad,
  }) async {
    final datos = await _pedir(
      'POST',
      'carritos/',
      datos: {
        'usuario': usuarioId,
        'producto': productoId,
        'cantidad': cantidad,
      },
    );
    return ItemCarrito.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  Future<ItemCarrito> actualizarCantidad(int itemId, int cantidad) async {
    final datos = await _pedir(
      'PATCH',
      'carritos/$itemId/',
      datos: {'cantidad': cantidad},
    );
    return ItemCarrito.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  Future<void> eliminarItem(int itemId) async {
    await _pedir('DELETE', 'carritos/$itemId/');
  }

  // ------------------------------------------------------------------ pedidos

  Future<PedidoCreado> crearPedido() async {
    final datos = await _pedir(
      'POST',
      'pedidos/crear-desde-carrito/',
      datos: const {},
    );
    final mapa = Map<String, dynamic>.from(datos as Map);
    final pedido = Map<String, dynamic>.from(mapa['pedido'] as Map);
    return PedidoCreado(
      id: (pedido['id'] ?? 0) as int,
      total: double.tryParse('${pedido['total']}') ?? 0,
      mensaje: (mapa['mensaje'] ?? '') as String,
    );
  }

  Future<void> registrarPago(int pedidoId, String metodo) async {
    await _pedir(
      'POST',
      'pedidos/$pedidoId/registrar-pago/',
      datos: {'metodo': metodo},
    );
  }

  Future<List<Pedido>> pedidos() async {
    final datos = await _pedir('GET', 'pedidos/');
    return _lista(datos, Pedido.fromJson);
  }

  Future<List<DetallePedido>> detallePedidos() async {
    final datos = await _pedir('GET', 'detallePedidos/');
    return _lista(datos, DetallePedido.fromJson);
  }

  Future<List<int>> pedidosPagados() async {
    final datos = await _pedir('GET', 'pagos/');
    final pagos = _lista(datos, (j) => (j['pedido'] ?? 0) as int);
    return pagos;
  }

  // --------------------------------------------------------------- utilidades

  List<T> _lista<T>(dynamic datos, T Function(Map<String, dynamic>) desde) {
    if (datos is! List) return <T>[];
    return datos
        .map((e) => desde(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
