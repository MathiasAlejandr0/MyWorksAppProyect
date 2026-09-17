import '../../domain/user_location_context.dart';
import '../../domain/worker_login_item.dart';
import '../../services/worker_reputation_service.dart';
import '../../utils/worker_zone_matcher.dart';
import '../models/worker_model.dart';
import '../supabase_db.dart';
import 'job_repository.dart';
class WorkerRepository {
  static const String _table = 'trabajadores';

  Future<void> createWorker(WorkerModel worker) async {
    await supabase.from(_table).upsert(worker.toMap());
  }

  Future<WorkerModel?> getWorkerByUserId(String userId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id_usuario', userId)
        .maybeSingle();
    if (row == null) return null;
    return WorkerModel.fromMap(row);
  }

  /// Obtiene un trabajador por su ID (alias para getWorkerByUserId)
  Future<WorkerModel?> getWorkerById(String userId) async {
    return getWorkerByUserId(userId);
  }

  Future<List<WorkerModel>> getWorkersByServiceCategory(
    String category, {
    UserLocationContext? near,
  }) async {
    var rows = await supabase
        .from(_table)
        .select()
        .eq('categoria_servicio', category)
        .order('calificacion', ascending: false);

    if (rows.isEmpty) {
      final needle = category.replaceAll(RegExp(r'[%_,]'), '');
      if (needle.isNotEmpty) {
        rows = await supabase
            .from(_table)
            .select()
            .ilike('categoria_servicio', '%$needle%')
            .order('calificacion', ascending: false);
      }
    }

    final workers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    return _filterListedWorkers(workers, near: near);
  }

  /// Solo trabajadores disponibles y ordenados por reputación
  Future<List<WorkerModel>> _filterListedWorkers(
    List<WorkerModel> workers, {
    UserLocationContext? near,
  }) async {
    if (workers.isEmpty) return [];

    final jobRepository = JobRepository();
    final busyIds = await jobRepository.getBusyWorkerIds(
      workers.map((w) => w.userId).toList(),
    );
    final listed = <WorkerModel>[];
    for (final worker in workers) {
      if (!worker.isAvailable) continue;
      if (busyIds.contains(worker.userId)) continue;
      if (near != null && worker.workZone != null && worker.workZone!.isNotEmpty) {
        if (!WorkerZoneMatcher.serves(
          workZone: worker.workZone,
          userLocation: near,
        )) {
          continue;
        }
      }
      listed.add(worker);
    }

    // Fallback de integridad: Si el filtro de zona o disponibilidad dejó 0 resultados,
    // devolver los trabajadores de la categoría para no dejar al cliente sin alternativas demo.
    if (listed.isEmpty) {
      for (final worker in workers) {
        listed.add(worker);
      }
    }

    WorkerReputationService.instance.sortForListing(listed);
    return listed;
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('profesion', profession)
        .eq('disponible', 1);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final rows = await supabase.from(_table).select().eq('disponible', 1);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  /// Lista trabajadores con nombre y correo para el selector de login demo.
  Future<List<WorkerLoginItem>> getWorkersForLogin() async {
    final workerRows = await supabase
        .from(_table)
        .select('id_usuario, profesion, categoria_servicio');

    final profileRows = await supabase
        .from('perfiles')
        .select('id, nombre, correo, rol')
        .eq('rol', 'trabajador');

    final profilesById = <String, Map<String, dynamic>>{
      for (final row in profileRows)
        row['id'] as String: Map<String, dynamic>.from(row),
    };

    final items = <WorkerLoginItem>[];
    for (final row in workerRows) {
      final userId = row['id_usuario'] as String;
      final profile = profilesById[userId];
      if (profile == null) continue;

      items.add(
        WorkerLoginItem(
          userId: userId,
          name: profile['nombre'] as String? ?? 'Trabajador',
          email: profile['correo'] as String? ?? '',
          profession: row['profesion'] as String? ?? '',
          serviceCategory: row['categoria_servicio'] as String? ?? 'general',
        ),
      );
    }

    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> updateWorker(WorkerModel worker) async {
    await supabase
        .from(_table)
        .update(worker.toMap())
        .eq('id_usuario', worker.userId);
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await supabase
        .from(_table)
        .update({'disponible': isAvailable ? 1 : 0}).eq('id_usuario', userId);
  }

  /// Disponible para nuevos trabajos: flag activo y sin trabajos en curso.
  Future<bool> isWorkerAcceptingJobs(String userId) async {
    final worker = await getWorkerByUserId(userId);
    if (worker == null || !worker.isAvailable) return false;
    final jobRepository = JobRepository();
    return !await jobRepository.hasActiveJobs(userId);
  }

  /// Mantiene al trabajador como no disponible mientras tenga trabajos activos.
  Future<void> enforceUnavailableWhileBusy(String userId) async {
    final jobRepository = JobRepository();
    if (!await jobRepository.hasActiveJobs(userId)) return;

    final worker = await getWorkerByUserId(userId);
    if (worker != null && worker.isAvailable) {
      await updateAvailability(userId, false);
    }
  }

  Future<void> updateRating(String userId, double rating) async {
    await supabase
        .from(_table)
        .update({'calificacion': rating}).eq('id_usuario', userId);
  }

  // Obtener trabajadores disponibles que no tienen trabajos activos
  Future<List<WorkerModel>> getAvailableWorkersWithoutActiveJobs({
    UserLocationContext? near,
  }) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('disponible', 1)
        .eq('precios_configurados', 1)
        .order('calificacion', ascending: false);
    final allWorkers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    return _filterListedWorkers(allWorkers, near: near);
  }

  /// Indica si el trabajador tiene trabajos activos (para badge «ocupado»).
  Future<bool> hasActiveJobs(String userId) async {
    final jobRepository = JobRepository();
    return jobRepository.hasActiveJobs(userId);
  }
}
