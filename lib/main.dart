import 'package:flutter/material.dart';

import 'app_keys.dart';
import 'pantallas/arranque.dart';
import 'tema/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IntShotApp());
}

class IntShotApp extends StatelessWidget {
  const IntShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INTSHOT',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      navigatorKey: navigatorKey,
      // Usa la paleta de la marca (la misma de la web de INTSHOT)
      theme: Tema.claro(),
      darkTheme: Tema.oscuro(),
      themeMode: ThemeMode.system,
      home: const ArranquePantalla(),
    );
  }
}
