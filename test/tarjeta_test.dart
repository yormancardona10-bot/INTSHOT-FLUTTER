import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intshot_flutter/modelos/producto.dart';
import 'package:intshot_flutter/tema/tema.dart';
import 'package:intshot_flutter/widgets/tarjeta_producto.dart';

// Producto con nombre largo para forzar dos líneas en la tarjeta.
const _producto = Producto(
  id: 1,
  nombre: 'Camiseta básica de algodón manga larga azul',
  color: 'Azul',
  descripcion: 'Camiseta cómoda',
  talla: 'M',
  stock: 3,
  precio: '25000.00',
  categoria: 'Camisetas',
  imagen: null,
);

Future<void> _pump(
  WidgetTester tester,
  Widget tarjeta,
  Size tamano,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: Tema.claro(),
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(size: tamano, child: tarjeta),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la tarjeta del catálogo no desborda (grid)', (tester) async {
    await _pump(
      tester,
      TarjetaProducto(
        producto: _producto,
        onTap: () {},
        onAgregar: () {},
      ),
      const Size(185, 344), // celda real del GridView
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ver detalle'), findsOneWidget);
  });

  testWidgets('la tarjeta compacta no desborda (destacados)', (tester) async {
    await _pump(
      tester,
      TarjetaProducto(
        producto: _producto,
        compacta: true,
        onTap: () {},
      ),
      const Size(158, 232), // celda real del carrusel
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta agotada no desborda', (tester) async {
    await _pump(
      tester,
      TarjetaProducto(
        producto: const Producto(
          id: 2,
          nombre: 'Jean clásico',
          color: 'Azul',
          descripcion: '',
          talla: '32',
          stock: 0,
          precio: '90000.00',
          categoria: 'Pantalones',
          imagen: null,
        ),
        onTap: () {},
        onAgregar: () {},
      ),
      const Size(185, 344),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('AGOTADO'), findsOneWidget);
  });

  testWidgets('categoría larga no desborda la tarjeta', (tester) async {
    await _pump(
      tester,
      TarjetaProducto(
        producto: const Producto(
          id: 3,
          nombre: 'Gorra',
          color: 'Negro',
          descripcion: '',
          talla: 'U',
          stock: 10,
          precio: '35000.00',
          categoria: 'Accesorios textiles para caballero y dama',
          imagen: null,
        ),
        onTap: () {},
        onAgregar: () {},
      ),
      const Size(185, 344),
    );

    expect(tester.takeException(), isNull);
  });
}
