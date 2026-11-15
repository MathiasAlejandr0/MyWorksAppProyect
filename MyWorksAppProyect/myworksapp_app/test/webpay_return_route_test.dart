import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/core/utils/webpay_return_route.dart';

void main() {
  setUp(resetWebpayReturnRouteForTest);

  test('sin sesión o sin pago no redirige', () {
    expect(webpayReturnLocation(isLoggedIn: false), isNull);
    expect(webpayReturnLocation(isLoggedIn: true), isNull);
  });

  test('ruta de detalle usa el prefijo de job', () {
    expect(
      '${AppConstants.routeJobDetail}/abc',
      '/job/detail/abc',
    );
  });
}
