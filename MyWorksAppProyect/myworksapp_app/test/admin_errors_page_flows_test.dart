// AdminErrorsPage: pestañas de errores, sync y abuso con filas reales,
// filtros por estado, búsqueda, cambio de estado, resolver abuso y error de
// carga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_errors_page.dart';

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

const _plataformas = [
  'android',
  'ios',
  'windows',
  'macos',
  'linux',
  'web',
  'tv',
  null
];

void _seed(FakeBackend b) {
  b.seed('registros_error_app', [
    for (var i = 0; i < _plataformas.length; i++)
      {
        'id': 'e$i',
        'id_usuario': i.isEven ? fakeUserId : null,
        'tipo_error': i.isEven ? 'flutter' : 'red',
        'mensaje': 'Falla número $i',
        'traza_pila': i == 0 ? '#0 main' : null,
        'metadatos': {'ruta': '/x$i'},
        'estado': ['nuevo', 'reconocido', 'resuelto', 'ignorado'][i % 4],
        'version_app': '1.0.$i',
        'plataforma': _plataformas[i],
        'creado_en': '2026-05-0${i + 1}T10:00:00Z',
      },
  ]);
  b.seed('acciones_pendientes', [
    for (final (i, estado) in [
      (1, 'fallido'),
      (2, 'pendiente'),
      (3, 'completado')
    ])
      {
        'id': 'a$i',
        'id_usuario': fakeUserId,
        'tipo_accion': 'crear',
        'tipo_entidad': 'trabajo',
        'id_entidad': 'j$i',
        'datos': '{}',
        'estado': estado,
        'conteo_reintentos': i,
        'mensaje_error': estado == 'fallido' ? 'timeout' : null,
        'creado_en': '2026-05-01T10:00:00Z',
        'actualizado_en': '2026-05-01T10:00:00Z',
      },
  ]);
  b.seed('eventos_abuso', [
    for (final (i, resuelto) in [(1, 0), (2, 1)])
      {
        'id': 'ab$i',
        'id_usuario': '$fakeUserId'.padRight(36, '0'),
        'tipo_abuso': 'spam_mensajes',
        'conteo': i * 3,
        'detectado_en': '2026-05-01T10:00:00Z',
        'accion_tomada': resuelto == 1 ? 'bloqueo' : null,
        'resuelto': resuelto,
      },
  ]);
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 5);
  // Errores: filtros y cambios de estado.
  for (final f in ['Nuevos', 'Reconocidos', 'Resueltos', 'Todos']) {
    await _tap(t, find.text(f));
  }
  for (final a in ['Reconocer', 'Resolver', 'Ignorar']) {
    await _tap(t, find.text(a));
  }
  final tile = find.byType(ExpansionTile);
  if (tile.evaluate().isNotEmpty) await _tap(t, tile);
  await t.fling(find.byType(Scrollable).last, const Offset(0, 400), 1000);
  await _pasos(t, 3);
  // Sync.
  await _tap(t, find.textContaining('Sync ('));
  for (final f in ['Fallidos', 'Pendientes', 'Todos']) {
    await _tap(t, find.text(f));
  }
  // Abuso.
  await _tap(t, find.textContaining('Abuso ('));
  await _tap(t, find.text('Resolver'));
  await _tap(t, find.text('Solo sin resolver'));
  await _tap(t, find.text('Solo sin resolver'));
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isNotEmpty) {
    await t.fling(scroll.last, const Offset(0, 400), 1000);
    await _pasos(t, 3);
  }
  // Búsqueda.
  final campo = find.byType(TextField);
  if (campo.evaluate().isNotEmpty) {
    await t.enterText(campo.first, 'falla');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await _pasos(t, 4);
    await t.enterText(campo.first, 'zzz-sin-resultados');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await _pasos(t, 4);
  }
}

void main() {
  testWidgets('incidencias con filas', (t) async {
    await smokeWidget(t, () => const AdminErrorsPage(),
        interact: false, role: 'admin', setup: _seed, script: _recorrido);
  });

  testWidgets('incidencias vacías', (t) async {
    await smokeWidget(t, () => const AdminErrorsPage(),
        interact: false, role: 'admin', setup: (b) {
      b.seed('registros_error_app', []);
      b.seed('acciones_pendientes', []);
      b.seed('eventos_abuso', []);
    }, script: _recorrido);
  });

  testWidgets('falla la carga de abuso', (t) async {
    await smokeWidget(t, () => const AdminErrorsPage(),
        interact: false,
        role: 'admin',
        setup: (b) {
          _seed(b);
          b.failing.add('eventos_abuso');
        },
        script: (t) => _pasos(t, 5));
  });
}
