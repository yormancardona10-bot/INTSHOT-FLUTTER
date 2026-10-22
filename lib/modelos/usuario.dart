// El cliente que inicia sesión en la app (inventario.Usuario en Django)
class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] ?? 0) as int,
      nombre: (json['nombre'] ?? '') as String,
      apellido: (json['apellido'] ?? '') as String,
      correo: (json['correo'] ?? '') as String,
      telefono: (json['telefono'] ?? '') as String,
      rol: (json['rol'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'rol': rol,
      };

  String get nombreCompleto =>
      (nombre.isEmpty && apellido.isEmpty) ? correo : '$nombre $apellido'.trim();
}
