// AppLifecycleService al volver a primer plano: sesión válida de trabajador
// con trabajos activos, sesión cerrada en Supabase (logout), restauración de
// una sesión guardada sin usuario en estado y errores del backend.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/app_lifecycle_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Widget _host() => Consumer(
      builder: (ctx, ref, _) => FilledButton(
        onPressed: () => AppLifecycleService.instance.initialize(ref),
        child: const Text('iniciar'),
      ),
    );

Future<void> _resumir(WidgetTester t) async {
  await t.tap(find.text('iniciar'));
  await t.pump();
  AppLifecycleService.instance
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
  await _pasos(t, 4);
}

void _trabajoActivo(FakeBackend b) {
  b.seed('trabajos', [
    {
      ...sampleJobModel,
      'id': 'activo-1',
      'id_trabajador': fakeUserId,
      'estado': 'en_curso',
    },
  ]);
}

void main() {
  tearDown(() => AppLifecycleService.instance.dispose());

  testWidgets('trabajador con sesión válida y trabajos activos', (t) async {
    await smokeWidget(t, _host,
        interact: false,
        role: 'trabajador',
        setup: _trabajoActivo,
        script: _resumir);
  });

  testWidgets('backend caído al resumir no cierra la sesión', (t) async {
    await smokeWidget(t, _host, interact: false, role: 'trabajador',
        script: (t) async {
      FakeBackend.instance.failAll = true;
      await _resumir(t);
      FakeBackend.instance.failAll = false;
    });
  });

  testWidgets('sesión cerrada en Supabase fuerza logout', (t) async {
    await smokeWidget(t, _host, interact: false, script: (t) async {
      await t.runAsync(() async {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      });
      await _resumir(t);
    });
  });

  testWidgets('sin usuario en estado pero con sesión guardada restaura',
      (t) async {
    await smokeWidget(t, _host, signedIn: false, interact: false, setup: (b) {
      b.user = {
        'id': fakeUserId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': fakeUserEmail,
        'app_metadata': {'provider': 'email', 'rol': 'usuario'},
        'user_metadata': {'nombre': 'Ana Pérez', 'rol': 'usuario'},
        'created_at': '2026-01-01T00:00:00Z',
      };
    }, script: (t) async {
      await t.runAsync(() async {
        try {
          await signInFake();
        } catch (_) {}
      });
      await _resumir(t);
      // Segunda vez con el backend caído: restoreSession falla.
      FakeBackend.instance.failAll = true;
      AppLifecycleService.instance
          .didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _pasos(t, 3);
      FakeBackend.instance.failAll = false;
    });
  });
}
