import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/distance_match.dart';
import 'package:myworksapp/core/services/gps_publish_gate.dart';

void main() {
  test('haversine aproxima Santiago–Valparaíso', () {
    final km = haversineKm(-33.4489, -70.6693, -33.0472, -71.6127);
    expect(km, greaterThan(90));
    expect(km, lessThan(120));
  });

  test('excluye al profesional fuera de su radio y puntúa dentro', () {
    final far = matchByDistance(
      workerLat: -33.45,
      workerLng: -70.66,
      jobLat: -33.05,
      jobLng: -71.61,
      radiusKm: 15,
    );
    expect(far?.outsideRadius, isTrue);

    final near = matchByDistance(
      workerLat: -33.4500,
      workerLng: -70.6600,
      jobLat: -33.4520,
      jobLng: -70.6620,
      radiusKm: 15,
    );
    expect(near?.outsideRadius, isFalse);
    expect(near!.score, greaterThan(0.5));
    expect(matchByDistance(workerLat: null, workerLng: null, jobLat: 0, jobLng: 0), isNull);
  });

  test('el GPS se publica solo en camino o en curso y se espacia', () {
    expect(publishesLiveGps('en_camino'), isTrue);
    expect(publishesLiveGps('en_curso'), isTrue);
    expect(publishesLiveGps('aceptado'), isFalse);

    final gate = GpsPublishGate(minInterval: const Duration(seconds: 20), minMeters: 40);
    final t0 = DateTime.utc(2026, 9, 30, 12);
    expect(gate.shouldPublish(now: t0, latitude: -33.45, longitude: -70.66), isTrue);
    expect(
      gate.shouldPublish(now: t0.add(const Duration(seconds: 5)), latitude: -33.45, longitude: -70.66),
      isFalse,
    );
    expect(
      gate.shouldPublish(now: t0.add(const Duration(seconds: 21)), latitude: -33.45, longitude: -70.66),
      isTrue,
    );
  });

  test('la llegada estimada es un entero en minutos', () {
    expect(estimateEtaMinutes(28), 60);
    expect(estimateEtaMinutes(0.01), 1);
    expect(estimateEtaMinutes(double.nan), isNull);
  });
}
