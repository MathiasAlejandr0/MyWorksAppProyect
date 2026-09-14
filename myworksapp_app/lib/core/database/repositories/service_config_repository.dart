import '../models/service_config_model.dart';
import '../supabase_db.dart';
import '../../utils/app_logger.dart';

class ServiceConfigRepository {
  static const String _table = 'configuraciones_servicio';

  Future<ServiceConfigModel?> getConfigByServiceId(String serviceId) async {
    try {
      final row = await supabase
          .from(_table)
          .select()
          .eq('id_servicio', serviceId)
          .maybeSingle();
      if (row == null) return null;
      return ServiceConfigModel.fromMap(row);
    } catch (e) {
      AppLogger.e('Error getting service config', e);
      return null;
    }
  }

  Future<void> createConfig(ServiceConfigModel config) async {
    try {
      await supabase.from(_table).upsert(config.toMap());
    } catch (e) {
      AppLogger.e('Error creating service config', e);
      rethrow;
    }
  }

  Future<void> updateConfig(ServiceConfigModel config) async {
    try {
      await supabase
          .from(_table)
          .update(config.toMap())
          .eq('id_servicio', config.serviceId);
    } catch (e) {
      AppLogger.e('Error updating service config', e);
      rethrow;
    }
  }
}
