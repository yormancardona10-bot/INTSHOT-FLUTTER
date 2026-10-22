import '../config/api_config.dart';

// Un producto tal como lo devuelve la API de Django (inventario.Producto)
class Producto {
  final int id;
  final String nombre;
  final String color;
  final String descripcion;
  final String talla;
  final int stock;
  final String precio; // "25000.00"
  final String categoria;
  final String? imagen;

  const Producto({
    required this.id,
    required this.nombre,
    required this.color,
    required this.descripcion,
    required this.talla,
    required this.stock,
    required this.precio,
    required this.categoria,
    this.imagen,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: (json['nombre'] ?? '') as String,
      color: (json['color'] ?? '') as String,
      descripcion: (json['descripcion'] ?? '') as String,
      talla: (json['talla'] ?? '') as String,
      stock: (json['stock'] ?? 0) as int,
      precio: (json['precio'] ?? '0') as String,
      categoria: (json['categoria'] ?? '') as String,
      imagen: json['imagen'] as String?,
    );
  }

  double get precioDouble => double.tryParse(precio) ?? 0;

  bool get disponible => stock > 0;

  bool get ultimasUnidades => stock > 0 && stock <= 5;

  // Construye la URL absoluta de la imagen. Django puede devolver la ruta
  // completa o relativa a /media/; en ese caso se antepone la URL base.
  String? get imagenUrl {
    final ruta = imagen;
    if (ruta == null || ruta.isEmpty) return null;

    if (ruta.startsWith('http://127.0.0.1') || ruta.startsWith('http://localhost')) {
      return ApiConfig.baseUrl + Uri.parse(ruta).path;
    }
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) return ruta;

    // Si es relativa a media
    if (ruta.startsWith('/media/') || ruta.contains('/media/')) {
      return ruta.startsWith('http') ? ruta : ApiConfig.baseUrl + (ruta.startsWith('/') ? ruta : '/$ruta');
    }
    return ApiConfig.baseUrl + (ruta.startsWith('/') ? ruta : '/$ruta');
  }
}
