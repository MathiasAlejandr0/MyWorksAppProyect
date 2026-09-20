/// Puerto de pasarela de pago (autorización / hold vía PSP).
///
/// Separado de [PaymentGuardPorts], que valida estado de pagos ya registrados
/// en transiciones de trabajo. El contrato es contra un PSP externo
/// (Webpay Plus / Transbank).
abstract class PaymentGatewayPort {
  /// Inicia autorización/hold por el monto del trabajo (CLP).
  /// En Webpay, [PaymentGatewayResult.redirectUrl] apunta a Transbank.
  Future<PaymentGatewayResult> authorizeHold({
    required String jobId,
    required int amountClp,
    required String userId,
  });
}

/// Resultado de una operación de pasarela.
class PaymentGatewayResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? redirectUrl;
  final String? token;

  const PaymentGatewayResult({
    required this.success,
    this.transactionId,
    this.message,
    this.redirectUrl,
    this.token,
  });

  factory PaymentGatewayResult.ok(
    String transactionId, {
    String? redirectUrl,
    String? token,
  }) =>
      PaymentGatewayResult(
        success: true,
        transactionId: transactionId,
        redirectUrl: redirectUrl,
        token: token,
      );

  factory PaymentGatewayResult.fail(String message) => PaymentGatewayResult(
        success: false,
        message: message,
      );
}

/// Solo tests unitarios. Producción usa [TransbankWebpayGateway].
class MockPaymentGateway implements PaymentGatewayPort {
  @override
  Future<PaymentGatewayResult> authorizeHold({
    required String jobId,
    required int amountClp,
    required String userId,
  }) async {
    if (amountClp <= 0) {
      return PaymentGatewayResult.fail('Monto inválido');
    }
    return PaymentGatewayResult.ok(
      'mock-hold-$jobId-$userId-$amountClp',
      redirectUrl: null,
    );
  }
}
