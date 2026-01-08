import '../database_helper.dart';
import '../models/report_model.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createReport(ReportModel report) async {
    final db = await _dbHelper.database;
    await db.insert('reports', report.toMap());
  }

  Future<List<ReportModel>> getReportsByReporterId(String reporterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reports',
      where: 'reporterId = ?',
      whereArgs: [reporterId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ReportModel.fromMap(map)).toList();
  }

  Future<List<ReportModel>> getReportsByReportedUserId(String reportedUserId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reports',
      where: 'reportedUserId = ?',
      whereArgs: [reportedUserId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ReportModel.fromMap(map)).toList();
  }

  Future<void> updateReportStatus(String id, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'reports',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

