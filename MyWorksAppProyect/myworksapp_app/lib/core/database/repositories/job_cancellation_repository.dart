import '../../services/evento_service.dart';
import '../models/job_cancellation_model.dart';
import '../supabase_db.dart';

class JobCancellationRepository {
  static const String _table = 'cancelaciones_trabajo';

  Future<void> createCancellation(JobCancellationModel cancellation) async {
    await supabase.from(_table).insert(cancellation.toMap());
    registrarEvento(tipo: 'cancelacion', entidadId: cancellation.jobId);
  }

  Future<JobCancellationModel?> getCancellationByJobId(String jobId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id_trabajo', jobId)
        .maybeSingle();
    if (row == null) return null;
    return JobCancellationModel.fromMap(row);
  }
}
