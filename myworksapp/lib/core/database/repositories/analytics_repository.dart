import '../database_helper.dart';
import '../models/analytics_event_model.dart';
import '../../interfaces/analytics_repository_interface.dart';
import '../../utils/app_logger.dart';

/// Implementación local de AnalyticsRepository (SQLite)
/// 
/// Preparado para migrar a implementación remota (Firebase/Supabase/Segment).
class AnalyticsRepository implements IAnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<void> trackEvent(AnalyticsEventModel event) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('analytics_events', event.toMap());
      AppLogger.d('Analytics event tracked: ${event.eventName}');
    } catch (e) {
      AppLogger.e('Error tracking analytics event', e);
      // No lanzar error - analytics no debe romper la app
    }
  }

  @override
  Future<void> trackEvents(List<AnalyticsEventModel> events) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (final event in events) {
        batch.insert('analytics_events', event.toMap());
      }
      
      await batch.commit(noResult: true);
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
      final db = await _dbHelper.database;
      final where = <String>[];
      final whereArgs = <dynamic>[];

      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (eventName != null) {
        where.add('eventName = ?');
        whereArgs.add(eventName);
      }

      if (userId != null) {
        where.add('userId = ?');
        whereArgs.add(userId);
      }

      final whereClause = where.isNotEmpty ? where.join(' AND ') : null;
      
      final maps = await db.query(
        'analytics_events',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => AnalyticsEventModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting analytics events', e);
      return [];
    }
  }

  @override
  Future<void> cleanOldEvents(int daysToKeep) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await db.delete(
        'analytics_events',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
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
      final db = await _dbHelper.database;
      final where = <String>[];
      final whereArgs = <dynamic>[];

      if (startDate != null) {
        where.add('timestamp >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        where.add('timestamp <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      final whereClause = where.isNotEmpty ? where.join(' AND ') : null;
      
      final maps = await db.rawQuery('''
        SELECT eventName, COUNT(*) as count
        FROM analytics_events
        ${whereClause != null ? 'WHERE $whereClause' : ''}
        GROUP BY eventName
      ''', whereArgs.isNotEmpty ? whereArgs : null);

      final counts = <String, int>{};
      for (final map in maps) {
        counts[map['eventName'] as String] = map['count'] as int;
      }

      return counts;
    } catch (e) {
      AppLogger.e('Error getting event counts', e);
      return {};
    }
  }

  @override
  Future<void> syncPendingEvents() async {
    try {
      // TODO: Implementar cuando tengamos backend
      // Por ahora, solo loguear
      AppLogger.d('Sync pending analytics events (not implemented yet)');
    } catch (e) {
      AppLogger.e('Error syncing pending events', e);
    }
  }
}

