import '../../utils/memo_cache.dart';
import '../models/service_model.dart';
import '../supabase_db.dart';

class ServiceRepository {
  static const String _table = 'servicios';

  /// El catálogo de servicios casi no cambia y varias pantallas lo piden al
  /// arrancar (antes salían 3 requests iguales). Compartido entre instancias.
  static final MemoCache<List<ServiceModel>> _lists =
      MemoCache(ttl: const Duration(minutes: 10));
  static final MemoCache<ServiceModel?> _byId =
      MemoCache(ttl: const Duration(minutes: 10));

  static void clearCache() {
    _lists.clear();
    _byId.clear();
  }

  Future<List<ServiceModel>> getAllServices() =>
      _lists.get('all', _fetchAllServices);

  Future<List<ServiceModel>> _fetchAllServices() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('activo', 1)
        .order('nombre', ascending: true)
        .limit(80);
    return rows.map<ServiceModel>((m) => ServiceModel.fromMap(m)).toList();
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) =>
      _lists.get('cat:$category', () => _fetchByCategory(category));

  Future<List<ServiceModel>> _fetchByCategory(String category) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('categoria', category)
        .eq('activo', 1)
        .order('nombre', ascending: true)
        .limit(80);
    return rows.map<ServiceModel>((m) => ServiceModel.fromMap(m)).toList();
  }

  Future<ServiceModel?> getServiceById(String id) =>
      _byId.get(id, () => _fetchById(id));

  Future<ServiceModel?> _fetchById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return ServiceModel.fromMap(row);
  }

  Future<void> createService(ServiceModel service) async {
    await supabase.from(_table).upsert(service.toMap());
    clearCache();
  }

  Future<void> updateService(ServiceModel service) async {
    await supabase.from(_table).update(service.toMap()).eq('id', service.id);
    clearCache();
  }

  /// Obtiene solo servicios principales (uno por categoría)
  /// Útil para mostrar en el home sin duplicados
  Future<List<ServiceModel>> getMainServices() =>
      _lists.get('main', _fetchMainServices);

  Future<List<ServiceModel>> _fetchMainServices() async {
    final rows = await supabase
        .from(_table)
        .select(
          'id, nombre, descripcion, categoria, activo, modelo_precio, creado_en, actualizado_en',
        )
        .eq('activo', 1)
        .order('categoria', ascending: true)
        .order('nombre', ascending: true)
        .limit(80);
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
