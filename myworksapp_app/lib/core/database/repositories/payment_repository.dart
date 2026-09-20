import '../models/payment_model.dart';
import '../supabase_db.dart';
import '../../domain/pricing_constants.dart';

class PaymentRepository {
  static const String _table = 'pagos';

  /// Columnas visibles al cliente (sin token_tbk / url_tbk).
  static const String clientSelect =
      'id, id_trabajo, id_orden_cambio, tipo_pago, monto, moneda, estado, '
      'metodo_pago, id_transaccion, buy_order, ambiente, autorizado_en, '
      'liberado_en, reembolsado_en, creado_en, actualizado_en';

  /// Insert directo prohibido en flujos comerciales (RLS).
  /// Usar Edge `webpay-create` / RPC `crear_intencion_pago`.
  @Deprecated('Usar TransbankWebpayGateway / webpay-create')
  Future<void> createPayment(PaymentModel payment) async {
    throw UnsupportedError(
      'createPayment directo deshabilitado. Usa Webpay (webpay-create).',
    );
  }

  Future<PaymentModel?> getPaymentById(String id) async {
    final row = await supabase
        .from(_table)
        .select(clientSelect)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return PaymentModel.fromMap(row);
  }

  Future<PaymentModel?> getPaymentByJobId(String jobId) async {
    return getPrimaryByJobId(jobId);
  }

  Future<PaymentModel?> getPrimaryByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select(clientSelect)
        .eq('id_trabajo', jobId)
        .eq('tipo_pago', PricingConstants.paymentTypePrimary)
        .limit(1);
    if (rows.isNotEmpty) {
      return PaymentModel.fromMap(rows.first);
    }
    final legacy = await supabase
        .from(_table)
        .select(clientSelect)
        .eq('id_trabajo', jobId)
        .limit(1);
    if (legacy.isEmpty) return null;
    return PaymentModel.fromMap(legacy.first);
  }

  Future<PaymentModel> transitionPaymentStatus({
    required String paymentId,
    required String newStatus,
    String? transferRef,
    String? notes,
  }) async {
    if (newStatus == PricingConstants.paymentReleased) {
      final ref = (transferRef ?? '').trim();
      if (ref.length < 4) {
        throw ArgumentError(
          'transferRef requerido para liberar escrow (liquidación manual)',
        );
      }
      final res = await supabase.functions.invoke(
        'webpay-release',
        body: {
          'paymentId': paymentId,
          'transferRef': ref,
          'notes': notes,
          'confirmExternal': true,
          'provider': 'manual',
        },
      );
      return _mapEdgePayment(res.data, paymentId);
    }
    if (newStatus == PricingConstants.paymentRefunded) {
      final res = await supabase.functions.invoke(
        'webpay-refund',
        body: {'paymentId': paymentId},
      );
      return _mapEdgePayment(res.data, paymentId);
    }

    final refreshed = await getPaymentById(paymentId);
    if (refreshed == null) {
      throw StateError('Pago no encontrado tras transición');
    }
    return refreshed;
  }

  PaymentModel _mapEdgePayment(dynamic data, String paymentId) {
    if (data is Map && data['payment'] is Map) {
      return PaymentModel.fromMap(
        Map<String, dynamic>.from(data['payment'] as Map),
      );
    }
    if (data is Map && data['error'] != null) {
      throw StateError(data['error'].toString());
    }
    throw StateError('Respuesta Edge inválida para pago $paymentId');
  }

  Future<List<PaymentModel>> listByJobIds(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];
    final rows = await supabase
        .from(_table)
        .select(clientSelect)
        .inFilter('id_trabajo', jobIds);
    return rows.map((r) => PaymentModel.fromMap(r)).toList();
  }
}
