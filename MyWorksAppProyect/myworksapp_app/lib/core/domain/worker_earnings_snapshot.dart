/// Resumen de cobros del profesional (demo / escrow simulado).
class WorkerEarningsSnapshot {
  final int escrowClp;
  final int releasedClp;
  final int pendingClp;
  final int paymentCount;

  /// Variación entera de lo liberado este mes contra el mes anterior.
  /// Null cuando el mes anterior no tiene liberaciones: la tarjeta no inventa un %.
  final int? growthPercent;

  const WorkerEarningsSnapshot({
    required this.escrowClp,
    required this.releasedClp,
    required this.pendingClp,
    required this.paymentCount,
    this.growthPercent,
  });

  static const zero = WorkerEarningsSnapshot(
    escrowClp: 0,
    releasedClp: 0,
    pendingClp: 0,
    paymentCount: 0,
  );

  int get totalRecordedClp => escrowClp + releasedClp + pendingClp;
}

/// Porcentaje de pagos liberados del mes civil de [now] contra el mes anterior.
///
/// [at] y [now] ya vienen en la misma hora civil (en la app, Santiago).
/// Si el mes anterior no suma liberaciones, devuelve null.
int? releasedMonthOverMonthPercent({
  required Iterable<({int amountClp, DateTime at})> released,
  required DateTime now,
}) {
  final previous = _shiftMonth(now, -1);
  var currentSum = 0;
  var previousSum = 0;
  for (final payment in released) {
    if (payment.amountClp <= 0) continue;
    if (_sameMonth(payment.at, now)) {
      currentSum += payment.amountClp;
    } else if (_sameMonth(payment.at, previous)) {
      previousSum += payment.amountClp;
    }
  }
  if (previousSum <= 0) return null;
  return ((currentSum - previousSum) / previousSum * 100).round();
}

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

DateTime _shiftMonth(DateTime from, int delta) {
  final monthIndex = from.year * 12 + (from.month - 1) + delta;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  return DateTime(year, month, 1);
}
