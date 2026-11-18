import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/clp_format.dart';

void main() {
  test('pesos chilenos con el símbolo adelante y punto de miles', () {
    expect(formatClp(121600), r'$121.600');
    expect(formatClp(32000), r'$32.000');
    expect(formatClp(1000), r'$1.000');
    expect(formatClp(999), r'$999');
    expect(formatClp(0), r'$0');
    expect(formatClp(1234567), r'$1.234.567');
    expect(formatClp(-6400), r'-$6.400');
    expect(formatClp(1600.4), r'$1.600');
  });
}
