import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/pages/worker_list_page.dart';

import 'support/catalog_seed.dart';
import 'support/widget_harness.dart';

Future<void> _step(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tapText(WidgetTester t, String s) async {
  final f = find.text(s);
  if (f.evaluate().isEmpty) return;
  await t.tap(f.first, warnIfMissed: false);
  await _step(t, 3);
}

Future<void> _script(WidgetTester t) async {
  await _step(t, 8);
  final buscar =
      find.widgetWithText(TextField, 'Buscar por nombre o profesión...');
  final campo = buscar.evaluate().isNotEmpty ? buscar : find.byType(TextField);
  if (campo.evaluate().isNotEmpty) {
    for (final q in ['gasf', 'Pro Número 2', 'zzz', '']) {
      await t.enterText(campo.first, q);
      await t.pump(const Duration(milliseconds: 600));
      await _step(t, 2);
    }
  }
  for (final orden in ['Precio', 'Calificación', 'Cercanía, nota y precio']) {
    final dd = find.byType(DropdownButton<String>);
    if (dd.evaluate().isEmpty) break;
    await t.tap(dd.first, warnIfMissed: false);
    await _step(t, 2);
    await _tapText(t, orden);
  }
  for (final nota in ['4.5+', 'Todas']) {
    final dd = find.byType(DropdownButton<double>);
    if (dd.evaluate().isEmpty) break;
    await t.tap(dd.first, warnIfMissed: false);
    await _step(t, 2);
    await _tapText(t, nota);
  }
  final sw = find.byType(Switch);
  if (sw.evaluate().isNotEmpty) {
    await t.tap(sw.first, warnIfMissed: false);
    await _step(t, 2);
    await t.tap(sw.first, warnIfMissed: false);
    await _step(t, 2);
  }
  await _tapText(t, 'Búsqueda Inteligente');
  await _step(t, 6);
  await _tapText(t, 'Lista Manual');
  await _step(t, 6);
  await _tapText(t, 'Pro Número 1');
  await _step(t, 4);
}

void main() {
  for (final caso in ['general', 'servicio', 'matching', 'ocupados']) {
    testWidgets('WorkerListPage con catálogo ($caso)', (t) async {
      await smokeWidget(
        t,
        () => WorkerListPage(
          serviceId: caso == 'general' ? null : catalogServiceId,
          jobId: caso == 'matching' ? catalogJobId : null,
        ),
        interact: caso != 'ocupados',
        size: const Size(480, 3200),
        setup: (b) => seedCatalog(
          b,
          ocupados: caso == 'ocupados' ? {catalogProId(1)} : const {},
        ),
        script: _script,
      );
    });
  }
}
