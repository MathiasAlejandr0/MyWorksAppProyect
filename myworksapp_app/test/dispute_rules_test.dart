import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/dispute_rules.dart';

void main() {
  test('abierta y en revisión bloquean otra disputa y la calificación', () {
    expect(disputeIsOpen('abierta'), isTrue);
    expect(disputeIsOpen('en_revision'), isTrue);
    expect(disputeIsOpen('resuelta'), isFalse);
    expect(disputeIsOpen(null), isFalse);
  });
}
