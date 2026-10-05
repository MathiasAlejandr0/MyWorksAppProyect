import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myworksapp/core/services/user_location_service.dart';
import 'package:myworksapp/core/widgets/location_picker_widget.dart';

/// GPS falso: getCurrentPosition puede quedar colgado (como el emulador trabado).
class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({this.current, this.lastKnown, this.lastKnownHangs = false});

  final Future<Position> Function()? current;
  final Position? lastKnown;
  final bool lastKnownHangs;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      current?.call() ?? Completer<Position>().future;

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) {
    if (lastKnownHangs) return Completer<Position?>().future;
    return Future.value(lastKnown);
  }
}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 10, 5),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late GeolocatorPlatform original;
  setUp(() => original = GeolocatorPlatform.instance);
  tearDown(() => GeolocatorPlatform.instance = original);

  group('UserLocationService.currentPosition', () {
    test('GPS colgado: usa la última posición conocida sin esperar más', () async {
      GeolocatorPlatform.instance =
          _FakeGeolocator(lastKnown: _pos(-41.47, -72.93));
      final sw = Stopwatch()..start();
      final p = await UserLocationService.instance
          .currentPosition(timeout: const Duration(milliseconds: 50));
      expect(p?.latitude, -41.47);
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('GPS con error: usa la última posición conocida', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(
        current: () => Future.error(const LocationServiceDisabledException()),
        lastKnown: _pos(-41.4, -72.9),
      );
      final p = await UserLocationService.instance
          .currentPosition(timeout: const Duration(milliseconds: 50));
      expect(p?.longitude, -72.9);
    });

    test('todo colgado: devuelve null en pocos segundos, nunca lanza', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(lastKnownHangs: true);
      final p = await UserLocationService.instance
          .currentPosition(timeout: const Duration(milliseconds: 50));
      expect(p, isNull);
    });

    test('GPS ok: devuelve la posición actual', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(
        current: () async => _pos(-41.4717, -72.9366),
        lastKnown: _pos(0, 0),
      );
      final p = await UserLocationService.instance.currentPosition();
      expect(p?.latitude, -41.4717);
    });
  });

  testWidgets(
      'Solicitar servicio: con el GPS colgado no se queda en "Obteniendo..." '
      'y usa Puerto Montt', (tester) async {
    GeolocatorPlatform.instance = _FakeGeolocator();
    String? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPickerWidget(
            onLocationSelected: (address, lat, lng) => emitted = address,
          ),
        ),
      ),
    );
    expect(find.text('Obteniendo tu ubicación GPS...'), findsOneWidget);

    await tester.pump(UserLocationService.gpsTimeout + const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Obteniendo tu ubicación GPS...'), findsNothing);
    expect(find.text(UserLocationService.demoFallbackLabel), findsOneWidget);
    expect(emitted, UserLocationService.demoFallbackLabel);
  });
}
