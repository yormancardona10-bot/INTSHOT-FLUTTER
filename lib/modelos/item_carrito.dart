// Una línea del carrito (inventario.Carrito en Django).
// El precio y la imagen no están aquí: se buscan en el producto correspondiente.
class ItemCarrito {
  final int id;
  final int usuarioId;
  final int productoId;
  int cantidad;

  ItemCarrito({
    required this.id,
    required this.usuarioId,
    required this.productoId,
    required this.cantidad,
  });

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      id: (json['id'] ?? 0) as int,
      usuarioId: (json['usuario'] ?? 0) as int,
      productoId: (json['producto'] ?? 0) as int,
      cantidad: (json['cantidad'] ?? 1) as int,
    );
  }
}
