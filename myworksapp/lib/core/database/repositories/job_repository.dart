import '../database_helper.dart';
import '../models/job_model.dart';

class JobRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> createJob(JobModel job) async {
    final db = await _dbHelper.database;
    await db.insert('jobs', job.toMap());
    return job.id;
  }

  Future<JobModel?> getJobById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return JobModel.fromMap(maps.first);
  }

  Future<List<JobModel>> getJobsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobModel.fromMap(map)).toList();
  }

  Future<List<JobModel>> getJobsByWorkerId(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobModel.fromMap(map)).toList();
  }

  Future<List<JobModel>> getPendingJobsForWorker(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'workerId = ? AND status = ?',
      whereArgs: [workerId, 'pending'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobModel.fromMap(map)).toList();
  }

  // Obtener trabajos activos (accepted o in_progress) de un trabajador
  Future<List<JobModel>> getActiveJobsByWorkerId(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'workerId = ? AND (status = ? OR status = ?)',
      whereArgs: [workerId, 'accepted', 'in_progress'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobModel.fromMap(map)).toList();
  }

  // Verificar si un trabajador tiene trabajos activos
  Future<bool> hasActiveJobs(String workerId) async {
    final activeJobs = await getActiveJobsByWorkerId(workerId);
    return activeJobs.isNotEmpty;
  }

  Future<List<JobModel>> getJobsByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'jobs',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobModel.fromMap(map)).toList();
  }

  Future<void> updateJob(JobModel job) async {
    final db = await _dbHelper.database;
    await db.update(
      'jobs',
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<void> updateJobStatus(String id, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'jobs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> assignWorker(String jobId, String workerId) async {
    final db = await _dbHelper.database;
    await db.update(
      'jobs',
      {'workerId': workerId, 'status': 'accepted'},
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  Future<void> deleteJob(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene todos los trabajos de un trabajador (alias para getJobsByWorkerId)
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    return await getJobsByWorkerId(workerId);
  }
}

