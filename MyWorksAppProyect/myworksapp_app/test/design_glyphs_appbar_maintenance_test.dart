// Glifos de marca, AppGradientAppBar en estilo iOS y la página de
// mantenimiento (reintento fallido, reintento exitoso y soporte).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/presentation/pages/maintenance_page.dart';
import 'package:myworksapp/core/services/app_health_service.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:myworksapp/core/widgets/design_system/premium_glyphs.dart';

import 'support/fake_supabase.dart';

void main() {
  testWidgets('PremiumGlyph dibuja todos los tipos y repinta al cambiar',
      (t) async {
    for (final color in [Colors.black, Colors.red]) {
      await t.pumpWidget(MaterialApp(
        home: Wrap(children: [
          for (final k in PremiumGlyphKind.values)
            PremiumGlyph(kind: k, size: 48, color: color),
        ]),
      ));
    }
    expect(find.byType(PremiumGlyph), findsNWidgets(6));
  });

  for (final dark in [false, true]) {
    testWidgets('AppGradientAppBar iOS (oscuro=$dark)', (t) async {
      final theme = (dark ? ThemeData.dark() : ThemeData.light())
          .copyWith(platform: TargetPlatform.iOS);
      await t.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('base')),
      ));
      final nav = t.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppGradientAppBar(
            title: const Text('Título'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.add))
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(20),
              child: SizedBox(height: 20),
            ),
          ),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text('Título'), findsOneWidget);
      expect(
        const AppGradientAppBar(
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(10), child: SizedBox()),
        ).preferredSize.height,
        kToolbarHeight + 10,
      );
      final back = find.byType(BackButton).evaluate().isNotEmpty
          ? find.byType(BackButton)
          : find.byIcon(CupertinoIconsBack.icon);
      if (back.evaluate().isNotEmpty) {
        await t.tap(back.first);
        await t.pumpAndSettle();
      }
      nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          appBar: AppGradientAppBar(
            leading: Icon(Icons.menu),
            automaticallyImplyLeading: false,
          ),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  }

  testWidgets('MaintenancePage: reintento fallido, exitoso y soporte',
      (t) async {
    // Regresión O3: con 600 px de alto la columna ya no desborda (se
    // desplaza); un desborde haría fallar la prueba.
    t.view.physicalSize = const Size(800, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late FakeBackend b;
    await t.runAsync(() async {
      b = await setUpFakeSupabase();
      b.failing.add('servicios');
      await AppHealthService.instance.checkHealth();
    });
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Text('inicio'))));
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => const MaintenancePage()));
    await t.pumpAndSettle();
    expect(find.textContaining('Servidor no disponible'), findsOneWidget);

    Future<void> pasos(int n) async {
      for (var i = 0; i < n; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pump(const Duration(milliseconds: 400));
      }
    }

    await t.tap(find.text('Contactar Soporte'));
    await pasos(4);
    if (find.text('Cerrar').evaluate().isNotEmpty) {
      await t.tap(find.text('Cerrar'));
      await pasos(2);
    }

    await t.tap(find.text('Reintentar'));
    await pasos(6);

    b.failing.clear();
    await t.tap(find.text('Reintentar'));
    await pasos(8);
    await t.pump(const Duration(seconds: 2));
    await pasos(2);
    expect(find.text('inicio'), findsOneWidget);
    AppHealthService.instance.activateMaintenanceMode();
    AppHealthService.instance.deactivateMaintenanceMode();
  });
}

class CupertinoIconsBack {
  static const icon = Icons.arrow_back_ios;
}
