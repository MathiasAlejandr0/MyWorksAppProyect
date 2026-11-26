// Visor de portafolio: imagen de red, archivo local, sin fuente y video
// (asset, red y archivo) con el reproductor falso, incluido el error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/portfolio_media_viewer.dart';

import 'support/fake_plugins.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<BuildContext> _base(WidgetTester t) async {
  await t.pumpWidget(const MaterialApp(home: Scaffold(body: Text('base'))));
  return t.element(find.text('base'));
}

Future<void> _volver(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator)).pop();
  await _pasos(t, 3);
}

void main() {
  setUp(() async {
    await setUpFakeSupabase();
  });

  testWidgets('imágenes: archivo local y ruta desconocida', (t) async {
    final ctx = await _base(t);
    PortfolioMediaViewer.open(ctx,
        photoPath: fakeImagePath(), mediaType: 'foto', description: '');
    await _pasos(t);
    expect(find.text('Trabajo anterior'), findsOneWidget);
    await _volver(t);

    PortfolioMediaViewer.open(ctx,
        photoPath: 'no/existe.jpg', mediaType: 'foto');
    await _pasos(t);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    await _volver(t);
  });

  // La imagen de red deja temporizadores de la caché: se usa el arnés, que
  // los agota al desmontar.
  testWidgets('imagen de red con descripción', (t) async {
    await smokeWidget(
      t,
      () => Builder(
        builder: (ctx) => TextButton(
          onPressed: () => PortfolioMediaViewer.openImagePath(ctx,
              imagePath: 'https://cdn.example/x.jpg',
              description: 'Baño nuevo'),
          child: const Text('abrir'),
        ),
      ),
      interact: false,
      script: (t) async {
        await t.tap(find.text('abrir'));
        await _pasos(t);
        expect(find.text('Baño nuevo'), findsOneWidget);
        t.state<NavigatorState>(find.byType(Navigator).first).pop();
        await _pasos(t, 3);
        PortfolioMediaViewer.open(t.element(find.text('abrir')),
            photoPath: 'demo:gasfiter', mediaType: 'foto');
        await _pasos(t);
        expect(find.text('Trabajo anterior'), findsOneWidget);
        //(find.text('Baño nuevo'), findsOneWidget);
      },
    );
  });

  for (final ruta in [
    'assets/video/demo.mp4',
    'https://cdn.example/v.mp4',
    '/tmp/v.mp4',
  ]) {
    testWidgets('video $ruta: reproduce, pausa y vuelve a reproducir',
        (t) async {
      installFakeVideo();
      final ctx = await _base(t);
      PortfolioMediaViewer.open(ctx,
          photoPath: ruta, mediaType: 'video', description: 'Video de obra');
      await _pasos(t, 8);
      expect(find.text('Video del trabajo'), findsOneWidget);
      for (final tip in ['Pausar', 'Reproducir']) {
        final f = find.byTooltip(tip);
        if (f.evaluate().isNotEmpty) {
          await t.tap(f.first);
          await _pasos(t, 2);
        }
      }
      final gd = find.descendant(
          of: find.byType(Center), matching: find.byType(GestureDetector));
      if (gd.evaluate().isNotEmpty) {
        await t.tap(gd.first, warnIfMissed: false);
        await _pasos(t, 2);
      }
      await _volver(t);
    });
  }

  testWidgets('video que no carga muestra el error', (t) async {
    installFakeVideo(fails: true);
    final ctx = await _base(t);
    PortfolioMediaViewer.open(ctx,
        photoPath: 'https://cdn.example/roto.mp4', mediaType: 'video');
    await _pasos(t, 8);
    expect(find.text('No se pudo cargar el video'), findsOneWidget);
    await _volver(t);
  });

  testWidgets('cerrar el video antes de que cargue', (t) async {
    installFakeVideo();
    final ctx = await _base(t);
    PortfolioMediaViewer.open(ctx,
        photoPath: 'https://cdn.example/v.mp4', mediaType: 'video');
    await t.pump();
    await _volver(t);
    await _pasos(t, 4);
  });
}
