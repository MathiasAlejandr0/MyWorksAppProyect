import '../database/models/job_model.dart';

/// Utilidades para cotización abierta.
class OpenQuoteUtils {
  OpenQuoteUtils._();

  static const String metadataInvitedWorkerId = 'invited_worker_id';

  static String? invitedWorkerId(JobModel job) {
    final meta = job.serviceMetadata;
    if (meta == null) return null;
    final id = meta[metadataInvitedWorkerId];
    return id is String && id.isNotEmpty ? id : null;
  }

  static bool canWorkerSubmitQuote(JobModel job, String workerId) {
    final invited = invitedWorkerId(job);
    if (invited == null) return false;
    return invited == workerId;
  }
}
