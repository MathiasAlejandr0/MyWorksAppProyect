// WorkerHomePage: disponibilidad (activar, desactivar, bloqueada por trabajo
// activo), pestañas con trabajos reales y vacíos, abrir un trabajo, accesos de
// la barra superior, reanudar la app y error de carga del panel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/worker/presentation/pages/worker_home_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
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

Future<void> _volver(WidgetTester t) async {
  for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
    while (st.canPop()) {
      st.pop();
      await _pasos(t, 1);
    }
  }
  await _pasos(t, 2);
}

Finder get _pastilla => find
    .byWidgetPredicate((w) => w.runtimeType.toString() == '_AvailabilityPill');

Map<String, dynamic> _trabajo(String id, String estado,
        {String? trabajador = fakeUserId}) =>
    {
      ...sampleJobModel,
      'id': id,
      'id_usuario': 'cliente-1',
      'id_trabajador': trabajador,
      'estado': estado,
      'descripcion': 'Trabajo $id',
      'invitados': [fakeUserId],
    };

void _ficha(FakeBackend b, {bool disponible = false}) {
  b.seed('trabajadores', [
    {
      'id': 'w1',
      'id_usuario': fakeUserId,
      'profesion': 'Gasfíter',
      'categoria_servicio': 'plomeria',
      'disponible': disponible ? 1 : 0,
      'calificacion': 4.6,
    },
  ]);
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 6);
  await _tap(t, find.text('Omitir'));
  await _tap(t, _pastilla);
  await _pasos(t, 3);
  await _tap(t, _pastilla);
  await _pasos(t, 3);
  for (final p in ['Pendientes', 'En curso', 'Finalizados']) {
    await _tap(t, find.textContaining(p));
    final card = find.textContaining('Trabajo j');
    if (await _tap(t, card)) await _volver(t);
    for (final a in [
      'Activar disponibilidad',
      'Ver calendario',
      'Ver estadísticas',
      'Reintentar',
    ]) {
      if (await _tap(t, find.text(a))) await _volver(t);
    }
  }
  for (final e in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    t.binding.handleAppLifecycleStateChanged(e);
  }
  await _pasos(t, 4);
  for (final icono in [
    Icons.notifications_outlined,
    Icons.notifications_none_rounded,
    Icons.settings_outlined,
    Icons.person_outline,
  ]) {
    if (await _tap(t, find.byIcon(icono))) await _volver(t);
  }
  final tops = find.byType(IconButton);
  for (var i = 0; i < tops.evaluate().length && i < 4; i++) {
    final f = find.byType(IconButton);
    if (f.evaluate().length <= i) break;
    await t.tap(f.at(i), warnIfMissed: false);
    await _pasos(t, 2);
    await _volver(t);
  }
}

void main() {
  // Regresión O1: sin desbordes ni aserciones de layout ya corregidos.
  tearDown(() => expect(smokeBugErrors(), isEmpty));

  testWidgets('sin trabajos activos: mercado abierto y disponibilidad',
      (t) async {
    await smokeWidget(t, () => const WorkerHomePage(),
        interact: false, role: 'trabajador', setup: (b) {
      _ficha(b);
      b.seed('trabajos', [
        _trabajo('j1', 'pendiente', trabajador: null),
        _trabajo('j2', 'esperando_cotizaciones', trabajador: null),
        _trabajo('j3', 'completado'),
      ]);
    }, script: _recorrido);
  });

  testWidgets('con trabajo activo: disponibilidad bloqueada', (t) async {
    await smokeWidget(t, () => const WorkerHomePage(),
        interact: false, role: 'trabajador', setup: (b) {
      _ficha(b, disponible: true);
      b.seed('trabajos', [
        _trabajo('j4', 'en_curso'),
        _trabajo('j5', 'aceptado'),
        _trabajo('j6', 'completado'),
      ]);
    }, script: _recorrido);
  });

  testWidgets('sin trabajos y fallas al cambiar disponibilidad', (t) async {
    await smokeWidget(t, () => const WorkerHomePage(),
        interact: false, role: 'trabajador', setup: (b) {
      _ficha(b, disponible: true);
      b.seed('trabajos', []);
      b.failing.add('trabajadores:patch');
    }, script: _recorrido);
  });

  testWidgets('error al cargar el panel', (t) async {
    await smokeWidget(t, () => const WorkerHomePage(),
        interact: false, role: 'trabajador', setup: (b) {
      b.failing.add('notificaciones');
    }, script: (t) async {
      await _pasos(t, 5);
      await _tap(t, find.text('Error al cargar. Toca para reintentar.'));
      await _pasos(t, 3);
    });
  });

  testWidgets('sin usuario', (t) async {
    await smokeWidget(t, () => const WorkerHomePage(),
        signedIn: false, interact: false, script: (t) => _pasos(t, 2));
  });
}
