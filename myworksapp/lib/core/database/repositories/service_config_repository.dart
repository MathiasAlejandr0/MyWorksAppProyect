import '../database_helper.dart';
import '../models/service_config_model.dart';
import '../../utils/app_logger.dart';

class ServiceConfigRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ServiceConfigModel?> getConfigByServiceId(String serviceId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'service_configs',
        where: 'serviceId = ?',
        whereArgs: [serviceId],
      );
      if (maps.isEmpty) return null;
      return ServiceConfigModel.fromMap(maps.first);
    } catch (e) {
      AppLogger.e('Error getting service config', e);
      return null;
    }
  }

  Future<void> createConfig(ServiceConfigModel config) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('service_configs', config.toMap());
    } catch (e) {
      AppLogger.e('Error creating service config', e);
      rethrow;
    }
  }

  Future<void> updateConfig(ServiceConfigModel config) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'service_configs',
        config.toMap(),
        where: 'serviceId = ?',
        whereArgs: [config.serviceId],
      );
    } catch (e) {
      AppLogger.e('Error updating service config', e);
      rethrow;
    }
  }
}

