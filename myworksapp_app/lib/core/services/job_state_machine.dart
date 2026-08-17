import '../database/models/job_model.dart';
import '../database/repositories/job_repository.dart';
import '../domain/pricing_constants.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'job_transition_matrix.dart';
import 'payment_guard.dart';
import 'payment_service.dart';

/// Máquina de estados para jobs con validación por modalidad de cobro y escrow.
class JobStateMachine {
  static final JobStateMachine instance = JobStateMachine._();
  JobStateMachine._();

  final JobRepository _jobRepository = JobRepository();

  static const int pendingTimeoutMinutes = 5;
  static const int acceptedTimeoutMinutes = 30;

  /// Mapa legado (solo [PricingConstants.modeLegacy]).
  @Deprecated('Usar JobTransitionMatrix.forMode(pricingMode)')
  static Map<String, List<String>> get validTransitions =>
      JobTransitionMatrix.forMode(PricingConstants.modeLegacy);

  bool isValidTransition(
    String fromStatus,
    String toStatus, {
    String pricingMode = PricingConstants.modeLegacy,
  }) {
    return JobTransitionMatrix.isAllowed(pricingMode, fromStatus, toStatus);
  }

  Future<JobModel> transitionTo({
    required String jobId,
    required String newStatus,
    String? userId,
  }) async {
    try {
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      if (!isValidTransition(
        job.status,
        newStatus,
        pricingMode: job.pricingMode,
      )) {
        AppLogger.e(
          'Transición inválida (${job.pricingMode}): ${job.status} -> $newStatus',
        );
        throw AppError.validation(
          'No se puede cambiar el estado de ${job.status} a $newStatus',
        );
      }

      if (userId != null) {
        final hasPermission = _validatePermission(job, newStatus, userId);
        if (!hasPermission) {
          throw AppError.permission('No tienes permiso para realizar esta acción');
        }
      }

      await PaymentGuard.validate(job: job, targetStatus: newStatus);

      final updatedJob = job.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _jobRepository.updateJob(updatedJob);

      if (newStatus == AppConstants.jobStatusCompleted) {
        await PaymentService.instance.releasePrimaryOnJobCompleted(jobId);
      } else if (newStatus == AppConstants.jobStatusCancelled) {
        await PaymentService.instance.refundPrimaryOnCancellation(jobId);
      }

      AppLogger.i(
        'Estado de job ${job.id} cambiado: ${job.status} -> $newStatus',
      );

      return updatedJob;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error en transición de estado', e);
      throw AppError.database('Error al cambiar estado: ${e.toString()}');
    }
  }

  bool _validatePermission(JobModel job, String newStatus, String userId) {
    if (newStatus == AppConstants.jobStatusCancelled && job.userId == userId) {
      return true;
    }

    if (job.workerId == userId) {
      const workerActions = [
        AppConstants.jobStatusAccepted,
        AppConstants.jobStatusInProgress,
        AppConstants.jobStatusCompleted,
        PricingConstants.jobAwaitingClientApproval,
        AppConstants.jobStatusNoShow,
        PricingConstants.jobPausedChangeOrder,
      ];
      return workerActions.contains(newStatus);
    }

    if (job.userId == userId) {
      const clientActions = [
        PricingConstants.jobQuoteSelected,
        PricingConstants.jobAwaitingPayment,
        AppConstants.jobStatusAccepted,
        AppConstants.jobStatusCompleted,
        AppConstants.jobStatusInProgress,
        AppConstants.jobStatusCancelled,
      ];
      return clientActions.contains(newStatus);
    }

    return false;
  }

  Future<void> processTimeouts() async {
    try {
      AppLogger.i('Procesando timeouts de jobs...');

      final now = DateTime.now();
      int expiredCount = 0;
      int revertedCount = 0;

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
          } catch (e) {
            AppLogger.e('Error expirando job ${job.id}', e);
          }
        }
      }

      final awaitingQuotes = await _jobRepository.getJobsByStatus(
        PricingConstants.jobAwaitingQuotes,
      );
      for (final job in awaitingQuotes) {
        final minutesSinceCreation = now.difference(job.createdAt).inMinutes;
        if (minutesSinceCreation >= pendingTimeoutMinutes * 12) {
          try {
            await transitionTo(
              jobId: job.id,
              newStatus: AppConstants.jobStatusExpired,
            );
            expiredCount++;
          } catch (e) {
            AppLogger.e('Error expirando cotización ${job.id}', e);
          }
        }
      }

      final acceptedJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusAccepted,
      );

      for (final job in acceptedJobs) {
        final minutesSinceAccepted = now.difference(job.updatedAt).inMinutes;
        if (minutesSinceAccepted >= acceptedTimeoutMinutes) {
          try {
            if (job.pricingMode == PricingConstants.modeLegacy) {
              await transitionTo(
                jobId: job.id,
                newStatus: AppConstants.jobStatusPending,
              );
              await _jobRepository.updateJob(
                job.copyWith(workerId: null, updatedAt: DateTime.now()),
              );
              revertedCount++;
            }
          } catch (e) {
            AppLogger.e('Error revirtiendo job ${job.id}', e);
          }
        }
      }

      if (expiredCount > 0 || revertedCount > 0) {
        AppLogger.i(
          'Timeouts: $expiredCount expirados, $revertedCount revertidos',
        );
      }
    } catch (e) {
      AppLogger.e('Error procesando timeouts', e);
    }
  }

  String? getSuggestedNextStatus(JobModel job) {
    final targets = JobTransitionMatrix.allowedTargets(job.pricingMode, job.status);
    if (targets.isEmpty) return null;

    if (job.status == AppConstants.jobStatusPending ||
        job.status == PricingConstants.jobAwaitingPayment) {
      return targets.contains(AppConstants.jobStatusAccepted)
          ? AppConstants.jobStatusAccepted
          : targets.first;
    }
    if (job.status == AppConstants.jobStatusAccepted) {
      return AppConstants.jobStatusInProgress;
    }
    if (job.status == AppConstants.jobStatusInProgress) {
      return AppConstants.jobStatusCompleted;
    }
    return targets.first;
  }

  bool canCancel(JobModel job) {
    return JobTransitionMatrix.allowedTargets(job.pricingMode, job.status)
        .contains(AppConstants.jobStatusCancelled);
  }

  bool canComplete(JobModel job) {
    return job.status == AppConstants.jobStatusInProgress;
  }

  static List<String> getFinalStates() {
    return [
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusExpired,
      AppConstants.jobStatusNoShow,
    ];
  }

  static bool isFinalState(String status) {
    return getFinalStates().contains(status);
  }
}
