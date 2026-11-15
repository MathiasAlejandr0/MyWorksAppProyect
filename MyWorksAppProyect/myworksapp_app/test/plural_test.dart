import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/plural.dart';

void main() {
  test('singular solo con 1', () {
    expect(plural(1, 'nota'), '1 nota');
    expect(plural(0, 'nota'), '0 notas');
    expect(plural(3, 'disputa abierta', 'disputas abiertas'),
        '3 disputas abiertas');
    expect(plural(1, 'reseña'), '1 reseña');
  });
}
