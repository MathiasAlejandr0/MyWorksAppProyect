// RegisterPage: falta de consentimiento, registro exitoso como cliente y como
// especialista, consentimiento que falla al guardarse y error de Auth.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/features/auth/presentation/pages/register_page.dart';
import 'package:myworksapp/features/auth/presentation/widgets/role_selector_chips.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _llenar(WidgetTester t, {bool consentir = true}) async {
  final campos = find.byType(TextFormField);
  await t.enterText(campos.at(0), 'Ana Pérez');
  await t.enterText(campos.at(1), fakeUserEmail);
  await t.enterText(campos.at(2), 'Secreta#2026xy');
  await t.enterText(campos.at(3), 'Secreta#2026xy');
  await t.pump();
  if (consentir) {
    final check = find.byType(Checkbox);
    await t.ensureVisible(check.first);
    await t.tap(check.first);
    await t.pump();
  }
}

Future<void> _enviarConEnter(WidgetTester t) async {
  await t.showKeyboard(find.byType(TextFormField).at(3));
  await t.testTextInput.receiveAction(TextInputAction.done);
  await _pasos(t, 5);
}

void _usuarioRegistrado(FakeBackend b, String rol) {
  b.user = {
    'id': fakeUserId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': fakeUserEmail,
    'app_metadata': {'provider': 'email', 'rol': rol},
    'user_metadata': {'nombre': 'Ana Pérez', 'rol': rol},
    'created_at': '2026-01-01T00:00:00Z',
  };
}

void main() {
  testWidgets('sin consentimiento avisa', (t) async {
    await smokeWidget(t, () => const RegisterPage(),
        signedIn: false,
        interact: false,
        size: const Size(500, 1600), script: (t) async {
      await _llenar(t, consentir: false);
      await t.tap(find.text('Registrarse'));
      await _pasos(t, 2);
    });
  });

  for (final rol in ['usuario', 'trabajador']) {
    testWidgets('registro exitoso como $rol', (t) async {
      await smokeWidget(t, () => const RegisterPage(),
          signedIn: false,
          interact: false,
          size: const Size(500, 1600),
          setup: (b) => _usuarioRegistrado(b, rol),
          script: (t) async {
            if (rol == 'trabajador') {
              t
                  .widget<RoleSelectorChips>(find.byType(RoleSelectorChips))
                  .onChanged(UserRole.especialista);
              await t.pump();
            }
            await _llenar(t);
            await _enviarConEnter(t);
          });
    });
  }

  testWidgets('consentimiento que falla al guardarse muestra error', (t) async {
    await smokeWidget(t, () => const RegisterPage(),
        signedIn: false,
        interact: false,
        size: const Size(500, 1600), setup: (b) {
      _usuarioRegistrado(b, 'usuario');
      b.failing
          .addAll(['consentimientos_usuario', 'consentimientos_usuario:post']);
    }, script: (t) async {
      await _llenar(t);
      await t.tap(find.text('Registrarse'));
      await _pasos(t, 5);
    });
  });

  testWidgets('error de Auth al registrar', (t) async {
    await smokeWidget(t, () => const RegisterPage(),
        signedIn: false,
        interact: false,
        size: const Size(500, 1600),
        setup: (b) => b.failing.add('auth'),
        script: (t) async {
          await _llenar(t);
          await t.tap(find.text('Registrarse'));
          await _pasos(t, 4);
        });
  });
}
