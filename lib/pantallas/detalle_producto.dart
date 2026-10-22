import 'package:flutter/material.dart';

import '../modelos/producto.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../utilidades/carrito_calc.dart';
import '../utilidades/formato.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';
import '../widgets/imagen_producto.dart';

// Ficha completa de un producto
class DetalleProductoPantalla extends StatefulWidget {
  final Producto producto;

  const DetalleProductoPantalla({super.key, required this.producto});

  @override
  State<DetalleProductoPantalla> createState() =>
      _DetalleProductoPantallaState();
}

class _DetalleProductoPantallaState extends State<DetalleProductoPantalla> {
  late Producto _producto;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    // Si el catálogo ya trae una versión más nueva del producto, se usa esa
    final actualizado = sesion.productosPorId[_producto.id];
    if (actualizado != null) _producto = actualizado;
  }

  void _cambiarCantidad(int delta) {
    final nueva = _cantidad + delta;
    if (nueva < 1 || nueva > _producto.stock) return;
    setState(() => _cantidad = nueva);
  }

  Future<void> _agregar({bool irAlCarrito = false}) async {
    if (!sesion.logueado) {
      final inicio = await abrirLogin(context);
      if (inicio != true || !mounted) return;
    }

    final error = await sesion.agregarAlCarrito(_producto, _cantidad);
    if (!mounted) return;

    if (error != null) {
      avisar(context, error, esError: true);
      return;
    }

    if (irAlCarrito) {
      await abrirCarrito(context);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Se agregó "${_producto.nombre}" al carrito'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () => abrirCarrito(context),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _producto.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [IconoCarrito()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _foto(c),
          const SizedBox(height: 18),
          _etiquetas(c),
          const SizedBox(height: 12),
          Text(
            _producto.nombre,
            style: TextStyle(
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: c.texto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatoPesos(_producto.precioDouble),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: c.primarioOscuro,
            ),
          ),
          const SizedBox(height: 14),
          _atributos(c),
          if (_producto.descripcion.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _producto.descripcion,
              style: TextStyle(fontSize: 14.5, height: 1.55, color: c.textoSuave),
            ),
          ],
          const SizedBox(height: 16),
          _disponibilidad(c),
          const SizedBox(height: 22),
          if (_producto.disponible) ...[
            _selectorCantidad(c),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _agregar(),
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
              label: Text(
                'Agregar al carrito  ·  '
                '${formatoPesos(subtotalItem(_cantidad, _producto.precioDouble))}',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _agregar(irAlCarrito: true),
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: const Text('Comprar ahora'),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.peligroSuave,
                borderRadius: BorderRadius.circular(Colores.radioLg),
                border: Border.all(color: c.peligro.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: c.peligro, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Este producto no tiene existencias en este momento.',
                      style: TextStyle(
                        color: c.peligro,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // Foto en una tarjeta con borde, como en la web
  Widget _foto(Colores c) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Colores.radioLg),
        border: Border.all(color: c.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: ImagenProducto(url: _producto.imagenUrl),
    );
  }

  Widget _etiquetas(Colores c) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_producto.categoria.isNotEmpty)
          Etiqueta(
            texto: _producto.categoria.toUpperCase(),
            color: c.primario,
            fondo: c.primarioSuave,
            icono: Icons.label_outline,
          ),
        if (_producto.disponible)
          Etiqueta(
            texto: 'Disponible',
            color: c.exito,
            fondo: c.exitoSuave,
            icono: Icons.check_circle_outline,
          )
        else
          Etiqueta(
            texto: 'Agotado',
            color: c.peligro,
            fondo: c.peligroSuave,
            icono: Icons.cancel_outlined,
          ),
      ],
    );
  }

  Widget _atributos(Colores c) {
    final atributos = <(IconData, String)>[
      if (_producto.color.isNotEmpty)
        (Icons.palette_outlined, 'Color: ${_producto.color}'),
      if (_producto.talla.isNotEmpty)
        (Icons.straighten_outlined, 'Talla: ${_producto.talla}'),
    ];
    if (atributos.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icono, texto) in atributos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: c.superficie,
              borderRadius: BorderRadius.circular(Colores.radioSm),
              border: Border.all(color: c.borde),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 16, color: c.textoSuave),
                const SizedBox(width: 6),
                Text(
                  texto,
                  style: TextStyle(fontSize: 13, color: c.texto),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _disponibilidad(Colores c) {
    if (_producto.stock <= 0) return const SizedBox.shrink();

    final Color color;
    final IconData icono;
    final String texto;
    if (_producto.ultimasUnidades) {
      color = c.alerta;
      icono = Icons.warning_amber_rounded;
      texto = '¡Solo quedan ${_producto.stock} unidades!';
    } else {
      color = c.exito;
      icono = Icons.check_circle_outline;
      texto = 'Disponible: ${_producto.stock} unidades';
    }

    return Row(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _selectorCantidad(Colores c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Colores.radioLg),
        border: Border.all(color: c.borde),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cantidad',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.texto,
            ),
          ),
          Row(
            children: [
              _botonCantidad(
                c,
                Icons.remove,
                _cantidad > 1 ? () => _cambiarCantidad(-1) : null,
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '$_cantidad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.texto,
                  ),
                ),
              ),
              _botonCantidad(
                c,
                Icons.add,
                _cantidad < _producto.stock ? () => _cambiarCantidad(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonCantidad(Colores c, IconData icono, VoidCallback? accion) {
    final activo = accion != null;
    return Material(
      color: activo ? c.primarioSuave : c.superficieTenue,
      borderRadius: BorderRadius.circular(Colores.radioSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Colores.radioSm),
        onTap: accion,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icono,
            size: 20,
            color: activo ? c.primario : c.textoDebil,
          ),
        ),
      ),
    );
  }
}
