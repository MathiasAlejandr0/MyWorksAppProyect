import '../database_helper.dart';
import '../models/job_cancellation_model.dart';

class JobCancellationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createCancellation(JobCancellationModel cancellation) async {
    final db = await _dbHelper.database;
    await db.insert('job_cancellations', cancellation.toMap());
  }

  Future<JobCancellationModel?> getCancellationByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'job_cancellations',
      where: 'jobId = ?',
      whereArgs: [jobId],
    );
    if (maps.isEmpty) return null;
    return JobCancellationModel.fromMap(maps.first);
  }
}

