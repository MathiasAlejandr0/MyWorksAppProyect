import '../database_helper.dart';
import '../models/portfolio_model.dart';

class PortfolioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createPortfolioItem(PortfolioModel item) async {
    final db = await _dbHelper.database;
    await db.insert('worker_portfolio', item.toMap());
  }

  Future<List<PortfolioModel>> getPortfolioByWorkerId(String workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worker_portfolio',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => PortfolioModel.fromMap(map)).toList();
  }

  Future<void> deletePortfolioItem(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'worker_portfolio',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

