import '../models/abuse_event_model.dart';
import '../supabase_db.dart';
import '../../utils/app_logger.dart';

/// Repositorio para eventos de abuso
class AbuseRepository {
  static const String _table = 'eventos_abuso';

  Future<void> createAbuseEvent(AbuseEventModel event) async {
    try {
      await supabase.from(_table).insert(event.toMap());
      AppLogger.d('Abuse event created: ${event.id}');
    } catch (e) {
      AppLogger.e('Error creating abuse event', e);
      rethrow;
    }
  }

  Future<List<AbuseEventModel>> getAbuseEventsByUserId(String userId) async {
    try {
      final rows = await supabase
          .from(_table)
          .select()
          .eq('id_usuario', userId)
          .order('detectado_en', ascending: false);
      return rows
          .map<AbuseEventModel>((m) => AbuseEventModel.fromMap(m))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting abuse events', e);
      return [];
    }
  }

  Future<List<AbuseEventModel>> getUnresolvedAbuseEvents() async {
    try {
      final rows = await supabase
          .from(_table)
          .select()
          .eq('resuelto', 0)
          .order('detectado_en', ascending: false);
      return rows
          .map<AbuseEventModel>((m) => AbuseEventModel.fromMap(m))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting unresolved abuse events', e);
      return [];
    }
  }

  Future<void> updateAbuseEvent(AbuseEventModel event) async {
    try {
      await supabase.from(_table).update(event.toMap()).eq('id', event.id);
      AppLogger.d('Abuse event updated: ${event.id}');
    } catch (e) {
      AppLogger.e('Error updating abuse event', e);
      rethrow;
    }
  }

  Future<void> resolveAbuseEvent(String eventId) async {
    try {
      await supabase.from(_table).update({'resuelto': 1}).eq('id', eventId);
      AppLogger.d('Abuse event resolved: $eventId');
    } catch (e) {
      AppLogger.e('Error resolving abuse event', e);
      rethrow;
    }
  }
}
