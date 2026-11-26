// LoginPage sin sesión: cambio de rol con credenciales demo, selector de
// profesionales demo, login exitoso por rol y login fallido.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/auth/presentation/pages/login_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
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
  await _pasos(t, 3);
}

Map<String, dynamic> _usuario(String rol) => {
      'id': fakeUserId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': fakeUserEmail,
      'app_metadata': {'provider': 'email', 'rol': rol},
      'user_metadata': {'nombre': 'Ana Pérez', 'rol': rol},
      'created_at': '2026-01-01T00:00:00Z',
    };

Future<void> _credenciales(WidgetTester t, String email) async {
  final campos = find.byType(TextFormField);
  if (campos.evaluate().length < 2) return;
  await t.enterText(campos.at(0), email);
  await t.enterText(campos.at(1), 'aaaaaaaa1');
  await t.pump();
}

void main() {
  for (final rol in ['cliente', 'especialista', 'administrador']) {
    testWidgets('LoginPage entra como $rol', (t) async {
      await smokeWidget(
        t,
        () => LoginPage(role: rol),
        signedIn: false,
        interact: false,
        role: rol == 'especialista'
            ? 'trabajador'
            : (rol == 'cliente' ? 'usuario' : 'admin'),
        setup: (b) {
          b.user = _usuario(rol);
          b.seed('perfiles', [
            {
              'id': fakeUserId,
              'nombre': 'Ana Pérez',
              'correo': fakeUserEmail,
              'rol': rol == 'especialista'
                  ? 'trabajador'
                  : (rol == 'cliente' ? 'usuario' : 'admin'),
              'estado_cuenta': 'activo',
              'creado_en': '2026-01-01T00:00:00Z',
            },
          ]);
        },
        script: (t) async {
          await _pasos(t, 3);
          if (rol == 'especialista') {
            await _tap(t, 'María Fuentes');
          }
          await _credenciales(t, fakeUserEmail);
          await _tap(t, 'Entrar');
          await _pasos(t, 8);
        },
      );
    });
  }

  testWidgets('LoginPage cambia de rol y falla el login', (t) async {
    await smokeWidget(
      t,
      () => const LoginPage(),
      signedIn: false,
      interact: false,
      setup: (b) => b.failing.add('auth'),
      script: (t) async {
        await _pasos(t, 3);
        for (final r in [
          'Especialista',
          'Administrador',
          'Cliente',
          'Especialista'
        ]) {
          await _tap(t, r);
        }
        await _tap(t, 'Pedro Rojas');
        await _credenciales(t, 'ana@example.com');
        await _tap(t, 'Entrar');
        await _pasos(t, 6);
        // Formulario inválido: no intenta entrar.
        final campos = find.byType(TextFormField);
        if (campos.evaluate().isNotEmpty) {
          await t.enterText(campos.first, 'no-es-correo');
          await t.pump();
          await _tap(t, 'Entrar');
        }
        for (final txt in ['Olvidaste', 'Regístrate']) {
          final f = find.textContaining(txt, findRichText: true);
          if (f.evaluate().isEmpty) continue;
          await t.ensureVisible(f.first);
          await t.tap(f.first, warnIfMissed: false);
          await _pasos(t, 2);
        }
        final ver = find.byIcon(Icons.visibility_outlined);
        if (ver.evaluate().isNotEmpty) {
          await t.tap(ver.first, warnIfMissed: false);
          await t.pump();
        }
      },
    );
  });
}
