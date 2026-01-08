import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/feature_flag_model.dart';
import '../../utils/app_logger.dart';

/// Repositorio para feature flags
class FeatureFlagRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Crea o actualiza un feature flag
  Future<void> upsertFlag(FeatureFlagModel flag) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'feature_flags',
        flag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.d('Feature flag upserted: ${flag.flagName}');
    } catch (e) {
      AppLogger.e('Error upserting feature flag', e);
      rethrow;
    }
  }

  /// Obtiene un feature flag por nombre y contexto
  Future<FeatureFlagModel?> getFlag({
    required String flagName,
    String? appVersion,
    String? role,
    String? userId,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      // Buscar flag más específico primero (usuario > rol > versión > global)
      final where = <String>['flagName = ?'];
      final whereArgs = <dynamic>[flagName];

      // Prioridad: userId > role > appVersion > global
      if (userId != null) {
        where.add('(userId = ? OR userId IS NULL)');
        whereArgs.add(userId);
      } else if (role != null) {
        where.add('(role = ? OR role IS NULL)');
        whereArgs.add(role);
      } else if (appVersion != null) {
        where.add('(appVersion = ? OR appVersion IS NULL)');
        whereArgs.add(appVersion);
      }

      final maps = await db.query(
        'feature_flags',
        where: where.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'CASE WHEN userId IS NOT NULL THEN 1 WHEN role IS NOT NULL THEN 2 WHEN appVersion IS NOT NULL THEN 3 ELSE 4 END',
      );

      if (maps.isEmpty) {
        return null;
      }

      // Retornar el más específico (primero en la lista ordenada)
      return FeatureFlagModel.fromMap(maps.first);
    } catch (e) {
      AppLogger.e('Error getting feature flag', e);
      return null;
    }
  }

  /// Obtiene todos los feature flags
  Future<List<FeatureFlagModel>> getAllFlags() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('feature_flags', orderBy: 'flagName ASC');
      return maps.map((map) => FeatureFlagModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.e('Error getting all feature flags', e);
      return [];
    }
  }

  /// Elimina un feature flag
  Future<void> deleteFlag(String flagId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('feature_flags', where: 'id = ?', whereArgs: [flagId]);
      AppLogger.d('Feature flag deleted: $flagId');
    } catch (e) {
      AppLogger.e('Error deleting feature flag', e);
      rethrow;
    }
  }
}

