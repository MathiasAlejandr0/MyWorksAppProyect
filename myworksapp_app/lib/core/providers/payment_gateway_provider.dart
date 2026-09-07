import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/payment_gateway_port.dart';

/// Provider opcional del puerto de pasarela.
/// Por defecto usa [MockPaymentGateway]; override en tests o al integrar PSP real.
final paymentGatewayProvider = Provider<PaymentGatewayPort>((ref) {
  return MockPaymentGateway();
});
