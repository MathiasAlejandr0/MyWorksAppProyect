// WorkerProfilePage: edición por secciones (datos, oficio, tarifas,
// servicios, portafolio), foto de perfil, portafolio (agregar y eliminar),
// cierre de sesión y estados sin ficha o con error de carga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/profile_avatar_picker.dart';
import 'package:myworksapp/features/worker/presentation/pages/worker_profile_page.dart';

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

Future<bool> _tap(WidgetTester t, Finder f, {int i = 0}) async {
  if (f.evaluate().length <= i) return false;
  await t.ensureVisible(f.at(i));
  await t.pump();
  await t.tap(f.at(i), warnIfMissed: false);
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

Map<String, dynamic> _ficha({bool tarifas = true}) => {
      'id': 'w1',
      'id_usuario': fakeUserId,
      'profesion': 'Gasfíter',
      'categoria_servicio': 'plomeria',
      'descripcion':
          'Gasfitería general, urgencias, cambio de llaves, calefont y todo tipo '
              'de filtraciones en casas y departamentos de Puerto Montt.',
      'zona_trabajo': 'Puerto Montt',
      'disponible': 1,
      'tarifa_visita': 15000,
      if (tarifas)
        'trabajador_precios': [
          {'id_opcion': 'plumbing_minor', 'monto_clp': 20000},
        ],
      'trabajador_servicios_extra': [
        for (var i = 1; i <= 4; i++)
          {'id': 'x$i', 'titulo': 'Extra $i', 'monto_clp': 5000 * i},
      ],
    };

List<Map<String, dynamic>> _portafolio() => [
      for (var i = 1; i <= 3; i++)
        {
          'id': 'p$i',
          'id_trabajador': fakeUserId,
          'ruta_foto': 'portafolio/$fakeUserId/p$i.webp',
          'descripcion': 'Trabajo $i',
          'creado_en': '2026-0$i-01T00:00:00Z',
          'tipo_medio': 'foto',
        },
    ];

Future<void> _seccion(WidgetTester t, int i,
    {String? campo, String? valor, bool guardar = true}) async {
  if (!await _tap(t, find.text('Editar'), i: i)) return;
  if (campo != null) {
    final f = find.widgetWithText(TextFormField, campo);
    if (f.evaluate().isNotEmpty) {
      await t.enterText(f.first, valor ?? '');
      await t.pump();
    }
  }
  if (guardar) {
    final g = find.byWidgetPredicate((w) =>
        w is Text &&
        (w.data == 'Guardar' || (w.data ?? '').startsWith('Guardar')));
    if (!await _tap(t, g)) await _tap(t, find.text('Cancelar'));
  } else {
    await _tap(t, find.text('Cancelar'));
  }
  await _pasos(t, 3);
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 5);
  // Foto de perfil.
  for (final o in ['Elegir de la galería', 'Tomar foto', 'Quitar foto']) {
    await _tap(t, find.byType(ProfileAvatarPicker));
    await _tap(t, find.text(o));
    await _pasos(t, 3);
  }
  // Secciones: cancelar, inválido y guardar.
  await _seccion(t, 0, guardar: false);
  await _seccion(t, 0, campo: 'Nombre completo', valor: '');
  await _seccion(t, 0, campo: 'Nombre completo', valor: 'Pedro Rojas');
  await _seccion(t, 1, campo: 'Profesión', valor: '');
  await _seccion(t, 1, campo: 'Descripción profesional', valor: 'Corto');
  await _seccion(t, 1, campo: 'Profesión', valor: 'Gasfíter certificado');
  for (var i = 2; i <= 4; i++) {
    await _seccion(t, i);
  }
  // Portafolio.
  await _tap(t, find.text('Agregar foto'));
  await _tap(t, find.text('Galería'));
  await _pasos(t, 4);
  await _tap(t, find.text('Agregar foto'));
  await _tap(t, find.text('Tomar foto'));
  await _pasos(t, 4);
  fakePickerReturnsImage = false;
  await _tap(t, find.text('Agregar foto'));
  await _tap(t, find.text('Galería'));
  fakePickerReturnsImage = true;
  fakeCompressReturnsNull = true;
  await _tap(t, find.text('Agregar foto'));
  await _tap(t, find.text('Galería'));
  fakeCompressReturnsNull = false;
  await _tap(t, find.byTooltip('Eliminar'));
  await _pasos(t, 3);
  // Lista horizontal.
  final h = find.byType(ListView);
  if (h.evaluate().isNotEmpty) {
    await t.drag(h.first, const Offset(-300, 0));
    await _pasos(t, 2);
  }
  for (final a in [
    'Configuración',
    'Encuesta de la prueba',
    'Completar registro',
  ]) {
    if (await _tap(t, find.text(a))) await _volver(t);
  }
  await _tap(t, find.text('Cerrar sesión'));
  await _tap(t, find.text('Cancelar'));
  await _tap(t, find.text('Cerrar sesión'));
  await _tap(t, find.text('Cerrar sesión').last);
  await _pasos(t, 3);
}

void main() {
  testWidgets('WorkerProfilePage recorrido completo', (t) async {
    await smokeWidget(
      t,
      () => const WorkerProfilePage(),
      interact: false,
      role: 'trabajador',
      size: const Size(480, 1400),
      overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
      setup: (b) {
        b.seed('trabajadores', [_ficha()]);
        b.seed('portafolio_trabajador', _portafolio());
      },
      script: _recorrido,
    );
  });

  testWidgets('WorkerProfilePage sin tarifas y con fallas al guardar',
      (t) async {
    await smokeWidget(
      t,
      () => const WorkerProfilePage(),
      interact: false,
      role: 'trabajador',
      size: const Size(480, 1400),
      overrides: {'ruta_foto_perfil': 'perfiles/$fakeUserId/foto.webp'},
      setup: (b) {
        b.seed('trabajadores', [_ficha(tarifas: false)]);
        b.seed('portafolio_trabajador', _portafolio());
        b.failing.addAll([
          'perfiles:patch',
          'trabajadores:patch',
          'portafolio_trabajador:post',
          'portafolio_trabajador:delete',
          'storage',
        ]);
      },
      script: _recorrido,
    );
  });

  testWidgets('WorkerProfilePage sin ficha de especialista', (t) async {
    await smokeWidget(
      t,
      () => const WorkerProfilePage(),
      interact: false,
      role: 'trabajador',
      setup: (b) {
        b.seed('trabajadores', []);
        b.seed('portafolio_trabajador', []);
      },
      script: _recorrido,
    );
  });

  testWidgets('WorkerProfilePage error de carga y reintento', (t) async {
    await smokeWidget(
      t,
      () => const WorkerProfilePage(),
      interact: false,
      role: 'trabajador',
      setup: (b) => b.failing.add('trabajadores'),
      script: (t) async {
        await _pasos(t, 4);
        await _tap(t, find.text('Reintentar'));
        await _pasos(t, 3);
      },
    );
  });

  testWidgets('WorkerProfilePage sin usuario', (t) async {
    await smokeWidget(
      t,
      () => const WorkerProfilePage(),
      signedIn: false,
      interact: false,
      script: (t) => _pasos(t, 2),
    );
  });
}
