import '../database_helper.dart';
import '../models/payment_model.dart';
import '../../domain/pricing_constants.dart';

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

  /// Primer pago del job (compatibilidad con esquema 1:1 anterior).
  Future<PaymentModel?> getPaymentByJobId(String jobId) async {
    return getPrimaryByJobId(jobId);
  }

  Future<PaymentModel?> getPrimaryByJobId(String jobId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'jobId = ? AND paymentType = ?',
      whereArgs: [jobId, PricingConstants.paymentTypePrimary],
      limit: 1,
    );
    if (maps.isEmpty) {
      // Fallback registros antiguos sin paymentType
      final legacy = await db.query(
        'payments',
        where: 'jobId = ?',
        whereArgs: [jobId],
        limit: 1,
      );
      if (legacy.isEmpty) return null;
      return PaymentModel.fromMap(legacy.first);
    }
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
