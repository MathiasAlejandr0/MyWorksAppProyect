import 'package:uuid/uuid.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';
import '../database/repositories/notification_repository.dart';
import '../database/models/job_model.dart';
import '../database/models/notification_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'notification_service.dart';
import 'service_legal_validator.dart';
import 'abuse_protection_service.dart';
import 'analytics_service.dart';

/// Servicio de trabajos (jobs)
/// 
/// Maneja toda la lógica de negocio relacionada con trabajos:
/// - Crear solicitud de trabajo
/// - Aceptar/rechazar trabajos
/// - Actualizar estado de trabajos
/// - Obtener trabajos por usuario/trabajador
/// - Cancelar trabajos
class JobService {
  static final JobService instance = JobService._();
  JobService._();

  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  final ServiceLegalValidator _legalValidator = ServiceLegalValidator.instance;
  final AbuseProtectionService _abuseProtection = AbuseProtectionService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  /// Crea una nueva solicitud de trabajo
  /// 
  /// Retorna el trabajo creado o null si falla.
  /// Lanza AppError si hay problemas de validación.
  Future<JobModel?> createJob({
    required String userId,
    required String serviceId,
    required String description,
    required String address,
    double? latitude,
    double? longitude,
    DateTime? scheduledDate,
    Map<String, dynamic>? serviceMetadata,
  }) async {
    try {
      AppLogger.i('Creando trabajo para usuario: $userId');

      // Validar que el usuario existe
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw AppError.notFound('Usuario no encontrado');
      }

      if (user.role != AppConstants.roleUser) {
        throw AppError.validation('Solo los usuarios pueden crear trabajos');
      }

      // Validar descripción
      if (description.trim().isEmpty) {
        throw AppError.validation('La descripción es requerida');
      }

      if (description.trim().length < 10) {
        throw AppError.validation('La descripción debe tener al menos 10 caracteres');
      }

      // Validar protección anti-abuso
      final abuseCheck = await _abuseProtection.canCreateJob(userId);
      if (!abuseCheck.allowed) {
        throw AppError.validation(abuseCheck.reason ?? 'No puedes crear más trabajos en este momento');
      }

      // Validar servicio legalmente
      final legalValidation = await _legalValidator.validateService(serviceId);
      if (!legalValidation.valid) {
        throw AppError.validation(legalValidation.reason ?? 'Servicio no disponible legalmente');
      }

      // Crear trabajo
      final now = DateTime.now();
      final job = JobModel(
        id: const Uuid().v4(),
        userId: userId,
        workerId: null, // Se asignará cuando un trabajador acepte
        serviceId: serviceId,
        description: description.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        status: AppConstants.jobStatusPending,
        scheduledDate: scheduledDate,
        serviceMetadata: serviceMetadata,
        createdAt: now,
        updatedAt: now,
      );

      // Guardar en base de datos
      await _jobRepository.createJob(job);

      // Trackear en analytics
      await _analytics.trackJobCreated(
        userId: userId,
        jobId: job.id,
        serviceId: serviceId,
      );

      // Crear notificación para trabajadores disponibles
      await _createJobCreatedNotification(job);

      AppLogger.i('Trabajo creado exitosamente: ${job.id}');
      return job;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al crear trabajo', e);
      throw AppError.database('Error al crear trabajo: ${e.toString()}');
    }
  }

  /// Acepta un trabajo (solo para trabajadores)
  /// 
  /// Retorna true si se aceptó exitosamente.
  Future<bool> acceptJob({
    required String jobId,
    required String workerId,
  }) async {
    try {
      AppLogger.i('Aceptando trabajo $jobId por trabajador $workerId');

      // Validar que el trabajador existe
      final worker = await _workerRepository.getWorkerById(workerId);
      if (worker == null) {
        throw AppError.notFound('Trabajador no encontrado');
      }

      // Obtener el trabajo
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      // Validar estado
      if (job.status != AppConstants.jobStatusPending) {
        throw AppError.validation('El trabajo ya no está disponible');
      }

      // Actualizar trabajo
      final updatedJob = job.copyWith(
        workerId: workerId,
        status: AppConstants.jobStatusAccepted,
        updatedAt: DateTime.now(),
      );

      await _jobRepository.updateJob(updatedJob);

      // Crear notificación para el usuario
      await _createJobAcceptedNotification(job, workerId);

      AppLogger.i('Trabajo aceptado exitosamente');
      return true;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al aceptar trabajo', e);
      throw AppError.database('Error al aceptar trabajo: ${e.toString()}');
    }
  }

  /// Rechaza un trabajo (solo para trabajadores)
  /// 
  /// Retorna true si se rechazó exitosamente.
  Future<bool> rejectJob({
    required String jobId,
    required String workerId,
  }) async {
    try {
      AppLogger.i('Rechazando trabajo $jobId por trabajador $workerId');

      // Obtener el trabajo
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      // El trabajo vuelve a estar disponible para otros trabajadores
      // No se cambia el estado, solo se registra el rechazo (si se implementa tracking)

      AppLogger.i('Trabajo rechazado');
      return true;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al rechazar trabajo', e);
      throw AppError.database('Error al rechazar trabajo: ${e.toString()}');
    }
  }

  /// Actualiza el estado de un trabajo
  /// 
  /// Retorna el trabajo actualizado o null si falla.
  Future<JobModel?> updateJobStatus({
    required String jobId,
    required String newStatus,
    String? userId, // Para validar permisos
  }) async {
    try {
      AppLogger.i('Actualizando estado del trabajo $jobId a $newStatus');

      // Obtener el trabajo
      final job = await _jobRepository.getJobById(jobId);
      if (job == null) {
        throw AppError.notFound('Trabajo no encontrado');
      }

      // Validar permisos (solo el usuario o trabajador asignado pueden cambiar el estado)
      if (userId != null) {
        if (job.userId != userId && job.workerId != userId) {
          throw AppError.permission('No tienes permisos para modificar este trabajo');
        }
      }

      // Validar transición de estado
      if (!_isValidStatusTransition(job.status, newStatus)) {
        throw AppError.validation('Transición de estado inválida: ${job.status} -> $newStatus');
      }

      // Actualizar trabajo
      final updatedJob = job.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _jobRepository.updateJob(updatedJob);

      // Crear notificación según el nuevo estado
      await _createStatusChangeNotification(updatedJob);

      AppLogger.i('Estado del trabajo actualizado exitosamente');
      return updatedJob;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al actualizar estado del trabajo', e);
      throw AppError.database('Error al actualizar estado: ${e.toString()}');
    }
  }

  /// Obtiene todos los trabajos de un usuario
  Future<List<JobModel>> getUserJobs(String userId) async {
    try {
      return await _jobRepository.getJobsByUserId(userId);
    } catch (e) {
      AppLogger.e('Error al obtener trabajos del usuario', e);
      return [];
    }
  }

  /// Obtiene todos los trabajos de un trabajador
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    try {
      return await _jobRepository.getJobsByWorkerId(workerId);
    } catch (e) {
      AppLogger.e('Error al obtener trabajos del trabajador', e);
      return [];
    }
  }

  /// Obtiene trabajos disponibles (pendientes, sin trabajador asignado)
  Future<List<JobModel>> getAvailableJobs() async {
    try {
      return await _jobRepository.getJobsByStatus(AppConstants.jobStatusPending);
    } catch (e) {
      AppLogger.e('Error al obtener trabajos disponibles', e);
      return [];
    }
  }

  /// Obtiene un trabajo por ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      return await _jobRepository.getJobById(jobId);
    } catch (e) {
      AppLogger.e('Error al obtener trabajo', e);
      return null;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Valida si una transición de estado es válida
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    // Definir transiciones válidas
    const validTransitions = {
      AppConstants.jobStatusPending: [
        AppConstants.jobStatusAccepted,
        AppConstants.jobStatusCancelled,
        AppConstants.jobStatusExpired,
      ],
      AppConstants.jobStatusAccepted: [
        AppConstants.jobStatusInProgress,
        AppConstants.jobStatusCancelled,
      ],
      AppConstants.jobStatusInProgress: [
        AppConstants.jobStatusCompleted,
        AppConstants.jobStatusCancelled,
        AppConstants.jobStatusNoShow,
      ],
      AppConstants.jobStatusCompleted: [], // Estado final
      AppConstants.jobStatusCancelled: [], // Estado final
      AppConstants.jobStatusExpired: [], // Estado final
      AppConstants.jobStatusNoShow: [], // Estado final
    };

    final allowed = validTransitions[currentStatus] ?? [];
    return allowed.contains(newStatus);
  }

  /// Crea notificación cuando se crea un trabajo
  Future<void> _createJobCreatedNotification(JobModel job) async {
    try {
      // Notificar a trabajadores disponibles (esto se implementaría con un sistema de matching)
      // Por ahora, solo logueamos
      AppLogger.i('Trabajo creado, notificando trabajadores disponibles');
    } catch (e) {
      AppLogger.e('Error al crear notificación de trabajo creado', e);
    }
  }

  /// Crea notificación cuando un trabajador acepta un trabajo
  Future<void> _createJobAcceptedNotification(JobModel job, String workerId) async {
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: job.userId,
        type: 'job_accepted',
        title: 'Trabajo aceptado',
        body: 'Un trabajador ha aceptado tu solicitud de trabajo',
        relatedId: job.id,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      await NotificationService.instance.showNotification(
        title: notification.title,
        body: notification.body,
        userId: job.userId,
        type: 'job_accepted',
        relatedId: job.id,
      );
    } catch (e) {
      AppLogger.e('Error al crear notificación de trabajo aceptado', e);
    }
  }

  /// Crea notificación cuando cambia el estado de un trabajo
  Future<void> _createStatusChangeNotification(JobModel job) async {
    try {
      String title = 'Estado del trabajo actualizado';
      String message = 'El estado de tu trabajo ha cambiado';

      switch (job.status) {
        case AppConstants.jobStatusInProgress:
          title = 'Trabajo en progreso';
          message = 'El trabajador ha comenzado el trabajo';
          break;
        case AppConstants.jobStatusCompleted:
          title = 'Trabajo completado';
          message = 'El trabajo ha sido completado';
          break;
        case AppConstants.jobStatusCancelled:
          title = 'Trabajo cancelado';
          message = 'El trabajo ha sido cancelado';
          break;
      }

      // Notificar al usuario
      final userNotification = NotificationModel(
        id: const Uuid().v4(),
        userId: job.userId,
        type: 'job_status_changed',
        title: title,
        body: message,
        relatedId: job.id,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(userNotification);
      await NotificationService.instance.showNotification(
        title: userNotification.title,
        body: userNotification.body,
        userId: job.userId,
        type: 'job_status_changed',
        relatedId: job.id,
      );

      // Notificar al trabajador si está asignado
      if (job.workerId != null) {
        final workerNotification = NotificationModel(
          id: const Uuid().v4(),
          userId: job.workerId!,
          type: 'job_status_changed',
          title: title,
          body: message,
          relatedId: job.id,
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _notificationRepository.createNotification(workerNotification);
        await NotificationService.instance.showNotification(
          title: workerNotification.title,
          body: workerNotification.body,
          userId: job.workerId!,
          type: 'job_status_changed',
          relatedId: job.id,
        );
      }
    } catch (e) {
      AppLogger.e('Error al crear notificación de cambio de estado', e);
    }
  }
}

