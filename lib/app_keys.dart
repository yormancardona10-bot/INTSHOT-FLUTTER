import 'package:flutter/material.dart';

// Llaves globales de la app: permiten mostrar mensajes y navegar desde
// lugares que no tienen un BuildContext (por ejemplo, al cerrar la sesión).
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
