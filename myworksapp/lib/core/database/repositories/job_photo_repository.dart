import '../database_helper.dart';
import '../models/job_photo_model.dart';

class JobPhotoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createJobPhoto(JobPhotoModel photo) async {
    final db = await _dbHelper.database;
    await db.insert('job_photos', photo.toMap());
  }

  Future<List<JobPhotoModel>> getPhotosByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'job_photos',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => JobPhotoModel.fromMap(map)).toList();
  }

  Future<void> deleteJobPhoto(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'job_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePhotosByJobId(String jobId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'job_photos',
      where: 'jobId = ?',
      whereArgs: [jobId],
    );
  }

  // Contar fotos de un trabajo
  Future<int> getPhotoCountByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM job_photos WHERE jobId = ?',
      [jobId],
    );
    return result.first['count'] as int;
  }
}

