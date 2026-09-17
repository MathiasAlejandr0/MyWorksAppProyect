import '../models/service_model.dart';
import '../supabase_db.dart';

class ServiceRepository {
  static const String _table = 'servicios';

  Future<List<ServiceModel>> getAllServices() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('activo', 1)
        .order('nombre', ascending: true);
    return rows.map<ServiceModel>((m) => ServiceModel.fromMap(m)).toList();
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('categoria', category)
        .eq('activo', 1)
        .order('nombre', ascending: true);
    return rows.map<ServiceModel>((m) => ServiceModel.fromMap(m)).toList();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return ServiceModel.fromMap(row);
  }

  Future<void> createService(ServiceModel service) async {
    await supabase.from(_table).upsert(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await supabase.from(_table).update(service.toMap()).eq('id', service.id);
  }

  /// Obtiene solo servicios principales (uno por categoría)
  /// Útil para mostrar en el home sin duplicados
  Future<List<ServiceModel>> getMainServices() async {
    final rows = await supabase
        .from(_table)
        .select(
          'id, nombre, descripcion, categoria, activo, modelo_precio, creado_en, actualizado_en',
        )
        .eq('activo', 1)
        .order('categoria', ascending: true)
        .order('nombre', ascending: true);
    final allServices =
        rows.map<ServiceModel>((m) => ServiceModel.fromMap(m)).toList();

    final Map<String, ServiceModel> mainServices = {};
    for (final service in allServices) {
      mainServices.putIfAbsent(service.category, () => service);
    }

    final result = mainServices.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
