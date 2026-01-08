import '../database_helper.dart';
import '../models/boost_model.dart';

class BoostRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createBoost(BoostModel boost) async {
    final db = await _dbHelper.database;
    await db.insert('boosts', boost.toMap());
  }

  Future<List<BoostModel>> getActiveBoosts(String workerId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'boosts',
      where: 'workerId = ? AND startDate <= ? AND endDate >= ?',
      whereArgs: [workerId, now, now],
    );
    return maps.map((map) => BoostModel.fromMap(map)).toList();
  }

  Future<List<BoostModel>> getAllBoosts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('boosts');
    return maps.map((map) => BoostModel.fromMap(map)).toList();
  }

  Future<void> deleteBoost(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'boosts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

