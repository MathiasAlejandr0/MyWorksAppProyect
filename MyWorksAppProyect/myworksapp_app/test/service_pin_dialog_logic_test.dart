import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/service_pin.dart';

void main() {
  group('verifyServicePin', () {
    test('acepta coincidencia exacta', () {
      expect(verifyServicePin('4829', '4829'), isTrue);
    });

    test('rechaza expected vacío (sin backdoor)', () {
      expect(verifyServicePin('1234', ''), isFalse);
      expect(verifyServicePin('0000', '   '), isFalse);
    });

    test('no hay backdoors 1234/0000', () {
      expect(verifyServicePin('1234', '9999'), isFalse);
      expect(verifyServicePin('0000', '9999'), isFalse);
    });

    test('rechaza PIN distinto', () {
      expect(verifyServicePin('1111', '2222'), isFalse);
    });
  });
}
