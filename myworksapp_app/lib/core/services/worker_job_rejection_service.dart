import '../domain/user_location_context.dart';
import '../database/models/job_model.dart';
import '../database/models/worker_model.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../database/repositories/service_repository.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'notification_service.dart';
import 'user_location_service.dart';
import 'worker_reputation_service.dart';

/// Maneja el rechazo de un trabajo por el profesional e informa al cliente.
class WorkerJobRejectionService {
  WorkerJobRejectionService._();
  static final WorkerJobRejectionService instance = WorkerJobRejectionService._();

  final JobRepository _jobs = JobRepository();
  final WorkerRepository _workers = WorkerRepository();
  final UserRepository _users = UserRepository();
  final ServiceRepository _services = ServiceRepository();

  Future<List<WorkerModel>> rejectAndSuggestAlternatives({
    required String jobId,
    required String workerId,
  }) async {
    final job = await _jobs.getJobById(jobId);
    if (job == null) {
      throw AppError.notFound('Trabajo no encontrado');
    }

    if (job.status == AppConstants.jobStatusCancelled &&
        job.serviceMetadata?['rejection_reason'] == 'worker_unavailable') {
      return _loadAlternatives(
        job: job,
        excludeWorkerId: workerId,
      );
    }

    if (job.status != AppConstants.jobStatusPending) {
      throw AppError.validation('Este trabajo ya no está pendiente');
    }

    if (job.workerId != workerId) {
      throw AppError.permission('No puedes rechazar este trabajo');
    }

    final metadata = Map<String, dynamic>.from(job.serviceMetadata ?? {});
    metadata['rejected_by_worker_id'] = workerId;
    metadata['rejected_at'] = DateTime.now().toIso8601String();
    metadata['rejection_reason'] = 'worker_unavailable';

    final updated = await _jobs.rejectPendingJobByWorker(
      jobId: jobId,
      workerId: workerId,
      metadata: metadata,
    );

    if (!updated) {
      throw AppError.database(
        'No se pudo actualizar el trabajo. Intenta de nuevo.',
      );
    }

    await _incrementRejectionCount(workerId);

    final worker = await _workers.getWorkerByUserId(workerId);
    final workerUser = await _users.getUserById(workerId);
    final workerName = workerUser?.name ?? worker?.profession ?? 'El profesional';

    try {
      await NotificationService.instance.showNotification(
        title: 'Profesional no disponible',
        body:
            '$workerName no puede tomar tu solicitud en este momento. Te sugerimos otros profesionales.',
        userId: job.userId,
        type: 'worker_unavailable',
        relatedId: jobId,
      );
    } catch (_) {}

    return _loadAlternatives(
      job: job,
      excludeWorkerId: workerId,
    );
  }

  Future<List<WorkerModel>> _loadAlternatives({
    required JobModel job,
    required String excludeWorkerId,
  }) async {
    final service = await _services.getServiceById(job.serviceId);
    if (service == null) return [];

    UserLocationContext? near;
    if (job.latitude != null && job.longitude != null) {
      near = await UserLocationService.instance.fromCoordinates(
        job.latitude!,
        job.longitude!,
      );
    }

    final workers = await _workers.getWorkersByServiceCategory(
      service.category,
      near: near,
    );
    final jobRepository = JobRepository();
    final available = <WorkerModel>[];

    for (final worker in workers) {
      if (worker.userId == excludeWorkerId || !worker.isAvailable) continue;
      if (await jobRepository.hasActiveJobs(worker.userId)) continue;
      available.add(worker);
    }

    WorkerReputationService.instance.sortForListing(available);
    return available.take(5).toList();
  }

  Future<void> _incrementRejectionCount(String workerId) async {
    final worker = await _workers.getWorkerByUserId(workerId);
    if (worker == null) return;
    await _workers.updateWorker(
      worker.copyWith(rejectionCount: worker.rejectionCount + 1),
    );
  }

  Future<List<WorkerModel>> alternativesForJob(JobModel job) async {
    final rejectedId = job.serviceMetadata?['rejected_by_worker_id'] as String?;
    if (rejectedId == null) return [];
    return _loadAlternatives(
      job: job,
      excludeWorkerId: rejectedId,
    );
  }
}
