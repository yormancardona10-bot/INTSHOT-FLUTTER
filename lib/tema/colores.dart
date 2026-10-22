import 'package:flutter/material.dart';

// Paleta de INTSHOT.
//
// Los colores están copiados de la web del proyecto Django
// (proyecto/static/css/theme.css), que es la identidad de la marca. Se
// mantienen los mismos tonos en modo claro y oscuro para que la app se vea
// como la tienda web.
class Colores {
  // --- Colores base ---
  final Color fondo;
  final Color superficie;
  final Color superficieTenue;
  final Color borde;
  final Color bordeFuerte;

  // --- Texto ---
  final Color texto;
  final Color textoSuave;
  final Color textoDebil;

  // --- Marca ---
  final Color primario;
  final Color primarioOscuro;
  final Color primarioSuave;

  // --- Estados ---
  final Color exito;
  final Color exitoSuave;
  final Color peligro;
  final Color peligroSuave;
  final Color alerta;
  final Color alertaSuave;
  final Color info;
  final Color infoSuave;

  // --- Pie de página / barra oscura ---
  final Color pie;

  // --- Degradados de marca ---
  final List<Color> degradadoBienvenida; // fondo claro del hero
  final List<Color> degradadoMarca; // franja azul
  final List<Color> degradadoAuth; // panel lateral del login

  const Colores({
    required this.fondo,
    required this.superficie,
    required this.superficieTenue,
    required this.borde,
    required this.bordeFuerte,
    required this.texto,
    required this.textoSuave,
    required this.textoDebil,
    required this.primario,
    required this.primarioOscuro,
    required this.primarioSuave,
    required this.exito,
    required this.exitoSuave,
    required this.peligro,
    required this.peligroSuave,
    required this.alerta,
    required this.alertaSuave,
    required this.info,
    required this.infoSuave,
    required this.pie,
    required this.degradadoBienvenida,
    required this.degradadoMarca,
    required this.degradadoAuth,
  });

  // Modo claro (el de la web por defecto)
  static const Colores claro = Colores(
    fondo: Color(0xFFF8FAFC),
    superficie: Color(0xFFFFFFFF),
    superficieTenue: Color(0xFFF1F5F9),
    borde: Color(0xFFE2E8F0),
    bordeFuerte: Color(0xFFCBD5E1),
    texto: Color(0xFF1E293B),
    textoSuave: Color(0xFF64748B),
    textoDebil: Color(0xFF94A3B8),
    primario: Color(0xFF0052CC),
    primarioOscuro: Color(0xFF003D9B),
    primarioSuave: Color(0x140052CC),
    exito: Color(0xFF16A34A),
    exitoSuave: Color(0xFFDCFCE7),
    peligro: Color(0xFFEF4444),
    peligroSuave: Color(0xFFFEE2E2),
    alerta: Color(0xFFF59E0B),
    alertaSuave: Color(0xFFFEF3C7),
    info: Color(0xFF0EA5E9),
    infoSuave: Color(0xFFE0F2FE),
    pie: Color(0xFF0F172A),
    degradadoBienvenida: [Color(0xFFE6EEFF), Color(0xFFFFFFFF)],
    degradadoMarca: [Color(0xFF0052CC), Color(0xFF003D9B)],
    degradadoAuth: [
      Color(0xFF0052CC),
      Color(0xFF003D9B),
      Color(0xFF001F4D),
    ],
  );

  // Modo oscuro (el mismo de la web)
  static const Colores oscuro = Colores(
    fondo: Color(0xFF0F172A),
    superficie: Color(0xFF1E293B),
    superficieTenue: Color(0xFF334155),
    borde: Color(0xFF334155),
    bordeFuerte: Color(0xFF475569),
    texto: Color(0xFFF1F5F9),
    textoSuave: Color(0xFF94A3B8),
    textoDebil: Color(0xFF64748B),
    primario: Color(0xFF5B9BF0),
    primarioOscuro: Color(0xFF7FB2F5),
    primarioSuave: Color(0x265B9BF0),
    exito: Color(0xFF4ADE80),
    exitoSuave: Color(0x2922C55E),
    peligro: Color(0xFFF87171),
    peligroSuave: Color(0x29EF4444),
    alerta: Color(0xFFFBBF24),
    alertaSuave: Color(0x29F59E0B),
    info: Color(0xFF38BDF8),
    infoSuave: Color(0x290EA5E9),
    pie: Color(0xFF0F172A),
    degradadoBienvenida: [Color(0xFF1E293B), Color(0xFF0F172A)],
    degradadoMarca: [Color(0xFF1D4ED8), Color(0xFF16307A)],
    degradadoAuth: [
      Color(0xFF1D4ED8),
      Color(0xFF16307A),
      Color(0xFF0B1220),
    ],
  );

  // Radios de la web
  static const double radioSm = 6;
  static const double radioLg = 12;
  static const double radioTarjeta = 14;
  static const double radioGrande = 20;
  static const double radioPill = 999;

  // Sombras de la web
  static List<BoxShadow> sombra({double nivel = 1}) {
    switch (nivel) {
      case 2:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
    }
  }

  // Según el tema que esté usando la aplicación
  static bool esOscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Colores of(BuildContext context) =>
      esOscuro(context) ? oscuro : claro;
}
