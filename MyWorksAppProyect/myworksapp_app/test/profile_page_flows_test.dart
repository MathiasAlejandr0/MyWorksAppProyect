// ProfilePage (perfil común): accesos por rol, foto de perfil, refresco,
// diseño ancho y ramas sin perfil profesional o con errores de carga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/profile_avatar_picker.dart';
import 'package:myworksapp/features/auth/presentation/pages/profile_page.dart';

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

Future<void> _volver(WidgetTester t) async {
  for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
    while (st.canPop()) {
      st.pop();
      await _pasos(t, 1);
    }
  }
  await _pasos(t, 2);
}

const _accesos = [
  'Ver historial completo',
  'Editar datos personales',
  'Portafolio, tarifas y zona',
  'Pagos y cuenta bancaria',
  'Horario semanal',
  'Mis calificaciones',
  'Mis disputas',
  'Mensajes',
  'Configuración',
  'Completar perfil de especialista',
];

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 4);
  for (final o in ['Elegir de la galería', 'Tomar foto', 'Quitar foto']) {
    await _tap(t, find.byType(ProfileAvatarPicker));
    await _tap(t, find.text(o));
    await _pasos(t, 3);
  }
  fakePickerReturnsImage = false;
  await _tap(t, find.byType(ProfileAvatarPicker));
  await _tap(t, find.text('Tomar foto'));
  fakePickerReturnsImage = true;
  await _pasos(t, 2);

  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isNotEmpty) {
    await t.fling(scroll.first, const Offset(0, 500), 1200);
    await _pasos(t, 4);
  }
  for (final a in _accesos) {
    if (await _tap(t, find.text(a))) await _volver(t);
  }
}

Map<String, dynamic> _trabajador() => {
      'id_usuario': fakeUserId,
      'profesion': 'Gasfíter',
      'categoria_servicio': 'plomeria',
      'zona_trabajo': 'Puerto Montt',
      'descripcion': 'Gasfitería general y urgencias.',
      'disponible': 1,
      'trabajador_servicios_extra': [
        {
          'id': 'x1',
          'titulo': 'Visita de diagnóstico',
          'monto_clp': 15000,
          'unidad': 'fijo',
        },
        {
          'id': 'x2',
          'titulo': 'Sellado',
          'subtitulo': 'Por metro',
          'monto_clp': 4000,
          'unidad': 'por_m2',
        },
      ],
    };

void main() {
  for (final rol in ['usuario', 'trabajador']) {
    for (final ancho in [false, true]) {
      testWidgets('ProfilePage $rol ${ancho ? 'ancho' : 'móvil'}', (t) async {
        await smokeWidget(
          t,
          () => const ProfilePage(),
          interact: false,
          role: rol,
          size: ancho ? const Size(1400, 1000) : const Size(430, 932),
          overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
          setup: (b) {
            if (rol == 'trabajador') b.seed('trabajadores', [_trabajador()]);
          },
          script: _recorrido,
        );
      });
    }
  }

  testWidgets('ProfilePage trabajador sin perfil profesional', (t) async {
    await smokeWidget(
      t,
      () => const ProfilePage(),
      interact: false,
      role: 'trabajador',
      setup: (b) => b.seed('trabajadores', []),
      script: _recorrido,
    );
  });

  testWidgets('ProfilePage con fallas de carga y guardado', (t) async {
    await smokeWidget(
      t,
      () => const ProfilePage(),
      interact: false,
      role: 'trabajador',
      overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
      setup: (b) {
        b.failing
            .addAll(['trabajadores', 'trabajos', 'perfiles:patch', 'storage']);
      },
      script: _recorrido,
    );
  });
}
