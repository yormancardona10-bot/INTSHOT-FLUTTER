import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/item_carrito.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/usuario.dart';
import '../utilidades/carrito_calc.dart' as calculo;
import 'api.dart';
import 'notificaciones.dart' as notif;

// Estado de la sesión y del carrito. Es la única "fuente de verdad" de la
// app: las pantallas la escuchan con ListenableBuilder y se redibujan solas.
class Sesion extends ChangeNotifier {
  Sesion({Api? api, notif.Notificaciones? notificaciones})
      : api = api ?? Api(),
        notificaciones = notificaciones ?? notif.notificaciones;

  final Api api;
  final notif.Notificaciones notificaciones;

  Usuario? usuario;
  List<Producto> productos = [];
  List<ItemCarrito> items = [];

  bool cargandoCatalogo = false;
  bool cargandoCarrito = false;
  String? errorCatalogo;
  String? errorCarrito;
  String? ultimoErrorPedido;
  String? ultimoAvisoSeguridad;

  // IDs de pedidos que el cliente puede operar. Se llenan únicamente con los
  // pedidos cuyo usuario coincide con la sesión autenticada.
  Set<int> _pedidosPropios = {};

  bool get logueado => usuario != null && (api.token?.isNotEmpty ?? false);

  int get unidadesEnCarrito =>
      items.fold(0, (suma, item) => suma + item.cantidad);

  Map<int, Producto> get productosPorId =>
      {for (final producto in productos) producto.id: producto};

  double get totalCarrito => calculo.totalCarrito(items, productosPorId);

  // -------------------------------------------------------------- persistencia

  Future<void> restaurar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final datos = prefs.getString('usuario');
      if (token == null || token.isEmpty || datos == null) return;

      api.token = token;
      usuario = Usuario.fromJson(jsonDecode(datos) as Map<String, dynamic>);
      await notificaciones.cargarParaUsuario(usuario!.id);
      notifyListeners();

      // Comprueba que el token siga siendo válido. Si falla la red se conserva
      // la sesión; solo se borra cuando el servidor rechaza el token.
      try {
        items = await api.carrito();
        errorCarrito = null;
      } on ApiException catch (e) {
        if (e.sesionInvalida) {
          await _limpiarSesion();
        } else {
          errorCarrito = e.mensaje;
        }
      }
      notifyListeners();
    } catch (_) {
      await _limpiarSesion();
    }
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = api.token;
    if (token == null || usuario == null) {
      await prefs.remove('token');
      await prefs.remove('usuario');
      return;
    }
    await prefs.setString('token', token);
    await prefs.setString('usuario', jsonEncode(usuario!.toJson()));
  }

  Future<void> _limpiarSesion() async {
    api.token = null;
    usuario = null;
    items = [];
    productos = [];
    _pedidosPropios = {};
    errorCarrito = null;
    ultimoErrorPedido = null;
    ultimoAvisoSeguridad = null;
    notificaciones.limpiarSesion();
    await _guardar();
    notifyListeners();
  }

  // Traduce un error de la API y limpia la sesión si el token ya no sirve.
  Future<String?> _procesarError(ApiException e) async {
    if (e.sesionInvalida && logueado) {
      await _limpiarSesion();
      return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
    }
    return e.mensaje;
  }

  // ------------------------------------------------------------- autenticación

  Future<String?> iniciarSesion(String correo, String password) async {
    try {
      final guardada = await api.login(correo, password);
      api.token = guardada.token;
      usuario = guardada.usuario;
      await _guardar();
      await notificaciones.cargarParaUsuario(usuario!.id);
      notifyListeners();
      await cargarCatalogo();
      await cargarCarrito();
      await sincronizarNotificacionesPedidos();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
    required String veriPassword,
  }) async {
    try {
      final guardada = await api.registro(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
        password: password,
        veriPassword: veriPassword,
      );
      api.token = guardada.token;
      usuario = guardada.usuario;
      await _guardar();
      await notificaciones.cargarParaUsuario(usuario!.id);
      notifyListeners();
      await cargarCatalogo();
      await cargarCarrito();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<void> cerrarSesion() async {
    await api.logout();
    await _limpiarSesion();
  }

  // ------------------------------------------------------------------ catálogo

  Future<String?> cargarCatalogo({bool silencioso = false}) async {
    if (!logueado) {
      productos = [];
      errorCatalogo = 'Inicia sesión para consultar el catálogo.';
      if (!silencioso) notifyListeners();
      return errorCatalogo;
    }
    if (!silencioso) {
      cargandoCatalogo = true;
      errorCatalogo = null;
      notifyListeners();
    }
    try {
      productos = await api.productos();
      errorCatalogo = null;
      return null;
    } on ApiException catch (e) {
      errorCatalogo = await _procesarError(e);
      return errorCatalogo;
    } finally {
      if (!silencioso) {
        cargandoCatalogo = false;
        notifyListeners();
      }
    }
  }

  // ------------------------------------------------------------------- carrito

  Future<String?> cargarCarrito({bool silencioso = false}) async {
    if (!logueado) {
      items = [];
      if (!silencioso) notifyListeners();
      return null;
    }
    if (!silencioso) {
      cargandoCarrito = true;
      errorCarrito = null;
      notifyListeners();
    }
    try {
      items = await api.carrito();
      errorCarrito = null;
      return null;
    } on ApiException catch (e) {
      errorCarrito = await _procesarError(e);
      return errorCarrito;
    } finally {
      if (!silencioso) {
        cargandoCarrito = false;
        notifyListeners();
      }
    }
  }

  ItemCarrito? _itemDe(int productoId) {
    for (final item in items) {
      if (item.productoId == productoId) return item;
    }
    return null;
  }

  Future<String?> agregarAlCarrito(Producto producto, int cantidad) async {
    if (!logueado) return 'Debes iniciar sesión para comprar';

    final problema = calculo.validarCantidad(producto, cantidad);
    if (problema != null) return problema;

    // En Django cada producto aparece una sola vez en el carrito, con una
    // cantidad, así que si ya está se le suma a la existente.
    final existente = _itemDe(producto.id);

    try {
      if (existente == null) {
        final nuevo = await api.agregarAlCarrito(
          usuarioId: usuario!.id,
          productoId: producto.id,
          cantidad: cantidad,
        );
        items = [...items, nuevo];
      } else {
        final nueva = existente.cantidad + cantidad;
        final problemaTotal = calculo.validarCantidad(producto, nueva);
        if (problemaTotal != null) return problemaTotal;
        await api.actualizarCantidad(existente.id, nueva);
        existente.cantidad = nueva;
        items = [...items];
      }
      errorCarrito = null;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      final mensaje = await _procesarError(e);
      if (logueado) await cargarCarrito(silencioso: true);
      return mensaje;
    }
  }

  Future<String?> cambiarCantidad(ItemCarrito item, int nueva) async {
    final producto = productosPorId[item.productoId];
    if (producto != null) {
      final problema = calculo.validarCantidad(producto, nueva);
      if (problema != null) return problema;
    }
    try {
      await api.actualizarCantidad(item.id, nueva);
      item.cantidad = nueva;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return _procesarError(e);
    }
  }

  Future<String?> quitarItem(ItemCarrito item) async {
    try {
      await api.eliminarItem(item.id);
      items = items.where((i) => i.id != item.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return _procesarError(e);
    }
  }

  // ------------------------------------------------------------------- pedidos

  // Devuelve el pedido creado o null si hubo un error (ver ultimoErrorPedido)
  Future<PedidoCreado?> confirmarPedido() async {
    ultimoErrorPedido = null;
    if (!logueado) {
      ultimoErrorPedido = 'Debes iniciar sesión para comprar';
      return null;
    }
    if (items.isEmpty) {
      ultimoErrorPedido = 'El carrito está vacío';
      return null;
    }
    try {
      final pedido = await api.crearPedido();
      items = [];
      _pedidosPropios.add(pedido.id);
      await cargarCatalogo(silencioso: true);
      await notificaciones.registrarPedidoCreado(
        pedido.id,
        total: pedido.total,
      );
      notifyListeners();
      return pedido;
    } on ApiException catch (e) {
      // El servidor pudo rechazar el pedido: se refrescan los datos
      final mensaje = await _procesarError(e);
      if (logueado) {
        await cargarCarrito(silencioso: true);
        await cargarCatalogo(silencioso: true);
      }
      ultimoErrorPedido = mensaje;
      return null;
    }
  }

  Future<String?> registrarPago(int pedidoId, String metodo) async {
    if (!logueado) return 'Debes iniciar sesión para continuar';
    if (!_pedidosPropios.contains(pedidoId)) {
      return 'No puedes operar sobre un pedido que no pertenece a tu cuenta';
    }
    try {
      await api.registrarPago(pedidoId, metodo);
      await notificaciones.registrarPago(pedidoId, metodo);
      await cargarCatalogo(silencioso: true);
      await sincronizarNotificacionesPedidos();
      return null;
    } on ApiException catch (e) {
      return _procesarError(e);
    }
  }

  // Solo devuelve pedidos cuyo propietario es el usuario de la sesión. El
  // filtrado local es una defensa adicional: la autorización real debe hacerla
  // el backend a partir del token (ver docs/AUTORIZACION_PEDIDOS_DJANGO.md).
  Future<List<PedidoResumen>?> cargarPedidos() async {
    if (!logueado || usuario == null) {
      ultimoErrorPedido = 'Debes iniciar sesión para ver tus pedidos';
      return null;
    }

    try {
      final usuarioId = usuario!.id;
      final todos = await api.pedidos();
      final propios = todos.where((p) => p.usuarioId == usuarioId).toList();
      final ajenos = todos.length - propios.length;

      ultimoAvisoSeguridad = ajenos > 0
          ? 'El servidor devolvió $ajenos pedido(s) de otras cuentas. '
              'La app los ocultó, pero la autorización debe corregirse en el '
              'backend.'
          : null;

      _pedidosPropios = propios.map((p) => p.id).toSet();
      final idsPropios = _pedidosPropios;

      final detalles = idsPropios.isEmpty
          ? <DetallePedido>[]
          : (await api.detallePedidos())
              .where((d) => idsPropios.contains(d.pedidoId))
              .toList();
      final pagados = idsPropios.isEmpty
          ? <int>[]
          : (await api.pedidosPagados())
              .where(idsPropios.contains)
              .toSet();

      final resumenes = propios.map((pedido) {
        return PedidoResumen(
          pedido: pedido,
          detalles: detalles.where((d) => d.pedidoId == pedido.id).toList(),
          pagado: pagados.contains(pedido.id),
        );
      }).toList()
        ..sort((a, b) => b.pedido.id.compareTo(a.pedido.id));

      await notificaciones.sincronizarPedidos(propios);
      ultimoErrorPedido = null;
      return resumenes;
    } on ApiException catch (e) {
      ultimoErrorPedido = await _procesarError(e);
      return null;
    }
  }

  // Sondeo en primer plano para detectar cambios de estado sin abrir la lista
  // de pedidos. No muestra errores de red para no interrumpir al cliente.
  Future<void> sincronizarNotificacionesPedidos() async {
    if (!logueado || usuario == null) return;
    try {
      final usuarioId = usuario!.id;
      final propios = (await api.pedidos())
          .where((p) => p.usuarioId == usuarioId)
          .toList();
      _pedidosPropios = propios.map((p) => p.id).toSet();
      await notificaciones.sincronizarPedidos(propios);
    } on ApiException catch (e) {
      if (e.sesionInvalida && logueado) {
        await _limpiarSesion();
      }
    }
  }
}

// Instancia única que usan todas las pantallas
final Sesion sesion = Sesion();
