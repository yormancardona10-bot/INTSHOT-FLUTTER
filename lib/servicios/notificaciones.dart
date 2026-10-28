import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/pedido.dart';
import '../utilidades/formato.dart';

// Un aviso que ve el cliente en la campana de la app
class Aviso {
  final int pedidoId;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  bool leido;

  Aviso({
    required this.pedidoId,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    this.leido = false,
  });

  factory Aviso.fromJson(Map<String, dynamic> json) {
    return Aviso(
      pedidoId: (json['pedido'] ?? 0) as int,
      titulo: (json['titulo'] ?? '') as String,
      mensaje: (json['mensaje'] ?? '') as String,
      fecha: DateTime.tryParse('${json['fecha']}') ?? DateTime.now(),
      leido: (json['leido'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'pedido': pedidoId,
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha': fecha.toIso8601String(),
        'leido': leido,
      };
}

// Avisos de los pedidos del cliente: se guardan en el teléfono (por usuario)
// y además se muestran como notificación del sistema Android.
//
// Django no envía notificaciones push, así que los cambios de estado se
// detectan comparando el estado de cada pedido con el último que se vio
// (ver Sesion.sincronizarNotificacionesPedidos, que se llama cada cierto
// tiempo mientras la app está abierta).
class Notificaciones extends ChangeNotifier {
  Notificaciones({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _pluginListo = false;

  static const int _maxAvisos = 50;

  int? _usuarioId;
  List<Aviso> avisos = [];

  // Último estado conocido de cada pedido: {id: estado}. Es null mientras no
  // se haya sincronizado nunca para este usuario; en ese caso la primera
  // sincronización solo guarda los estados, sin avisar de pedidos viejos.
  Map<int, String>? _estados;

  int get noLeidas => avisos.where((a) => !a.leido).length;

  String get _claveAvisos => 'avisos_$_usuarioId';
  String get _claveEstados => 'estados_pedidos_$_usuarioId';

  // ------------------------------------------------------------ sistema

  // Prepara las notificaciones de Android y pide el permiso (Android 13+).
  // Si falla (por ejemplo en las pruebas) la app sigue con los avisos internos.
  Future<void> iniciar() async {
    if (_pluginListo || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _pluginListo = true;
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  Future<void> _mostrarEnSistema(Aviso aviso) async {
    if (!_pluginListo) return;
    try {
      await _plugin.show(
        aviso.pedidoId,
        aviso.titulo,
        aviso.mensaje,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pedidos',
            'Pedidos',
            channelDescription: 'Avisos sobre el estado de tus pedidos',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
    }
  }

  // ------------------------------------------------------------ persistencia

  Future<void> cargarParaUsuario(int usuarioId) async {
    _usuarioId = usuarioId;
    avisos = [];
    _estados = null;
    try {
      final prefs = await SharedPreferences.getInstance();

      final textoAvisos = prefs.getString(_claveAvisos);
      if (textoAvisos != null) {
        avisos = (jsonDecode(textoAvisos) as List)
            .map((e) => Aviso.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final textoEstados = prefs.getString(_claveEstados);
      if (textoEstados != null) {
        final mapa = Map<String, dynamic>.from(jsonDecode(textoEstados) as Map);
        _estados = {
          for (final e in mapa.entries) int.parse(e.key): '${e.value}',
        };
      }
    } catch (_) {
      avisos = [];
      _estados = null;
    }
    notifyListeners();
  }

  Future<void> _guardar() async {
    if (_usuarioId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveAvisos,
      jsonEncode(avisos.map((a) => a.toJson()).toList()),
    );
    final estados = _estados;
    if (estados != null) {
      await prefs.setString(
        _claveEstados,
        jsonEncode({for (final e in estados.entries) '${e.key}': e.value}),
      );
    }
  }

  // Al cerrar sesión se olvida lo que hay en memoria. Lo guardado en el
  // teléfono se conserva para cuando ese mismo cliente vuelva a entrar.
  void limpiarSesion() {
    _usuarioId = null;
    avisos = [];
    _estados = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ avisos

  Future<void> _agregar(Aviso aviso) async {
    avisos = [aviso, ...avisos].take(_maxAvisos).toList();
    notifyListeners();
    await _guardar();
    await _mostrarEnSistema(aviso);
  }

  Future<void> registrarPedidoCreado(int pedidoId, {required double total}) async {
    if (_usuarioId == null) return;
    (_estados ??= {})[pedidoId] = 'Pendiente';
    await _agregar(Aviso(
      pedidoId: pedidoId,
      titulo: 'Pedido #$pedidoId recibido',
      mensaje: 'Recibimos tu pedido por ${formatoPesos(total)}. '
          'Te avisaremos cuando cambie de estado.',
      fecha: DateTime.now(),
    ));
  }

  Future<void> registrarPago(int pedidoId, String metodo) async {
    if (_usuarioId == null) return;
    await _agregar(Aviso(
      pedidoId: pedidoId,
      titulo: 'Pago del pedido #$pedidoId registrado',
      mensaje: 'Registramos tu pago con $metodo.',
      fecha: DateTime.now(),
    ));
  }

  // Compara los pedidos que llegan del servidor con los últimos estados
  // conocidos y crea un aviso por cada pedido nuevo o con estado distinto.
  Future<void> sincronizarPedidos(List<Pedido> pedidos) async {
    if (_usuarioId == null) return;

    final anteriores = _estados;
    final actuales = {for (final p in pedidos) p.id: p.estado};
    _estados = actuales;

    // Primera vez en este teléfono: solo se guarda la foto actual
    if (anteriores == null) {
      await _guardar();
      return;
    }

    final nuevos = <Aviso>[];
    for (final pedido in pedidos) {
      final antes = anteriores[pedido.id];
      if (antes == pedido.estado) continue;
      nuevos.add(antes == null
          ? Aviso(
              pedidoId: pedido.id,
              titulo: 'Nuevo pedido #${pedido.id}',
              mensaje: 'Se registró el pedido #${pedido.id} en tu cuenta '
                  '(estado: ${pedido.estado}).',
              fecha: DateTime.now(),
            )
          : Aviso(
              pedidoId: pedido.id,
              titulo: 'Pedido #${pedido.id}: ${pedido.estado}',
              mensaje: mensajeDeEstado(pedido.id, pedido.estado),
              fecha: DateTime.now(),
            ));
    }

    if (nuevos.isEmpty) {
      await _guardar();
      return;
    }
    for (final aviso in nuevos) {
      await _agregar(aviso);
    }
  }

  static String mensajeDeEstado(int pedidoId, String estado) {
    return switch (estado.toLowerCase()) {
      'pendiente' => 'Tu pedido #$pedidoId está pendiente de revisión.',
      'en proceso' => 'Estamos preparando tu pedido #$pedidoId.',
      'enviado' => 'Tu pedido #$pedidoId va en camino.',
      'entregado' =>
        'Tu pedido #$pedidoId fue entregado. ¡Gracias por comprar en INTSHOT!',
      'cancelado' => 'Tu pedido #$pedidoId fue cancelado.',
      _ => 'El estado de tu pedido #$pedidoId cambió a $estado.',
    };
  }

  Future<void> marcarTodasLeidas() async {
    if (noLeidas == 0) return;
    for (final aviso in avisos) {
      aviso.leido = true;
    }
    notifyListeners();
    await _guardar();
  }

  Future<void> borrarTodas() async {
    avisos = [];
    notifyListeners();
    await _guardar();
  }
}

// Instancia única que usan la sesión y las pantallas
final Notificaciones notificaciones = Notificaciones();
