import '../database/repositories/job_repository.dart';
import '../database/repositories/worker_repository.dart';
import 'notification_service.dart';

/// Notifica al profesional elegido por el cliente (cotización abierta).
class OpenQuoteNotificationService {
  OpenQuoteNotificationService._();
  static final OpenQuoteNotificationService instance =
      OpenQuoteNotificationService._();

  /// Avisa solo al profesional al que el cliente envió la solicitud.
  Future<bool> notifyInvitedWorker({
    required String jobId,
    required String workerId,
    JobRepository? jobRepository,
    String? jobLabel,
    bool isTierInvitation = false,
  }) async {
    final workers = WorkerRepository();
    if (!await workers.isWorkerAcceptingJobs(workerId)) return false;

    try {
      if (isTierInvitation) {
        await NotificationService.instance.showNotification(
          title: 'Nueva solicitud de trabajo',
          body: jobLabel == null
              ? 'Un cliente te eligió. Revisa si te interesa el trabajo.'
              : 'Un cliente solicita: $jobLabel. Revisa si te interesa.',
          userId: workerId,
          type: 'new_job',
          relatedId: jobId,
        );
        return true;
      }

      await NotificationService.instance.showNotification(
        title: 'Te solicitaron una cotización',
        body:
            'Un cliente te eligió desde su perfil. Revisa su pedido y envía tu propuesta con materiales, mano de obra y tiempo.',
        userId: workerId,
        type: 'new_job_quote',
        relatedId: jobId,
      );
    } catch (e) {
      // La solicitud ya fue creada; no bloquear al cliente por fallo de notificación.
      print('Error notificando al trabajador: $e');
    }
    return true;
  }
}
