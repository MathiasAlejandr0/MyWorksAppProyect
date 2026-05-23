import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';

/// Relación N:M entre trabajadores y categorías de servicio.
class WorkerServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> linkWorkerToCategory(String workerId, String serviceCategory) async {
    final db = await _dbHelper.database;
    await db.insert(
      'worker_services',
      {
        'workerId': workerId,
        'serviceCategory': serviceCategory,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearWorkerLinks(String workerId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'worker_services',
      where: 'workerId = ?',
      whereArgs: [workerId],
    );
  }

  Future<List<String>> getCategoriesForWorker(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worker_services',
      columns: ['serviceCategory'],
      where: 'workerId = ?',
      whereArgs: [workerId],
    );
    return maps.map((m) => m['serviceCategory'] as String).toList();
  }
}
