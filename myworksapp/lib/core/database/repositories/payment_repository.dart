import '../models/payment_model.dart';
import '../supabase_db.dart';
import '../../domain/pricing_constants.dart';

class PaymentRepository {
  static const String _table = 'payments';

  Future<void> createPayment(PaymentModel payment) async {
    await supabase.from(_table).insert(payment.toMap());
  }

  Future<PaymentModel?> getPaymentById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return PaymentModel.fromMap(row);
  }

  /// Primer pago del job (compatibilidad con esquema 1:1 anterior).
  Future<PaymentModel?> getPaymentByJobId(String jobId) async {
    return getPrimaryByJobId(jobId);
  }

  Future<PaymentModel?> getPrimaryByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .eq('paymentType', PricingConstants.paymentTypePrimary)
        .limit(1);
    if (rows.isNotEmpty) {
      return PaymentModel.fromMap(rows.first);
    }
    // Fallback registros antiguos sin paymentType
    final legacy =
        await supabase.from(_table).select().eq('jobId', jobId).limit(1);
    if (legacy.isEmpty) return null;
    return PaymentModel.fromMap(legacy.first);
  }

  Future<void> updatePayment(PaymentModel payment) async {
    await supabase.from(_table).update(payment.toMap()).eq('id', payment.id);
  }
}
