import 'package:flutter/material.dart';

import '../modelos/producto.dart';
import '../tema/colores.dart';
import '../utilidades/formato.dart';
import 'estado.dart';
import 'imagen_producto.dart';

// Tarjeta de producto, igual a la de la web (.producto-card): foto arriba,
// cuerpo con categoría, nombre y precio, y pie con los botones de acción.
class TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final VoidCallback? onAgregar;

  // Versión reducida para el carrusel de destacados
  final bool compacta;

  const TarjetaProducto({
    super.key,
    required this.producto,
    required this.onTap,
    this.onAgregar,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    final cuerpo = _cuerpo(c);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: compacta ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _imagen(context, c),
            // En la tarjeta normal el cuerpo se expande para que el pie quede
            // siempre abajo, sin importar el alto de la celda.
            if (compacta) cuerpo else Expanded(child: cuerpo),
            if (!compacta && onAgregar != null) ...[
              Divider(height: 1, color: c.borde),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Ver detalle'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Agregar al carrito',
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: FilledButton(
                          onPressed: producto.disponible ? onAgregar : null,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Icon(Icons.add_shopping_cart_outlined,
                              size: 19),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Categoría, nombre y precio
  Widget _cuerpo(Colores c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, compacta ? 12 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compacta ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!compacta && producto.categoria.isNotEmpty) ...[
            Etiqueta(
              texto: producto.categoria.toUpperCase(),
              color: c.primario,
              fondo: c.primarioSuave,
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: Text(
              producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compacta ? 14 : 14.5,
                fontWeight: FontWeight.w700,
                color: c.texto,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatoPesos(producto.precioDouble),
            style: TextStyle(
              fontSize: compacta ? 15 : 16.5,
              fontWeight: FontWeight.w800,
              color: c.primarioOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagen(BuildContext context, Colores c) {
    return Stack(
      children: [
        SizedBox(
          height: compacta ? 130 : 160,
          width: double.infinity,
          child: ImagenProducto(url: producto.imagenUrl),
        ),
        if (!producto.disponible)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: const Etiqueta(
                texto: 'AGOTADO',
                color: Colors.white,
                fondo: Color(0xCC000000),
                icono: Icons.block,
              ),
            ),
          )
        else if (producto.ultimasUnidades)
          Positioned(
            top: 8,
            right: 8,
            child: Etiqueta(
              texto: 'Últimas ${producto.stock}',
              color: c.alerta,
              fondo: c.alertaSuave,
              icono: Icons.local_fire_department_outlined,
            ),
          ),
      ],
    );
  }
}
