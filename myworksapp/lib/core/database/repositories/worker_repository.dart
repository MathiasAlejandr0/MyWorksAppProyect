import '../../domain/worker_login_item.dart';
import '../../services/worker_reputation_service.dart';
import '../models/worker_model.dart';
import '../supabase_db.dart';
import 'job_repository.dart';
class WorkerRepository {
  static const String _table = 'workers';

  Future<void> createWorker(WorkerModel worker) async {
    await supabase.from(_table).upsert(worker.toMap());
  }

  Future<WorkerModel?> getWorkerByUserId(String userId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .maybeSingle();
    if (row == null) return null;
    return WorkerModel.fromMap(row);
  }

  /// Obtiene un trabajador por su ID (alias para getWorkerByUserId)
  Future<WorkerModel?> getWorkerById(String userId) async {
    return getWorkerByUserId(userId);
  }

  Future<List<WorkerModel>> getWorkersByServiceCategory(String category) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('isAvailable', 1)
        .eq('serviceCategory', category)
        .order('rating', ascending: false);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('profession', profession)
        .eq('isAvailable', 1);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final rows = await supabase.from(_table).select().eq('isAvailable', 1);
    final workers = rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
    WorkerReputationService.instance.sortForListing(workers);
    return workers;
  }

  /// Lista trabajadores con nombre y correo para el selector de login demo.
  Future<List<WorkerLoginItem>> getWorkersForLogin() async {
    final workerRows = await supabase
        .from(_table)
        .select('userId, profession, serviceCategory');

    final profileRows = await supabase
        .from('profiles')
        .select('id, name, email, role')
        .eq('role', 'worker');

    final profilesById = <String, Map<String, dynamic>>{
      for (final row in profileRows)
        row['id'] as String: Map<String, dynamic>.from(row),
    };

    final items = <WorkerLoginItem>[];
    for (final row in workerRows) {
      final userId = row['userId'] as String;
      final profile = profilesById[userId];
      if (profile == null) continue;

      items.add(
        WorkerLoginItem(
          userId: userId,
          name: profile['name'] as String? ?? 'Trabajador',
          email: profile['email'] as String? ?? '',
          profession: row['profession'] as String? ?? '',
          serviceCategory: row['serviceCategory'] as String? ?? 'general',
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
        .eq('userId', worker.userId);
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await supabase
        .from(_table)
        .update({'isAvailable': isAvailable ? 1 : 0}).eq('userId', userId);
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
    await supabase.from(_table).update({'rating': rating}).eq('userId', userId);
  }

  // Obtener trabajadores disponibles que no tienen trabajos activos
  Future<List<WorkerModel>> getAvailableWorkersWithoutActiveJobs() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('isAvailable', 1)
        .order('rating', ascending: false);
    final allWorkers =
        rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();

    final jobRepository = JobRepository();
    final availableWorkers = <WorkerModel>[];
    for (final worker in allWorkers) {
      final hasActiveJobs = await jobRepository.hasActiveJobs(worker.userId);
      if (!hasActiveJobs) {
        availableWorkers.add(worker);
      }
    }
    WorkerReputationService.instance.sortForListing(availableWorkers);
    return availableWorkers;
  }
}
