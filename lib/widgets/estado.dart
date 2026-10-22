import 'package:flutter/material.dart';

import '../tema/colores.dart';

// Etiqueta pequeña tipo "pastilla" (categoría, estado, stock...). Es la
// versión en Flutter de los badges de la web.
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color? fondo;
  final IconData? icono;
  final bool solida;

  const Etiqueta({
    super.key,
    required this.texto,
    required this.color,
    this.fondo,
    this.icono,
    this.solida = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = solida ? Colors.white : color;
    final colorFondo = solida ? color : (fondo ?? color.withValues(alpha: 0.12));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(Colores.radioPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: colorTexto),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorTexto,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Título de sección con un enlace opcional a la derecha ("Ver todo").
class TituloSeccion extends StatelessWidget {
  final String texto;
  final String? accionTexto;
  final VoidCallback? accion;

  const TituloSeccion({
    super.key,
    required this.texto,
    this.accionTexto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          texto,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: c.texto,
          ),
        ),
        if (accionTexto != null)
          TextButton(
            onPressed: accion,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(accionTexto!),
          ),
      ],
    );
  }
}

// Mensaje centrado cuando una lista está vacía.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? accionTexto;
  final VoidCallback? accion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accionTexto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.primarioSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 40, color: c.primario),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textoSuave, height: 1.4),
            ),
            if (accionTexto != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: accion, child: Text(accionTexto!)),
            ],
          ],
        ),
      ),
    );
  }
}

// Mensaje centrado cuando falla una carga (por ejemplo, sin conexión).
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const EstadoError({super.key, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.peligroSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_outlined, size: 40, color: c.peligro),
            ),
            const SizedBox(height: 18),
            Text(
              'No se pudo cargar la información',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textoSuave, height: 1.4),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
