import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_error.dart';

/// Abre el handoff de Transbank.
///
/// En web navega la misma pestaña (`_self` → `location.assign`) para no
/// perder el checkout por un popup bloqueado después de llamar a Edge.
Future<void> openTransbankCheckout(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') {
    throw AppError.validation('URL de pago inválida');
  }
  if (kIsWeb) {
    final opened = await launchUrl(
      uri,
      webOnlyWindowName: '_self',
    );
    if (!opened) {
      throw AppError.network('No se pudo abrir Transbank');
    }
    return;
  }
  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!opened) {
    throw AppError.network('No se pudo abrir Transbank');
  }
}
