import '../database/supabase_db.dart';
import '../domain/worker_charge.dart';
import '../domain/worker_earnings_snapshot.dart';
import '../utils/santiago_time.dart';

class WorkerEarningsService {
  WorkerEarningsService._();

  static final WorkerEarningsService instance = WorkerEarningsService._();

  /// Bruto, comisión y neto vienen calculados por la base
  /// (vista `cobros_profesional`).
  Future<WorkerEarningsSnapshot> getSnapshot(String workerId) async {
    final rows = await supabase
        .from(WorkerCharge.view)
        .select(WorkerCharge.columns)
        .eq('id_trabajador', workerId);
    final charges = [
      for (final row in rows as List)
        WorkerCharge.fromRow(Map<String, dynamic>.from(row as Map)),
    ];
    if (charges.isEmpty) return WorkerEarningsSnapshot.zero;
    return WorkerEarningsSnapshot.fromCharges(
      charges,
      now: SantiagoTime.wall(DateTime.now()),
      toLocal: SantiagoTime.wall,
    );
  }
}
