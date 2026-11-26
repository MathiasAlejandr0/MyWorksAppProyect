// QuickBookingPage: validaciones, elección de fecha y hora, cobro en
// garantía (pagado y cancelado) y fallas al crear el pedido.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/pages/quick_booking_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _worker = '00000000-0000-4000-8000-00000000e001';
const _service = '00000000-0000-4000-8000-0000000005e1';
final _hora = RegExp(r'^\d{1,2}:\d{2}$');

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

void _setup(FakeBackend b, {Object? charge = const {'charged': true}}) {
  final base = DateTime.now().toUtc();
  b.rpc('horarios_libres_profesional', [
    for (var h = 0; h < 96; h += 1)
      {
        'inicio': DateTime.utc(base.year, base.month, base.day)
            .add(Duration(hours: h))
            .toIso8601String(),
      },
  ]);
  b.rpc('resumen_cobro_trabajo', [
    {
      'total_clp': 25000,
      'tarifa_clp': 20000,
      'traslado_clp': 5000,
      'comision_clp': 2500,
      'neto_clp': 22500,
    },
  ]);
  b.functions['oneclick-charge'] = (_) => charge;
}

Finder get _primeraHora => find.byWidgetPredicate(
      (w) => w is Text && w.data != null && _hora.hasMatch(w.data!.trim()),
    );

Future<void> _confirmar(WidgetTester t) => _tap(
    t,
    find.text('Continuar al pago').evaluate().isNotEmpty
        ? find.text('Continuar al pago')
        : find.byType(ElevatedButton).last);

Future<void> _campo(WidgetTester t, String label, String valor) async {
  final f = find.widgetWithText(TextField, label);
  if (f.evaluate().isEmpty) return;
  await t.enterText(f.first, valor);
  await t.pump();
}

Future<void> _validaciones(WidgetTester t) async {
  await _pasos(t, 4);
  await _campo(t, 'Dirección', 'abc');
  await _confirmar(t);
  await _campo(t, 'Dirección', 'Av. Diego Portales 860, Puerto Montt');
  await _campo(t, 'Notas (opcional)', 'Llámame al +56 9 8765 4321');
  await _confirmar(t);
  await _tap(t, find.text('Entendido'));
  await _tap(t, find.text('Aceptar'));
  await _campo(t, 'Notas (opcional)', '');
  await _confirmar(t);
  // Cambiar fecha con el selector.
  if (await _tap(t, find.text('Cambiar'))) {
    for (final ok in ['Aceptar', 'OK', 'Listo', 'Confirmar']) {
      if (await _tap(t, find.text(ok))) break;
    }
    await _tap(t, find.text('Cancelar'));
  }
}

Future<void> _pagar(WidgetTester t, {bool cancelar = false}) async {
  await _pasos(t, 4);
  await _tap(t, _primeraHora);
  await _confirmar(t);
  await _pasos(t, 4);
  if (cancelar) {
    await _tap(t, find.text('Cancelar'));
  } else {
    await _tap(t, find.textContaining('Pagar con tarjeta'));
  }
  await _pasos(t, 6);
}

void main() {
  // Regresión O5: sin desbordes ni aserciones de layout ya corregidos.
  tearDown(() => expect(smokeBugErrors(), isEmpty));

  testWidgets('QuickBookingPage validaciones y fecha', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      role: 'usuario',
      overrides: {'estado': 'esperando_pago', 'id_usuario': fakeUserId},
      setup: _setup,
      script: _validaciones,
    );
  });

  testWidgets('QuickBookingPage paga y agenda', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      role: 'usuario',
      overrides: {'estado': 'esperando_pago', 'id_usuario': fakeUserId},
      setup: _setup,
      script: _pagar,
    );
  });

  testWidgets('QuickBookingPage cancela el cobro', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      role: 'usuario',
      overrides: {'estado': 'esperando_pago', 'id_usuario': fakeUserId},
      setup: _setup,
      script: (t) => _pagar(t, cancelar: true),
    );
  });

  testWidgets('QuickBookingPage cobro rechazado y tarjeta no lista', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      role: 'usuario',
      overrides: {'estado': 'esperando_pago', 'id_usuario': fakeUserId},
      setup: (b) => _setup(b, charge: {'charged': false}),
      script: (t) async {
        await _pagar(t);
        await _tap(t, find.text('Cancelar'));
        await _pasos(t, 3);
      },
    );
  });

  testWidgets('QuickBookingPage falla al crear el pedido', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      role: 'usuario',
      setup: (b) {
        _setup(b);
        b.failing.add('trabajos:post');
      },
      script: _pagar,
    );
  });

  testWidgets('QuickBookingPage sin agenda ni profesional', (t) async {
    await smokeWidget(
      t,
      () => const QuickBookingPage(workerId: _worker, serviceId: _service),
      interact: false,
      seeded: false,
      role: 'usuario',
      setup: (b) {
        b.failing
            .addAll(['horarios_libres_profesional', 'trabajador_horarios']);
      },
      script: (t) => _pasos(t, 4),
    );
  });
}
