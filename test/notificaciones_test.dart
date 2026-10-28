import 'package:flutter_test/flutter_test.dart';
import 'package:intshot_flutter/modelos/pedido.dart';
import 'package:intshot_flutter/servicios/notificaciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

Pedido pedido(int id, String estado) =>
    Pedido(id: id, fecha: '2026-10-27', estado: estado, usuarioId: 1);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('la primera sincronización no avisa de pedidos viejos', () async {
    final n = Notificaciones();
    await n.cargarParaUsuario(1);
    await n.sincronizarPedidos([pedido(1, 'Entregado')]);
    expect(n.avisos, isEmpty);
  });

  test('avisa cuando cambia el estado y cuando aparece un pedido', () async {
    final n = Notificaciones();
    await n.cargarParaUsuario(1);
    await n.sincronizarPedidos([pedido(1, 'Pendiente')]);

    await n.sincronizarPedidos([pedido(1, 'Enviado'), pedido(2, 'Pendiente')]);
    expect(n.avisos.map((a) => a.titulo),
        containsAll(['Pedido #1: Enviado', 'Nuevo pedido #2']));
    expect(n.noLeidas, 2);

    // Sin cambios no se repite el aviso
    await n.sincronizarPedidos([pedido(1, 'Enviado'), pedido(2, 'Pendiente')]);
    expect(n.avisos.length, 2);
  });

  test('el pedido creado desde la app no se avisa dos veces', () async {
    final n = Notificaciones();
    await n.cargarParaUsuario(1);
    await n.sincronizarPedidos([]);
    await n.registrarPedidoCreado(5, total: 25000);
    await n.sincronizarPedidos([pedido(5, 'Pendiente')]);
    expect(n.avisos.length, 1);
    expect(n.avisos.first.titulo, 'Pedido #5 recibido');
  });

  test('los avisos se guardan por usuario', () async {
    final n = Notificaciones();
    await n.cargarParaUsuario(1);
    await n.registrarPedidoCreado(5, total: 1000);
    await n.marcarTodasLeidas();

    await n.cargarParaUsuario(2);
    expect(n.avisos, isEmpty);

    await n.cargarParaUsuario(1);
    expect(n.avisos.length, 1);
    expect(n.noLeidas, 0);
  });
}
