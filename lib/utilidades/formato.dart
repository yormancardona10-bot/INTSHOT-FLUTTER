// Formato de dinero: pesos colombianos (25000 -> $ 25.000)
String formatoPesos(dynamic valor) {
  double numero;
  if (valor is double) {
    numero = valor;
  } else if (valor is int) {
    numero = valor.toDouble();
  } else {
    numero = double.tryParse(valor.toString()) ?? 0;
  }

  final entero = numero.truncate();
  final texto = entero.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return '\$ $texto';
}

// "2026-10-16T14:09:25.639545-05:00" -> "16/10/2026"
String fechaCorta(String fechaIso) {
  if (fechaIso.length < 10) return fechaIso;
  final parte = fechaIso.substring(0, 10).split('-');
  if (parte.length != 3) return fechaIso;
  return '${parte[2]}/${parte[1]}/${parte[0]}';
}
