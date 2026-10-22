import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intshot_flutter/servicios/api.dart';

void main() {
  // Respuesta típica de DRF/JSON
  http.Response ok(Object cuerpo, {int estado = 200}) =>
      http.Response(estado == 204 ? '' : jsonEncode(cuerpo), estado);

  group('Catálogo', () {
    test('lista los productos del backend real', () async {
      late Uri urlPedida;
      final api = Api(
        cliente: MockClient((request) async {
          urlPedida = request.url;
          return ok([
            {
              'id': 15,
              'nombre': 'Marquillas',
              'color': 'Blanco',
              'descripcion': 'Marquillas para producto',
              'talla': 'Unica',
              'stock': 200,
              'precio': '500.00',
              'categoria': 'Insumos',
              'imagen': null,
            },
          ]);
        }),
      );

      final productos = await api.productos();

      expect(productos, hasLength(1));
      expect(productos.single.nombre, 'Marquillas');
      expect(productos.single.precioDouble, 500);
      expect(urlPedida.path, endsWith('/api/v1/productos/'));
      // El catálogo se puede pedir sin iniciar sesión
      expect(urlPedida.queryParameters, isEmpty);
    });

    test('un error del servidor se vuelve ApiException en español', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => http.Response('{"error": "El carrito está vacío"}', 400),
        ),
      );

      expect(
        api.crearPedido,
        throwsA(isA<ApiException>()
            .having((e) => e.mensaje, 'mensaje', 'El carrito está vacío')
            .having((e) => e.codigo, 'codigo', 400)),
      );
    });

    test('si Django no contesta, el mensaje aconseja revisar el servidor',
        () async {
      final api = Api(
        cliente: MockClient((_) async => throw Exception('sin red')),
      );

      expect(
        api.productos,
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje,
            'mensaje',
            allOf(contains('No se pudo conectar'), contains(':8000')))),
      );
    });
  });

  group('Inicio de sesión', () {
    final respuestaLogin = {
      'token': 'abc123',
      'usuario': {
        'id': 16,
        'nombre': 'Cliente',
        'apellido': 'Demo',
        'correo': 'cliente@gmail.com',
        'telefono': '3001234567',
        'rol': 'Cliente',
      },
    };

    test('devuelve el token y los datos del usuario', () async {
      late http.Request capturada;
      final api = Api(
        cliente: MockClient((request) async {
          capturada = request;
          return ok(respuestaLogin);
        }),
      );

      final sesion = await api.login('cliente@gmail.com', 'cliente');

      expect(sesion.token, 'abc123');
      expect(sesion.usuario.id, 16);
      expect(sesion.usuario.nombreCompleto, 'Cliente Demo');
      expect(capturada.url.path, endsWith('/api/v1/auth/login/'));
      expect(capturada.headers['Authorization'], isNull);
      expect(capturada.body, contains('cliente@gmail.com'));
    });

    test('contraseña incorrecta: muestra el mensaje de Django', () async {
      final api = Api(
        cliente: MockClient(
          (_) async =>
              http.Response('{"error": "Usuario o contraseña incorrectos"}', 401),
        ),
      );

      expect(
        api.login('cliente@gmail.com', 'mala'),
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje, 'mensaje', 'Usuario o contraseña incorrectos')),
      );
    });

    test('correo vacío: muestra la validación de Django', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => http.Response(
              '{"error": "Debe digitar el correo y la contraseña"}', 400),
        ),
      );

      expect(
        api.login('', ''),
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Debe digitar el correo y la contraseña')),
      );
    });

    test('acciones protegidas sin token: pide iniciar sesión', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => http.Response('{"detail": "No autenticado"}', 403),
        ),
      );

      expect(
        api.carrito(),
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje, 'mensaje', 'Debes iniciar sesión para continuar.')),
      );
    });

    test('token vencido: avisa que hay que entrar de nuevo', () async {
      final api = Api()
        ..token = 'vencido';
      final cliente = MockClient(
        (_) async => http.Response('{"error": "El Token ha expirado"}', 401),
      );
      final apiConRed = Api(cliente: cliente)..token = 'vencido';

      expect(
        api.token,
        'vencido',
        reason: 'la sesión guardada se vuelve a cargar al abrir la app',
      );
      expect(
        apiConRed.carrito(),
        throwsA(isA<ApiException>()
            .having((e) => e.mensaje, 'mensaje', 'El Token ha expirado')
            .having((e) => e.codigo, 'codigo', 401)),
      );
      // sin mensaje en el cuerpo, se usa el genérico
      final apiGenerica = Api(
        cliente: MockClient((_) async => http.Response('', 401)),
      )..token = 'x';
      expect(
        apiGenerica.carrito(),
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Tu sesión ha expirado. Inicia sesión de nuevo.')),
      );
    });
  });

  group('Carrito', () {
    test('las peticiones llevan el token de la sesión', () async {
      late http.Request capturada;
      final api = Api(
        cliente: MockClient((request) async {
          capturada = request;
          return ok(<Map<String, dynamic>>[]);
        }),
      )..token = 'mi-token';

      await api.carrito();

      expect(capturada.headers['Authorization'], 'Token mi-token');
      expect(capturada.url.path, endsWith('/api/v1/carritos/'));
    });

    test('si el producto supera el stock, el backend responde 400', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => http.Response(
              '{"error": "Solo hay 5 unidades de Marquillas"}', 400),
        ),
      );

      expect(
        api.agregarAlCarrito(usuarioId: 16, productoId: 15, cantidad: 6),
        throwsA(isA<ApiException>().having(
            (e) => e.mensaje, 'mensaje', 'Solo hay 5 unidades de Marquillas')),
      );
    });
  });

  group('Pedidos', () {
    test('lee el pedido recién creado', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => ok({
            'pedido': {'id': 41, 'total': '85000.00'},
            'mensaje': 'Pedido #41 creado correctamente',
          }),
        ),
      );

      final pedido = await api.crearPedido();

      expect(pedido.id, 41);
      expect(pedido.total, 85000);
      expect(pedido.mensaje, contains('41'));
    });

    test('lista los pedidos y sus detalles', () async {
      final api = Api(
        cliente: MockClient(
          (_) async => ok([
            {
              'id': 41,
              'fecha': '2026-10-16T14:09:25.639545-05:00',
              'estado': 'Pendiente',
              'usuario': 16,
            },
          ]),
        ),
      );

      final pedidos = await api.pedidos();

      expect(pedidos.single.estado, 'Pendiente');
      expect(pedidos.single.usuarioId, 16);
    });

    test('registra el método de pago elegido', () async {
      late String cuerpo;
      final api = Api(
        cliente: MockClient((request) async {
          cuerpo = request.body;
          return ok({'pago': {'id': 7}});
        }),
      );

      await api.registrarPago(41, 'Efectivo');

      expect(cuerpo, contains('Efectivo'));
    });
  });

  group('Mensajes de error de Django', () {
    test('lee error, detail, mensaje y errores', () {
      expect(Api.mensajeDeError({'error': 'X'}), 'X');
      expect(Api.mensajeDeError({'detail': 'Y'}), 'Y');
      expect(Api.mensajeDeError({'mensaje': 'Z'}), 'Z');
      expect(
        Api.mensajeDeError({
          'errores': ['A', 'B'],
        }),
        'A\nB',
      );
      expect(Api.mensajeDeError({'nombre': ['Requerido']}) != null, isTrue);
      expect(Api.mensajeDeError(null), isNull);
      expect(Api.mensajeDeError('texto'), 'texto');
    });
  });
}
