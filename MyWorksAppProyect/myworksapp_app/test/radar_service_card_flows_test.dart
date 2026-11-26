// LiveWorkerRadarWidget (pines, hoja del profesional, ir a búsqueda, vacío y
// tema oscuro) y ServiceCard (inclinación con el dedo, cancelar y categorías
// con imagen local).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/widgets/design_system/live_worker_radar_widget.dart';
import 'package:myworksapp/core/widgets/design_system/service_card.dart';

import 'support/model_samples.dart';

Widget _router(Widget home, {bool oscuro = false}) {
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: SingleChildScrollView(child: home))),
    GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Búsqueda'))),
  ]);
  return MaterialApp.router(
    routerConfig: router,
    theme: oscuro ? ThemeData.dark() : ThemeData.light(),
  );
}

WorkerModel _pro(int i, String oficio) => WorkerModel.fromMap({
      ...sampleWorkerModel,
      'id': 'radar-$i',
      'profesion': oficio,
      'calificacion': 4.0 + i / 10,
    });

void main() {
  for (final oscuro in [false, true]) {
    testWidgets('radar con profesionales (oscuro $oscuro)', (t) async {
      final pros = [
        for (var i = 0; i < 8; i++) _pro(i, i == 0 ? '' : 'Gasfíter $i'),
      ];
      await t.pumpWidget(_router(
          LiveWorkerRadarWidget(workers: pros, city: 'Osorno'),
          oscuro: oscuro));
      await t.pump(const Duration(seconds: 1));
      final pines = find
          .byWidgetPredicate((w) => w.runtimeType.toString() == '_RadarPin');
      expect(pines, findsWidgets);
      await t.tap(pines.first, warnIfMissed: false);
      await t.pump(const Duration(seconds: 1));
      // Cerrar la hoja tocando fuera y abrir la del segundo pin.
      await t.tapAt(const Offset(5, 5));
      await t.pump(const Duration(seconds: 1));
      await t.tap(pines.at(1), warnIfMissed: false);
      await t.pump(const Duration(seconds: 1));
      final ver = find.text('Ver perfil y solicitar');
      expect(ver, findsOneWidget);
      {
        await t.pump();
        t
            .widget<ElevatedButton>(find.ancestor(
                of: ver.first, matching: find.byType(ElevatedButton)))
            .onPressed!();
        for (var i = 0; i < 5; i++) {
          await t.pump(const Duration(milliseconds: 400));
        }
      }
      expect(find.text('Búsqueda'), findsOneWidget);
    });

    testWidgets('radar vacío (oscuro $oscuro)', (t) async {
      await t.pumpWidget(
          _router(const LiveWorkerRadarWidget(workers: []), oscuro: oscuro));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Sin profesionales en vivo ahora'), findsWidgets);
    });
  }

  for (final cat in [
    'plomeria',
    'limpieza',
    'ensamblaje',
    'soporte_tecnico',
    'mudanza',
    'construccion',
  ]) {
    testWidgets('ServiceCard $cat se inclina con el dedo', (t) async {
      var toques = 0;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 260,
              child: ServiceCard(
                name: 'Servicio $cat',
                description: 'Descripción',
                icon: Icons.build,
                categoryKey: cat,
                actionLabel: 'Pedir',
                onTap: () => toques++,
              ),
            ),
          ),
        ),
      ));
      await t.pump();
      final card = find.byType(ServiceCard);
      final centro = t.getCenter(card);
      var g = await t.startGesture(centro);
      await g.moveBy(const Offset(40, -30));
      await t.pump(const Duration(milliseconds: 100));
      await g.moveBy(const Offset(-80, 60));
      await t.pump(const Duration(milliseconds: 100));
      await g.up();
      await t.pump(const Duration(milliseconds: 300));
      g = await t.startGesture(centro);
      await t.pump(const Duration(milliseconds: 100));
      await g.cancel();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(card);
      await t.pump(const Duration(milliseconds: 300));
      expect(toques, greaterThanOrEqualTo(1));
    });
  }
}
