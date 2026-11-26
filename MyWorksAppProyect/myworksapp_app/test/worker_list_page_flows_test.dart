// WorkerListPage: búsqueda inteligente con el trabajo del cliente, mapa
// (elegir profesional, marcar punto, buscar dirección, GPS), cambio manual de
// ciudad y mapa ampliado. Los callbacks del mapa se invocan directo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/pages/worker_list_page.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_search_map.dart';

import 'support/catalog_seed.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t, 3);
  return true;
}

Future<void> _mapa(WidgetTester t) async {
  final m = find.byType(WorkerSearchMap);
  if (m.evaluate().isEmpty) return;
  final w = t.widget<WorkerSearchMap>(m.first);
  if (w.workers.isNotEmpty) {
    w.onSelectWorker(w.workers.last);
    await _pasos(t, 2);
    w.onOpenWorker?.call(w.workers.first);
    await _pasos(t, 2);
    for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
      while (st.canPop()) {
        st.pop();
        await _pasos(t, 1);
      }
    }
  }
  w.onPickClientLocation?.call(-41.4717, -72.9369);
  await _pasos(t, 3);
  w.onPickClientLocation?.call(-33.4489, -70.6693);
  await _pasos(t, 4);
  w.addressController?.text = 'ab';
  w.onSearchAddress?.call();
  await _pasos(t, 2);
  w.addressController?.text = 'Av. Diego Portales 860, Puerto Montt';
  w.onSearchAddress?.call();
  await _pasos(t, 4);
  w.onUseGps?.call();
  await _pasos(t, 4);
}

Future<void> _ciudad(WidgetTester t) async {
  for (final abrir in ['Cambiar ciudad', 'Cambiar']) {
    if (await _tap(t, find.text(abrir))) break;
  }
  if (find.text('Selecciona tu ciudad').evaluate().isEmpty) return;
  await _tap(t, find.text('Cancelar'));
  for (final abrir in ['Cambiar ciudad', 'Cambiar']) {
    if (await _tap(t, find.text(abrir))) break;
  }
  final dd = find.byType(DropdownButtonFormField<String>);
  if (dd.evaluate().isNotEmpty) {
    await _tap(t, dd.last);
    await _tap(t, find.text('Osorno').last);
  }
  await _tap(t, find.text('Usar esta ciudad'));
  await _pasos(t, 4);
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 8);
  await _tap(t, find.text('Búsqueda Inteligente'));
  await _pasos(t, 6);
  await _mapa(t);
  await _tap(t, find.text('Lista Manual'));
  await _pasos(t, 4);
  await _mapa(t);
  await _ciudad(t);
  await _tap(t, find.byTooltip('Ampliar mapa'));
  await _mapa(t);
  await _tap(t, find.byTooltip('Ver lista'));
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isNotEmpty) {
    await t.fling(scroll.first, const Offset(0, 500), 1200);
    await _pasos(t, 4);
  }
}

void main() {
  testWidgets('búsqueda inteligente y mapa con trabajo', (t) async {
    await smokeWidget(
      t,
      () => const WorkerListPage(
          serviceId: catalogServiceId, jobId: catalogJobId),
      interact: false,
      role: 'usuario',
      size: const Size(480, 1400),
      setup: (b) => seedCatalog(b, n: 4),
      script: _recorrido,
    );
  });

  testWidgets('sin servicio y sin profesionales', (t) async {
    await smokeWidget(
      t,
      () => const WorkerListPage(),
      interact: false,
      role: 'usuario',
      size: const Size(480, 1400),
      setup: (b) {
        seedCatalog(b, n: 0);
        b.seed('trabajadores', []);
      },
      script: _recorrido,
    );
  });

  testWidgets('servicio inexistente y matching que falla', (t) async {
    await smokeWidget(
      t,
      () => const WorkerListPage(serviceId: 'no-existe', jobId: 'no-existe'),
      interact: false,
      role: 'usuario',
      size: const Size(480, 1400),
      setup: (b) {
        seedCatalog(b, n: 2);
        b.seed('servicios', []);
      },
      script: _recorrido,
    );
  });
}
