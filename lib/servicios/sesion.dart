import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/item_carrito.dart';
import '../modelos/pedido.dart';
import '../modelos/producto.dart';
import '../modelos/usuario.dart';
import '../utilidades/carrito_calc.dart' as calculo;
import 'api.dart';

// Estado de la sesión y del carrito. Es la única "fuente de verdad" de la
// app: las pantallas la escuchan con ListenableBuilder y se redibujan solas.
class Sesion extends ChangeNotifier {
  final Api api = Api();

  Usuario? usuario;
  List<Producto> productos = [];
  List<ItemCarrito> items = [];

  bool cargandoCatalogo = false;
  bool cargandoCarrito = false;
  String? errorCatalogo;
  String? errorCarrito;
  String? ultimoErrorPedido;

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
      if (token == null || datos == null) return;

      api.token = token;
      usuario = Usuario.fromJson(jsonDecode(datos) as Map<String, dynamic>);
      notifyListeners();

      // Comprueba que el token siga siendo válido
      final error = await cargarCarrito();
      if (error != null) {
        await cerrarSesion();
      }
    } catch (_) {
      await cerrarSesion();
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

  // ------------------------------------------------------------- autenticación

  Future<String?> iniciarSesion(String correo, String password) async {
    try {
      final guardada = await api.login(correo, password);
      api.token = guardada.token;
      usuario = guardada.usuario;
      await _guardar();
      await cargarCatalogo();
      await cargarCarrito();
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
      await cargarCarrito();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<void> cerrarSesion() async {
    await api.logout();
    api.token = null;
    usuario = null;
    items = [];
    await _guardar();
    notifyListeners();
  }

  // ------------------------------------------------------------------ catálogo

  Future<String?> cargarCatalogo({bool silencioso = false}) async {
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
      errorCatalogo = e.mensaje;
      return e.mensaje;
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
      errorCarrito = e.mensaje;
      return e.mensaje;
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
      await cargarCarrito(silencioso: true);
      return e.mensaje;
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
      return e.mensaje;
    }
  }

  Future<String?> quitarItem(ItemCarrito item) async {
    try {
      await api.eliminarItem(item.id);
      items = items.where((i) => i.id != item.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
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
      notifyListeners();
      return pedido;
    } on ApiException catch (e) {
      // El servidor pudo rechazar el pedido: se refrescan los datos
      await cargarCarrito(silencioso: true);
      await cargarCatalogo(silencioso: true);
      ultimoErrorPedido = e.mensaje;
      return null;
    }
  }

  Future<String?> registrarPago(int pedidoId, String metodo) async {
    try {
      await api.registrarPago(pedidoId, metodo);
      await cargarCatalogo(silencioso: true);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<List<PedidoResumen>?> cargarPedidos() async {
    try {
      final pedidos = await api.pedidos();
      final detalles = await api.detallePedidos();
      final pagados = await api.pedidosPagados();

      final resumenes = pedidos.map((pedido) {
        return PedidoResumen(
          pedido: pedido,
          detalles: detalles.where((d) => d.pedidoId == pedido.id).toList(),
          pagado: pagados.contains(pedido.id),
        );
      }).toList()
        ..sort((a, b) => b.pedido.id.compareTo(a.pedido.id));

      return resumenes;
    } on ApiException catch (e) {
      ultimoErrorPedido = e.mensaje;
      return null;
    }
  }
}

// Instancia única que usan todas las pantallas
final Sesion sesion = Sesion();
