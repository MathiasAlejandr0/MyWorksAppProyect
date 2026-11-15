import 'package:flutter/foundation.dart';

import 'constants.dart';

bool _consumed = false;

@visibleForTesting
void resetWebpayReturnRouteForTest() {
  _consumed = false;
}

/// Tras Webpay, Transbank vuelve a `?pago=ok&jobId=…` en el origen del cliente.
String? webpayReturnLocation({required bool isLoggedIn}) {
  if (!kIsWeb || _consumed || !isLoggedIn) return null;
  final pago = Uri.base.queryParameters['pago'];
  if (pago != 'ok' && pago != 'retorno') return null;
  _consumed = true;
  final jobId = Uri.base.queryParameters['jobId']?.trim() ?? '';
  if (jobId.isNotEmpty) return '${AppConstants.routeJobDetail}/$jobId';
  return AppConstants.routeJobHistory;
}
