import '../database/repositories/job_repository.dart';
import 'notification_service.dart';

/// Notifica al profesional elegido por el cliente (cotización abierta).
class OpenQuoteNotificationService {
  OpenQuoteNotificationService._();
  static final OpenQuoteNotificationService instance = OpenQuoteNotificationService._();

  /// Avisa solo al profesional al que el cliente envió la solicitud.
  Future<bool> notifyInvitedWorker({
    required String jobId,
    required String workerId,
    JobRepository? jobRepository,
  }) async {
    final jobs = jobRepository ?? JobRepository();
    if (await jobs.hasActiveJobs(workerId)) return false;

    await NotificationService.instance.showNotification(
      title: 'Te solicitaron una cotización',
      body:
          'Un cliente te eligió desde tu perfil. Revisa su pedido y envía tu propuesta con materiales, mano de obra y tiempo.',
      userId: workerId,
      type: 'new_job_quote',
      relatedId: jobId,
    );
    return true;
  }
}
