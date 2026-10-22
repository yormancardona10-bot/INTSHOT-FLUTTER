import 'package:flutter/material.dart';

import '../tema/colores.dart';

// Imagen del producto tal como se ve en la tienda web: la foto se muestra
// completa (sin recortar) sobre un fondo gris claro y, cuando no hay imagen,
// aparece el logo de INTSHOT tenue en el centro.
class ImagenProducto extends StatelessWidget {
  final String? url;
  final double? ancho;
  final double? alto;

  const ImagenProducto({super.key, this.url, this.ancho, this.alto});

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);

    Widget contenido;
    if (url == null || url!.isEmpty) {
      contenido = _placeholder(context);
    } else {
      contenido = Image.network(
        url!,
        width: ancho,
        height: alto,
        fit: BoxFit.contain,
        loadingBuilder: (context, hijo, progreso) {
          if (progreso == null) return hijo;
          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progreso.expectedTotalBytes != null
                    ? progreso.cumulativeBytesLoaded /
                        progreso.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, traza) => _placeholder(context),
      );
    }

    return Container(
      width: ancho,
      height: alto,
      color: c.superficieTenue,
      alignment: Alignment.center,
      child: contenido,
    );
  }

  // Logo de la marca en tono muy bajo, igual que la web cuando el producto no
  // tiene foto cargada.
  Widget _placeholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: 0.3,
        child: Image.asset(
          'assets/img/Logo-INTSHOT.jpg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
