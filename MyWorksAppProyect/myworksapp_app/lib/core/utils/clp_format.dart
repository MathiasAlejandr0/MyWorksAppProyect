import 'package:intl/intl.dart';

/// Pesos chilenos como se escriben en Chile: `$121.600`, sin decimales.
///
/// `NumberFormat.currency(locale: 'es_CL')` deja el símbolo al final
/// (`121.600 $`); este formato lo deja adelante en toda la app.
class ClpFormat {
  const ClpFormat();

  static final NumberFormat _digits = NumberFormat.decimalPattern('es_CL');

  String format(num value) {
    final amount = value.round();
    final digits = _digits.format(amount.abs());
    return amount < 0 ? '-\$$digits' : '\$$digits';
  }
}

String formatClp(num value) => const ClpFormat().format(value);
