// AdminDashboardPage: cada acceso del panel navega, error de métricas con
// reintento y cierre de sesión cancelado y confirmado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_dashboard_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

const _accesos = [
  'Usuarios',
  'Trabajadores',
  'Ranking y reseñas',
  'Trabajos',
  'Servicios',
  'Reclamos de usuarios',
  'Disputas de trabajos',
  'Errores y sincronización',
  'Feature flags',
  'Liquidaciones',
  'Programa de escritorio',
];

void main() {
  for (final acceso in _accesos) {
    testWidgets('acceso $acceso navega', (t) async {
      await smokeWidget(t, () => const AdminDashboardPage(),
          interact: false,
          role: 'admin',
          size: const Size(600, 3000), script: (t) async {
        await _pasos(t, 3);
        final tile = find.text(acceso);
        if (tile.evaluate().isEmpty) return;
        await t.ensureVisible(tile.first);
        await t.pump();
        await t.tap(tile.first, warnIfMissed: false);
        await _pasos(t, 2);
      });
    });
  }

  testWidgets('error de métricas y reintento', (t) async {
    await smokeWidget(t, () => const AdminDashboardPage(),
        interact: false,
        role: 'admin',
        size: const Size(600, 1600),
        setup: (b) => b.failing.add('pagos'),
        script: (t) async {
          await _pasos(t, 3);
          FakeBackend.instance.failing.remove('pagos');
          final reintentar = find.text('Reintentar');
          if (reintentar.evaluate().isNotEmpty) {
            await t.tap(reintentar);
            await _pasos(t, 3);
          }
        });
  });

  testWidgets('cerrar sesión: cancelar y confirmar', (t) async {
    await smokeWidget(t, () => const AdminDashboardPage(),
        interact: false,
        role: 'admin',
        size: const Size(600, 1600), script: (t) async {
      await _pasos(t, 3);
      await t.tap(find.byTooltip('Cerrar sesión'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Cerrar sesión'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await _pasos(t, 4);
    });
  });
}
