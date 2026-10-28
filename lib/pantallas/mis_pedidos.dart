import 'package:flutter/material.dart';

import '../modelos/pedido.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../utilidades/formato.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';

// Lista de los pedidos del cliente, con su detalle y el pago (de prueba)
class MisPedidosPantalla extends StatefulWidget {
  const MisPedidosPantalla({super.key});

  @override
  State<MisPedidosPantalla> createState() => _MisPedidosPantallaState();
}

class _MisPedidosPantallaState extends State<MisPedidosPantalla> {
  bool _cargando = true;
  String? _error;
  List<PedidoResumen> _pedidos = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    if (sesion.productos.isEmpty) {
      await sesion.cargarCatalogo(silencioso: true);
    }

    final resumenes = await sesion.cargarPedidos();

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resumenes == null) {
        _error = sesion.ultimoErrorPedido ?? 'No se pudieron cargar tus pedidos';
      } else {
        _pedidos = resumenes;
      }
    });
  }

  Future<void> _registrarPago(PedidoResumen resumen) async {
    final c = Colores.of(context);

    final metodo = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Pago del pedido #${resumen.pedido.id}'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Registro de prueba dentro del sistema: no se cobra dinero ni se '
              'piden datos bancarios. Al registrarlo se descuenta el inventario.',
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
            child: Text('Cancelar', style: TextStyle(color: c.textoSuave)),
          ),
        ],
      ),
    );
    if (metodo == null || !mounted) return;

    final error = await sesion.registrarPago(resumen.pedido.id, metodo);
    if (!mounted) return;

    if (error != null) {
      avisar(context, error, esError: true);
    } else {
      avisar(context, 'Pago ($metodo) registrado correctamente');
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          const IconoNotificaciones(),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (!sesion.logueado) {
      return EstadoVacio(
        icono: Icons.receipt_long_outlined,
        titulo: 'Inicia sesión',
        mensaje: 'Necesitas una cuenta para ver tus pedidos.',
        accionTexto: 'Iniciar sesión',
        accion: () => abrirLogin(context),
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EstadoError(mensaje: _error!, onReintentar: _cargar);
    }

    final aviso = sesion.ultimoAvisoSeguridad;

    return Column(
      children: [
        if (aviso != null) _avisoSeguridad(aviso),
        Expanded(
          child: _pedidos.isEmpty
              ? const EstadoVacio(
                  icono: Icons.shopping_bag_outlined,
                  titulo: 'Sin pedidos todavía',
                  mensaje: 'Cuando realices tu primer pedido aparecerá aquí.',
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _pedidos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _tarjeta(_pedidos[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _avisoSeguridad(String mensaje) {
    final c = Colores.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.alertaSuave,
        borderRadius: BorderRadius.circular(Colores.radioSm),
        border: Border.all(color: c.alerta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: c.alerta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(fontSize: 12.5, color: c.texto, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(PedidoResumen resumen) {
    final c = Colores.of(context);
    final pedido = resumen.pedido;

    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Colores.radioLg),
        border: Border.all(color: c.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.texto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fechaCorta(pedido.fecha)}  ·  ${resumen.detalles.length} producto(s)',
                        style: TextStyle(fontSize: 13, color: c.textoSuave),
                      ),
                    ],
                  ),
                ),
                _estado(pedido.estado),
              ],
            ),
          ),
          if (resumen.detalles.isNotEmpty) _detalle(resumen),
          Divider(height: 1, color: c.borde),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(
                  resumen.pagado
                      ? Icons.verified_outlined
                      : Icons.hourglass_empty,
                  size: 17,
                  color: resumen.pagado ? c.exito : c.alerta,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resumen.pagado ? 'Pagado' : 'Pendiente de pago',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: resumen.pagado ? c.exito : c.alerta,
                    ),
                  ),
                ),
                Text(
                  formatoPesos(resumen.total),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.primarioOscuro,
                  ),
                ),
                if (!resumen.pagado &&
                    pedido.estado.toLowerCase() != 'cancelado') ...[
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => _registrarPago(resumen),
                    child: const Text('Pagar', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalle(PedidoResumen resumen) {
    final c = Colores.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.superficieTenue,
        borderRadius: BorderRadius.circular(Colores.radioSm),
        border: Border.all(color: c.borde),
      ),
      // Material transparente: sin él el fondo del Container tapa el efecto
      // al tocar el ExpansionTile
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          iconColor: c.primario,
          collapsedIconColor: c.textoSuave,
          title: Text(
            'Ver detalle',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: c.texto,
            ),
          ),
          children: [
            for (final detalle in resumen.detalles) _filaDetalle(detalle),
          ],
        ),
      ),
    );
  }

  Widget _filaDetalle(DetallePedido detalle) {
    final c = Colores.of(context);
    final producto = sesion.productosPorId[detalle.productoId];
    final nombre = producto?.nombre ?? 'Producto #${detalle.productoId}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$nombre  x${detalle.cantidad}',
              style: TextStyle(fontSize: 13, color: c.texto),
            ),
          ),
          Text(
            formatoPesos(detalle.subtotal),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.primarioOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estado(String estado) {
    final c = Colores.of(context);
    final color = switch (estado.toLowerCase()) {
      'entregado' => c.exito,
      'enviado' => c.primario,
      'en proceso' => c.info,
      'cancelado' => c.peligro,
      _ => c.alerta,
    };
    return Etiqueta(texto: estado.toUpperCase(), color: color);
  }
}
