// UserRightsPage (derechos GDPR) contra el backend falso: cancelar en cada
// confirmación, eliminar con éxito y con error, sin sesión, y exportación
// sin sesión y con error.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/gdpr/presentation/pages/user_rights_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tap(WidgetTester t, String texto) async {
  final f = find.text(texto);
  if (f.evaluate().isEmpty) return;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t);
}

Future<void> _eliminar(WidgetTester t, {bool cancelar = false}) async {
  await _pasos(t, 2);
  await _tap(t, 'Solicitar Eliminación');
  await _tap(t, 'Cancelar');
  await _tap(t, 'Solicitar Eliminación');
  await _tap(t, 'Eliminar Permanentemente');
  if (cancelar) {
    await _tap(t, 'No, cancelar');
    return;
  }
  await _tap(t, 'Sí, eliminar');
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('cancelar en la segunda confirmación', (t) async {
    await smokeWidget(t, () => const UserRightsPage(),
        interact: false, script: (t) => _eliminar(t, cancelar: true));
  });

  testWidgets('eliminar con éxito', (t) async {
    await smokeWidget(t, () => const UserRightsPage(),
        interact: false, script: (t) => _eliminar(t));
  });

  testWidgets('eliminar con error del backend', (t) async {
    await smokeWidget(t, () => const UserRightsPage(),
        interact: false,
        setup: (b) => b.failing.add('perfiles'),
        script: (t) => _eliminar(t));
  });

  testWidgets('sin sesión: eliminar y exportar', (t) async {
    await smokeWidget(t, () => const UserRightsPage(),
        interact: false, signedIn: false, script: (t) async {
      await _eliminar(t);
      await _tap(t, 'Exportar Mis Datos');
    });
  });

  testWidgets('exportar con error', (t) async {
    await smokeWidget(t, () => const UserRightsPage(),
        interact: false,
        setup: (b) => b.failAll = true,
        script: (t) async {
          await _pasos(t, 2);
          await _tap(t, 'Exportar Mis Datos');
          FakeBackend.instance.failAll = false;
          await _pasos(t, 2);
        });
  });
}
