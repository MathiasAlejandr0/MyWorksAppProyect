import '../database_helper.dart';
import '../models/rating_model.dart';

class RatingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createRating(RatingModel rating) async {
    final db = await _dbHelper.database;
    await db.insert('ratings', rating.toMap());
  }

  Future<RatingModel?> getRatingByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ratings',
      where: 'jobId = ?',
      whereArgs: [jobId],
    );
    if (maps.isEmpty) return null;
    return RatingModel.fromMap(maps.first);
  }

  Future<List<RatingModel>> getRatingsByWorkerId(String workerId) async {
    final db = await _dbHelper.database;
    // Necesitamos hacer un JOIN con jobs para obtener las calificaciones de un trabajador
    final maps = await db.rawQuery('''
      SELECT r.* FROM ratings r
      INNER JOIN jobs j ON r.jobId = j.id
      WHERE j.workerId = ?
      ORDER BY r.createdAt DESC
    ''', [workerId]);
    return maps.map((map) => RatingModel.fromMap(map)).toList();
  }

  Future<double> getAverageRatingByWorkerId(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT AVG(r.score) as avgRating FROM ratings r
      INNER JOIN jobs j ON r.jobId = j.id
      WHERE j.workerId = ?
    ''', [workerId]);
    if (maps.isEmpty || maps.first['avgRating'] == null) return 0.0;
    return (maps.first['avgRating'] as num).toDouble();
  }

  /// Obtiene todas las calificaciones donde el usuario es el calificador
  Future<List<RatingModel>> getRatingsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ratings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => RatingModel.fromMap(map)).toList();
  }
}

