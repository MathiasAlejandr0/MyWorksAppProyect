import '../database_helper.dart';
import '../models/worker_model.dart';
import 'job_repository.dart';

class WorkerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createWorker(WorkerModel worker) async {
    final db = await _dbHelper.database;
    await db.insert('workers', worker.toMap());
  }

  Future<WorkerModel?> getWorkerByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return WorkerModel.fromMap(maps.first);
  }

  /// Obtiene un trabajador por su ID (alias para getWorkerByUserId)
  Future<WorkerModel?> getWorkerById(String userId) async {
    return getWorkerByUserId(userId);
  }

  Future<List<WorkerModel>> getWorkersByServiceCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT w.* FROM workers w
      LEFT JOIN worker_services ws ON w.userId = ws.workerId
      WHERE w.isAvailable = 1
        AND (ws.serviceCategory = ? OR w.serviceCategory = ?)
      GROUP BY w.userId
      ORDER BY w.rating DESC
      ''',
      [category, category],
    );
    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<List<WorkerModel>> getWorkersByProfession(String profession) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'profession = ? AND isAvailable = 1',
      whereArgs: [profession],
    );
    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<List<WorkerModel>> getAllAvailableWorkers() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'isAvailable = 1',
    );
    return maps.map((map) => WorkerModel.fromMap(map)).toList();
  }

  Future<void> updateWorker(WorkerModel worker) async {
    final db = await _dbHelper.database;
    await db.update(
      'workers',
      worker.toMap(),
      where: 'userId = ?',
      whereArgs: [worker.userId],
    );
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    final db = await _dbHelper.database;
    await db.update(
      'workers',
      {'isAvailable': isAvailable ? 1 : 0},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateRating(String userId, double rating) async {
    final db = await _dbHelper.database;
    await db.update(
      'workers',
      {'rating': rating},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Obtener trabajadores disponibles que no tienen trabajos activos
  Future<List<WorkerModel>> getAvailableWorkersWithoutActiveJobs() async {
    final db = await _dbHelper.database;
    final allWorkers = await db.query(
      'workers',
      where: 'isAvailable = 1',
      orderBy: 'rating DESC',
    );
    
    final jobRepository = JobRepository();
    final availableWorkers = <WorkerModel>[];
    
    for (var map in allWorkers) {
      final worker = WorkerModel.fromMap(map);
      final hasActiveJobs = await jobRepository.hasActiveJobs(worker.userId);
      if (!hasActiveJobs) {
        availableWorkers.add(worker);
      }
    }
    
    return availableWorkers;
  }
}

