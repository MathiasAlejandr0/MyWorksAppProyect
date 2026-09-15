import '../models/payment_model.dart';
import '../supabase_db.dart';
import '../../domain/pricing_constants.dart';

class PaymentRepository {
  static const String _table = 'pagos';

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
        .eq('id_trabajo', jobId)
        .eq('tipo_pago', PricingConstants.paymentTypePrimary)
        .limit(1);
    if (rows.isNotEmpty) {
      return PaymentModel.fromMap(rows.first);
    }
    // Fallback registros antiguos sin paymentType
    final legacy =
        await supabase.from(_table).select().eq('id_trabajo', jobId).limit(1);
    if (legacy.isEmpty) return null;
    return PaymentModel.fromMap(legacy.first);
  }

  /// Mock escrow: transición de estado vía RPC (no UPDATE directo de clientes).
  /// Sustituir por webhook PSP cuando exista pasarela real.
  Future<PaymentModel> transitionPaymentStatus({
    required String paymentId,
    required String newStatus,
  }) async {
    final row = await supabase.rpc(
      'simular_transicion_pago',
      params: {
        'p_pago_id': paymentId,
        'p_nuevo_estado': newStatus,
      },
    );
    if (row is Map<String, dynamic>) {
      return PaymentModel.fromMap(row);
    }
    if (row is List && row.isNotEmpty) {
      return PaymentModel.fromMap(Map<String, dynamic>.from(row.first as Map));
    }
    final refreshed = await getPaymentById(paymentId);
    if (refreshed == null) {
      throw StateError('Pago no encontrado tras transición');
    }
    return refreshed;
  }

  @Deprecated('Usar transitionPaymentStatus — RLS bloquea UPDATE directo')
  Future<void> updatePayment(PaymentModel payment) async {
    await transitionPaymentStatus(
      paymentId: payment.id,
      newStatus: payment.status,
    );
  }

  Future<List<PaymentModel>> listByJobIds(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];
    final rows = await supabase
        .from(_table)
        .select()
        .inFilter('id_trabajo', jobIds)
        .order('creado_en', ascending: false);
    return rows
        .map<PaymentModel>((m) => PaymentModel.fromMap(m))
        .toList();
  }
}
