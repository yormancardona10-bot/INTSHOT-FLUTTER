import 'package:flutter/material.dart';

import '../modelos/item_carrito.dart';
import '../servicios/api.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../utilidades/formato.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';
import '../widgets/imagen_producto.dart';
import 'catalogo.dart';
import 'detalle_producto.dart';

// Carrito real: los artículos viven en el servidor (inventario.Carrito)
class CarritoPantalla extends StatefulWidget {
  const CarritoPantalla({super.key});

  @override
  State<CarritoPantalla> createState() => _CarritoPantallaState();
}

class _CarritoPantallaState extends State<CarritoPantalla> {
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !sesion.logueado) return;
      sesion.cargarCarrito();
      if (sesion.productos.isEmpty) sesion.cargarCatalogo();
    });
  }

  Future<void> _cambiarCantidad(ItemCarrito item, int delta) async {
    final producto = sesion.productosPorId[item.productoId];
    if (producto == null) return;

    final nueva = item.cantidad + delta;
    final error = await sesion.cambiarCantidad(item, nueva);
    if (!mounted) return;
    if (error != null) {
      avisar(context, error, esError: true);
    } else if (nueva > producto.stock) {
      avisar(context, 'Solo hay ${producto.stock} unidades disponibles',
          esError: true);
    }
  }

  Future<void> _quitar(ItemCarrito item) async {
    final producto = sesion.productosPorId[item.productoId];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar del carrito'),
        content: Text(
            '¿Deseas quitar ${producto?.nombre ?? 'este producto'} del carrito?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final error = await sesion.quitarItem(item);
    if (!mounted) return;
    if (error != null) {
      avisar(context, error, esError: true);
    } else {
      avisar(context, 'Producto eliminado del carrito');
    }
  }

  Future<void> _confirmarPedido() async {
    if (_confirmando) return;

    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pedido'),
        content: const Text(
            'Se creará tu pedido con los productos del carrito. '
            'Ningún cargo se realiza en este momento.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (continuar != true || !mounted) return;

    setState(() => _confirmando = true);
    final pedido = await sesion.confirmarPedido();
    if (!mounted) return;
    setState(() => _confirmando = false);

    if (pedido == null) {
      avisar(context, sesion.ultimoErrorPedido ?? 'No se pudo crear el pedido',
          esError: true);
      return;
    }

    await _pedidoCreado(pedido);
  }

  Future<void> _pedidoCreado(PedidoCreado pedido) async {
    final c = Colores.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: c.exito, size: 48),
        title: const Text('Pedido creado'),
        content: Text(
          'Tu pedido #${pedido.id} quedó guardado en la tienda por '
          '${formatoPesos(pedido.total)}.\n\n${pedido.mensaje}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    await _registrarPago(pedido);
  }

  // Django no tiene integración con una pasarela de pago real: el "pago" solo
  // registra el método elegido y descuenta el inventario del sistema.
  Future<void> _registrarPago(PedidoCreado pedido) async {
    if (!mounted) return;
    final c = Colores.of(context);

    final metodo = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Registrar el pago'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Este es un registro de prueba dentro del sistema: no se cobra '
              'ningún dinero ni se piden datos bancarios.',
              style: TextStyle(fontSize: 13, color: c.textoSuave, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          for (final m in const ['Efectivo', 'Tarjeta', 'Transferencia'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Row(
                children: [
                  Icon(
                    switch (m) {
                      'Efectivo' => Icons.payments_outlined,
                      'Tarjeta' => Icons.credit_card_outlined,
                      _ => Icons.account_balance_outlined,
                    },
                    size: 20,
                    color: c.primario,
                  ),
                  const SizedBox(width: 12),
                  Text(m),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Ahora no', style: TextStyle(color: c.textoSuave)),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (metodo != null) {
      final error = await sesion.registrarPago(pedido.id, metodo);
      if (!mounted) return;
      if (error != null) {
        avisar(context, error, esError: true);
      } else {
        avisar(context, 'Pago ($metodo) registrado. Se descontó el inventario.');
      }
    }

    if (!mounted) return;
    await abrirMisPedidos(context);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: ListenableBuilder(
        listenable: sesion,
        builder: (context, _) {
          if (!sesion.logueado) return _sinSesion();
          if (sesion.cargandoCarrito && sesion.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sesion.errorCarrito != null && sesion.items.isEmpty) {
            return EstadoError(
              mensaje: sesion.errorCarrito!,
              onReintentar: () => sesion.cargarCarrito(),
            );
          }
          if (sesion.items.isEmpty) return _vacio();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => sesion.cargarCarrito(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: sesion.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _tarjeta(sesion.items[i]),
                  ),
                ),
              ),
              _pieCompra(),
            ],
          );
        },
      ),
    );
  }

  Widget _tarjeta(ItemCarrito item) {
    final c = Colores.of(context);
    final producto = sesion.productosPorId[item.productoId];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Colores.radioLg),
        border: Border.all(color: c.borde),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(Colores.radioSm),
            onTap: producto == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleProductoPantalla(producto: producto),
                      ),
                    ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c.superficieTenue,
                borderRadius: BorderRadius.circular(Colores.radioSm),
                border: Border.all(color: c.borde),
              ),
              clipBehavior: Clip.antiAlias,
              child: ImagenProducto(url: producto?.imagenUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto?.nombre ?? 'Producto #${item.productoId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.texto,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatoPesos(producto?.precioDouble ?? 0)} c/u',
                  style: TextStyle(fontSize: 13, color: c.textoSuave),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _botonCantidad(
                      c,
                      Icons.remove,
                      item.cantidad > 1 ? () => _cambiarCantidad(item, -1) : null,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${item.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: c.texto,
                        ),
                      ),
                    ),
                    _botonCantidad(
                      c,
                      Icons.add,
                      (producto == null || item.cantidad < producto.stock)
                          ? () => _cambiarCantidad(item, 1)
                          : null,
                    ),
                    const Spacer(),
                    Text(
                      formatoPesos(
                          (producto?.precioDouble ?? 0) * item.cantidad),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: c.primarioOscuro,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            onPressed: () => _quitar(item),
            icon: Icon(Icons.delete_outline, color: c.peligro, size: 21),
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
          width: 32,
          height: 32,
          child: Icon(
            icono,
            size: 18,
            color: activo ? c.primario : c.textoDebil,
          ),
        ),
      ),
    );
  }

  Widget _pieCompra() {
    final c = Colores.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: c.borde)),
        boxShadow: Colores.sombra(nivel: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sesion.unidadesEnCarrito} producto(s)',
                style: TextStyle(color: c.textoSuave, fontSize: 13.5),
              ),
              Text(
                formatoPesos(sesion.totalCarrito),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.primarioOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirmando ? null : _confirmarPedido,
              icon: _confirmando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_confirmando ? 'Creando pedido…' : 'Confirmar pedido'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sinSesion() {
    return EstadoVacio(
      icono: Icons.person_outline,
      titulo: 'Inicia sesión',
      mensaje: 'Necesitas una cuenta para ver tu carrito y realizar pedidos.',
      accionTexto: 'Iniciar sesión',
      accion: () => abrirLogin(context),
    );
  }

  Widget _vacio() {
    return EstadoVacio(
      icono: Icons.shopping_cart_outlined,
      titulo: 'Tu carrito está vacío',
      mensaje: 'Explora el catálogo y agrega los productos que te gusten.',
      accionTexto: 'Ver catálogo',
      accion: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CatalogoPantalla()),
      ),
    );
  }
}
