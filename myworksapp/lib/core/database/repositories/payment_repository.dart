import '../database_helper.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createPayment(PaymentModel payment) async {
    final db = await _dbHelper.database;
    await db.insert('payments', payment.toMap());
  }

  Future<PaymentModel?> getPaymentById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PaymentModel.fromMap(maps.first);
  }

  Future<PaymentModel?> getPaymentByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'jobId = ?',
      whereArgs: [jobId],
    );
    if (maps.isEmpty) return null;
    return PaymentModel.fromMap(maps.first);
  }

  Future<void> updatePayment(PaymentModel payment) async {
    final db = await _dbHelper.database;
    await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }
}

