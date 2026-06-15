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
        .from('workers')
        .select('*, profiles!workers_userId_fkey(name, email, accountStatus)');
    if (availableOnly == true) {
      query = query.eq('isAvailable', 1);
    } else if (availableOnly == false) {
      query = query.eq('isAvailable', 0);
    }
    final rows = await query.order('profession', ascending: true).limit(limit);

    var entries = rows.map<AdminWorkerEntry>((row) {
      final map = Map<String, dynamic>.from(row);
      final profile = map['profiles'] as Map<String, dynamic>?;
      map.remove('profiles');
      return AdminWorkerEntry(
        worker: WorkerModel.fromMap(map),
        name: profile?['name'] as String? ?? 'Sin nombre',
        email: profile?['email'] as String?,
        accountStatus: profile?['accountStatus'] as String? ?? 'active',
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
    await supabase.from('workers').update({
      'isAvailable': available ? 1 : 0,
    }).eq('userId', userId);
  }

  Future<List<FeatureFlagModel>> listFeatureFlags() => _flagRepo.getAllFlags();

  Future<void> upsertFeatureFlag(FeatureFlagModel flag) =>
      _flagRepo.upsertFlag(flag);

  Future<void> deleteFeatureFlag(String flagId) => _flagRepo.deleteFlag(flagId);

  Future<List<ServiceModel>> listAllServices() async {
    final rows = await supabase
        .from('services')
        .select()
        .order('name', ascending: true);
    return rows
        .map<ServiceModel>(
          (m) => ServiceModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<void> setServiceActive(String serviceId, bool active) async {
    await supabase.from('services').update({
      'isActive': active ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', serviceId);
  }
}
