import 'package:flutter_test/flutter_test.dart';
import 'package:intshot_flutter/modelos/item_carrito.dart';
import 'package:intshot_flutter/modelos/producto.dart';
import 'package:intshot_flutter/utilidades/carrito_calc.dart';
import 'package:intshot_flutter/utilidades/formato.dart';

Producto producto({
  int id = 1,
  int stock = 10,
  String precio = '25000.00',
  String nombre = 'Camiseta basica',
}) {
  return Producto(
    id: id,
    nombre: nombre,
    color: 'Negro',
    descripcion: 'Camiseta de algodón manga corta',
    talla: 'M',
    stock: stock,
    precio: precio,
    categoria: 'Camisetas',
    imagen: null,
  );
}

ItemCarrito item({int id = 1, int productoId = 1, int cantidad = 2}) {
  return ItemCarrito(
    id: id,
    usuarioId: 16,
    productoId: productoId,
    cantidad: cantidad,
  );
}

void main() {
  group('Cálculos del carrito', () {
    test('el subtotal es cantidad por precio', () {
      expect(subtotalItem(3, 25000), 75000);
      expect(subtotalItem(1, 500), 500);
      expect(subtotalItem(0, 1000), 0);
    });

    test('el total suma los subtotales de los productos del catálogo', () {
      final productos = {
        1: producto(id: 1, precio: '25000.00'),
        2: producto(id: 2, precio: '35000.00', nombre: 'Jean clasico'),
      };
      final items = [
        item(id: 1, productoId: 1, cantidad: 2), // 50.000
        item(id: 2, productoId: 2, cantidad: 1), // 35.000
      ];

      expect(totalCarrito(items, productos), 85000);
    });

    test('un producto que ya no existe no se suma al total', () {
      final productos = {1: producto(id: 1)};
      final items = [
        item(id: 1, productoId: 1, cantidad: 1),
        item(id: 2, productoId: 99, cantidad: 3),
      ];

      expect(totalCarrito(items, productos), 25000);
    });

    test('un carrito vacío tiene total en cero', () {
      expect(totalCarrito([], {}), 0);
    });
  });

  group('Validación de stock', () {
    test('acepta cantidades dentro del stock', () {
      expect(validarCantidad(producto(stock: 10), 1), isNull);
      expect(validarCantidad(producto(stock: 10), 10), isNull);
    });

    test('rechaza cantidades mayores al stock', () {
      final error = validarCantidad(producto(stock: 5, nombre: 'Pulsera'), 6);
      expect(error, 'Solo hay 5 unidades de Pulsera');
    });

    test('rechaza cantidades menores a 1', () {
      expect(validarCantidad(producto(), 0), 'La cantidad debe ser mínimo 1');
    });

    test('rechaza productos agotados', () {
      expect(validarCantidad(producto(stock: 0), 1),
          'El producto Camiseta basica no tiene existencias');
    });
  });

  group('Formato colombiano', () {
    test('convierte a pesos con puntos de miles', () {
      expect(formatoPesos(25000), r'$ 25.000');
      expect(formatoPesos(500), r'$ 500');
      expect(formatoPesos(1000000), r'$ 1.000.000');
      expect(formatoPesos(25000.0), r'$ 25.000');
      expect(formatoPesos('35000.00'), r'$ 35.000');
      expect(formatoPesos('no-numero'), r'$ 0');
    });

    test('muestra la fecha corta', () {
      expect(fechaCorta('2026-10-16T14:09:25.639545-05:00'), '16/10/2026');
      expect(fechaCorta(''), '');
    });
  });

  group('Producto desde la API', () {
    test('lee los campos reales de Django', () {
      final p = Producto.fromJson({
        'id': 3,
        'nombre': 'Chaqueta deportiva negra',
        'color': 'Negra',
        'descripcion': 'Chaqueta deportiva',
        'talla': 'L',
        'stock': 10,
        'precio': '50000.00',
        'categoria': 'Chaquetas',
        'imagen': 'http://127.0.0.1:8000/media/productos/chaqueta.webp',
      });

      expect(p.id, 3);
      expect(p.precioDouble, 50000);
      expect(p.disponible, isTrue);
      expect(p.ultimasUnidades, isFalse);
      // La URL de localhost se reescribe con la IP configurada
      expect(p.imagenUrl!.contains('127.0.0.1'), isFalse);
      expect(p.imagenUrl!.endsWith('/media/productos/chaqueta.webp'), isTrue);
    });

    test('los productos sin imagen no tienen URL', () {
      final p = Producto.fromJson({
        'id': 14,
        'nombre': 'Cierres y cremalleras',
        'color': 'Plateado',
        'descripcion': '',
        'talla': '',
        'stock': 50,
        'precio': '2000.00',
        'categoria': 'Insumos',
        'imagen': null,
      });

      expect(p.imagenUrl, isNull);
      expect(p.ultimasUnidades, isFalse);
    });
  });
}
