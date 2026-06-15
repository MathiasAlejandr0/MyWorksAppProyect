/// Resumen de cobros del profesional (demo / escrow simulado).
class WorkerEarningsSnapshot {
  final int escrowClp;
  final int releasedClp;
  final int pendingClp;
  final int paymentCount;

  const WorkerEarningsSnapshot({
    required this.escrowClp,
    required this.releasedClp,
    required this.pendingClp,
    required this.paymentCount,
  });

  static const zero = WorkerEarningsSnapshot(
    escrowClp: 0,
    releasedClp: 0,
    pendingClp: 0,
    paymentCount: 0,
  );

  int get totalRecordedClp => escrowClp + releasedClp + pendingClp;
}
