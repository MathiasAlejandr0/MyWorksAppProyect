import 'package:flutter_test/flutter_test.dart';

/// Copia de la regla de éxito del WebView (sin montar platform views).
bool isApprovedReturn(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('tarjeta=fail')) return false;
  if (lower.contains('pago=fail') || lower.contains('ok=0')) return false;
  if (lower.contains('tarjeta=ok')) return true;
  if (lower.contains('pago=ok') || lower.contains('ok=1')) return true;
  return false;
}

void main() {
  test('pago=ok y ok=1 son éxito', () {
    expect(isApprovedReturn('myworksapp://pago?pago=ok'), isTrue);
    expect(isApprovedReturn('https://localhost:5173/?pago=ok&jobId=1'), isTrue);
    expect(isApprovedReturn('https://app/?ok=1'), isTrue);
  });

  test('pago=retorno solo no cuenta como aprobado', () {
    expect(isApprovedReturn('https://edge/pago?pago=retorno'), isFalse);
    expect(isApprovedReturn('myworksapp://pago'), isFalse);
  });

  test('pago=fail y tarjeta=fail son rechazo', () {
    expect(isApprovedReturn('https://x/?pago=fail'), isFalse);
    expect(isApprovedReturn('https://x/?tarjeta=fail'), isFalse);
  });
}
