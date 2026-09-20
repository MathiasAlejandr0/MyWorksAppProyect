import '../database/supabase_db.dart';
import 'payment_gateway_port.dart';

/// Gateway Webpay Plus vía Edge Function `webpay-create`.
///
/// Secretos de comercio solo en el servidor. El cliente recibe una URL de
/// handoff que hace POST `token_ws` a Transbank (sin capturar PAN).
class TransbankWebpayGateway implements PaymentGatewayPort {
  TransbankWebpayGateway({this.returnUrl});

  final String? returnUrl;

  @override
  Future<PaymentGatewayResult> authorizeHold({
    required String jobId,
    required int amountClp,
    required String userId,
  }) async {
    if (amountClp <= 0) {
      return PaymentGatewayResult.fail('Monto inválido');
    }

    try {
      final response = await supabase.functions.invoke(
        'webpay-create',
        body: {
          'jobId': jobId,
          'amountClp': amountClp,
          if (returnUrl != null) 'returnUrl': returnUrl,
        },
      );

      final data = response.data;
      if (data is! Map) {
        return PaymentGatewayResult.fail(
          'Respuesta inválida de webpay-create',
        );
      }

      final map = Map<String, dynamic>.from(data);
      if (map['error'] != null) {
        return PaymentGatewayResult.fail(map['error'].toString());
      }

      final redirectUrl = map['redirectUrl']?.toString();
      final buyOrder = map['buyOrder']?.toString();
      final token = map['token']?.toString();

      if (redirectUrl == null || redirectUrl.isEmpty) {
        return PaymentGatewayResult.fail('Webpay no devolvió URL de pago');
      }

      return PaymentGatewayResult.ok(
        buyOrder ?? jobId,
        redirectUrl: redirectUrl,
        token: token,
      );
    } catch (e) {
      return PaymentGatewayResult.fail('Webpay: $e');
    }
  }
}
