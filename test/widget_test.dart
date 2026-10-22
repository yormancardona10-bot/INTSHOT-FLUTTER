import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intshot_flutter/pantallas/login.dart';

void main() {
  testWidgets('el formulario de login valida antes de llamar al servidor',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPantalla()),
    );

    // Campos vacíos: no se debe intentar conectar con Django
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Debes digitar el correo'), findsOneWidget);
    expect(find.text('Debes digitar la contraseña'), findsOneWidget);

    // Correo mal escrito
    await tester.enterText(find.byType(TextFormField).first, 'no-es-correo');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('El correo no es válido'), findsOneWidget);
  });

  testWidgets('se puede mostrar y ocultar la contraseña', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPantalla()),
    );

    final campoClave =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(campoClave.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    final campoVisible =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(campoVisible.obscureText, isFalse);
  });
}
