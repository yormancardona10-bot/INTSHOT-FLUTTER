import 'package:flutter/material.dart';

import '../pantallas/carrito.dart';
import '../pantallas/login.dart';
import '../pantallas/mis_pedidos.dart';
import '../servicios/sesion.dart';
import '../tema/colores.dart';

// Mensajes cortos en pantalla
void avisar(BuildContext context, String texto, {bool esError = false}) {
  final c = Colores.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: esError ? c.peligro : c.exito,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
        backgroundColor: c.pie,
      ),
    );
}

Future<void> abrirCarrito(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CarritoPantalla()),
  );
}

// Devuelve true si la persona terminó iniciando sesión
Future<bool?> abrirLogin(BuildContext context) {
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginPantalla()),
  );
}

Future<void> abrirMisPedidos(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MisPedidosPantalla()),
  );
}

// Botón cuadrado de la barra superior, como los .topbar-toggle de la web.
class _BotonBarra extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget? badge;

  const _BotonBarra({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    Widget contenido = Icon(icono, size: 21);
    if (badge != null) contenido = badge!;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: c.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Colores.radioSm),
            side: BorderSide(color: c.borde),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Colores.radioSm),
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: contenido),
            ),
          ),
        ),
      ),
    );
  }
}

// Icono del carrito con el contador de unidades
class IconoCarrito extends StatelessWidget {
  const IconoCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final unidades = sesion.unidadesEnCarrito;
        return _BotonBarra(
          icono: Icons.shopping_cart_outlined,
          tooltip: 'Carrito',
          onPressed: () => abrirCarrito(context),
          badge: unidades > 0
              ? Badge(
                  label: Text('$unidades'),
                  backgroundColor: c.peligro,
                  child: const Icon(Icons.shopping_cart_outlined, size: 21),
                )
              : null,
        );
      },
    );
  }
}

// Icono de la cuenta: inicia sesión o muestra las opciones del cliente
class IconoCuenta extends StatelessWidget {
  const IconoCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        return _BotonBarra(
          icono: sesion.logueado
              ? Icons.person_outline
              : Icons.login_outlined,
          tooltip: sesion.logueado ? 'Mi cuenta' : 'Iniciar sesión',
          onPressed: () => _mostrarOpciones(context),
        );
      },
    );
  }

  void _mostrarOpciones(BuildContext context) {
    if (!sesion.logueado) {
      abrirLogin(context);
      return;
    }

    final c = Colores.of(context);
    final usuario = sesion.usuario!;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: c.degradadoMarca,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                usuario.nombre.isNotEmpty
                    ? usuario.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              usuario.nombreCompleto,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(usuario.correo,
                style: TextStyle(color: c.textoSuave, fontSize: 13.5)),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.borde),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Mis pedidos'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                abrirMisPedidos(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: c.peligro),
              title: Text('Cerrar sesión', style: TextStyle(color: c.peligro)),
              onTap: () async {
                Navigator.pop(context);
                await sesion.cerrarSesion();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
