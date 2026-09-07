/// Puerto de pasarela de pago (autorización / hold).
///
/// Separado de [PaymentGuardPorts], que valida estado de pagos ya registrados
/// en transiciones de trabajo. Aquí el contrato es contra un PSP externo
/// (Webpay, Mercado Pago, etc.).
abstract class PaymentGatewayPort {
  /// Autoriza un hold/reserva por el monto del trabajo (CLP).
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

  const PaymentGatewayResult({
    required this.success,
    this.transactionId,
    this.message,
  });

  factory PaymentGatewayResult.ok(String transactionId) => PaymentGatewayResult(
        success: true,
        transactionId: transactionId,
      );

  factory PaymentGatewayResult.fail(String message) => PaymentGatewayResult(
        success: false,
        message: message,
      );
}

/// Simulación local para desarrollo y tests.
///
/// Reemplazar por una implementación real (Webpay Plus / Mercado Pago)
/// cuando se integre la pasarela en producción.
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
    );
  }
}
