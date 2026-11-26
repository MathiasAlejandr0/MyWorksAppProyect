// UserProfilePage: foto de perfil (cámara, galería, quitar), edición del
// perfil, cierre de sesión y ramas de error del guardado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/profile_avatar_picker.dart';
import 'package:myworksapp/features/user/presentation/pages/user_profile_page.dart';

import 'support/fake_plugins.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

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

Future<void> _foto(WidgetTester t, String opcion) async {
  await _tap(t, find.byType(ProfileAvatarPicker));
  await _tap(t, find.text(opcion));
  await _pasos(t, 4);
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 3);
  for (final o in ['Elegir de la galería', 'Tomar foto', 'Quitar foto']) {
    await _foto(t, o);
  }
  fakePickerReturnsImage = false;
  await _foto(t, 'Elegir de la galería');
  fakePickerReturnsImage = true;

  await _tap(t, find.byTooltip('Editar'));
  final campos = find.byType(TextFormField);
  if (campos.evaluate().length >= 2) {
    await t.enterText(campos.at(0), 'Ana María Pérez');
    await t.enterText(campos.at(1), 'ANA.PEREZ@EXAMPLE.COM');
    await t.pump();
  }
  await _tap(t, find.text('Guardar cambios'));
  await _pasos(t, 3);
  await _tap(t, find.byTooltip('Editar'));
  if (find.byType(TextFormField).evaluate().isNotEmpty) {
    await t.enterText(find.byType(TextFormField).first, '');
    await t.pump();
    await _tap(t, find.text('Guardar cambios'));
  }
  await _tap(t, find.byTooltip('Cerrar'));

  await _tap(t, find.text('Configuración'));
  for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
    while (st.canPop()) {
      st.pop();
      await _pasos(t, 1);
    }
  }
  await _pasos(t, 2);
  await _tap(t, find.text('Cerrar sesión'));
  await _tap(t, find.text('Cancelar'));
  await _tap(t, find.text('Cerrar sesión'));
  await _tap(t, find.text('Cerrar sesión').last);
  await _pasos(t, 4);
}

void main() {
  testWidgets('UserProfilePage recorrido completo', (t) async {
    await smokeWidget(
      t,
      () => const UserProfilePage(),
      interact: false,
      role: 'usuario',
      overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
      script: _recorrido,
    );
  });

  testWidgets('UserProfilePage con fallas al guardar', (t) async {
    await smokeWidget(
      t,
      () => const UserProfilePage(),
      interact: false,
      role: 'usuario',
      overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
      setup: (b) {
        b.failing.add('perfiles:patch');
        b.failing.add('storage');
      },
      script: _recorrido,
    );
  });

  testWidgets('UserProfilePage sin usuario', (t) async {
    await smokeWidget(
      t,
      () => const UserProfilePage(),
      signedIn: false,
      interact: false,
      script: (t) => _pasos(t, 2),
    );
  });
}
