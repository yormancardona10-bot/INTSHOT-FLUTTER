import 'package:flutter/material.dart';

import '../modelos/producto.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';
import '../widgets/tarjeta_producto.dart';
import 'detalle_producto.dart';

// Catálogo real: se lee desde la API de Django
class CatalogoPantalla extends StatefulWidget {
  final String? categoriaInicial;
  final String? buscarInicial;

  const CatalogoPantalla({super.key, this.categoriaInicial, this.buscarInicial});

  @override
  State<CatalogoPantalla> createState() => _CatalogoPantallaState();
}

class _CatalogoPantallaState extends State<CatalogoPantalla> {
  late final TextEditingController _buscar;
  String _categoria = '';

  @override
  void initState() {
    super.initState();
    _buscar = TextEditingController(text: widget.buscarInicial ?? '');
    _categoria = widget.categoriaInicial ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && sesion.productos.isEmpty) sesion.cargarCatalogo();
    });
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<Producto> _filtrados() {
    final texto = _buscar.text.trim().toLowerCase();
    return sesion.productos.where((producto) {
      final coincideCategoria =
          _categoria.isEmpty || producto.categoria == _categoria;
      final coincideBuscar = texto.isEmpty ||
          producto.nombre.toLowerCase().contains(texto) ||
          producto.descripcion.toLowerCase().contains(texto) ||
          producto.color.toLowerCase().contains(texto) ||
          producto.talla.toLowerCase().contains(texto) ||
          producto.categoria.toLowerCase().contains(texto);
      return coincideCategoria && coincideBuscar;
    }).toList();
  }

  void _abrirDetalle(Producto producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleProductoPantalla(producto: producto),
      ),
    );
  }

  // Agrega una unidad al carrito directo desde el catálogo.
  Future<void> _agregarRapido(Producto producto) async {
    if (!sesion.logueado) {
      final inicio = await abrirLogin(context);
      if (inicio != true || !mounted) return;
    }

    final error = await sesion.agregarAlCarrito(producto, 1);
    if (!mounted) return;
    if (error != null) {
      avisar(context, error, esError: true);
      return;
    }
    avisar(context, 'Se agregó "${producto.nombre}" al carrito');
  }

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: const [IconoCarrito()],
      ),
      body: ListenableBuilder(
        listenable: sesion,
        builder: (context, _) {
          if (sesion.cargandoCatalogo && sesion.productos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sesion.errorCatalogo != null && sesion.productos.isEmpty) {
            return EstadoError(
              mensaje: sesion.errorCatalogo!,
              onReintentar: () => sesion.cargarCatalogo(),
            );
          }

          final productos = _filtrados();

          return Column(
            children: [
              Container(
                color: c.superficie,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _buscar,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, color, talla o categoría',
                        prefixIcon: const Icon(Icons.search, size: 21),
                        suffixIcon: _buscar.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Limpiar',
                                onPressed: () {
                                  _buscar.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chipCategoria('Todas', ''),
                          for (final categoria in _categorias())
                            _chipCategoria(categoria, categoria),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.borde),
              if (productos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${productos.length} '
                      '${productos.length == 1 ? 'producto' : 'productos'}',
                      style: TextStyle(fontSize: 12.5, color: c.textoSuave),
                    ),
                  ),
                ),
              if (productos.isEmpty)
                Expanded(child: _vacio(sesion.productos.isEmpty))
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      mainAxisExtent: 344,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, i) => TarjetaProducto(
                      producto: productos[i],
                      onTap: () => _abrirDetalle(productos[i]),
                      onAgregar: () => _agregarRapido(productos[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<String> _categorias() {
    final categorias = sesion.productos
        .map((p) => p.categoria)
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categorias;
  }

  Widget _chipCategoria(String texto, String valor) {
    final c = Colores.of(context);
    final activo = _categoria == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        showCheckmark: false,
        selectedColor: c.primario,
        backgroundColor: c.superficie,
        side: BorderSide(color: activo ? c.primario : c.borde),
        labelStyle: TextStyle(
          color: activo ? Colors.white : c.texto,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        onSelected: (_) => setState(() => _categoria = valor),
      ),
    );
  }

  Widget _vacio(bool sinDatos) {
    return EstadoVacio(
      icono: sinDatos ? Icons.inventory_2_outlined : Icons.search_off,
      titulo: sinDatos ? 'Catálogo vacío' : 'Sin resultados',
      mensaje: sinDatos
          ? 'El catálogo está vacío por el momento.'
          : 'No hay productos que coincidan con tu búsqueda.',
      accionTexto: sinDatos ? 'Actualizar' : null,
      accion: sinDatos ? () => sesion.cargarCatalogo() : null,
    );
  }
}
