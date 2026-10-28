// Configuración de la dirección del servidor Django.
//
// Por defecto la app usa el despliegue de PythonAnywhere. Para probar contra
// el Django del computador (sin subir nada) se corre así:
//   flutter run --dart-define=API_URL=http://IP_DEL_COMPUTADOR:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://intshot.pythonanywhere.com',
  );
  static final String urlApi = '$baseUrl/api/v1';
}
