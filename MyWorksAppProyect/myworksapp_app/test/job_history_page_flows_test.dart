// JobHistoryPage: páginas que se cargan con scroll y con "Cargar más", error
// en la siguiente página, refresco, historial vacío, error inicial y sin sesión.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_history_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t);
}

void _trabajos(FakeBackend b, int n) {
  final base = Map<String, dynamic>.from(sampleJobModel);
  b.seed('trabajos', [
    for (var i = 0; i < n; i++)
      {
        ...base,
        'id': 'hist-$i',
        'id_usuario': fakeUserId,
        'id_trabajador': fakeUserId,
        'estado': i < 2 ? 'aceptado' : 'completado',
        'fecha_programada': null,
      },
  ]);
}

Future<void> _bajar(WidgetTester t) async {
  final lista = find.byType(Scrollable);
  if (lista.evaluate().isEmpty) return;
  await t.drag(lista.first, const Offset(0, -4000), warnIfMissed: false);
  await _pasos(t, 2);
}

void main() {
  for (final rol in ['usuario', 'trabajador']) {
    testWidgets('historial largo ($rol)', (t) async {
      await smokeWidget(t, () => const JobHistoryPage(),
          interact: false,
          role: rol,
          setup: (b) => _trabajos(b, 30),
          script: (t) async {
            await _pasos(t, 4);
            await _bajar(t);
            await _bajar(t);
            await _tap(t, find.text('Cargar más'));
            FakeBackend.instance.failing.add('trabajos');
            await _bajar(t);
            await _tap(t, find.text('Cargar más'));
            await _bajar(t);
            await _tap(t, find.text('No se pudieron cargar más. Reintentar'));
            FakeBackend.instance.failing.remove('trabajos');
            await _tap(t, find.text('No se pudieron cargar más. Reintentar'));
            final lista = find.byType(Scrollable);
            if (lista.evaluate().isNotEmpty) {
              await t.fling(lista.first, const Offset(0, 20000), 5000,
                  warnIfMissed: false);
              await t.pump();
              await t.fling(lista.first, const Offset(0, 600), 2000,
                  warnIfMissed: false);
              await _pasos(t, 5);
            }
          });
    });
  }

  testWidgets('historial vacío', (t) async {
    await smokeWidget(t, () => const JobHistoryPage(),
        interact: false,
        setup: (b) => b.seed('trabajos', []),
        script: (t) => _pasos(t, 4));
  });

  testWidgets('error inicial y reintento', (t) async {
    await smokeWidget(t, () => const JobHistoryPage(),
        interact: false,
        setup: (b) => b.failing.add('trabajos'),
        script: (t) async {
          await _pasos(t, 4);
          FakeBackend.instance.failing.remove('trabajos');
          await _tap(t, find.text('Reintentar'));
          await _pasos(t, 3);
        });
  });

  testWidgets('sin sesión', (t) async {
    await smokeWidget(t, () => const JobHistoryPage(),
        interact: false, signedIn: false, script: (t) => _pasos(t, 2));
  });
}
