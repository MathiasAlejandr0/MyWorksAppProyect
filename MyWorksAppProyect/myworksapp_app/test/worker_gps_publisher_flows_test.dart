// WorkerGpsPublisher con un GPS falso: servicio apagado, permiso denegado,
// posiciones publicadas (éxito y error del RPC), error del stream, pausa y
// reanudación de la app y desactivación del trabajo.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/worker_gps_publisher.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

class _Gps extends GeolocatorPlatform {
  _Gps({
    this.enabled = true,
    this.permission = LocationPermission.whileInUse,
    this.afterRequest = LocationPermission.whileInUse,
  });

  final bool enabled;
  LocationPermission permission;
  final LocationPermission afterRequest;
  final stream = StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async =>
      permission = afterRequest;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      stream.stream;
}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 11, 26),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Widget _host() {
  var active = true;
  return StatefulBuilder(
    builder: (ctx, set) => Column(
      children: [
        WorkerGpsPublisher(jobId: 'job-gps', active: active),
        TextButton(
          onPressed: () => set(() => active = !active),
          child: const Text('alternar'),
        ),
      ],
    ),
  );
}

void main() {
  late GeolocatorPlatform original;
  setUp(() => original = GeolocatorPlatform.instance);
  tearDown(() => GeolocatorPlatform.instance = original);

  testWidgets('GPS apagado', (t) async {
    GeolocatorPlatform.instance = _Gps(enabled: false);
    await smokeWidget(t, _host, interact: false, script: (t) => _pasos(t, 2));
  });

  for (final final_ in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    testWidgets('permiso $final_', (t) async {
      GeolocatorPlatform.instance = _Gps(
        permission: LocationPermission.denied,
        afterRequest: final_,
      );
      await smokeWidget(t, _host, interact: false, script: (t) => _pasos(t, 2));
    });
  }

  testWidgets('publica, falla, error del stream, pausa y desactiva', (t) async {
    final gps = _Gps(
      permission: LocationPermission.denied,
      afterRequest: LocationPermission.whileInUse,
    );
    GeolocatorPlatform.instance = gps;
    await smokeWidget(t, _host, interact: false, script: (t) async {
      await _pasos(t, 2);
      gps.stream.add(_pos(-41.47, -72.94));
      await _pasos(t, 2);
      FakeBackend.instance.failAll = true;
      gps.stream.add(_pos(-41.30, -72.80));
      await _pasos(t, 2);
      FakeBackend.instance.failAll = false;
      gps.stream.addError(Exception('sin señal'));
      await _pasos(t, 1);
      final binding = t.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _pasos(t, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _pasos(t, 2);
      await t.tap(find.text('alternar'));
      await _pasos(t, 2);
      gps.stream.add(_pos(-41.10, -72.60));
      await _pasos(t, 1);
      await t.tap(find.text('alternar'));
      await _pasos(t, 2);
    });
  });
}
