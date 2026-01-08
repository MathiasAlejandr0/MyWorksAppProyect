import 'package:uuid/uuid.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/job_cancellation_repository.dart';
import '../database/repositories/notification_repository.dart';
import '../database/models/job_model.dart';
import '../database/models/job_cancellation_model.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

/// Servicio para manejar cancelaciones de trabajos
class JobCancellationService {
  final JobRepository _jobRepository = JobRepository();
  final JobCancellationRepository _cancellationRepository = JobCancellationRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();

  /// Cancela un trabajo con validaciones y motivo
  /// Retorna true si se canceló exitosamente, false si no se puede cancelar
  Future<bool> cancelJob({
    required String jobId,
    required String cancelledBy,
    required String reason,
    required String userRole, // 'user' o 'worker'
  }) async {
    try {
      // 1. Obtener el trabajo
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        AppLogger.w('Trabajo no encontrado: $jobId');
        return false;
      }

      // 2. Validar reglas de cancelación
      if (userRole == AppConstants.roleUser) {
        // Usuario solo puede cancelar si status == 'pending'
        if (job.status != AppConstants.jobStatusPending) {
          AppLogger.w('Usuario no puede cancelar trabajo con status: ${job.status}');
          return false;
        }
      } else if (userRole == AppConstants.roleWorker) {
        // Trabajador solo puede cancelar si status == 'accepted'
        if (job.status != AppConstants.jobStatusAccepted) {
          AppLogger.w('Trabajador no puede cancelar trabajo con status: ${job.status}');
          return false;
        }
      } else {
        AppLogger.w('Rol inválido para cancelar: $userRole');
        return false;
      }

      // 3. Validar que el motivo no esté vacío
      if (reason.trim().isEmpty) {
        AppLogger.w('Motivo de cancelación vacío');
        return false;
      }

      // 4. Actualizar estado del trabajo a 'cancelled'
      await _jobRepository.updateJobStatus(jobId, AppConstants.jobStatusCancelled);

      // 5. Crear registro de cancelación
      final cancellation = JobCancellationModel(
        id: const Uuid().v4(),
        jobId: jobId,
        cancelledBy: cancelledBy,
        reason: reason.trim(),
        cancelledAt: DateTime.now(),
      );
      await _cancellationRepository.createCancellation(cancellation);

      // 6. Generar notificación automática
      final otherUserId = cancelledBy == job.userId ? job.workerId : job.userId;
      if (otherUserId != null) {
        final notificationTitle = userRole == AppConstants.roleUser
            ? 'Trabajo Cancelado'
            : 'Trabajo Cancelado por Trabajador';
        final notificationBody = userRole == AppConstants.roleUser
            ? 'El usuario ha cancelado el trabajo. Motivo: $reason'
            : 'El trabajador ha cancelado el trabajo. Motivo: $reason';

        await NotificationService.instance.showNotification(
          title: notificationTitle,
          body: notificationBody,
          userId: otherUserId,
          type: 'job_cancelled',
          relatedId: jobId,
        );
      }

      AppLogger.i('Trabajo cancelado exitosamente: $jobId');
      return true;
    } catch (e) {
      AppLogger.e('Error al cancelar trabajo', e);
      return false;
    }
  }

  /// Verifica si un trabajo puede ser cancelado por un usuario/trabajador
  Future<bool> canCancelJob(String jobId, String userId, String userRole) async {
    try {
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) return false;

      // Verificar que el usuario es el dueño del trabajo o el trabajador asignado
      if (userRole == AppConstants.roleUser && job.userId != userId) {
        return false;
      }
      if (userRole == AppConstants.roleWorker && job.workerId != userId) {
        return false;
      }

      // Validar estado según rol
      if (userRole == AppConstants.roleUser) {
        return job.status == AppConstants.jobStatusPending;
      } else if (userRole == AppConstants.roleWorker) {
        return job.status == AppConstants.jobStatusAccepted;
      }

      return false;
    } catch (e) {
      AppLogger.e('Error al verificar si se puede cancelar trabajo', e);
      return false;
    }
  }

  /// Obtiene el motivo de cancelación de un trabajo
  Future<String?> getCancellationReason(String jobId) async {
    try {
      final cancellation = await _cancellationRepository.getCancellationByJobId(jobId);
      return cancellation?.reason;
    } catch (e) {
      AppLogger.e('Error al obtener motivo de cancelación', e);
      return null;
    }
  }
}

