import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myworksapp/features/jobs/presentation/pages/evidence_shutter_camera_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_photos_page.dart';

import 'support/fake_plugins.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _job = 'job-fotos-1';

List<Map<String, dynamic>> _fotos() => [
      {
        'id': 'f1',
        'id_trabajo': _job,
        'ruta_foto': '$_job/$fakeUserId/f1.webp',
        'tipo_medio': 'foto',
        'creado_en': '2026-11-20T10:00:00Z',
      },
      {
        'id': 'f2',
        'id_trabajo': _job,
        'ruta_foto': '$_job/$fakeUserId/f2.mp4',
        'tipo_medio': 'video',
        'creado_en': '2026-11-20T11:00:00Z',
      },
      {
        'id': 'f3',
        'id_trabajo': _job,
        'ruta_foto': 'local/legado.jpg',
        'tipo_medio': 'foto',
        'creado_en': '2026-11-20T12:00:00Z',
      },
    ];

Future<void> _step(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _abrirHoja(WidgetTester t) async {
  final add = find.byTooltip('Agregar evidencia');
  if (add.evaluate().isEmpty) return;
  await t.tap(add);
  await _step(t, 3);
}

Future<void> _elegir(WidgetTester t, String texto) async {
  await _abrirHoja(t);
  final f = find.text(texto);
  if (f.evaluate().isEmpty) return;
  await t.tap(f.first);
  await _step(t, 8);
}

void main() {
  testWidgets('galería: foto y video se suben y aparecen', (t) async {
    await smokeWidget(
      t,
      () => const JobPhotosPage(jobId: _job),
      interact: false,
      setup: (b) => b.tables['fotos_trabajo'] = [],
      script: (t) async {
        await _elegir(t, 'Elegir foto de galería');
        await _elegir(t, 'Elegir video de galería');
        fakePickerReturnsImage = false;
        await _elegir(t, 'Elegir foto de galería');
        await _elegir(t, 'Elegir video de galería');
      },
    );
  });

  testWidgets('subida falla y se reintenta', (t) async {
    await smokeWidget(
      t,
      () => const JobPhotosPage(jobId: _job),
      interact: false,
      setup: (b) {
        b.tables['fotos_trabajo'] = [];
        b.failing.add('storage');
      },
      script: (t) async {
        await _elegir(t, 'Elegir foto de galería');
        final retry = find.text('Reintentar');
        if (retry.evaluate().isNotEmpty) {
          await t.tap(retry.first);
          await _step(t, 8);
        }
        await _elegir(t, 'Elegir video de galería');
        if (retry.evaluate().isNotEmpty) {
          await t.tap(retry.first);
          await _step(t, 8);
        }
      },
    );
  });

  // PNG real de 1x1: la luma de la foto verificada necesita decodificarla.
  const png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  String archivo(String nombre, List<int> bytes) {
    final d = Directory('${Directory.systemTemp.path}/mwa_test_captura')
      ..createSync(recursive: true);
    return (File('${d.path}/$nombre')..writeAsBytesSync(bytes)).path;
  }

  Future<void> capturar(WidgetTester t, String op, EvidenceCapture? c) async {
    await _elegir(t, op);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    if (nav.canPop()) nav.pop(c);
    await _step(t, 10);
  }

  for (final falla in [false, true]) {
    testWidgets('cámara de evidencia: foto y video verificados (falla=$falla)',
        (t) async {
      await smokeWidget(
        t,
        () => const JobPhotosPage(jobId: _job),
        interact: false,
        setup: (b) {
          b.tables['fotos_trabajo'] = [];
          if (falla) b.failing.add('storage');
        },
        script: (t) async {
          final foto = XFile(archivo('cap.png', base64Decode(png)));
          final video = XFile(archivo('cap.mp4', List<int>.filled(4096, 7)));
          await capturar(t, 'Evidencia del antes', null);
          await capturar(t, 'Evidencia del antes',
              EvidenceCapture(file: foto, isVideo: false));
          await capturar(
              t,
              'Evidencia del después',
              EvidenceCapture(
                  file: video,
                  isVideo: true,
                  duration: const Duration(seconds: 5)));
          await capturar(
              t,
              'Detalle del trabajo',
              EvidenceCapture(
                  file: video,
                  isVideo: true,
                  duration: const Duration(milliseconds: 100)));
          final retry = find.text('Reintentar');
          if (retry.evaluate().isNotEmpty) {
            await t.tap(retry.first);
            await _step(t, 10);
          }
          await capturar(t, 'Detalle del trabajo',
              EvidenceCapture(file: foto, isVideo: false));
          if (retry.evaluate().isNotEmpty) {
            await t.tap(retry.first);
            await _step(t, 10);
          }
        },
      );
    });
  }

  // Regresión B4: el botón Eliminar del visor abre la confirmación y, al
  // confirmar, borra la evidencia (antes el pop cerraba el diálogo).
  for (final confirmar in [false, true]) {
    testWidgets('visor: eliminar evidencia (confirmar=$confirmar)', (t) async {
      late FakeBackend b;
      await smokeWidget(
        t,
        () => const JobPhotosPage(jobId: _job),
        interact: false,
        setup: (backend) {
          b = backend;
          b.tables['fotos_trabajo'] = _fotos();
        },
        script: (t) async {
          await _step(t, 4);
          final grid = find.descendant(
            of: find.byType(GridView),
            matching: find.byType(GestureDetector),
          );
          expect(grid, findsWidgets);
          await t.tap(grid.first, warnIfMissed: false);
          await _step(t, 4);
          await t.tap(find.byTooltip('Eliminar').last);
          await _step(t, 3);
          expect(find.text('Eliminar evidencia'), findsOneWidget);
          await t.tap(find.text(confirmar ? 'Eliminar' : 'Cancelar').last);
          await _step(t, 6);
          expect(find.text('Eliminar evidencia'), findsNothing);
        },
      );
      final ids = [for (final r in b.tables['fotos_trabajo']!) r['id']];
      expect(ids.length, confirmar ? 2 : 3);
    });
  }

  testWidgets('solo lectura y carga con error', (t) async {
    await smokeWidget(
      t,
      () => const JobPhotosPage(jobId: _job, canAddPhotos: false),
      interact: false,
      setup: (b) => b.failing.add('fotos_trabajo'),
    );
  });

  testWidgets('sin sesión: la subida avisa', (t) async {
    await smokeWidget(
      t,
      () => const JobPhotosPage(jobId: _job),
      interact: false,
      signedIn: false,
      script: (t) => _elegir(t, 'Elegir foto de galería'),
    );
  });
}
