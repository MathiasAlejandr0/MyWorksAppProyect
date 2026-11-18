import 'worker_charge.dart';

const payoutOpenPaymentStatuses = {
  'autorizado',
  'retenido',
  'liberado',
  'pagado_por_confirmar',
};

const payoutClosedPaymentStatuses = {
  'reembolsado',
  'reembolsado_auto',
  'anulado',
  'fallido',
  'rechazado',
};

class PayoutMovement {
  const PayoutMovement({
    required this.paymentId,
    required this.jobId,
    required this.amountClp,
    required this.paymentStatus,
    int? grossClp,
    this.feeClp = 0,
    this.transferStatus,
    this.transferReference,
    this.settledAt,
  }) : grossClp = grossClp ?? amountClp + feeClp;

  factory PayoutMovement.fromCharge(WorkerCharge charge) => PayoutMovement(
        paymentId: charge.paymentId,
        jobId: charge.jobId,
        amountClp: charge.netClp,
        grossClp: charge.grossClp,
        feeClp: charge.feeClp,
        paymentStatus: charge.paymentStatus,
        transferStatus: charge.transferStatus,
        transferReference: charge.transferReference,
        settledAt: charge.settledAt,
      );

  final String paymentId;
  final String jobId;

  /// Neto para el profesional: bruto menos la comisión del servicio.
  final int amountClp;

  /// Lo que pagó el cliente.
  final int grossClp;

  /// Comisión del servicio descontada al profesional.
  final int feeClp;
  final String paymentStatus;

  /// `transferido` cuando el admin ya registró la transferencia.
  /// Null si todavía no hay liquidación.
  final String? transferStatus;
  final String? transferReference;
  final DateTime? settledAt;

  bool get isTransferred => transferStatus == 'transferido';

  bool get countsAsPending {
    if (isTransferred) return false;
    if (payoutClosedPaymentStatuses.contains(paymentStatus)) return false;
    return payoutOpenPaymentStatuses.contains(paymentStatus);
  }
}

class PayoutSummary {
  const PayoutSummary({required this.movements});

  final List<PayoutMovement> movements;

  /// Neto por transferir.
  int get pendingClp => movements
      .where((row) => row.countsAsPending)
      .fold(0, (sum, row) => sum + row.amountClp);

  int get pendingGrossClp => movements
      .where((row) => row.countsAsPending)
      .fold(0, (sum, row) => sum + row.grossClp);

  int get pendingFeeClp => movements
      .where((row) => row.countsAsPending)
      .fold(0, (sum, row) => sum + row.feeClp);

  Iterable<PayoutMovement> get _transferred =>
      movements.where((row) => row.isTransferred);

  /// Neto ya transferido al profesional.
  int get transferredClp =>
      _transferred.fold(0, (sum, row) => sum + row.amountClp);

  int get transferredGrossClp =>
      _transferred.fold(0, (sum, row) => sum + row.grossClp);

  int get transferredFeeClp =>
      _transferred.fold(0, (sum, row) => sum + row.feeClp);

  List<PayoutMovement> get history => movements
      .where((row) => row.transferStatus != null)
      .toList(growable: false);
}

String? validateBankAccount({
  required String bank,
  required String accountType,
  required String accountNumber,
  required String holderRut,
  required String holderName,
}) {
  if (bank.trim().length < 2) return 'Indica el banco';
  const types = {'vista', 'corriente', 'rut', 'ahorro'};
  if (!types.contains(accountType)) return 'Elige el tipo de cuenta';
  final digits = accountNumber.replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^\d{4,20}$').hasMatch(digits)) {
    return 'El número de cuenta debe tener entre 4 y 20 dígitos';
  }
  if (!isValidChileanRut(holderRut)) return 'Revisa el RUT del titular';
  if (holderName.trim().length < 3) return 'Indica el nombre del titular';
  return null;
}

String maskAccountNumber(String accountNumber) {
  final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return digits;
  return '•••• ${digits.substring(digits.length - 4)}';
}

bool isValidChileanRut(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
  if (cleaned.length < 2 || cleaned.length > 10) return false;
  final body = cleaned.substring(0, cleaned.length - 1);
  final check = cleaned.substring(cleaned.length - 1);
  if (!RegExp(r'^\d+$').hasMatch(body)) return false;
  var sum = 0;
  var factor = 2;
  for (var i = body.length - 1; i >= 0; i--) {
    sum += int.parse(body[i]) * factor;
    factor = factor == 7 ? 2 : factor + 1;
  }
  final mod = 11 - (sum % 11);
  final expected = mod == 11
      ? '0'
      : mod == 10
          ? 'K'
          : '$mod';
  return expected == check;
}
