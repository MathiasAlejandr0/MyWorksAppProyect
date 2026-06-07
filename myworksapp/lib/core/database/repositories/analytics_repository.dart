import '../models/analytics_event_model.dart';
import '../supabase_db.dart';
import '../../interfaces/analytics_repository_interface.dart';
import '../../utils/app_logger.dart';

/// Implementación de AnalyticsRepository sobre Supabase.
class AnalyticsRepository implements IAnalyticsRepository {
  static const String _table = 'analytics_events';

  @override
  Future<void> trackEvent(AnalyticsEventModel event) async {
    try {
      await supabase.from(_table).insert(event.toMap());
      AppLogger.d('Analytics event tracked: ${event.eventName}');
    } catch (e) {
      AppLogger.e('Error tracking analytics event', e);
    }
  }

  @override
  Future<void> trackEvents(List<AnalyticsEventModel> events) async {
    try {
      if (events.isEmpty) return;
      await supabase.from(_table).insert(events.map((e) => e.toMap()).toList());
      AppLogger.d('Batch analytics events tracked: ${events.length}');
    } catch (e) {
      AppLogger.e('Error tracking batch analytics events', e);
    }
  }

  @override
  Future<List<AnalyticsEventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventName,
    String? userId,
  }) async {
    try {
      var query = supabase.from(_table).select();
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }
      if (eventName != null) {
        query = query.eq('eventName', eventName);
      }
      if (userId != null) {
        query = query.eq('userId', userId);
      }
      final rows = await query.order('timestamp', ascending: false);
      return rows
          .map<AnalyticsEventModel>((m) => AnalyticsEventModel.fromMap(m))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting analytics events', e);
      return [];
    }
  }

  @override
  Future<void> cleanOldEvents(int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      await supabase
          .from(_table)
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());
      AppLogger.i('Cleaned old analytics events (older than $daysToKeep days)');
    } catch (e) {
      AppLogger.e('Error cleaning old analytics events', e);
    }
  }

  @override
  Future<Map<String, int>> getEventCounts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getEvents(startDate: startDate, endDate: endDate);
      final counts = <String, int>{};
      for (final e in events) {
        counts[e.eventName] = (counts[e.eventName] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      AppLogger.e('Error getting event counts', e);
      return {};
    }
  }

  @override
  Future<void> syncPendingEvents() async {
    // Con Supabase los eventos se escriben directamente; no hay cola local.
    AppLogger.d('syncPendingEvents: no-op (Supabase online)');
  }
}
