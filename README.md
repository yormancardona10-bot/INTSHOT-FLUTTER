# INTSHOT — aplicación móvil del cliente (Flutter)

Aplicación Flutter para que un cliente de INTSHOT vea la tienda, consulte el
catálogo real que está guardado en Django, arme un carrito y confirme un pedido.

No incluye panel de administración ni módulos para empleados: solo la
experiencia del cliente (ver tienda → abrir producto → agregar al carrito →
confirmar pedido).

## Qué necesitas antes de empezar

1. **Python y el proyecto Django** (`INTSHOT-django-main`) funcionando.
2. **Flutter** instalado (`flutter --version`).
3. El **teléfono Android** conectado por USB con la *depuración USB* activada
   (o un emulador), en la **misma red Wi-Fi** que el computador.

## 1. Dirección del servidor

Toda la dirección de la API está en un solo archivo: `lib/config/api_config.dart`.

```dart
class ApiConfig {
  static const String host = '10.2.90.44'; // IP local de ESTE computador
  static const int puerto = 8000;
}
```

- **Teléfono físico:** usa la IP local del computador (la que muestra
  `hostname -I`). Nunca `127.0.0.1` ni `localhost`: desde el teléfono eso
  apuntaría al propio teléfono.
- **Emulador Android:** usa `10.0.2.2`, que es el computador visto desde el
  emulador.

Si cambias de red, vuelve a mirar la IP con `hostname -I` y actualiza este
archivo.

## 2. Arrancar Django

Desde la carpeta `INTSHOT-django-main/proyecto` y con el entorno virtual activo:

```bash
python manage.py runserver 0.0.0.0:8000
```

`0.0.0.0` es importante: así Django escucha también en la red local y el
teléfono puede conectarse. Comprueba desde el navegador del teléfono que
`http://IP_DEL_COMPUTADOR:8000/api/v1/productos/` responde.

Si no carga, revisa el firewall del computador y que el teléfono esté en la
misma red Wi-Fi.

## 3. Ejecutar la aplicación

```bash
flutter pub get
flutter devices                       # mira el ID del teléfono
flutter run -d ID_DEL_DISPOSITIVO     # ej: flutter run -d HT7A1...
```

Con la aplicación ya instalada, los cambios de código se aplican con `r`
(hot reload) en la consola donde corre `flutter run`.

## 4. Pruebas y revisiones

```bash
flutter analyze                                   # errores y avisos del código
flutter test                                      # pruebas del carrito y de la API
dart run tool/verificar_api.dart                  # prueba real contra Django
```

`tool/verificar_api.dart` hace una compra completa contra un Django encendido
(catálogo, login, carrito, pedido y pago) y va mostrando `[ok]`/`[FALLO]`.
**Úsala solo contra una copia de la base de datos**, porque crea un pedido de
prueba.

## Endpoints de Django que usa la aplicación

| Acción | Método y ruta |
| --- | --- |
| Catálogo (público) | `GET /api/v1/productos/` |
| Detalle de producto | `GET /api/v1/productos/{id}/` |
| Iniciar sesión | `POST /api/v1/auth/login/` |
| Registro de cliente | `POST /api/v1/auth/registro/` |
| Cerrar sesión | `POST /api/auth/logout/` |
| Ver / agregar al carrito | `GET`, `POST /api/v1/carritos/` |
| Cambiar cantidad / quitar | `PATCH`, `DELETE /api/v1/carritos/{id}/` |
| Confirmar pedido | `POST /api/v1/pedidos/crear-desde-carrito/` |
| Mis pedidos | `GET /api/v1/pedidos/` y `GET /api/v1/detallePedidos/` |
| Registrar el pago | `POST /api/v1/pedidos/{id}/registrar-pago/` |

## Sobre el pago

Django no tiene una pasarela de pago real conectada. El botón **Pagar** solo
**registra el método** elegido (Efectivo, Tarjeta o Transferencia) y descuenta
el inventario, igual que hace la web. La aplicación lo avisa antes de usarlo:
no se cobra dinero ni se piden datos bancarios.

## Producción: usar HTTPS

En desarrollo la aplicación habla con Django por HTTP sin cifrar y por eso
`android/app/src/debug/AndroidManifest.xml` y
`android/app/src/profile/AndroidManifest.xml` tienen
`android:usesCleartextTraffic="true"`.

**En producción hay que usar HTTPS y quitar esa línea.** No se puede publicar
una aplicación que envíe contraseñas sin cifrar.
