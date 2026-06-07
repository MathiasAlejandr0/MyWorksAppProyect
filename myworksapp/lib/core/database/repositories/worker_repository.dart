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
    return rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('profession', profession)
        .eq('isAvailable', 1);
    return rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final rows = await supabase.from(_table).select().eq('isAvailable', 1);
    return rows.map<WorkerModel>((m) => WorkerModel.fromMap(m)).toList();
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
    return availableWorkers;
  }
}
