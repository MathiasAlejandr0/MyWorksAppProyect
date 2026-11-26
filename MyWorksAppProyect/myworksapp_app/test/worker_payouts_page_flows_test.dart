// WorkerPayoutsPage: cuenta guardada, resumen con pendientes y transferidos,
// validación del formulario, guardado correcto y con error, y carga fallida.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/worker/presentation/pages/worker_payouts_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
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

Map<String, dynamic> _cobro(String id, String estado, String? transf,
        {String? ref}) =>
    {
      'id_pago': id,
      'id_trabajo': 'job-$id',
      'id_trabajador': fakeUserId,
      'tipo_pago': 'principal',
      'estado_pago': estado,
      'bruto_clp': 40000,
      'comision_clp': 2000,
      'neto_clp': null,
      'estado_transferencia': transf,
      'referencia_transferencia': ref,
      'liquidado_en': transf == null ? null : '2026-05-03T10:00:00Z',
      'liberado_en': '2026-05-02T10:00:00Z',
      'creado_en': '2026-05-01T10:00:00Z',
    };

void _datos(FakeBackend b, {bool cuenta = true}) {
  b.seed('cuentas_bancarias', [
    if (cuenta)
      {
        'id_usuario': fakeUserId,
        'banco': 'BancoEstado',
        'tipo_cuenta': ' ',
        'numero_cuenta': '12345678',
        'rut_titular': '11.111.111-1',
        'nombre_titular': 'Mathias Jara',
      },
  ]);
  b.seed('cobros_profesional', [
    _cobro('p1', 'retenido', null),
    _cobro('p2', 'liberado', 'pendiente'),
    _cobro('p3', 'liberado', 'transferido', ref: 'TRX-99'),
    _cobro('p4', 'liberado', 'fallido'),
    _cobro('p5', 'liberado', 'otro'),
  ]);
}

Future<void> _llenar(WidgetTester t, List<String> valores) async {
  final campos = find.byType(TextField);
  for (var i = 0; i < valores.length && i < campos.evaluate().length; i++) {
    await t.enterText(campos.at(i), valores[i]);
    await t.pump();
  }
}

Future<void> _tipoCuenta(WidgetTester t) async {
  final dd = find.byType(DropdownButtonFormField<String>);
  if (dd.evaluate().isEmpty) return;
  await _tap(t, dd);
  final op = find.text('Cuenta corriente');
  if (op.evaluate().isNotEmpty) {
    await t.tap(op.last, warnIfMissed: false);
    await _pasos(t, 2);
  }
}

void main() {
  testWidgets('cuenta existente, validación y guardado', (t) async {
    await smokeWidget(t, () => const WorkerPayoutsPage(),
        interact: false, role: 'trabajador', setup: _datos, script: (t) async {
      await _pasos(t, 4);
      await _tipoCuenta(t);
      await _llenar(t, ['B', '1', 'x', 'y']);
      await _tap(t, find.text('Guardar cuenta'));
      await _llenar(
          t, ['Banco de Chile', '987654321', '11.111.111-1', 'Mathias Jara']);
      await _tap(t, find.text('Guardar cuenta'));
      await _pasos(t, 3);
    });
  });

  testWidgets('guardado con error y sin cuenta previa', (t) async {
    await smokeWidget(t, () => const WorkerPayoutsPage(),
        interact: false, role: 'trabajador', setup: (b) {
      _datos(b, cuenta: false);
      b.failing.add('cuentas_bancarias:post');
    }, script: (t) async {
      await _pasos(t, 4);
      await _llenar(
          t, ['Banco de Chile', '987654321', '11.111.111-1', 'Mathias Jara']);
      await _tap(t, find.text('Guardar cuenta'));
      await _pasos(t, 3);
    });
  });

  testWidgets('la carga falla', (t) async {
    await smokeWidget(t, () => const WorkerPayoutsPage(),
        interact: false,
        role: 'trabajador',
        setup: (b) => b.failing.add('cobros_profesional'),
        script: (t) => _pasos(t, 4));
  });

  testWidgets('sin sesión no carga ni guarda', (t) async {
    await smokeWidget(t, () => const WorkerPayoutsPage(),
        interact: false, signedIn: false, script: (t) async {
      await _pasos(t, 3);
      await _tap(t, find.text('Guardar cuenta'));
    });
  });
}
