import 'package:flutter/material.dart';

import '../modelos/producto.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';
import '../widgets/tarjeta_producto.dart';
import 'catalogo.dart';
import 'detalle_producto.dart';

// Pantalla de bienvenida de la tienda INTSHOT
class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  @override
  void initState() {
    super.initState();
    // Se carga después del primer cuadro: pedir datos mientras se construye la
    // pantalla avisaría a la sesión en plena construcción del árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && sesion.productos.isEmpty) sesion.cargarCatalogo();
    });
  }

  void _abrirCatalogo([String? categoria]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogoPantalla(categoriaInicial: categoria),
      ),
    );
  }

  void _abrirDetalle(Producto producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleProductoPantalla(producto: producto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _Marca(),
        actions: const [
          IconoNotificaciones(),
          IconoCarrito(),
          IconoCuenta(),
        ],
      ),
      body: ListenableBuilder(
        listenable: sesion,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => sesion.cargarCatalogo(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _bienvenida(context),
                const SizedBox(height: 16),
                _franjaConfianza(context),
                const SizedBox(height: 22),
                if (sesion.cargandoCatalogo && sesion.productos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sesion.errorCatalogo != null &&
                    sesion.productos.isEmpty)
                  EstadoError(
                    mensaje: sesion.errorCatalogo!,
                    onReintentar: () => sesion.cargarCatalogo(),
                  )
                else ...[
                  _seccionDestacados(context),
                  const SizedBox(height: 24),
                  _seccionCategorias(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Tarjeta de bienvenida (como el hero de la web) ---
  Widget _bienvenida(BuildContext context) {
    final c = Colores.of(context);
    final nombre = sesion.usuario?.nombre.isNotEmpty == true
        ? sesion.usuario!.nombre
        : sesion.usuario?.correo;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.6),
          radius: 1.2,
          colors: c.degradadoBienvenida,
        ),
        border: Border.all(color: c.borde),
        borderRadius: BorderRadius.circular(Colores.radioLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Etiqueta(
            texto: 'TIENDA OFICIAL',
            color: c.primario,
            fondo: c.primarioSuave,
            icono: Icons.verified_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            sesion.logueado && nombre != null
                ? 'Hola, $nombre'
                : 'Bienvenido a INTSHOT',
            style: TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: c.primarioOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ropa, accesorios e insumos textiles. Consulta el catálogo real de '
            'la tienda y realiza tu pedido desde el celular.',
            style: TextStyle(fontSize: 14, color: c.textoSuave, height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _abrirCatalogo(),
                  icon: const Icon(Icons.storefront_outlined, size: 19),
                  label: const Text('Ver catálogo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: sesion.logueado
                    ? OutlinedButton.icon(
                        onPressed: () => abrirMisPedidos(context),
                        icon: const Icon(Icons.receipt_long_outlined, size: 19),
                        label: const Text('Mis pedidos'),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => abrirLogin(context),
                        icon: const Icon(Icons.login_outlined, size: 19),
                        label: const Text('Entrar'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Franja con los beneficios de comprar en INTSHOT ---
  Widget _franjaConfianza(BuildContext context) {
    final c = Colores.of(context);
    const items = [
      (Icons.local_shipping_outlined, 'Envíos'),
      (Icons.lock_outline, 'Pago seguro'),
      (Icons.support_agent_outlined, 'Asesoría'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Colores.radioLg),
        border: Border.all(color: c.borde),
      ),
      child: Row(
        children: [
          for (final (icono, texto) in items)
            Expanded(
              child: Column(
                children: [
                  Icon(icono, size: 22, color: c.primario),
                  const SizedBox(height: 6),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Productos destacados (carrusel horizontal) ---
  Widget _seccionDestacados(BuildContext context) {
    final destacados =
        sesion.productos.where((p) => p.disponible).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloSeccion(
          texto: 'Productos destacados',
          accionTexto: 'Ver todos',
          accion: () => _abrirCatalogo(),
        ),
        const SizedBox(height: 12),
        if (destacados.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colores.of(context).superficie,
              borderRadius: BorderRadius.circular(Colores.radioLg),
              border: Border.all(color: Colores.of(context).borde),
            ),
            child: Text(
              'No hay productos disponibles por el momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.of(context).textoSuave),
            ),
          )
        else
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: destacados.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final producto = destacados[i];
                return SizedBox(
                  width: 158,
                  child: TarjetaProducto(
                    producto: producto,
                    compacta: true,
                    onTap: () => _abrirDetalle(producto),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- Categorías disponibles ---
  Widget _seccionCategorias(BuildContext context) {
    final c = Colores.of(context);
    final categorias = sesion.productos
        .map((p) => p.categoria)
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (categorias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccion(texto: 'Explora por categoría'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final categoria in categorias)
              ActionChip(
                avatar: Icon(Icons.label_outline, size: 16, color: c.primario),
                label: Text(categoria),
                backgroundColor: c.superficie,
                side: BorderSide(color: c.borde),
                onPressed: () => _abrirCatalogo(categoria),
              ),
          ],
        ),
      ],
    );
  }
}

// Nombre de la marca en la barra superior, con el logo oficial.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/img/logo-intshot-icon.png', height: 26),
        const SizedBox(width: 8),
        Text(
          'INTSHOT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: c.primarioOscuro,
          ),
        ),
      ],
    );
  }
}
