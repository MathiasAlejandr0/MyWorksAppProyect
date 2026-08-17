import '../database/repositories/job_repository.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'job_state_machine.dart';
import 'analytics_service.dart';

/// Reconciliador de timeouts en background
/// 
/// Ejecuta validaciones y transiciones automáticas de estados:
/// - pending → expired (si no se acepta en X minutos)
/// - accepted → pending (si no inicia en X minutos)
/// 
/// Se ejecuta en:
/// - Inicio de app
/// - Vuelta de background
/// - Login
class BackgroundTimeoutReconciler {
  static final BackgroundTimeoutReconciler instance = BackgroundTimeoutReconciler._();
  BackgroundTimeoutReconciler._();

  final JobRepository _jobRepository = JobRepository();
  final JobStateMachine _stateMachine = JobStateMachine.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Timeouts configurables
  static const int pendingTimeoutMinutes = 5;
  static const int acceptedTimeoutMinutes = 30;

  /// Ejecuta reconciliación completa
  /// 
  /// Procesa todos los jobs que necesitan transición automática.
  Future<ReconciliationResult> reconcile() async {
    try {
      AppLogger.i('🔄 Iniciando reconciliación de timeouts...');

      final result = ReconciliationResult();
      final now = DateTime.now();

      // 1. Procesar jobs pending que expiran
      final pendingJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusPending,
      );

      for (final job in pendingJobs) {
        final minutesSinceCreation = now.difference(job.createdAt).inMinutes;
        if (minutesSinceCreation >= pendingTimeoutMinutes) {
          try {
            await _stateMachine.transitionTo(
              jobId: job.id,
              newStatus: AppConstants.jobStatusExpired,
            );

            // Registrar en analytics
            await _analytics.trackJobExpired(
              jobId: job.id,
              userId: job.userId,
              metadata: {
                'minutesSinceCreation': minutesSinceCreation,
              },
            );

            result.expiredJobs++;
            AppLogger.i('Job ${job.id} expirado automáticamente');
          } catch (e) {
            AppLogger.e('Error expirando job ${job.id}', e);
            result.errors++;
          }
        }
      }

      // 2. Procesar jobs accepted que no inician
      final acceptedJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusAccepted,
      );

      for (final job in acceptedJobs) {
        final minutesSinceAccepted = now.difference(job.updatedAt).inMinutes;
        if (minutesSinceAccepted >= acceptedTimeoutMinutes) {
          try {
            // Revertir a pending
            await _stateMachine.transitionTo(
              jobId: job.id,
              newStatus: AppConstants.jobStatusPending,
            );

            // Limpiar workerId para que otro trabajador pueda aceptar
            final revertedJob = job.copyWith(
              workerId: null,
              updatedAt: DateTime.now(),
            );
            await _jobRepository.updateJob(revertedJob);

            // Registrar en analytics
            await _analytics.trackEvent(
              eventName: 'job_reverted_to_pending',
              userId: job.workerId,
              role: 'worker',
              metadata: {
                'jobId': job.id,
                'minutesSinceAccepted': minutesSinceAccepted,
                'reason': 'timeout_no_start',
              },
            );

            result.revertedJobs++;
            AppLogger.i('Job ${job.id} revertido a pending (no iniciado)');
          } catch (e) {
            AppLogger.e('Error revirtiendo job ${job.id}', e);
            result.errors++;
          }
        }
      }

      AppLogger.i(
        '✅ Reconciliación completada: ${result.expiredJobs} expirados, '
        '${result.revertedJobs} revertidos, ${result.errors} errores',
      );

      return result;
    } catch (e) {
      AppLogger.e('Error en reconciliación de timeouts', e);
      return ReconciliationResult();
    }
  }

  /// Reconciliación rápida (solo verifica, no procesa)
  /// 
  /// Útil para verificar estado sin hacer cambios.
  Future<ReconciliationStats> checkStatus() async {
    try {
      final now = DateTime.now();
      int pendingExpired = 0;
      int acceptedExpired = 0;

      // Contar pending que deberían expirar
      final pendingJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusPending,
      );
      for (final job in pendingJobs) {
        final minutesSinceCreation = now.difference(job.createdAt).inMinutes;
        if (minutesSinceCreation >= pendingTimeoutMinutes) {
          pendingExpired++;
        }
      }

      // Contar accepted que deberían revertir
      final acceptedJobs = await _jobRepository.getJobsByStatus(
        AppConstants.jobStatusAccepted,
      );
      for (final job in acceptedJobs) {
        final minutesSinceAccepted = now.difference(job.updatedAt).inMinutes;
        if (minutesSinceAccepted >= acceptedTimeoutMinutes) {
          acceptedExpired++;
        }
      }

      return ReconciliationStats(
        pendingExpired: pendingExpired,
        acceptedExpired: acceptedExpired,
      );
    } catch (e) {
      AppLogger.e('Error checking reconciliation status', e);
      return ReconciliationStats();
    }
  }
}

/// Resultado de reconciliación
class ReconciliationResult {
  int expiredJobs = 0;
  int revertedJobs = 0;
  int errors = 0;

  int get totalProcessed => expiredJobs + revertedJobs;
  bool get hasErrors => errors > 0;
}

/// Estadísticas de reconciliación
class ReconciliationStats {
  final int pendingExpired;
  final int acceptedExpired;

  ReconciliationStats({
    this.pendingExpired = 0,
    this.acceptedExpired = 0,
  });

  int get totalPending => pendingExpired + acceptedExpired;
  bool get needsReconciliation => totalPending > 0;
}

