// Widgets sueltos: selector segmentado, anillo de urgencia (mantener 3 s),
// selector de navegación externa (Google Maps, Waze, Apple Maps) y todas las
// ramas del cuestionario de modo de cobro.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_mode_recommendation.dart';
import 'package:myworksapp/core/utils/external_map_launcher.dart';
import 'package:myworksapp/core/widgets/design_system/apple_segmented_picker.dart';
import 'package:myworksapp/core/widgets/design_system/spatial_emergency_pulse.dart';
import 'package:myworksapp/features/user/presentation/widgets/pricing_mode_questionnaire.dart';

const _url = MethodChannel('plugins.flutter.io/url_launcher');

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  final abiertas = <String>[];
  var wazeInstalado = true;

  setUp(() {
    abiertas.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_url, (call) async {
      final url = (call.arguments as Map)['url'] as String;
      if (call.method == 'canLaunch') {
        return !url.startsWith('waze://') || wazeInstalado;
      }
      if (call.method == 'launch') abiertas.add(url);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_url, null);
  });

  for (final oscuro in [false, true]) {
    testWidgets('AppleSegmentedPicker (oscuro $oscuro)', (t) async {
      var elegido = 'a';
      await t.pumpWidget(_app(
        StatefulBuilder(
          builder: (ctx, set) => AppleSegmentedPicker<String>(
            options: const {'a': 'Todos', 'b': 'Activos', 'c': 'Cerrados'},
            selectedValue: elegido,
            padding: oscuro ? const EdgeInsets.all(2) : null,
            onValueChanged: (v) => set(() => elegido = v),
          ),
        ),
        theme: oscuro ? ThemeData.dark() : ThemeData.light(),
      ));
      await t.tap(find.text('Cerrados'));
      await t.pumpAndSettle();
      expect(elegido, 'c');
    });
  }

  for (final oscuro in [false, true]) {
    testWidgets('anillo de urgencia: soltar antes y mantener (oscuro $oscuro)',
        (t) async {
      await t.pumpWidget(MaterialApp(
        theme: oscuro ? ThemeData.dark() : ThemeData.light(),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => const SpatialEmergencyPulseDialog(),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      final anillo = find.descendant(
        of: find.byType(SpatialEmergencyPulseDialog),
        matching: find.byType(GestureDetector),
      );
      // Soltar a medio camino reinicia el progreso.
      var g = await t.startGesture(t.getCenter(anillo.first));
      await t.pump(const Duration(milliseconds: 500));
      await g.up();
      await t.pump();
      // Cancelar el gesto también.
      g = await t.startGesture(t.getCenter(anillo.first));
      await t.pump(const Duration(milliseconds: 200));
      await g.cancel();
      await t.pump();
      // Mantener hasta completar.
      g = await t.startGesture(t.getCenter(anillo.first));
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await t.pumpAndSettle();
      final ok = find.text('Entendido');
      if (ok.evaluate().isNotEmpty) {
        await t.tap(ok);
        await t.pumpAndSettle();
      }
    });
  }

  Future<void> abrirSelector(WidgetTester t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: FilledButton(
            onPressed: () => ExternalMapLauncher.showNavigationChooser(ctx,
                latitude: -41.4693, longitude: -72.9424),
            child: const Text('navegar'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('navegar'));
    await t.pumpAndSettle();
  }

  testWidgets('navegación externa: Google Maps y Waze', (t) async {
    for (final app in ['Google Maps', 'Waze']) {
      await abrirSelector(t);
      await t.tap(find.text(app));
      await t.pumpAndSettle();
    }
    wazeInstalado = false;
    await abrirSelector(t);
    await t.tap(find.text('Waze'));
    await t.pumpAndSettle();
    wazeInstalado = true;
    expect(abiertas, hasLength(3));
    expect(abiertas.last, startsWith('https://waze.com'));
  });

  testWidgets('navegación externa en iOS: Apple Maps', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await abrirSelector(t);
      await t.tap(find.text('Apple Maps'));
      await t.pumpAndSettle();
      expect(abiertas.single, startsWith('https://maps.apple.com'));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  group('cuestionario de modo de cobro', () {
    Future<List<PricingModeRecommendation>> montar(WidgetTester t,
        {String? categoria,
        bool preseleccionado = false,
        PricingModeRecommendation? inicial}) async {
      final recos = <PricingModeRecommendation>[];
      t.view.physicalSize = const Size(900, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(PricingModeQuestionnaire(
        workerPreselected: preseleccionado,
        category: categoria,
        initialRecommendation: inicial,
        onRecommendation: recos.add,
      )));
      await t.pumpAndSettle();
      return recos;
    }

    Future<void> tocar(WidgetTester t, String texto) async {
      final f = find.text(texto);
      if (f.evaluate().isEmpty) return;
      await t.ensureVisible(f.first);
      await t.tap(f.first);
      await t.pumpAndSettle();
    }

    const reparaciones = [
      'Grifo, lavatorio o sanitario',
      'Cerradura o llaves',
      'Calefón o termo',
      'Electricidad puntual',
      'Otra reparación acotada',
    ];

    for (final categoria in [
      null,
      'plomeria',
      'electricidad',
      'jardineria',
      'limpieza',
      'ensamblaje',
      'soporte_tecnico',
      'mudanza',
      'construccion',
    ]) {
      testWidgets('todas las ramas (categoría $categoria)', (t) async {
        final recos = await montar(t,
            categoria: categoria, preseleccionado: categoria == 'plomeria');
        for (final r in reparaciones) {
          await tocar(t, 'Reparar o cambiar algo puntual');
          await tocar(t, 'Volver');
          await tocar(t, 'Reparar o cambiar algo puntual');
          await tocar(t, r);
          await tocar(t, 'Responder de nuevo');
        }
        for (final h in ['2 h', '4 h', '8 h']) {
          await tocar(t, 'Trabajo que toma varias horas');
          await tocar(t, 'Volver');
          await tocar(t, 'Trabajo que toma varias horas');
          await tocar(t, h);
          await tocar(t, 'Responder de nuevo');
        }
        await tocar(t, 'Proyecto grande o por etapas');
        await tocar(t, 'Responder de nuevo');
        await tocar(t, 'No estoy seguro / quiero que lo evalúen');
        expect(recos, isNotEmpty);
        // Reabrir con la recomendación ya elegida.
        await t.pumpWidget(const SizedBox());
        await montar(t, categoria: categoria, inicial: recos.last);
        await tocar(t, 'Responder de nuevo');
      });
    }
  });
}
