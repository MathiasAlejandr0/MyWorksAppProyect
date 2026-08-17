import '../models/feature_flag_model.dart';
import '../supabase_db.dart';
import '../../utils/app_logger.dart';

/// Repositorio para feature flags
class FeatureFlagRepository {
  static const String _table = 'feature_flags';

  Future<void> upsertFlag(FeatureFlagModel flag) async {
    try {
      await supabase.from(_table).upsert(flag.toMap());
      AppLogger.d('Feature flag upserted: ${flag.flagName}');
    } catch (e) {
      AppLogger.e('Error upserting feature flag', e);
      rethrow;
    }
  }

  Future<FeatureFlagModel?> getFlag({
    required String flagName,
    String? appVersion,
    String? role,
    String? userId,
  }) async {
    try {
      final rows =
          await supabase.from(_table).select().eq('flagName', flagName);
      var flags = rows
          .map<FeatureFlagModel>((m) => FeatureFlagModel.fromMap(m))
          .toList();

      // Filtrar por el contexto más específico disponible.
      if (userId != null) {
        flags = flags
            .where((f) => f.userId == userId || f.userId == null)
            .toList();
      } else if (role != null) {
        flags = flags.where((f) => f.role == role || f.role == null).toList();
      } else if (appVersion != null) {
        flags = flags
            .where((f) => f.appVersion == appVersion || f.appVersion == null)
            .toList();
      }

      if (flags.isEmpty) return null;

      int specificity(FeatureFlagModel f) {
        if (f.userId != null) return 1;
        if (f.role != null) return 2;
        if (f.appVersion != null) return 3;
        return 4;
      }

      flags.sort((a, b) => specificity(a).compareTo(specificity(b)));
      return flags.first;
    } catch (e) {
      AppLogger.e('Error getting feature flag', e);
      return null;
    }
  }

  Future<List<FeatureFlagModel>> getAllFlags() async {
    try {
      final rows =
          await supabase.from(_table).select().order('flagName', ascending: true);
      return rows
          .map<FeatureFlagModel>((m) => FeatureFlagModel.fromMap(m))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting all feature flags', e);
      return [];
    }
  }

  Future<void> deleteFlag(String flagId) async {
    try {
      await supabase.from(_table).delete().eq('id', flagId);
      AppLogger.d('Feature flag deleted: $flagId');
    } catch (e) {
      AppLogger.e('Error deleting feature flag', e);
      rethrow;
    }
  }
}
