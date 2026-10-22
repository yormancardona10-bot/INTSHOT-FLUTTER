import '../modelos/item_carrito.dart';
import '../modelos/producto.dart';

// Cálculos del carrito escritos como funciones puras, para poder probarlos
// con `flutter test` sin tocar la red.

// Subtotal de una línea: cantidad * precio
double subtotalItem(int cantidad, double precio) => cantidad * precio;

// Total del carrito: suma de los subtotales de los productos que todavía
// existen en el catálogo. Si falta el producto no se suma nada.
double totalCarrito(
  List<ItemCarrito> items,
  Map<int, Producto> productos,
) {
  double total = 0;
  for (final item in items) {
    final producto = productos[item.productoId];
    if (producto == null) continue;
    total += subtotalItem(item.cantidad, producto.precioDouble);
  }
  return total;
}

// Devuelve null si la cantidad se puede comprar, o un mensaje en español si no.
String? validarCantidad(Producto producto, int cantidad) {
  if (cantidad < 1) {
    return 'La cantidad debe ser mínimo 1';
  }
  if (producto.stock <= 0) {
    return 'El producto ${producto.nombre} no tiene existencias';
  }
  if (cantidad > producto.stock) {
    return 'Solo hay ${producto.stock} unidades de ${producto.nombre}';
  }
  return null;
}
