import '../database_helper.dart';
import '../models/dispute_model.dart';

class DisputeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createDispute(DisputeModel dispute) async {
    final db = await _dbHelper.database;
    await db.insert('disputes', dispute.toMap());
  }

  Future<DisputeModel?> getDisputeById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'disputes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DisputeModel.fromMap(maps.first);
  }

  Future<DisputeModel?> getDisputeByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'disputes',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DisputeModel.fromMap(maps.first);
  }

  Future<void> updateDispute(DisputeModel dispute) async {
    final db = await _dbHelper.database;
    await db.update(
      'disputes',
      dispute.toMap(),
      where: 'id = ?',
      whereArgs: [dispute.id],
    );
  }

  Future<List<DisputeModel>> getOpenDisputes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'disputes',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => DisputeModel.fromMap(map)).toList();
  }
}

