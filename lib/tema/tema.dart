import 'package:flutter/material.dart';

import 'colores.dart';

// Tema de la aplicación construido con los colores de INTSHOT.
// En móvil se usa el mismo aspecto que la web: superficies claras, azul de
// marca, esquinas redondeadas y tipografía con títulos fuertes.
class Tema {
  static ThemeData claro() => _construir(Colores.claro, Brightness.light);
  static ThemeData oscuro() => _construir(Colores.oscuro, Brightness.dark);

  static ThemeData _construir(Colores c, Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: c.primario,
      brightness: brillo,
    ).copyWith(
      primary: c.primario,
      onPrimary: Colors.white,
      primaryContainer: c.primarioSuave,
      onPrimaryContainer: c.primarioOscuro,
      secondary: c.primarioOscuro,
      surface: c.superficie,
      onSurface: c.texto,
      onSurfaceVariant: c.textoSuave,
      error: c.peligro,
      onError: Colors.white,
      outline: c.bordeFuerte,
      outlineVariant: c.borde,
    );

    final titulos = TextStyle(
      color: c.texto,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: esquema,
      scaffoldBackgroundColor: c.fondo,
      dividerColor: c.borde,
      splashFactory: InkSparkle.splashFactory,

      // --- App bar: superficie con una línea inferior, como la web ---
      appBarTheme: AppBarTheme(
        backgroundColor: c.fondo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: c.borde)),
        titleTextStyle: titulos.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: c.primarioOscuro,
        ),
        iconTheme: IconThemeData(color: c.texto),
        actionsIconTheme: IconThemeData(color: c.texto),
      ),

      // --- Texto ---
      textTheme: TextTheme(
        titleLarge: titulos.copyWith(fontSize: 22),
        titleMedium: titulos.copyWith(fontSize: 17),
        titleSmall: titulos.copyWith(fontSize: 15),
        bodyLarge: TextStyle(color: c.texto, height: 1.45),
        bodyMedium: TextStyle(color: c.texto, height: 1.4),
        bodySmall: TextStyle(color: c.textoSuave, height: 1.35),
        labelLarge: TextStyle(
          color: c.texto,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),

      // --- Tarjetas ---
      cardTheme: CardThemeData(
        color: c.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Colores.radioLg),
          side: BorderSide(color: c.borde),
        ),
      ),

      // --- Botones (mismos radios y pesos que la web) ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.borde,
          disabledForegroundColor: c.textoDebil,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Colores.radioSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primario,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          side: BorderSide(color: c.primario, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Colores.radioSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primario,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.texto),
      ),

      // --- Campos de formulario ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.superficie,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: c.textoDebil, fontSize: 14),
        labelStyle: TextStyle(color: c.textoSuave, fontSize: 14),
        floatingLabelStyle: TextStyle(color: c.primario, fontSize: 14),
        prefixIconColor: c.textoDebil,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Colores.radioSm),
          borderSide: BorderSide(color: c.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Colores.radioSm),
          borderSide: BorderSide(color: c.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Colores.radioSm),
          borderSide: BorderSide(color: c.primario, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Colores.radioSm),
          borderSide: BorderSide(color: c.peligro),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Colores.radioSm),
          borderSide: BorderSide(color: c.peligro, width: 1.5),
        ),
        errorStyle: TextStyle(color: c.peligro),
      ),

      // --- Etiquetas / chips ---
      chipTheme: ChipThemeData(
        backgroundColor: c.superficie,
        selectedColor: c.primario,
        side: BorderSide(color: c.borde),
        labelStyle: TextStyle(
          color: c.texto,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // --- Mensajes flotantes ---
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.pie,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        actionTextColor: c.alerta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Colores.radioLg),
        ),
      ),

      // --- Diálogos y hojas inferiores ---
      dialogTheme: DialogThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Colores.radioGrande),
        ),
        titleTextStyle: titulos.copyWith(fontSize: 18),
        contentTextStyle: TextStyle(color: c.textoSuave, fontSize: 14, height: 1.4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.superficie,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.textoSuave,
        textColor: c.texto,
        titleTextStyle: TextStyle(
          color: c.texto,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primario),
      dividerTheme: DividerThemeData(color: c.borde, thickness: 1, space: 1),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.peligro,
        textColor: Colors.white,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
