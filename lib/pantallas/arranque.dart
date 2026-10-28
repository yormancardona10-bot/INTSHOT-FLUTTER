import 'dart:async';

import 'package:flutter/material.dart';

import '../app_keys.dart';
import '../servicios/notificaciones.dart';
import '../servicios/sesion.dart';
import 'inicio.dart';
import 'login.dart';

// Primera pantalla de la app: recupera la sesión guardada y decide qué
// mostrar. Sin sesión se ve el login; con sesión, la tienda. Mientras hay
// sesión revisa cada cierto tiempo si cambió el estado de algún pedido.
class ArranquePantalla extends StatefulWidget {
  const ArranquePantalla({super.key});

  // Cada cuánto se consulta el estado de los pedidos con la app abierta
  static const Duration intervaloRevision = Duration(seconds: 30);

  @override
  State<ArranquePantalla> createState() => _ArranquePantallaState();
}

class _ArranquePantallaState extends State<ArranquePantalla>
    with WidgetsBindingObserver {
  bool _restaurando = true;
  bool _estabaLogueado = false;
  Timer? _revision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sesion.addListener(_alCambiarSesion);
    _iniciar();
  }

  Future<void> _iniciar() async {
    await notificaciones.iniciar();
    await sesion.restaurar();
    if (!mounted) return;
    setState(() => _restaurando = false);
    _alCambiarSesion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sesion.removeListener(_alCambiarSesion);
    _revision?.cancel();
    super.dispose();
  }

  void _alCambiarSesion() {
    final logueado = sesion.logueado;
    if (logueado == _estabaLogueado) return;
    _estabaLogueado = logueado;

    if (logueado) {
      _empezarRevision();
    } else {
      _revision?.cancel();
      // Al cerrar sesión (o si vence el token) se vuelve al login aunque el
      // cliente esté en otra pantalla.
      navigatorKey.currentState?.popUntil((ruta) => ruta.isFirst);
    }
  }

  void _empezarRevision() {
    _revision?.cancel();
    _revision = Timer.periodic(
      ArranquePantalla.intervaloRevision,
      (_) => sesion.sincronizarNotificacionesPedidos(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (!sesion.logueado) return;
    if (estado == AppLifecycleState.resumed) {
      // Al volver a la app se revisa de una vez y se reanuda el sondeo
      sesion.sincronizarNotificacionesPedidos();
      _empezarRevision();
    } else if (estado == AppLifecycleState.paused) {
      _revision?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurando) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/img/logo-intshot-icon.png', height: 84),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) =>
          sesion.logueado ? const InicioPantalla() : const LoginPantalla(),
    );
  }
}
