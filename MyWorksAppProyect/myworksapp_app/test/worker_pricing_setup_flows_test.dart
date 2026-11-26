// WorkerPricingSetupPage con ficha real: tarifas guardadas (alta y edición),
// error al guardar, ficha sin tarifas (valores sugeridos) y tema oscuro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/worker/presentation/pages/worker_pricing_setup_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

void Function(FakeBackend) _ficha(
        {bool conTarifas = true, bool falla = false}) =>
    (b) {
      b.seed('trabajadores', [
        {
          ...sampleWorkerModel,
          'id_usuario': fakeUserId,
          'profesion': 'Maestro constructor',
          'categoria_servicio': 'construccion',
          'trabajador_precios': conTarifas
              ? [
                  {'codigo': 'visita', 'monto_clp': 15000},
                  {'codigo': 'm2', 'monto_clp': 22000},
                ]
              : <Map<String, dynamic>>[],
        },
      ]);
      if (falla) {
        b.failing.addAll([
          'trabajadores:patch',
          'trabajadores:post',
          'trabajador_precios',
          'trabajador_precios:post',
        ]);
      }
    };

Future<void> _guardar(WidgetTester t) async {
  await _pasos(t, 3);
  final boton = find.byType(FilledButton).last;
  await t.ensureVisible(boton);
  await t.pump();
  await t.tap(boton, warnIfMissed: false);
  await _pasos(t, 5);
}

void main() {
  for (final edit in [false, true]) {
    testWidgets('guarda tarifas (edición $edit)', (t) async {
      await smokeWidget(t, () => WorkerPricingSetupPage(editMode: edit),
          interact: false,
          role: 'trabajador',
          size: const Size(500, 2600),
          setup: _ficha(),
          script: _guardar);
    });
  }

  testWidgets('error al guardar y ficha sin tarifas', (t) async {
    await smokeWidget(t, () => const WorkerPricingSetupPage(),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 2600),
        setup: _ficha(conTarifas: false, falla: true),
        script: _guardar);
  });

  testWidgets('tema oscuro', (t) async {
    await smokeWidget(
        t,
        () => Theme(
              data: ThemeData.dark(),
              child: const WorkerPricingSetupPage(),
            ),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 2600),
        setup: _ficha(),
        script: (t) => _pasos(t, 3));
  });
}
