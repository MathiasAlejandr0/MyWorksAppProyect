import '../../models/feature_flag_model.dart';
import '../../models/service_model.dart';
import '../../models/worker_model.dart';
import '../../supabase_db.dart';
import '../feature_flag_repository.dart';
import 'admin_models.dart';

class AdminCatalogRepository {
  final FeatureFlagRepository _flagRepo = FeatureFlagRepository();

  Future<List<AdminWorkerEntry>> listWorkers({
    int limit = 100,
    String? search,
    bool? availableOnly,
  }) async {
    var query = supabase
        .from('trabajadores')
        .select(
          '*, perfiles!trabajadores_id_usuario_fkey(nombre, correo, estado_cuenta)',
        );
    if (availableOnly == true) {
      query = query.eq('disponible', 1);
    } else if (availableOnly == false) {
      query = query.eq('disponible', 0);
    }
    final rows = await query.order('profesion', ascending: true).limit(limit);

    var entries = rows.map<AdminWorkerEntry>((row) {
      final map = Map<String, dynamic>.from(row);
      final profile = map['perfiles'] as Map<String, dynamic>?;
      map.remove('perfiles');
      return AdminWorkerEntry(
        worker: WorkerModel.fromMap(map),
        name: profile?['nombre'] as String? ?? 'Sin nombre',
        email: profile?['correo'] as String?,
        accountStatus: profile?['estado_cuenta'] as String? ?? 'activo',
      );
    }).toList();

    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      entries = entries
          .where(
            (e) =>
                e.name.toLowerCase().contains(lower) ||
                (e.email?.toLowerCase().contains(lower) ?? false) ||
                e.worker.profession.toLowerCase().contains(lower) ||
                (e.worker.workZone?.toLowerCase().contains(lower) ?? false),
          )
          .toList();
    }
    return entries;
  }

  Future<void> setWorkerAvailability(String userId, bool available) async {
    await supabase.from('trabajadores').update({
      'disponible': available ? 1 : 0,
    }).eq('id_usuario', userId);
  }

  Future<List<FeatureFlagModel>> listFeatureFlags() => _flagRepo.getAllFlags();

  Future<void> upsertFeatureFlag(FeatureFlagModel flag) =>
      _flagRepo.upsertFlag(flag);

  Future<void> deleteFeatureFlag(String flagId) => _flagRepo.deleteFlag(flagId);

  Future<List<ServiceModel>> listAllServices() async {
    final rows = await supabase
        .from('servicios')
        .select()
        .order('nombre', ascending: true);
    return rows
        .map<ServiceModel>(
          (m) => ServiceModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<void> setServiceActive(String serviceId, bool active) async {
    await supabase.from('servicios').update({
      'activo': active ? 1 : 0,
      'actualizado_en': DateTime.now().toIso8601String(),
    }).eq('id', serviceId);
  }
}
