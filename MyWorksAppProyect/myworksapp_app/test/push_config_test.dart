import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/config/push_config.dart';

void main() {
  test('sin los dart-define FCM_* el push queda apagado', () {
    expect(PushConfig.isConfigured, isFalse);
    expect(PushConfig.isEnabled, isFalse);
  });
}
