import '../database/models/job_model.dart';
import '../database/repositories/job_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';

/// Máquina de estados para jobs con validación estricta
/// 
/// Maneja:
/// - Transiciones válidas de estados
/// - Timeouts automáticos
/// - Prevención de estados inválidos
/// - Logs de cambios de estado
class JobStateMachine {
  static final JobStateMachine instance = JobStateMachine._();
  JobStateMachine._();

  final JobRepository _jobRepository = JobRepository();

  // Timeouts configurables (en minutos)
  static const int pendingTimeoutMinutes = 5; // Job expira si no se acepta en 5 min
  static const int acceptedTimeoutMinutes = 30; // Job vuelve a pending si no inicia en 30 min

  /// Transiciones válidas de estados
  static const Map<String, List<String>> validTransitions = {
    AppConstants.jobStatusPending: [
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusExpired,
    ],
    AppConstants.jobStatusAccepted: [
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusPending, // Si no inicia a tiempo
    ],
    AppConstants.jobStatusInProgress: [
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusNoShow,
    ],
    AppConstants.jobStatusCompleted: [
      // No hay transiciones desde completed
    ],
    AppConstants.jobStatusCancelled: [
      // No hay transiciones desde cancelled
    ],
    AppConstants.jobStatusExpired: [
      // No hay transiciones desde expired
    ],
    AppConstants.jobStatusNoShow: [
      // No hay transiciones desde no_show
    ],
  };

  /// Valida si una transición de estado es válida
  bool isValidTransition(String fromStatus, String toStatus) {
    final allowed = validTransitions[fromStatus];
    if (allowed == null) return false;
    return allowed.contains(toStatus);
  }

  /// Cambia el estado de un job con validación estricta
  /// 
  /// Lanza AppError si la transición no es válida.
  Future<JobModel> transitionTo({
    required String jobId,
    required String newStatus,
    String? userId, // Para validar permisos
  }) async {
    try {
      // 1. Obtener job actual
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      // 2. Validar transición
      if (!isValidTransition(job.status, newStatus)) {
        AppLogger.e('Transición inválida: ${job.status} -> $newStatus');
        throw AppError.validation(
          'No se puede cambiar el estado de ${job.status} a $newStatus',
        );
      }

      // 3. Validar permisos (si se proporciona userId)
      if (userId != null) {
        final hasPermission = _validatePermission(job, newStatus, userId);
        if (!hasPermission) {
          throw AppError.permission('No tienes permiso para realizar esta acción');
        }
      }

      // 4. Actualizar estado
      final updatedJob = job.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _jobRepository.updateJob(updatedJob);

      // 5. Log del cambio
      AppLogger.i(
        'Estado de job ${job.id} cambiado: ${job.status} -> $newStatus',
      );

      return updatedJob;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error en transición de estado', e);
      throw AppError.database('Error al cambiar estado: ${e.toString()}');
    }
  }

  /// Valida permisos para cambiar estado
  bool _validatePermission(JobModel job, String newStatus, String userId) {
    // Usuario puede cancelar sus propios jobs
    if (newStatus == AppConstants.jobStatusCancelled && job.userId == userId) {
      return true;
    }

    // Trabajador puede aceptar, iniciar, completar, marcar no-show
    if (job.workerId == userId) {
      final workerActions = [
        AppConstants.jobStatusAccepted,
        AppConstants.jobStatusInProgress,
        AppConstants.jobStatusCompleted,
        AppConstants.jobStatusNoShow,
      ];
      return workerActions.contains(newStatus);
    }

    return false;
  }

  /// Verifica y procesa timeouts de jobs
  /// 
  /// Debe ejecutarse periódicamente (ej: cada minuto).
  /// 
  /// Procesa:
  /// - Jobs pending que expiran
  /// - Jobs accepted que no inician
  Future<void> processTimeouts() async {
    try {
      AppLogger.i('Procesando timeouts de jobs...');

      final now = DateTime.now();
      int expiredCount = 0;
      int revertedCount = 0;

      // 1. Procesar jobs pending que expiran
      final pendingJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusPending,
      );

      for (final job in pendingJobs) {
        final minutesSinceCreation = now.difference(job.createdAt).inMinutes;
        if (minutesSinceCreation >= pendingTimeoutMinutes) {
          try {
            await transitionTo(
              jobId: job.id,
              newStatus: AppConstants.jobStatusExpired,
            );
            expiredCount++;
            AppLogger.i('Job ${job.id} expirado automáticamente');
          } catch (e) {
            AppLogger.e('Error expirando job ${job.id}', e);
          }
        }
      }

      // 2. Procesar jobs accepted que no inician
      final acceptedJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusAccepted,
      );

      for (final job in acceptedJobs) {
        // Buscar cuando se aceptó (necesitaríamos un campo acceptedAt)
        // Por ahora, usamos updatedAt como aproximación
        final minutesSinceAccepted = now.difference(job.updatedAt).inMinutes;
        if (minutesSinceAccepted >= acceptedTimeoutMinutes) {
          try {
            await transitionTo(
              jobId: job.id,
              newStatus: AppConstants.jobStatusPending,
            );
            // Limpiar workerId para que otro trabajador pueda aceptar
            final revertedJob = job.copyWith(
              workerId: null,
              updatedAt: DateTime.now(),
            );
            await _jobRepository.updateJob(revertedJob);
            revertedCount++;
            AppLogger.i('Job ${job.id} revertido a pending (no iniciado)');
          } catch (e) {
            AppLogger.e('Error revirtiendo job ${job.id}', e);
          }
        }
      }

      if (expiredCount > 0 || revertedCount > 0) {
        AppLogger.i(
          'Timeouts procesados: $expiredCount expirados, $revertedCount revertidos',
        );
      }
    } catch (e) {
      AppLogger.e('Error procesando timeouts', e);
    }
  }

  /// Obtiene el estado siguiente válido sugerido
  String? getSuggestedNextStatus(String currentStatus) {
    final transitions = validTransitions[currentStatus];
    if (transitions == null || transitions.isEmpty) return null;

    // Priorizar transiciones comunes
    if (currentStatus == AppConstants.jobStatusPending) {
      return AppConstants.jobStatusAccepted;
    }
    if (currentStatus == AppConstants.jobStatusAccepted) {
      return AppConstants.jobStatusInProgress;
    }
    if (currentStatus == AppConstants.jobStatusInProgress) {
      return AppConstants.jobStatusCompleted;
    }

    return transitions.first;
  }

  /// Verifica si un job puede ser cancelado
  bool canCancel(JobModel job) {
    return validTransitions[job.status]?.contains(
          AppConstants.jobStatusCancelled,
        ) ??
        false;
  }

  /// Verifica si un job puede ser completado
  bool canComplete(JobModel job) {
    return job.status == AppConstants.jobStatusInProgress;
  }

  /// Obtiene estados finales (no tienen transiciones)
  static List<String> getFinalStates() {
    return [
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusExpired,
      AppConstants.jobStatusNoShow,
    ];
  }

  /// Verifica si un estado es final
  static bool isFinalState(String status) {
    return getFinalStates().contains(status);
  }
}

