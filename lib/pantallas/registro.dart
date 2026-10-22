import 'package:flutter/material.dart';

import '../servicios/sesion.dart';
import '../tema/colores.dart';
import '../widgets/comunes.dart';

// Registro de un cliente nuevo (mismas reglas que la web de Django)
class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _veriPassword = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    _password.dispose();
    _veriPassword.dispose();
    super.dispose();
  }

  Future<void> _registrarme() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _cargando = true);

    final error = await sesion.registrar(
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      correo: _correo.text.trim(),
      telefono: _telefono.text.trim(),
      password: _password.text,
      veriPassword: _veriPassword.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (error == null) {
      avisar(context, 'Cuenta creada. ¡Bienvenido a INTSHOT!');
      Navigator.pop(context, true);
    } else {
      avisar(context, error, esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Colores.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Solo necesitamos unos datos para que puedas comprar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textoSuave, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
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
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) {
                        final texto = (v ?? '').trim();
                        if (texto.isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        final sinEspacios = texto.replaceAll(' ', '');
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$')
                            .hasMatch(sinEspacios)) {
                          return 'El nombre solo puede tener letras';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _apellido,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) {
                        final texto = (v ?? '').trim();
                        if (texto.isEmpty) {
                          return 'El apellido es obligatorio';
                        }
                        final sinEspacios = texto.replaceAll(' ', '');
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$')
                            .hasMatch(sinEspacios)) {
                          return 'El apellido solo puede tener letras';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: (v) {
                        final texto = (v ?? '').trim();
                        if (texto.isEmpty) return 'El correo es obligatorio';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(texto)) {
                          return 'El correo no es válido. Ejemplo: nombre@correo.com';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _telefono,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        hintText: 'Ej: 3001234567',
                      ),
                      validator: (v) {
                        final texto = (v ?? '').trim();
                        if (texto.isEmpty) return 'El teléfono es obligatorio';
                        if (!RegExp(r'^\d+$').hasMatch(texto)) {
                          return 'El teléfono solo puede tener números';
                        }
                        if (texto.length < 7) {
                          return 'El teléfono debe tener mínimo 7 números';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                        helperText: 'Mínimo 5 caracteres',
                      ),
                      validator: (v) => (v ?? '').length < 5
                          ? 'La contraseña debe tener mínimo 5 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _veriPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                      validator: (v) => (v ?? '') != _password.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _cargando ? null : _registrarme,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
