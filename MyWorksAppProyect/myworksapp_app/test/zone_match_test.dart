import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/zone_match.dart';

void main() {
  test('prioriza la misma comuna y no inventa distancia', () {
    expect(zoneMatchScore('Ñuñoa', 'Av. Irarrázaval 1234, Ñuñoa'), 1);
    expect(zoneMatchScore('Las Condes', 'Ñuñoa'), 0);
    expect(zoneMatchScore(' ', 'Ñuñoa'), 0);
    expect(zoneMatchScore('Maipú', null), 0);
  });
}
