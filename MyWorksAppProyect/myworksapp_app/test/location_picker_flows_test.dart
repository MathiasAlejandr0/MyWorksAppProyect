// LocationPickerWidget con GPS y geocodificación falsos: servicio apagado,
// permisos (denegado, denegado para siempre, concedido tras pedirlo), error
// del plugin, punto fuera de Chile, dirección con lugar/parcial/vacía/error,
// edición manual de la dirección y selección en el mapa.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myworksapp/core/widgets/location_picker_widget.dart';

import 'support/fake_geocoding.dart';
import 'support/widget_harness.dart';

class _Gps extends GeolocatorPlatform {
  _Gps({
    this.enabled = true,
    this.permission = LocationPermission.whileInUse,
    this.afterRequest = LocationPermission.whileInUse,
    this.position,
    this.throwsOnCheck = false,
  });

  final bool enabled;
  final LocationPermission permission;
  final LocationPermission afterRequest;
  final Position? position;
  final bool throwsOnCheck;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async {
    if (throwsOnCheck) throw Exception('plugin caído');
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async => afterRequest;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    final p = position;
    if (p == null) return Future.error(Exception('sin fix'));
    return Future.value(p);
  }

  @override
  Future<Position?> getLastKnownPosition(
          {bool forceLocationManager = false}) async =>
      null;
}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 11, 26),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

final _puertoMontt = _pos(-41.4693, -72.9424);

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 250));
  }
}

Widget _host() => SingleChildScrollView(
      child: LocationPickerWidget(onLocationSelected: (_, __, ___) {}),
    );

Future<void> _montar(WidgetTester t, GeolocatorPlatform gps, GeoModo modo,
    [Future<void> Function(WidgetTester t)? extra]) async {
  final original = GeolocatorPlatform.instance;
  GeolocatorPlatform.instance = gps;
  geoModo = modo;
  try {
    await smokeWidget(t, _host,
        signedIn: false,
        interact: false,
        size: const Size(500, 1000), script: (t) async {
      await _pasos(t, 4);
      await extra?.call(t);
      await t.pump(const Duration(seconds: 8));
    });
    // Regresión B1, B2 y B10: con el tema real ("Usar este punto" se dibuja)
    // y sin usar el controlador del editor después de liberarlo.
    expect(lastSmokeErrors, isEmpty);
  } finally {
    GeolocatorPlatform.instance = original;
    geoModo = GeoModo.lugar;
  }
}

void main() {
  testWidgets(
      'GPS apagado', (t) => _montar(t, _Gps(enabled: false), GeoModo.lugar));

  testWidgets(
      'permiso denegado tras pedirlo',
      (t) => _montar(
          t,
          _Gps(
            permission: LocationPermission.denied,
            afterRequest: LocationPermission.denied,
          ),
          GeoModo.lugar));

  testWidgets(
      'permiso denegado para siempre',
      (t) => _montar(t, _Gps(permission: LocationPermission.deniedForever),
          GeoModo.lugar));

  testWidgets('plugin lanza error',
      (t) => _montar(t, _Gps(throwsOnCheck: true), GeoModo.lugar));

  testWidgets('sin posición', (t) => _montar(t, _Gps(), GeoModo.lugar));

  testWidgets('fuera de Chile',
      (t) => _montar(t, _Gps(position: _pos(40.4, -3.7)), GeoModo.lugar));

  for (final modo in GeoModo.values) {
    testWidgets(
        'en Puerto Montt con geocodificación $modo',
        (t) => _montar(
            t,
            _Gps(
              permission: LocationPermission.denied,
              afterRequest: LocationPermission.whileInUse,
              position: _puertoMontt,
            ),
            modo));
  }

  Future<void> abrirEditor(WidgetTester t) async {
    await t.tap(find.byTooltip('Editar dirección'));
    await t.pumpAndSettle();
  }

  testWidgets('editar dirección: cancelar', (t) async {
    await _montar(t, _Gps(position: _puertoMontt), GeoModo.lugar, (t) async {
      await abrirEditor(t);
      await t.tap(find.text('Cancelar'));
      await _pasos(t, 2);
    });
  });

  testWidgets('editar dirección: enviar con Enter', (t) async {
    await _montar(t, _Gps(position: _puertoMontt), GeoModo.lugar, (t) async {
      await abrirEditor(t);
      await t.enterText(
          find.byType(TextField).last, 'Urmeneta 500, Puerto Montt');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await _pasos(t, 3);
    });
  });

  testWidgets('editar dirección sin geocodificación', (t) async {
    await _montar(t, _Gps(position: _puertoMontt), GeoModo.lugar, (t) async {
      geoModo = GeoModo.error;
      await abrirEditor(t);
      await t.enterText(find.byType(TextField).last, 'Calle sin mapa 1');
      await t.tap(find.text('Usar dirección'));
      await _pasos(t, 3);
    });
  });

  testWidgets('actualizar ubicación', (t) async {
    await _montar(t, _Gps(position: _puertoMontt), GeoModo.lugar, (t) async {
      await t.tap(find.byTooltip('Actualizar ubicación'));
      await _pasos(t, 3);
    });
  });

  testWidgets('marcar en el mapa: arrastrar, tocar, cancelar y usar punto',
      (t) async {
    await _montar(t, _Gps(position: _puertoMontt), GeoModo.lugar, (t) async {
      await t.tap(find.byTooltip('Marcar en el mapa'));
      await _pasos(t, 2);
      await t.tap(find.text('Cancelar'));
      await _pasos(t, 2);
      await t.tap(find.byTooltip('Marcar en el mapa'));
      await _pasos(t, 2);
      final pin = find.byIcon(Icons.location_on);
      if (pin.evaluate().isNotEmpty) {
        final g = await t.startGesture(t.getCenter(pin.last));
        await g.moveBy(const Offset(30, 10));
        await t.pump();
        await g.moveBy(const Offset(20, 20));
        await t.pump();
        await g.up();
        await t.pump();
        final g2 = await t.startGesture(t.getCenter(pin.last));
        await g2.moveBy(const Offset(25, 0));
        await g2.cancel();
        await t.pump();
      }
      await t.tapAt(const Offset(250, 300));
      await _pasos(t, 1);
      await t.tap(find.text('Usar este punto'));
      await _pasos(t, 3);
    });
  });
}
