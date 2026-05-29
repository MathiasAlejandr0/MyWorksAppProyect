import 'package:uuid/uuid.dart';
import '../database/models/analytics_event_model.dart';
import '../interfaces/analytics_repository_interface.dart';
import '../database/repositories/analytics_repository.dart';
import '../utils/app_logger.dart';
import 'package:flutter/foundation.dart';

/// Eventos de analytics obligatorios
class AnalyticsEvents {
  // App lifecycle
  static const String appOpened = 'app_opened';
  static const String appBackgrounded = 'app_backgrounded';
  static const String appResumed = 'app_resumed';

  // Autenticación
  static const String registerStarted = 'register_started';
  static const String registerCompleted = 'register_completed';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String logout = 'logout';

  // Trabajos
  static const String jobCreated = 'job_created';
  static const String jobAccepted = 'job_accepted';
  static const String jobRejected = 'job_rejected';
  static const String jobExpired = 'job_expired';
  static const String jobCancelled = 'job_cancelled';
  static const String jobCompleted = 'job_completed';
  static const String jobInProgress = 'job_in_progress';
  static const String workerNoResponse = 'worker_no_response';

  // Matching
  static const String matchingAutomaticUsed = 'matching_automatic_used';
  static const String matchingManualUsed = 'matching_manual_used';
  static const String workerSelected = 'worker_selected';

  // Disputas
  static const String disputeOpened = 'dispute_opened';
  static const String disputeResolved = 'dispute_resolved';

  // Calificaciones
  static const String ratingSubmitted = 'rating_submitted';
  static const String ratingSkipped = 'rating_skipped';

  // Pagos
  static const String paymentAuthorized = 'payment_authorized';
  static const String paymentReleased = 'payment_released';
  static const String paymentRefunded = 'payment_refunded';

  // Trust Score
  static const String trustScoreUpdated = 'trust_score_updated';
  static const String softBanTriggered = 'soft_ban_triggered';

  // Abuso
  static const String abuseDetected = 'abuse_detected';
  static const String shadowBanApplied = 'shadow_ban_applied';
}

/// Servicio de analytics desacoplado
/// 
/// Preparado para migrar a Firebase/Supabase/Segment.
/// Implementación actual: SQLite local + logs.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  IAnalyticsRepository _repository = AnalyticsRepository();
  bool _isEnabled = true;

  /// Cambia el repositorio (para testing o migración a backend)
  void setRepository(IAnalyticsRepository repository) {
    _repository = repository;
  }

  /// Habilita/deshabilita analytics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Registra un evento de analytics
  /// 
  /// [eventName] - Nombre del evento (usar AnalyticsEvents)
  /// [userId] - ID del usuario (opcional)
  /// [role] - Rol del usuario (opcional)
  /// [metadata] - Metadata adicional del evento
  Future<void> trackEvent({
    required String eventName,
    String? userId,
    String? role,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) return;

    try {
      final event = AnalyticsEventModel(
        id: const Uuid().v4(),
        eventName: eventName,
        userId: userId,
        role: role,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _repository.trackEvent(event);

      // Log en debug mode
      if (kDebugMode) {
        AppLogger.d('📊 Analytics: $eventName (userId: $userId, role: $role)');
      }
    } catch (e) {
      AppLogger.e('Error tracking analytics event: $eventName', e);
      // No lanzar error - analytics no debe romper la app
    }
  }

  /// Registra evento de app abierta
  Future<void> trackAppOpened({String? userId, String? role}) async {
    await trackEvent(
      eventName: AnalyticsEvents.appOpened,
      userId: userId,
      role: role,
      metadata: {
        'platform': 'mobile', // TODO: Usar dart:io Platform cuando sea necesario
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Registra evento de registro completado
  Future<void> trackRegisterCompleted({
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.registerCompleted,
      userId: userId,
      role: role,
      metadata: {
        'registration_method': 'email',
        ...?metadata,
      },
    );
  }

  /// Registra evento de login exitoso
  Future<void> trackLoginSuccess({
    required String userId,
    required String role,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.loginSuccess,
      userId: userId,
      role: role,
    );
  }

  /// Registra evento de trabajo creado
  Future<void> trackJobCreated({
    required String userId,
    required String jobId,
    required String serviceId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.jobCreated,
      userId: userId,
      role: 'user',
      metadata: {
        'jobId': jobId,
        'serviceId': serviceId,
        ...?metadata,
      },
    );
  }

  /// Registra evento de trabajo aceptado
  Future<void> trackJobAccepted({
    required String workerId,
    required String jobId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.jobAccepted,
      userId: workerId,
      role: 'worker',
      metadata: {
        'jobId': jobId,
        ...?metadata,
      },
    );
  }

  /// Registra evento de trabajo expirado
  Future<void> trackJobExpired({
    required String jobId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.jobExpired,
      userId: userId,
      role: 'user',
      metadata: {
        'jobId': jobId,
        ...?metadata,
      },
    );
  }

  /// Registra evento de trabajo cancelado
  Future<void> trackJobCancelled({
    required String jobId,
    required String userId,
    required String role,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.jobCancelled,
      userId: userId,
      role: role,
      metadata: {
        'jobId': jobId,
        if (reason != null) 'reason': reason,
        ...?metadata,
      },
    );
  }

  /// Registra evento de trabajo completado
  Future<void> trackJobCompleted({
    required String jobId,
    required String workerId,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.jobCompleted,
      userId: workerId,
      role: 'worker',
      metadata: {
        'jobId': jobId,
        ...?metadata,
      },
    );
  }

  /// Registra evento de trabajador sin respuesta
  Future<void> trackWorkerNoResponse({
    required String jobId,
    required String userId,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.workerNoResponse,
      userId: userId,
      role: 'user',
      metadata: {
        'jobId': jobId,
      },
    );
  }

  /// Registra evento de disputa abierta
  Future<void> trackDisputeOpened({
    required String disputeId,
    required String jobId,
    required String userId,
    required String reason,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.disputeOpened,
      userId: userId,
      metadata: {
        'disputeId': disputeId,
        'jobId': jobId,
        'reason': reason,
      },
    );
  }

  /// Registra evento de calificación enviada
  Future<void> trackRatingSubmitted({
    required String jobId,
    required String workerId,
    required int score,
    bool hasComment = false,
  }) async {
    await trackEvent(
      eventName: AnalyticsEvents.ratingSubmitted,
      userId: workerId,
      role: 'worker',
      metadata: {
        'jobId': jobId,
        'score': score,
        'hasComment': hasComment,
      },
    );
  }

  /// Obtiene estadísticas de eventos
  Future<Map<String, int>> getEventStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getEventCounts(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.e('Error getting event stats', e);
      return {};
    }
  }

  /// Limpia eventos antiguos (más de 90 días por defecto)
  Future<void> cleanOldEvents({int daysToKeep = 90}) async {
    try {
      await _repository.cleanOldEvents(daysToKeep);
    } catch (e) {
      AppLogger.e('Error cleaning old events', e);
    }
  }

  /// Sincroniza eventos pendientes (preparado para backend)
  Future<void> syncPendingEvents() async {
    try {
      await _repository.syncPendingEvents();
    } catch (e) {
      AppLogger.e('Error syncing pending events', e);
    }
  }

  // ============================================
  // MÉTRICAS DE NEGOCIO (NUEVAS)
  // ============================================

  /// Clasificación de eventos para analytics
  static const String categoryBusiness = 'business';
  static const String categoryUX = 'ux';
  static const String categorySecurity = 'security';
  static const String categorySystem = 'system';

  /// Registra evento con categoría
  Future<void> trackEventWithCategory({
    required String eventName,
    required String category,
    String? userId,
    String? role,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: eventName,
      userId: userId,
      role: role,
      metadata: {
        'category': category,
        ...?metadata,
      },
    );
  }

  /// Calcula tasa de conversión usuario → solicitud
  /// 
  /// Retorna porcentaje de usuarios que crearon al menos un trabajo
  Future<double> calculateUserToRequestConversion({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final registeredUsers = await _repository.getEventCounts(
        startDate: startDate,
        endDate: endDate,
      );
      
      final registeredCount = registeredUsers[AnalyticsEvents.registerCompleted] ?? 0;
      
      if (registeredCount == 0) return 0.0;
      
      // Usuarios únicos que crearon trabajos
      final events = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobCreated,
      );
      final uniqueUsers = events.map((e) => e.userId).where((id) => id != null).toSet().length;
      
      return (uniqueUsers / registeredCount * 100);
    } catch (e) {
      AppLogger.e('Error calculating conversion rate', e);
      return 0.0;
    }
  }

  /// Calcula tasa de aceptación de trabajadores
  /// 
  /// Retorna porcentaje de trabajos aceptados vs creados
  Future<double> calculateWorkerAcceptanceRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stats = await _repository.getEventCounts(
        startDate: startDate,
        endDate: endDate,
      );
      
      final created = stats[AnalyticsEvents.jobCreated] ?? 0;
      final accepted = stats[AnalyticsEvents.jobAccepted] ?? 0;
      
      if (created == 0) return 0.0;
      
      return (accepted / created * 100);
    } catch (e) {
      AppLogger.e('Error calculating acceptance rate', e);
      return 0.0;
    }
  }

  /// Calcula tiempo promedio de respuesta de trabajadores
  /// 
  /// Retorna tiempo promedio en minutos entre job_created y job_accepted
  Future<double> calculateAverageResponseTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final createdEvents = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobCreated,
      );
      
      final acceptedEvents = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobAccepted,
      );
      
      // Mapear por jobId
      final createdMap = <String, DateTime>{};
      for (final event in createdEvents) {
        final jobId = event.metadata['jobId'] as String?;
        if (jobId != null) {
          createdMap[jobId] = event.timestamp;
        }
      }
      
      final responseTimes = <Duration>[];
      for (final event in acceptedEvents) {
        final jobId = event.metadata['jobId'] as String?;
        if (jobId != null && createdMap.containsKey(jobId)) {
          final createdTime = createdMap[jobId]!;
          final acceptedTime = event.timestamp;
          responseTimes.add(acceptedTime.difference(createdTime));
        }
      }
      
      if (responseTimes.isEmpty) return 0.0;
      
      final totalMinutes = responseTimes
          .map((d) => d.inMinutes)
          .reduce((a, b) => a + b);
      
      return totalMinutes / responseTimes.length;
    } catch (e) {
      AppLogger.e('Error calculating response time', e);
      return 0.0;
    }
  }

  /// Calcula tasa de cancelaciones por servicio
  Future<Map<String, double>> calculateCancellationRateByService({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final cancelledEvents = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobCancelled,
      );
      
      final createdEvents = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobCreated,
      );
      
      // Contar por serviceId
      final cancelledByService = <String, int>{};
      final createdByService = <String, int>{};
      
      for (final event in cancelledEvents) {
        final serviceId = event.metadata['serviceId'] as String?;
        if (serviceId != null) {
          cancelledByService[serviceId] = (cancelledByService[serviceId] ?? 0) + 1;
        }
      }
      
      for (final event in createdEvents) {
        final serviceId = event.metadata['serviceId'] as String?;
        if (serviceId != null) {
          createdByService[serviceId] = (createdByService[serviceId] ?? 0) + 1;
        }
      }
      
      final rates = <String, double>{};
      for (final serviceId in createdByService.keys) {
        final created = createdByService[serviceId] ?? 0;
        final cancelled = cancelledByService[serviceId] ?? 0;
        
        if (created > 0) {
          rates[serviceId] = (cancelled / created * 100);
        }
      }
      
      return rates;
    } catch (e) {
      AppLogger.e('Error calculating cancellation rates', e);
      return {};
    }
  }

  /// Calcula tasa de repetición de usuarios
  /// 
  /// Retorna porcentaje de usuarios que crearon más de un trabajo
  Future<double> calculateUserRepeatRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await _repository.getEvents(
        startDate: startDate,
        endDate: endDate,
        eventName: AnalyticsEvents.jobCreated,
      );
      
      final jobsByUser = <String, int>{};
      for (final event in events) {
        if (event.userId != null) {
          jobsByUser[event.userId!] = (jobsByUser[event.userId!] ?? 0) + 1;
        }
      }
      
      final totalUsers = jobsByUser.length;
      if (totalUsers == 0) return 0.0;
      
      final repeatUsers = jobsByUser.values.where((count) => count > 1).length;
      
      return (repeatUsers / totalUsers * 100);
    } catch (e) {
      AppLogger.e('Error calculating repeat rate', e);
      return 0.0;
    }
  }

  /// Obtiene métricas de negocio completas
  Future<BusinessMetrics> getBusinessMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final conversionRate = await calculateUserToRequestConversion(
        startDate: startDate,
        endDate: endDate,
      );
      
      final acceptanceRate = await calculateWorkerAcceptanceRate(
        startDate: startDate,
        endDate: endDate,
      );
      
      final avgResponseTime = await calculateAverageResponseTime(
        startDate: startDate,
        endDate: endDate,
      );
      
      final cancellationRates = await calculateCancellationRateByService(
        startDate: startDate,
        endDate: endDate,
      );
      
      final repeatRate = await calculateUserRepeatRate(
        startDate: startDate,
        endDate: endDate,
      );
      
      return BusinessMetrics(
        userToRequestConversion: conversionRate,
        workerAcceptanceRate: acceptanceRate,
        averageResponseTimeMinutes: avgResponseTime,
        cancellationRateByService: cancellationRates,
        userRepeatRate: repeatRate,
      );
    } catch (e) {
      AppLogger.e('Error getting business metrics', e);
      return BusinessMetrics.empty();
    }
  }
}

/// Métricas de negocio
class BusinessMetrics {
  final double userToRequestConversion; // %
  final double workerAcceptanceRate; // %
  final double averageResponseTimeMinutes; // minutos
  final Map<String, double> cancellationRateByService; // % por servicio
  final double userRepeatRate; // %

  BusinessMetrics({
    required this.userToRequestConversion,
    required this.workerAcceptanceRate,
    required this.averageResponseTimeMinutes,
    required this.cancellationRateByService,
    required this.userRepeatRate,
  });

  factory BusinessMetrics.empty() {
    return BusinessMetrics(
      userToRequestConversion: 0.0,
      workerAcceptanceRate: 0.0,
      averageResponseTimeMinutes: 0.0,
      cancellationRateByService: {},
      userRepeatRate: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userToRequestConversion': userToRequestConversion,
      'workerAcceptanceRate': workerAcceptanceRate,
      'averageResponseTimeMinutes': averageResponseTimeMinutes,
      'cancellationRateByService': cancellationRateByService,
      'userRepeatRate': userRepeatRate,
    };
  }
}
