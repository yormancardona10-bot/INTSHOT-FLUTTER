import 'package:flutter/material.dart';

import 'pantallas/inicio.dart';
import 'servicios/sesion.dart';
import 'tema/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Restaura la sesión guardada (token + usuario) si existe
  sesion.restaurar();
  runApp(const IntShotApp());
}

class IntShotApp extends StatelessWidget {
  const IntShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INTSHOT',
      debugShowCheckedModeBanner: false,
      // Usa la paleta de la marca (la misma de la web de INTSHOT)
      theme: Tema.claro(),
      darkTheme: Tema.oscuro(),
      themeMode: ThemeMode.system,
      home: const InicioPantalla(),
    );
  }
}
