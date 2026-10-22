// Verificación de extremo a extremo del cliente Flutter contra un Django real.
//
//   dart run tool/verificar_api.dart
//
// Sirve para comprobar que la app habla con la API de verdad (catálogo, login,
// carrito, pedido y pago). Solo debe apuntarse a una copia de la base de datos,
// porque crea un pedido de prueba.
import 'dart:io';

import 'package:intshot_flutter/config/api_config.dart';
import 'package:intshot_flutter/modelos/producto.dart';
import 'package:intshot_flutter/servicios/api.dart';

int fallos = 0;
int pasos = 0;

void paso(String texto) => stdout.writeln('\n=== $texto ===');
void bien(String texto) {
  pasos++;
  stdout.writeln('  [ok] $texto');
}

void mal(String texto) {
  fallos++;
  stdout.writeln('  [FALLO] $texto');
}

void esperar(bool condicion, String texto) {
  condicion ? bien(texto) : mal(texto);
}

Future<void> main() async {
  stdout.writeln('Cliente Flutter -> ${ApiConfig.urlApi}');
  final api = Api();

  // ------------------------------------------------------------- catálogo
  paso('Catálogo público (sin iniciar sesión)');
  List<Producto> productos;
  try {
    productos = await api.productos();
  } on ApiException catch (e) {
    mal('No se pudo leer el catálogo: ${e.mensaje}');
    stdout.writeln('\n¿Django está corriendo en 0.0.0.0:8000?');
    exit(1);
  }
  esperar(productos.isNotEmpty, 'se listaron ${productos.length} productos');

  final conStock = productos.where((p) => p.stock >= 4).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (conStock.isEmpty) {
    mal('no hay productos con stock suficiente para probar');
    exit(1);
  }
  final elegido =
      productos.firstWhere((p) => p.nombre == 'Marquillas', orElse: () => conStock.first);
  bien('producto de prueba: #${elegido.id} "${elegido.nombre}" '
      '(stock ${elegido.stock}, precio ${elegido.precio})');

  // ---------------------------------------------------------------- login
  paso('Inicio de sesión');
  SesionGuardada sesion;
  try {
    sesion = await api.login('cliente@gmail.com', 'cliente');
  } on ApiException catch (e) {
    mal('login falló: ${e.mensaje}');
    exit(1);
  }
  api.token = sesion.token;
  bien('token recibido para ${sesion.usuario.correo} '
      '(usuario #${sesion.usuario.id}, rol ${sesion.usuario.rol})');

  paso('Credenciales incorrectas');
  try {
    await api.login('cliente@gmail.com', 'clave-mala');
    mal('el servidor aceptó una contraseña incorrecta');
  } on ApiException catch (e) {
    esperar(e.mensaje.contains('incorrectos'),
        'se rechazó con el mensaje "${e.mensaje}"');
  }

  // -------------------------------------------------------------- carrito
  paso('Carrito');
  for (final item in await api.carrito()) {
    await api.eliminarItem(item.id);
  }
  bien('carrito limpio al empezar');

  final item =
      await api.agregarAlCarrito(usuarioId: sesion.usuario.id, productoId: elegido.id, cantidad: 2);
  bien('se agregó ${elegido.nombre} x2 (línea #${item.id})');

  try {
    await api.agregarAlCarrito(
      usuarioId: sesion.usuario.id,
      productoId: elegido.id,
      cantidad: elegido.stock + 50,
    );
    mal('el servidor dejó pedir más unidades de las que hay');
  } on ApiException catch (e) {
    esperar(e.codigo == 400, 'se rechazó por stock: "${e.mensaje}"');
  }

  final actualizado = await api.actualizarCantidad(item.id, 3);
  esperar(actualizado.cantidad == 3, 'la cantidad se cambió a 3');

  final carrito = await api.carrito();
  esperar(carrito.length == 1 && carrito.first.cantidad == 3,
      'el carrito tiene 1 producto con 3 unidades');

  final totalEsperado = elegido.precioDouble * 3;
  paso('Pedido');
  final pedido = await api.crearPedido();
  esperar(pedido.id > 0, 'pedido #${pedido.id} creado (${pedido.mensaje})');
  esperar(pedido.total == totalEsperado,
      'total ${pedido.total} = 3 x ${elegido.precioDouble}');

  final carritoTrasPedido = await api.carrito();
  esperar(carritoTrasPedido.isEmpty, 'el carrito quedó vacío después de comprar');

  final pedidos = await api.pedidos();
  esperar(pedidos.any((p) => p.id == pedido.id), 'el pedido aparece en "Mis pedidos"');

  final detalles = await api.detallePedidos();
  final delPedido = detalles.where((d) => d.pedidoId == pedido.id).toList();
  esperar(delPedido.length == 1 && delPedido.first.cantidad == 3,
      'el detalle del pedido tiene el producto con 3 unidades');

  // ---------------------------------------------------------------- pago
  paso('Pago (registro de prueba)');
  final stockAntes = (await api.producto(elegido.id)).stock;
  await api.registrarPago(pedido.id, 'Efectivo');
  bien('pago registrado con método Efectivo');

  final stockDespues = (await api.producto(elegido.id)).stock;
  esperar(stockDespues == stockAntes - 3,
      'el inventario bajó de $stockAntes a $stockDespues');

  final pagados = await api.pedidosPagados();
  esperar(pagados.contains(pedido.id), 'el pedido figura como pagado');

  try {
    await api.registrarPago(pedido.id, 'Efectivo');
    mal('el servidor dejó pagar dos veces el mismo pedido');
  } on ApiException catch (e) {
    esperar(e.codigo == 400, 'no se puede pagar dos veces: "${e.mensaje}"');
  }

  // -------------------------------------------------------------- sesión
  paso('Cierre de sesión');
  await api.logout();
  api.token = null;
  try {
    await api.carrito();
    mal('sin token el servidor siguió respondiendo');
  } on ApiException catch (e) {
    esperar(e.codigo == 401 || e.codigo == 403,
        'sin token ya no se puede ver el carrito ("${e.mensaje}")');
  }

  stdout.writeln('\n---------------------------------------------');
  if (fallos == 0) {
    stdout.writeln('TODO BIEN: $pasos comprobaciones pasaron.');
  } else {
    stdout.writeln('$fallos de ${pasos + fallos} comprobaciones FALLARON.');
    exitCode = 1;
  }
  stdout.writeln('Pedido de prueba #${pedido.id} creado en la base de prueba.');
}
