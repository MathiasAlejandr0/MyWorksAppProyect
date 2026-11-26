// SettingsPage: activar notificaciones (concedido, denegado y bloqueado con
// el diálogo de Ajustes), versión de la app, Acerca de y panel de administrador.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/settings/presentation/pages/settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/widget_harness.dart';

const _permisos = MethodChannel('flutter.baseflow.com/permissions/methods');

/// 0 denegado, 1 concedido, 4 bloqueado (PermissionStatus de permission_handler).
void _permiso({required int estado, int pedido = 0}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_permisos, (call) async {
    switch (call.method) {
      case 'checkPermissionStatus':
        return estado;
      case 'requestPermissions':
        final ids = (call.arguments as List).cast<int>();
        return {for (final id in ids) id: pedido};
      case 'openAppSettings':
        return true;
    }
    return null;
  });
}

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

Future<void> _switchNotif(WidgetTester t) => _tap(t, find.byType(Switch).first);

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MyWorksApp',
      packageName: 'cl.myworksapp',
      version: '2.4.1',
      buildNumber: '41',
      buildSignature: '',
    );
  });

  testWidgets('concedido: activa y desactiva', (t) async {
    await smokeWidget(t, () => const SettingsPage(),
        interact: false,
        setup: (_) => _permiso(estado: 1),
        script: (t) async {
          await _pasos(t);
          await _switchNotif(t);
          await _switchNotif(t);
          await _tap(t, find.text('Acerca de'));
          await _tap(t, find.text('Close'));
          await _tap(t, find.text('CERRAR'));
        });
  });

  testWidgets('denegado al pedir: aviso', (t) async {
    await smokeWidget(t, () => const SettingsPage(),
        interact: false,
        setup: (_) => _permiso(estado: 0, pedido: 0),
        script: (t) async {
          await _pasos(t);
          await _switchNotif(t);
          await _pasos(t);
        });
  });

  for (final abrir in [false, true]) {
    testWidgets('bloqueado: diálogo de Ajustes (abrir $abrir)', (t) async {
      await smokeWidget(t, () => const SettingsPage(),
          interact: false,
          setup: (_) => _permiso(estado: 4),
          script: (t) async {
            await _pasos(t);
            await _switchNotif(t);
            await _tap(t, find.text(abrir ? 'Abrir Ajustes' : 'Ahora no'));
          });
    });
  }

  testWidgets('administrador abre su panel', (t) async {
    await smokeWidget(t, () => const SettingsPage(),
        interact: false, role: 'administrador', script: (t) async {
      await _pasos(t);
      await _tap(t, find.text('Panel administrador'));
    });
  });
}
