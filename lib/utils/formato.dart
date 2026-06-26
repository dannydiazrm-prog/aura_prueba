import 'package:flutter/services.dart';

class Formato {
  static String miles(num valor) {
    final partes = valor.toInt().toString().split('');
    String resultado = '';
    int contador = 0;
    for (int i = partes.length - 1; i >= 0; i--) {
      if (contador > 0 && contador % 3 == 0) resultado = '.$resultado';
      resultado = partes[i] + resultado;
      contador++;
    }
    return resultado;
  }

  static int parseMiles(String valor) {
    return int.tryParse(valor.replaceAll('.', '')) ?? 0;
  }
}

class MilesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final soloDigitos = newValue.text.replaceAll('.', '');
    if (soloDigitos.isEmpty) return newValue.copyWith(text: '');
    final numero = int.tryParse(soloDigitos);
    if (numero == null) return oldValue;
    final formateado = Formato.miles(numero);
    return newValue.copyWith(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}