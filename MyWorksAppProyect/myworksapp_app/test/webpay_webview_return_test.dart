import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/webpay_webview_return.dart';

void main() {
  test('pago=ok y ok=1 son éxito', () {
    expect(isApprovedWebpayReturn('myworksapp://pago?pago=ok'), isTrue);
    expect(
      isApprovedWebpayReturn('https://localhost:5173/?pago=ok&jobId=1'),
      isTrue,
    );
    expect(isApprovedWebpayReturn('https://app/?ok=1'), isTrue);
    expect(
      isApprovedWebpayReturn(
        'https://myworksapp-cl.vercel.app/?pago=ok&paymentId=pay-1',
      ),
      isTrue,
    );
    expect(
      isApprovedWebpayReturn(
        'https://myworksapp-cl.vercel.app/?tarjeta=ok',
      ),
      isTrue,
    );
  });

  test('la vuelta https de la app se reconoce antes de abrirla', () {
    const url = 'https://myworksapp-cl.vercel.app/?pago=ok&jobId=job-1';
    expect(isWebpayReturnUrl(url), isTrue);
    expect(isApprovedWebpayReturn(url), isTrue);
  });

  test('pago=retorno solo no cuenta como aprobado', () {
    expect(isApprovedWebpayReturn('https://edge/pago?pago=retorno'), isFalse);
    expect(isApprovedWebpayReturn('myworksapp://pago'), isFalse);
    expect(isWebpayReturnUrl('myworksapp://pago'), isTrue);
  });

  test('pago=fail y tarjeta=fail son rechazo', () {
    expect(isApprovedWebpayReturn('https://x/?pago=fail'), isFalse);
    expect(isApprovedWebpayReturn('https://x/?tarjeta=fail'), isFalse);
    expect(isWebpayReturnUrl('https://x/?pago=fail'), isTrue);
  });
}
