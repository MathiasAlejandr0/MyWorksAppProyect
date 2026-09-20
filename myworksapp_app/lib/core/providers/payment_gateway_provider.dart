import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/payment_gateway_port.dart';
import '../services/transbank_webpay_gateway.dart';

/// `PAYMENTS_MODE`: integration | production | mock
final paymentGatewayProvider = Provider<PaymentGatewayPort>((ref) {
  const mode = String.fromEnvironment(
    'PAYMENTS_MODE',
    defaultValue: 'integration',
  );
  if (mode == 'mock') {
    return MockPaymentGateway();
  }
  return TransbankWebpayGateway();
});
