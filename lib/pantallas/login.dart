import 'package:flutter/material.dart';

import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../widgets/comunes.dart';
import 'registro.dart';

// Inicio de sesión contra la API de Django
class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _cargando = true);

    final error = await sesion.iniciarSesion(
      _correo.text.trim(),
      _password.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      avisar(context, error, esError: true);
    }
  }

  Future<void> _crearCuenta() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegistroPantalla()),
    );
    if (creado == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/img/logo-intshot-icon.png',
                  height: 72,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Entra a tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: c.primarioOscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Necesitas una cuenta para guardar tu carrito y realizar pedidos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textoSuave, fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.superficie,
                  borderRadius: BorderRadius.circular(Colores.radioGrande),
                  border: Border.all(color: c.borde),
                  boxShadow: Colores.sombra(nivel: 3),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (valor) {
                          final v = (valor ?? '').trim();
                          if (v.isEmpty) return 'Debes digitar el correo';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'El correo no es válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _ocultarClave,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarClave
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _ocultarClave = !_ocultarClave),
                          ),
                        ),
                        validator: (valor) => (valor ?? '').isEmpty
                            ? 'Debes digitar la contraseña'
                            : null,
                        onFieldSubmitted: (_) => _entrar(),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _cargando ? null : _entrar,
                        child: _cargando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _cargando ? null : _crearCuenta,
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
