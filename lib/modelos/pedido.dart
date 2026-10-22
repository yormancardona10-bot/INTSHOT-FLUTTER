// Pedido (inventario.Pedido) y su detalle (inventario.DetallePedido)
class Pedido {
  final int id;
  final String fecha;
  final String estado;
  final int usuarioId;

  const Pedido({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.usuarioId,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: (json['id'] ?? 0) as int,
      fecha: (json['fecha'] ?? '') as String,
      estado: (json['estado'] ?? '') as String,
      usuarioId: (json['usuario'] ?? 0) as int,
    );
  }
}

class DetallePedido {
  final int id;
  final int pedidoId;
  final int productoId;
  final int cantidad;
  final String precioUnitario;

  const DetallePedido({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      id: (json['id'] ?? 0) as int,
      pedidoId: (json['pedido'] ?? 0) as int,
      productoId: (json['producto'] ?? 0) as int,
      cantidad: (json['cantidad'] ?? 0) as int,
      precioUnitario: (json['precio_unitario'] ?? '0') as String,
    );
  }

  double get precioDouble => double.tryParse(precioUnitario) ?? 0;
  double get subtotal => cantidad * precioDouble;
}

// Lo que ve el cliente en "Mis pedidos": pedido + sus detalles + si ya pagó
class PedidoResumen {
  final Pedido pedido;
  final List<DetallePedido> detalles;
  final bool pagado;

  const PedidoResumen({
    required this.pedido,
    required this.detalles,
    required this.pagado,
  });

  double get total => detalles.fold(0.0, (suma, d) => suma + d.subtotal);
}
