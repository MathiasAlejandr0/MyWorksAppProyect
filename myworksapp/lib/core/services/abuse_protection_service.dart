import 'package:uuid/uuid.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/abuse_repository.dart';
import '../database/models/abuse_event_model.dart';
import '../database/models/job_model.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'trust_score_service.dart';
import 'analytics_service.dart';
import 'dart:io' show Platform;

/// Tipos de abuso detectables
enum AbuseType {
  excessiveJobs, // Demasiados jobs creados por día
  excessiveRejections, // Demasiados rechazos consecutivos
  excessiveCancellations, // Demasiadas cancelaciones
  spamPattern, // Patrón de spam detectado
}

/// Acciones que se pueden tomar
enum AbuseAction {
  shadowBan, // Ocultar del matching
  trustPenalty, // Penalizar trust score
  temporaryBan, // Bloqueo temporal
  warning, // Solo advertencia
}

/// Servicio de protección anti-spam y abuso
/// 
/// Reglas:
/// - Máx jobs creados por día (usuario)
/// - Máx rechazos consecutivos (trabajador)
/// - Máx cancelaciones sin penalización
class AbuseProtectionService {
  static final AbuseProtectionService instance = AbuseProtectionService._();
  AbuseProtectionService._();

  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final AbuseRepository _abuseRepository = AbuseRepository();
  final TrustScoreService _trustScore = TrustScoreService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Límites configurables
  static const int maxJobsPerDay = 10;
  static const int maxConsecutiveRejections = 5;
  static const int maxCancellationsPerDay = 3;

  // Cache de eventos de abuso (en memoria, se persiste en SQLite)
  final Map<String, List<AbuseEventModel>> _abuseCache = {};

  /// Verifica si un usuario puede crear un job
  Future<AbuseCheckResult> canCreateJob(String userId) async {
    try {
      // 1. Verificar límite diario de jobs
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final userJobs = await _jobRepository.getJobsByUserId(userId);
      final todayJobs = userJobs.where((job) => 
        job.createdAt.isAfter(startOfDay)
      ).length;

      if (todayJobs >= maxJobsPerDay) {
        await _recordAbuse(
          userId: userId,
          abuseType: AbuseType.excessiveJobs.name,
          count: todayJobs,
        );

        return AbuseCheckResult(
          allowed: false,
          reason: 'Has alcanzado el límite de trabajos por día ($maxJobsPerDay)',
          action: AbuseAction.temporaryBan,
        );
      }

      // 2. Verificar si está en shadow ban
      if (await _isShadowBanned(userId)) {
        return AbuseCheckResult(
          allowed: false,
          reason: 'Tu cuenta está temporalmente restringida',
          action: AbuseAction.shadowBan,
        );
      }

      return AbuseCheckResult(allowed: true);
    } catch (e) {
      AppLogger.e('Error checking abuse for job creation', e);
      // Por defecto, permitir (no bloquear por error)
      return AbuseCheckResult(allowed: true);
    }
  }

  /// Verifica si un trabajador puede rechazar más trabajos
  Future<AbuseCheckResult> canRejectJob(String workerId) async {
    try {
      // Obtener trabajos recientes del trabajador
      final workerJobs = await _jobRepository.getJobsByWorkerId(workerId);
      
      // Contar rechazos consecutivos (jobs que fueron asignados pero cancelados)
      int consecutiveRejections = 0;
      for (var i = workerJobs.length - 1; i >= 0; i--) {
        final job = workerJobs[i];
        if (job.status == AppConstants.jobStatusCancelled && 
            job.workerId == workerId) {
          consecutiveRejections++;
        } else {
          break; // Romper si encontramos uno que no fue rechazado
        }
      }

      if (consecutiveRejections >= maxConsecutiveRejections) {
        await _recordAbuse(
          userId: workerId,
          abuseType: AbuseType.excessiveRejections.name,
          count: consecutiveRejections,
        );

        return AbuseCheckResult(
          allowed: false,
          reason: 'Demasiados rechazos consecutivos. Tu cuenta puede ser restringida.',
          action: AbuseAction.trustPenalty,
        );
      }

      return AbuseCheckResult(allowed: true);
    } catch (e) {
      AppLogger.e('Error checking abuse for job rejection', e);
      return AbuseCheckResult(allowed: true);
    }
  }

  /// Verifica si un usuario puede cancelar más trabajos
  Future<AbuseCheckResult> canCancelJob(String userId) async {
    try {
      // Verificar límite diario de cancelaciones
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final userJobs = await _jobRepository.getJobsByUserId(userId);
      final todayCancellations = userJobs.where((job) => 
        job.status == AppConstants.jobStatusCancelled &&
        job.createdAt.isAfter(startOfDay)
      ).length;

      if (todayCancellations >= maxCancellationsPerDay) {
        await _recordAbuse(
          userId: userId,
          abuseType: AbuseType.excessiveCancellations.name,
          count: todayCancellations,
        );

        return AbuseCheckResult(
          allowed: false,
          reason: 'Has alcanzado el límite de cancelaciones por día ($maxCancellationsPerDay)',
          action: AbuseAction.trustPenalty,
        );
      }

      return AbuseCheckResult(allowed: true);
    } catch (e) {
      AppLogger.e('Error checking abuse for job cancellation', e);
      return AbuseCheckResult(allowed: true);
    }
  }

  /// Verifica si un usuario está en shadow ban
  Future<bool> _isShadowBanned(String userId) async {
    try {
      // Verificar en cache primero
      final abuseEvents = _abuseCache[userId] ?? [];
      final activeShadowBan = abuseEvents.any((event) =>
        event.abuseType == AbuseType.excessiveJobs.name &&
        event.actionTaken == AbuseAction.shadowBan.name &&
        !event.isResolved
      );

      return activeShadowBan;
    } catch (e) {
      AppLogger.e('Error checking shadow ban', e);
      return false;
    }
  }

  /// Registra un evento de abuso
  Future<void> _recordAbuse({
    required String userId,
    required String abuseType,
    required int count,
  }) async {
    try {
      final abuseEvent = AbuseEventModel(
        id: const Uuid().v4(),
        userId: userId,
        abuseType: abuseType,
        count: count,
        detectedAt: DateTime.now(),
      );

      // Guardar en SQLite (tabla abuse_events)
      await _abuseRepository.createAbuseEvent(abuseEvent);

      // Actualizar cache
      _abuseCache.putIfAbsent(userId, () => []).add(abuseEvent);

      // Aplicar acción automática
      await _applyAbuseAction(abuseEvent);

      // Registrar en analytics
      await _analytics.trackEvent(
        eventName: AnalyticsEvents.abuseDetected,
        userId: userId,
        metadata: {
          'abuseType': abuseType,
          'count': count,
        },
      );

      AppLogger.w('Abuso detectado: $abuseType para usuario $userId (count: $count)');
    } catch (e) {
      AppLogger.e('Error recording abuse', e);
    }
  }

  /// Aplica acción automática según el tipo de abuso
  Future<void> _applyAbuseAction(AbuseEventModel abuseEvent) async {
    try {
      AbuseAction action;

      switch (abuseEvent.abuseType) {
        case 'excessive_jobs':
          action = AbuseAction.shadowBan;
          break;
        case 'excessive_rejections':
          action = AbuseAction.trustPenalty;
          break;
        case 'excessive_cancellations':
          action = AbuseAction.trustPenalty;
          break;
        default:
          action = AbuseAction.warning;
      }

      // Aplicar acción
      switch (action) {
        case AbuseAction.shadowBan:
          // Shadow ban se maneja en el cache
          await _applyShadowBan(abuseEvent.userId);
          break;
        case AbuseAction.trustPenalty:
          // Penalizar trust score
          await _trustScore.recordCancellation(abuseEvent.userId);
          break;
        case AbuseAction.temporaryBan:
          // Bloquear temporalmente (actualizar accountStatus)
          await _applyTemporaryBan(abuseEvent.userId);
          break;
        case AbuseAction.warning:
          // Solo registrar, no aplicar acción
          break;
      }

      // Actualizar evento con acción tomada
      final updatedEvent = abuseEvent.copyWith(
        actionTaken: action.name,
        actionTakenAt: DateTime.now(),
      );

      // Actualizar en SQLite
      await _abuseRepository.updateAbuseEvent(updatedEvent);

      // Registrar en analytics
      if (action == AbuseAction.shadowBan) {
        await _analytics.trackEvent(
          eventName: AnalyticsEvents.shadowBanApplied,
          userId: abuseEvent.userId,
          metadata: {
            'abuseType': abuseEvent.abuseType,
            'count': abuseEvent.count,
          },
        );
      }
    } catch (e) {
      AppLogger.e('Error applying abuse action', e);
    }
  }

  /// Aplica shadow ban (ocultar del matching)
  Future<void> _applyShadowBan(String userId) async {
    // Shadow ban se maneja en el cache
    // En matching, verificar si está shadow banned
    AppLogger.w('Shadow ban aplicado a usuario: $userId');
  }

  /// Aplica bloqueo temporal
  Future<void> _applyTemporaryBan(String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null && user.accountStatus == 'active') {
        await _userRepository.updateAccountStatus(userId, 'suspended');
        AppLogger.w('Bloqueo temporal aplicado a usuario: $userId');
      }
    } catch (e) {
      AppLogger.e('Error applying temporary ban', e);
    }
  }

  /// Verifica si un usuario está shadow banned (para matching)
  Future<bool> isShadowBanned(String userId) async {
    return await _isShadowBanned(userId);
  }

  /// Resuelve un evento de abuso (admin action)
  Future<void> resolveAbuseEvent(String eventId) async {
    try {
      await _abuseRepository.resolveAbuseEvent(eventId);
      AppLogger.i('Abuse event resuelto: $eventId');
    } catch (e) {
      AppLogger.e('Error resolving abuse event', e);
    }
  }

  /// Obtiene eventos de abuso de un usuario
  Future<List<AbuseEventModel>> getAbuseEventsByUserId(String userId) async {
    try {
      return await _abuseRepository.getAbuseEventsByUserId(userId);
    } catch (e) {
      AppLogger.e('Error getting abuse events', e);
      return [];
    }
  }
}

/// Resultado de verificación de abuso
class AbuseCheckResult {
  final bool allowed;
  final String? reason;
  final AbuseAction? action;

  AbuseCheckResult({
    required this.allowed,
    this.reason,
    this.action,
  });
}

