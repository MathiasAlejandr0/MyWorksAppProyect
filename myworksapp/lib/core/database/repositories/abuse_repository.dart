import '../database_helper.dart';
import '../models/abuse_event_model.dart';
import '../../utils/app_logger.dart';

/// Repositorio para eventos de abuso
class AbuseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Crea un evento de abuso
  Future<void> createAbuseEvent(AbuseEventModel event) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('abuse_events', event.toMap());
      AppLogger.d('Abuse event created: ${event.id}');
    } catch (e) {
      AppLogger.e('Error creating abuse event', e);
      rethrow;
    }
  }

  /// Obtiene eventos de abuso por usuario
  Future<List<AbuseEventModel>> getAbuseEventsByUserId(String userId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'abuse_events',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'detectedAt DESC',
      );
      return maps.map((map) => AbuseEventModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting abuse events', e);
      return [];
    }
  }

  /// Obtiene eventos de abuso no resueltos
  Future<List<AbuseEventModel>> getUnresolvedAbuseEvents() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'abuse_events',
        where: 'isResolved = ?',
        whereArgs: [0],
        orderBy: 'detectedAt DESC',
      );
      return maps.map((map) => AbuseEventModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting unresolved abuse events', e);
      return [];
    }
  }

  /// Actualiza un evento de abuso
  Future<void> updateAbuseEvent(AbuseEventModel event) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'abuse_events',
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id],
      );
      AppLogger.d('Abuse event updated: ${event.id}');
    } catch (e) {
      AppLogger.e('Error updating abuse event', e);
      rethrow;
    }
  }

  /// Resuelve un evento de abuso
  Future<void> resolveAbuseEvent(String eventId) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'abuse_events',
        {
          'isResolved': 1,
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );
      AppLogger.d('Abuse event resolved: $eventId');
    } catch (e) {
      AppLogger.e('Error resolving abuse event', e);
      rethrow;
    }
  }
}

