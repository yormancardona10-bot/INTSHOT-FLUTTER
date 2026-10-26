# Informe de Pruebas — INTSHOT-FLUTTER

Fecha: 2026-10-23  
Proyecto: `INTSHOT-FLUTTER`  
Commit: `f52e8ec` — feat: harden order privacy and session handling  
Entorno: Flutter 3.50.0-1.0.pre-219 (channel master), Windows 11

## 1) Preparación del entorno

| Paso | Resultado | Notas |
|---|---|---|
| `flutter pub get` | OK | Dependencias resueltas correctamente. |
| `flutter analyze --no-pub` | WARNINGS/INFO | 26 issues encontrados, mayoritariamente `info` por uso de `package:flutter/material.dart` (deprecado en este canal master). No se detectaron errores bloqueantes para la compilación. |
| `flutter test test/carrito_test.dart test/tarjeta_test.dart` | OK (16/16) | Todas las pruebas existentes de carrito y tarjetas pasan. |
| `flutter test test/privacidad_pedidos_test.dart` | NO EJECUTADAS | Archivos eliminados al limpiar el proyecto. El plan de pruebas referencia pruebas que ya no existen en el repositorio. |
| `flutter test test/notificaciones_test.dart` | NO EJECUTADAS | Archivos eliminados al limpiar el proyecto. |
| `flutter test test/api_test.dart`, `flutter test test/widget_test.dart` | FALLOS AL CARGAR | Errores al cargar los tests (`loading ... [E]`) — requieren revisión puntual, no relacionados con los cambios hechos en el commit. |

## 2) Pruebas Manuales según PLAN_DE_PRUEBAS_INTSHOT.md

> Nota: No se ejecutaron pruebas manuales en emulador/dispositivo físico en este entorno. Se reporta el estado según lo indicado en el plan.

### FASE 2: Autenticación (Login)
| Prueba | Estado | Observación |
|---|---|---|
| 1) App limpia → debe mostrar Login | Pendiente (manual) | Requiere instalación limpia o borrado de datos. |
| 2) Login exitoso → redirige a Inicio/Catálogo | Pendiente (manual) | Requiere credenciales válidas. |
| 3) Persistencia tras cerrar app | Pendiente (manual) | Requiere ejecución en dispositivo/emulador. |
| 4) Cierre de sesión y navegación atrás | Pendiente (manual) | Requiere ejecución en dispositivo/emulador. |

### FASE 3: Privacidad de Pedidos (CRÍTICO)
| Prueba | Estado | Observación |
|---|---|---|
| 1) Usuario A solo ve sus pedidos | Pendiente (manual) | Requiere backend Django local con cambios aplicados o PythonAnywhere con los cambios. |
| 2) Usuario B solo ve sus pedidos | Pendiente (manual) | Requiere backend Django local con cambios aplicados o PythonAnywhere con los cambios. |
| 3) Acceso directo a pedido ajeno (API) | Pendiente (manual) | Requiere Postman/curl con token ajeno. El backend debe devolver 403/404. |
| 4) Token expirado | Pendiente (manual) | Requiere simular expiración en backend. |

### FASE 4: Notificaciones Locales
| Prueba | Estado | Observación |
|---|---|---|
| 1) Permisos en Android 13+/iOS | Pendiente (manual) | Requiere dispositivo físico/emulador con permisos. |
| 2) Icono de campanita visible | Pendiente (manual) | Requiere ejecución en app. |
| 3) Cambio de estado en admin → notificación in-app | Pendiente (manual) | Requiere backend Django local corriendo y sondeo activo. |
| 4) Notificación nativa en segundo plano | Pendiente (manual) | Requiere implementación de notificaciones locales activa. |

## 3) Hallazgos relevantes

- **CORS (bloqueador actual para web local):** Al correr Flutter Web en `http://localhost:8080` contra `https://intshot.pythonanywhere.com`, el navegador bloquea el login por falta de `Access-Control-Allow-Origin` en las respuestas del backend. Se creó `INSTRUCCIONES_CORS_PYTHONANYWHERE.md` con los pasos para añadir `django-cors-headers`.
- **Limpieza del proyecto:** Se restauró el código al estado del último commit y se eliminó código generado/innecesario. Las pruebas `privacidad_pedidos_test.dart` y `notificaciones_test.dart` creadas previamente fueron eliminadas junto con la carpeta `docs/` y archivos de notificaciones.
- **Cambios guardados:** El commit `f52e8ec` contiene los ajustes de privacidad de pedidos, gestión de sesión y mejoras en login/inicio/mis_pedidos según el trabajo realizado.

## 4) Recomendaciones

1. Aplicar los cambios CORS en PythonAnywhere (seguir `INSTRUCCIONES_CORS_PYTHONANYWHERE.md`).
2. Ejecutar las pruebas manuales del plan con backend accesible (Django local o PythonAnywhere tras configurar CORS).
3. Revisar `api_test.dart` y `widget_test.dart` para corregir los errores al cargar si se requieren pasar en CI.
4. Si se necesitan las pruebas de privacidad/notificaciones, restaurarlas desde historial git o volver a crearlas.

## Conclusión

**Estado general:** Parcialmente validado. Las pruebas unitarias existentes (carrito/tarjetas) pasan. Las pruebas automáticas específicas de privacidad/notificaciones ya no están en el repositorio tras la limpieza. Las pruebas manuales del plan quedan pendientes de ejecución en un entorno con backend y dispositivo/emulador.
