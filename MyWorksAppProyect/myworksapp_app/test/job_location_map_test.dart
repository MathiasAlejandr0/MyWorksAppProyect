import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/job_location_map.dart';

void main() {
  test('un punto en Puerto Montt sirve para el mapa', () {
    expect(JobLocationMap.hasUsablePoint(-41.4717, -72.9366), isTrue);
  });

  test('0,0 o nulos no pintan un mapa falso', () {
    expect(JobLocationMap.hasUsablePoint(null, null), isFalse);
    expect(JobLocationMap.hasUsablePoint(0, 0), isFalse);
    expect(JobLocationMap.hasUsablePoint(double.nan, -72.9), isFalse);
  });
}
