// AppLifecycleService y PermissionDeniedHandler necesitan un WidgetRef o un
// BuildContext reales: se llaman desde botones montados con el arnés.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/app_lifecycle_service.dart';
import 'package:myworksapp/core/services/permission_denied_handler.dart';
import 'package:permission_handler/permission_handler.dart';

import 'support/widget_harness.dart';

const _permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

void _statusPermiso(int status) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_permChannel, (call) async {
    if (call.method == 'checkPermissionStatus') return status;
    if (call.method == 'openAppSettings') return true;
    return null;
  });
}

void main() {
  for (final signedIn in [true, false]) {
    testWidgets('AppLifecycleService recorre los estados (sesión $signedIn)',
        (tester) async {
      final svc = AppLifecycleService.instance;
      await smokeWidget(
        tester,
        () => Consumer(
          builder: (ctx, ref, _) => Column(
            children: [
              FilledButton(
                onPressed: () {
                  svc.initialize(ref);
                  svc.initialize(ref);
                },
                child: const Text('iniciar'),
              ),
              for (final s in AppLifecycleState.values)
                FilledButton(
                  onPressed: () => svc.didChangeAppLifecycleState(s),
                  child: Text(s.name),
                ),
              FilledButton(
                onPressed: () {
                  svc.dispose();
                  svc.dispose();
                  svc.didChangeAppLifecycleState(AppLifecycleState.resumed);
                },
                child: const Text('cerrar'),
              ),
            ],
          ),
        ),
        signedIn: signedIn,
      );
      svc.dispose();
    });
  }

  // 0 denegado, 1 concedido, 2 restringido, 4 denegado permanentemente.
  for (final status in [0, 1, 2, 4]) {
    for (final fallback in [true, false]) {
      testWidgets('PermissionDeniedHandler status $status fallback $fallback',
          (tester) async {
        await smokeWidget(
          tester,
          () => Builder(
            builder: (ctx) => FilledButton(
              onPressed: () {
                _statusPermiso(status);
                PermissionDeniedHandler.instance.handleDeniedPermission(
                  context: ctx,
                  permission: Permission.location,
                  permissionName: 'ubicación',
                  fallbackMessage: fallback ? 'Escribe tu dirección' : null,
                  onFallback: fallback ? () {} : null,
                );
              },
              child: const Text('pedir'),
            ),
          ),
        );
      });
    }
  }

  test('PermissionDeniedHandler: mensajes alternativos y estado permanente',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final p in [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.notification,
      Permission.microphone,
      Permission.contacts,
    ]) {
      expect(PermissionDeniedHandler.getFallbackMessage(p), isA<String>());
    }
    for (final status in [1, 4]) {
      _statusPermiso(status);
      expect(
        await PermissionDeniedHandler.instance
            .isPermanentlyDenied(Permission.camera),
        status == 4,
      );
    }
  });
}
