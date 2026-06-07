import '../models/job_cancellation_model.dart';
import '../supabase_db.dart';

class JobCancellationRepository {
  static const String _table = 'job_cancellations';

  Future<void> createCancellation(JobCancellationModel cancellation) async {
    await supabase.from(_table).insert(cancellation.toMap());
  }

  Future<JobCancellationModel?> getCancellationByJobId(String jobId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .maybeSingle();
    if (row == null) return null;
    return JobCancellationModel.fromMap(row);
  }
}
