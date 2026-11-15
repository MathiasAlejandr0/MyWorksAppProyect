import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/support_config.dart';

void main() {
  test('sin --dart-define no se muestra ningún canal de soporte', () {
    expect(SupportConfig.hasEmail, isFalse);
    expect(SupportConfig.hasWhatsapp, isFalse);
  });

  test('el correo de soporte lleva asunto y cuerpo codificados', () {
    final uri = SupportConfig.emailUri(subject: 'No carga', body: 'a b\nc');
    expect(uri.scheme, 'mailto');
    expect(uri.query, contains('subject=No%20carga'));
    expect(uri.query, contains('body=a%20b%0Ac'));
  });
}
