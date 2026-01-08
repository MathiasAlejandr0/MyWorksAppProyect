import '../database/models/analytics_event_model.dart';

/// Interfaz para repositorio de analytics
/// 
/// Permite implementaciones locales (SQLite) y remotas (Firebase/Supabase/Segment).
abstract class IAnalyticsRepository {
  /// Registra un evento de analytics
  Future<void> trackEvent(AnalyticsEventModel event);

  /// Registra múltiples eventos (batch)
  Future<void> trackEvents(List<AnalyticsEventModel> events);

  /// Obtiene eventos por rango de fechas
  Future<List<AnalyticsEventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventName,
    String? userId,
  });

  /// Limpia eventos antiguos (más de X días)
  Future<void> cleanOldEvents(int daysToKeep);

  /// Obtiene estadísticas de eventos
  Future<Map<String, int>> getEventCounts({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Sincroniza eventos pendientes con servidor (si aplica)
  Future<void> syncPendingEvents();
}

