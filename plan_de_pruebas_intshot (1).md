# Plan de Pruebas y Validación — INTSHOT-FLUTTER

Este documento detalla los pasos para probar las tres grandes implementaciones realizadas en el proyecto: Flujo de Login, Aislamiento de Pedidos y Notificaciones Locales.

## FASE 1: Preparación del entorno y Pruebas Automáticas

Dado que el agente no pudo ejecutar los comandos de Flutter, el primer paso es validar que el código compile y pase los tests unitarios creados.

1. Abre tu terminal en la carpeta del proyecto Flutter (`INTSHOT-FLUTTER`).
2. Descarga las nuevas dependencias (como `flutter_local_notifications`):
   ```bash
   flutter pub get
   ```
3. Ejecuta el análisis de código para detectar errores de sintaxis:
   ```bash
   flutter analyze
   ```
4. Ejecuta las pruebas unitarias que OpenCode dejó preparadas:
   ```bash
   flutter test test/privacidad_pedidos_test.dart
   flutter test test/notificaciones_test.dart
   ```
   *(Si todo está verde, el código base está listo. Si hay errores, revísalos ya que pueden ser pequeñas fallas de sintaxis al inyectar el código).*

---

## FASE 2: Pruebas Manuales de Autenticación (Login)

**Objetivo:** Validar que nadie pueda entrar a la app sin sesión y que la sesión se mantenga si es válida.

- [ ] **Prueba 1 (App limpia):** Borra los datos de la app o desinstala/reinstala. Abre la app. **Debe mostrar directamente la pantalla de Login**, no el catálogo ni errores de carga.
- [ ] **Prueba 2 (Login exitoso):** Inicia sesión con un usuario válido. **Debe redirigirte al Inicio/Catálogo** y cargar los productos correctamente.
- [ ] **Prueba 3 (Persistencia):** Cierra la app por completo (mátala desde las apps recientes) y vuelve a abrirla. **Debe saltar el Login y entrar directo al catálogo**.
- [ ] **Prueba 4 (Cierre de sesión):** Usa el botón de cerrar sesión. **Debe borrar los datos, llevarte al Login** y, si intentas volver atrás (botón *back* de Android), no debe dejarte entrar a las pantallas privadas.

---

## FASE 3: Pruebas Manuales de Privacidad de Pedidos (CRÍTICO)

*Nota: Para que esto sea 100% real, debes tener corriendo el backend Django localmente con los cambios aplicados en las vistas.*

**Objetivo:** Garantizar que el Usuario A no vea cosas del Usuario B.

- [ ] **Prueba 1 (Aislamiento visual):** Inicia sesión con el `Usuario A`. Ve a "Mis Pedidos". Verifica que **solo ves los pedidos de A**.
- [ ] **Prueba 2 (Intercambio de cuentas):** Cierra sesión. Inicia sesión con el `Usuario B`. Ve a "Mis Pedidos". Verifica que **solo ves los pedidos de B** (ninguno de A).
- [ ] **Prueba 3 (Ataque de URL / API - opcional pero recomendado):** Si sabes usar Postman, intenta hacer una petición GET a `/api/pedidos/{ID_DEL_PEDIDO_DE_A}/` usando el Token de autenticación del `Usuario B`. **El servidor debe responder con un error 404 (Not Found) o 403 (Forbidden)**, nunca con los datos del pedido.
- [ ] **Prueba 4 (Token expirado):** (Simulado) Si el token expira o es revocado desde el panel de admin de Django, al intentar ver "Mis Pedidos" en la app, la pantalla debe manejar el error sin romperse y preferiblemente enviarte al Login.

---

## FASE 4: Pruebas Manuales de Notificaciones Locales

**Objetivo:** Validar que el sistema de sondeo genera alertas locales sin depender de Firebase.

- [ ] **Prueba 1 (Permisos):** Si pruebas en Android 13+ o iOS, al entrar por primera vez a la app o a la sección de notificaciones, **te debe solicitar el permiso nativo** para enviar notificaciones. Acéptalo.
- [ ] **Prueba 2 (Campanita):** Verifica que el icono de notificaciones aparezca en la AppBar del Inicio y de Mis Pedidos.
- [ ] **Prueba 3 (Cambio de estado en backend):** 
   1. Ten la app abierta en tu teléfono/emulador.
   2. Ve al panel de administrador de tu Django local (`/admin`).
   3. Cambia el estado de un pedido tuyo (por ejemplo, de "Pendiente" a "Enviado") y guarda.
   4. Espera unos segundos en la app de Flutter (el tiempo dependerá del intervalo de sondeo que haya programado OpenCode). **Debería aparecer una notificación in-app (Snackbar) o un globo/burbuja**.
- [ ] **Prueba 4 (Notificación del sistema - Opcional según implementación):** Minimiza la app (ponla en segundo plano). Cambia el estado de un pedido en el admin de Django. Al pasar unos segundos, **debería saltar una notificación push nativa en tu teléfono**.