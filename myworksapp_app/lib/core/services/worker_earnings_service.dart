import '../database/repositories/job_repository.dart';
import '../database/repositories/payment_repository.dart';
import '../domain/worker_earnings_snapshot.dart';

class WorkerEarningsService {
  WorkerEarningsService._();

  static final WorkerEarningsService instance = WorkerEarningsService._();

  final JobRepository _jobs = JobRepository();
  final PaymentRepository _payments = PaymentRepository();

  Future<WorkerEarningsSnapshot> getSnapshot(String workerId) async {
    final jobs = await _jobs.getJobsByWorkerId(workerId);
    final jobIds = jobs.map((j) => j.id).toList();
    if (jobIds.isEmpty) return WorkerEarningsSnapshot.zero;

    final payments = await _payments.listByJobIds(jobIds);
    var escrow = 0;
    var released = 0;
    var pending = 0;

    for (final payment in payments) {
      final amount = payment.amount.round();
      switch (payment.status) {
        case 'pending':
          pending += amount;
        case 'authorized':
        case 'held':
          escrow += amount;
        case 'released':
          released += amount;
      }
    }

    return WorkerEarningsSnapshot(
      escrowClp: escrow,
      releasedClp: released,
      pendingClp: pending,
      paymentCount: payments.length,
    );
  }
}
