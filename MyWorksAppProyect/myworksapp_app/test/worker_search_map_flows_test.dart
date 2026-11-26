// WorkerSearchMap: tocar pines, arrastrar el pin del cliente, mapa compacto
// con leyenda, sin profesionales ni cliente (centro por defecto), cobertura
// sin ubicación del cliente y buscar dirección con Enter.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_search_map.dart';

import 'support/model_samples.dart';
import 'support/widget_harness.dart';

WorkerModel _pro(int i) => WorkerModel.fromMap({
      ...sampleWorkerModel,
      'id_usuario': 'pro-mapa-$i',
      'latitud_base': -41.47 + i * 0.01,
      'longitud_base': -72.94 + i * 0.01,
      'radio_servicio_km': 10,
    });

Finder _tipo(String n) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == n);

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  final eventos = <String>[];

  Widget mapa({
    double alto = 520,
    List<WorkerModel>? pros,
    double? lat = -41.46,
    double? lng = -72.93,
    String? seleccionado,
  }) {
    final ctrl = TextEditingController(text: 'Av. Angelmó 2456');
    return Center(
      child: SizedBox(
        width: 400,
        height: alto,
        child: StatefulBuilder(
          builder: (ctx, set) => WorkerSearchMap(
            workers: pros ?? [_pro(0), _pro(1), _pro(2)],
            users: const {},
            selectedWorkerId: seleccionado,
            clientLatitude: lat,
            clientLongitude: lng,
            categoryLabel: 'Gasfitería',
            onSelectWorker: (w) => set(() {
              seleccionado = w.userId;
              eventos.add('sel:${w.userId}');
            }),
            onPickClientLocation: (a, b) => eventos.add('pick'),
            onOpenWorker: (w) => eventos.add('open'),
            addressController: ctrl,
            onSearchAddress: () => eventos.add('buscar'),
            onUseGps: () => eventos.add('gps'),
          ),
        ),
      ),
    );
  }

  testWidgets('pines, arrastre del cliente y búsqueda con Enter', (t) async {
    eventos.clear();
    await smokeWidget(t, () => mapa(), interact: false, script: (t) async {
      await _pasos(t, 4);
      final pines = _tipo('_MapPin');
      for (var i = 0; i < pines.evaluate().length && i < 3; i++) {
        await t.tap(pines.at(i), warnIfMissed: false);
        await _pasos(t, 2);
      }
      // El último pin es el del cliente: arrastrarlo.
      if (pines.evaluate().isNotEmpty) {
        final g = await t.startGesture(t.getCenter(pines.last));
        await g.moveBy(const Offset(20, 10));
        await t.pump(const Duration(milliseconds: 50));
        await g.moveBy(const Offset(25, 15));
        await t.pump(const Duration(milliseconds: 50));
        await g.up();
        await _pasos(t, 2);
      }
      final campo = find.byType(TextField);
      if (campo.evaluate().isNotEmpty) {
        await t.showKeyboard(campo.first);
        await t.testTextInput.receiveAction(TextInputAction.search);
        await _pasos(t, 2);
      }
      await _pasos(t, 3);
    });
  });

  testWidgets('mapa compacto con leyenda', (t) async {
    await smokeWidget(t, () => mapa(alto: 200, seleccionado: 'pro-mapa-0'),
        interact: false, script: (t) => _pasos(t, 5));
  });

  testWidgets('sin profesionales ni cliente usa el centro por defecto',
      (t) async {
    await smokeWidget(t, () => mapa(pros: const [], lat: null, lng: null),
        interact: false, script: (t) => _pasos(t, 6));
  });

  testWidgets('seleccionado sin ubicación del cliente', (t) async {
    await smokeWidget(
        t, () => mapa(lat: null, lng: null, seleccionado: 'pro-mapa-1'),
        interact: false, script: (t) => _pasos(t, 5));
  });
}
