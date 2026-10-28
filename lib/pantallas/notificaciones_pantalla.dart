import 'package:flutter/material.dart';

import '../servicios/notificaciones.dart';
import '../tema/colores.dart';
import '../widgets/comunes.dart';
import '../widgets/estado.dart';

// Lista de avisos de los pedidos del cliente (la campana de la barra)
class NotificacionesPantalla extends StatefulWidget {
  const NotificacionesPantalla({super.key});

  @override
  State<NotificacionesPantalla> createState() => _NotificacionesPantallaState();
}

class _NotificacionesPantallaState extends State<NotificacionesPantalla> {
  @override
  void dispose() {
    // Al salir de la pantalla los avisos quedan como leídos
    notificaciones.marcarTodasLeidas();
    super.dispose();
  }

  Future<void> _borrarTodas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar notificaciones'),
        content: const Text('¿Quieres borrar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar == true) await notificaciones.borrarTodas();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificaciones,
      builder: (context, _) {
        final avisos = notificaciones.avisos;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              if (avisos.isNotEmpty)
                IconButton(
                  tooltip: 'Borrar todas',
                  onPressed: _borrarTodas,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: avisos.isEmpty
              ? const EstadoVacio(
                  icono: Icons.notifications_none,
                  titulo: 'Sin notificaciones',
                  mensaje: 'Aquí te avisaremos cuando hagas un pedido o '
                      'cuando cambie su estado.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: avisos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _tarjeta(avisos[i]),
                ),
        );
      },
    );
  }

  Widget _tarjeta(Aviso aviso) {
    final c = Colores.of(context);
    return Material(
      color: aviso.leido ? c.superficie : c.primarioSuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Colores.radioLg),
        side: BorderSide(color: c.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Colores.radioLg),
        onTap: () => abrirMisPedidos(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.receipt_long_outlined, color: c.primario, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aviso.titulo,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: c.texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aviso.mensaje,
                      style: TextStyle(
                          fontSize: 13, color: c.textoSuave, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hace(aviso.fecha),
                      style: TextStyle(fontSize: 11.5, color: c.textoDebil),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hace(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 1) return 'Hace un momento';
    if (diferencia.inHours < 1) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'Hace ${diferencia.inHours} h';
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }
}
