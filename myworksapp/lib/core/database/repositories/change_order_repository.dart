import '../database_helper.dart';
import '../models/change_order_model.dart';
import '../../domain/pricing_constants.dart';

class ChangeOrderRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> create(ChangeOrderModel order) async {
    final database = await _db.database;
    await database.insert('change_orders', order.toMap());
  }

  Future<List<ChangeOrderModel>> getByJobId(String jobId) async {
    final database = await _db.database;
    final rows = await database.query(
      'change_orders',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ChangeOrderModel.fromMap).toList();
  }

  Future<int> countPendingClient(String jobId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM change_orders
      WHERE jobId = ? AND estado = ?
      ''',
      [jobId, PricingConstants.changeOrderPending],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> countApprovedUnpaid(String jobId) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM change_orders
      WHERE jobId = ? AND estado = ?
      ''',
      [jobId, PricingConstants.changeOrderApproved],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> update(ChangeOrderModel order) async {
    final database = await _db.database;
    await database.update(
      'change_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }
}
