// NotificationsPage: carpetas por trabajo, abrir avisos (chat, trabajo y
// otros), marcar como leídas, errores de carga y etiquetas de respaldo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/notifications/presentation/pages/notifications_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _job = 'aaaaaaaa-0000-4000-8000-000000000001';
const _job2 = 'aaaaaaaa-0000-4000-8000-000000000002';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

List<Map<String, dynamic>> _avisos() {
  final now = DateTime.now();
  var i = 0;
  Map<String, dynamic> n(String tipo, String? rel, int minutos, int leido) {
    i++;
    return {
      'id': 'n$i',
      'id_usuario': fakeUserId,
      'tipo': tipo,
      'titulo': 'Aviso $i',
      'cuerpo': 'Detalle del aviso $i',
      'id_relacionado': rel,
      'leido': leido,
      'creado_en':
          now.subtract(Duration(minutes: minutos)).toUtc().toIso8601String(),
    };
  }

  return [
    n('job_accepted', _job, 1, 0),
    n('new_message', _job, 90, 0),
    n('quote_received', _job, 60 * 30, 1),
    n('dispute_opened', _job2, 60 * 24 * 3, 0),
    n('pago_reembolsado', _job2, 60 * 24 * 40, 1),
    n('sistema', null, 60 * 24 * 400, 0),
    n('promo', 'otro', 5, 1),
  ];
}

void _seed(FakeBackend b) {
  b.seed('notificaciones', _avisos());
  b.seed('trabajos', [
    {
      'id': _job,
      'descripcion': 'Cambiar llave de paso',
      'direccion': 'Av. Siempre Viva 742',
      'servicios': {'nombre': 'Gasfitería'},
    },
    {'id': _job2, 'descripcion': null, 'direccion': null, 'servicios': null},
  ]);
}

Future<void> _recorrer(WidgetTester t) async {
  await _pasos(t, 4);
  final cartas = find.byType(Card).evaluate().length;
  for (var c = 0; c < cartas; c++) {
    final carta = find.byType(Card);
    if (carta.evaluate().length <= c) break;
    await t.ensureVisible(carta.at(c));
    await t.tap(carta.at(c), warnIfMissed: false);
    await _pasos(t, 3);
    for (var i = 1; i <= 7; i++) {
      final f = find.text('Aviso $i');
      if (f.evaluate().isEmpty) continue;
      await t.tap(f.first, warnIfMissed: false);
      await _pasos(t, 2);
      final nav = find.byType(Navigator).evaluate();
      if (find.text('Aviso $i').evaluate().isEmpty && nav.isNotEmpty) {
        final st = t.state<NavigatorState>(find.byType(Navigator).last);
        if (st.canPop()) st.pop();
        await _pasos(t, 2);
      }
    }
    final ver = find.text('Ver trabajo');
    if (ver.evaluate().isNotEmpty) {
      await t.tap(ver.first, warnIfMissed: false);
      await _pasos(t, 2);
    }
    for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
      while (st.canPop()) {
        st.pop();
        await _pasos(t, 1);
      }
    }
    await _pasos(t, 3);
  }
  final todas = find.text('Marcar todas como leídas');
  if (todas.evaluate().isNotEmpty) {
    await t.tap(todas.first, warnIfMissed: false);
    await _pasos(t, 3);
  }
  final lista = find.byType(RefreshIndicator);
  if (lista.evaluate().isNotEmpty) {
    await t.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await _pasos(t, 4);
  }
}

void main() {
  testWidgets('NotificationsPage recorre carpetas y avisos', (t) async {
    await smokeWidget(
      t,
      () => const NotificationsPage(),
      interact: false,
      role: 'usuario',
      setup: _seed,
      script: _recorrer,
    );
  });

  testWidgets('NotificationsPage con etiquetas de respaldo', (t) async {
    await smokeWidget(
      t,
      () => const NotificationsPage(),
      interact: false,
      role: 'trabajador',
      setup: (b) {
        _seed(b);
        b.failing.add('trabajos');
      },
      script: _recorrer,
    );
  });

  testWidgets('NotificationsPage error de carga y reintento', (t) async {
    await smokeWidget(
      t,
      () => const NotificationsPage(),
      interact: false,
      setup: (b) => b.failing.add('notificaciones'),
      script: (t) async {
        await _pasos(t, 4);
        final r = find.text('Reintentar');
        if (r.evaluate().isNotEmpty) {
          await t.tap(r.first, warnIfMissed: false);
          await _pasos(t, 3);
        }
      },
    );
  });

  testWidgets('NotificationsPage sin sesión', (t) async {
    await smokeWidget(
      t,
      () => const NotificationsPage(),
      signedIn: false,
      interact: false,
      script: (t) => _pasos(t, 4),
    );
  });
}
