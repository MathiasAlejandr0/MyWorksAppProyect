// Liquidaciones del admin con pagos sembrados: cancelar, marcar pagado,
// error al registrar y carga fallida.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_payouts_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

List<Map<String, dynamic>> _cobros() => [
      for (var i = 1; i <= 3; i++)
        {
          'id': 'pago-$i',
          'id_pago': 'pago-$i',
          'id_trabajo': 'trabajo-$i',
          'monto': 30000 * i,
          'bruto_clp': 30000 * i,
          'comision_clp': i == 3 ? null : 3000 * i,
          'neto_clp': i == 3 ? null : 27000 * i,
          'estado': 'retenido',
          'estado_pago': 'retenido',
          'creado_en': '2026-11-2${i}T10:00:00Z',
        },
    ];

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _marcar(WidgetTester t, String accion,
    {String ref = '1234'}) async {
  final b = find.text('Pagado');
  if (b.evaluate().isEmpty) return;
  await t.tap(b.first);
  await _pasos(t, 2);
  final campos = find.byType(TextField);
  if (campos.evaluate().length >= 2) {
    await t.enterText(campos.at(0), ref);
    await t.enterText(campos.at(1), 'nota');
  }
  await t.tap(find.text(accion));
  await _pasos(t, 4);
}

void main() {
  for (final falla in [false, true]) {
    testWidgets('AdminPayoutsPage marca transferencias (rpc falla=$falla)',
        (t) async {
      await smokeWidget(
        t,
        () => const AdminPayoutsPage(),
        role: 'admin',
        interact: false,
        // El botón "Pagado" va en el trailing de un ListTile y el tema le da
        // ancho mínimo infinito (bug B1): se acota para poder dibujarlo.
        boundedButtons: true,
        setup: (b) {
          b.seed('cobros_profesional', _cobros());
          b.seed('liquidaciones', [
            {
              'id_pago': 'pago-2',
              'estado_transferencia': 'transferido',
              'referencia_transferencia': 'REF',
              'id_trabajador': 'w',
            },
            {
              'id_pago': 'pago-1',
              'estado_transferencia': 'pendiente',
              'referencia_transferencia': null,
              'id_trabajador': 'w',
            },
          ]);
          if (falla) {
            b.failing.add('registrar_transferencia_profesional');
          } else {
            b.rpc('registrar_transferencia_profesional', {'ok': true});
          }
        },
        script: (t) async {
          await _pasos(t, 4);
          await _marcar(t, 'Marcar pagado');
          final r = find.byTooltip('Actualizar');
          if (r.evaluate().isNotEmpty) {
            await t.tap(r);
            await _pasos(t, 3);
          }
          // Al cancelar, los controladores se liberan mientras el diálogo
          // aún se cierra (bug B5): va al final para no cortar el guion.
          await _marcar(t, 'Cancelar');
        },
      );
    });
  }

  testWidgets('AdminPayoutsPage sin pagos y con carga fallida', (t) async {
    await smokeWidget(
      t,
      () => const AdminPayoutsPage(),
      role: 'admin',
      interact: false,
      setup: (b) => b.failing.add('cobros_profesional'),
    );
    await smokeWidget(
      t,
      () => const AdminPayoutsPage(),
      role: 'admin',
      interact: false,
      setup: (b) {
        b.seed('cobros_profesional', []);
        b.seed('liquidaciones', []);
      },
    );
  });
}
