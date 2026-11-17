/// La vuelta de Transbank, ya sea el esquema de la app o un https con la query.
bool isWebpayReturnUrl(String url) {
  final lower = url.toLowerCase();
  return lower.startsWith('myworksapp://pago') ||
      lower.contains('pago=ok') ||
      lower.contains('pago=fail') ||
      lower.contains('pago=retorno') ||
      lower.contains('tarjeta=ok') ||
      lower.contains('tarjeta=fail') ||
      lower.contains('/pago/retorno');
}

/// Solo señales explícitas de éxito. `pago=retorno` solo no cuenta.
bool isApprovedWebpayReturn(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('tarjeta=fail')) return false;
  if (lower.contains('pago=fail') || lower.contains('ok=0')) return false;
  if (lower.contains('tarjeta=ok')) return true;
  if (lower.contains('pago=ok') || lower.contains('ok=1')) return true;
  return false;
}
