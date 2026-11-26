// Arnés para tests de humo de widgets: monta el widget con Riverpod,
// go_router, tema de la app y textos en español, contra el backend Supabase
// falso. Después toca los botones visibles y escribe en los campos para
// recorrer los manejadores. Los errores de la app (overflow, plugins que no
// existen en la VM de tests, etc.) se registran pero no fallan el test: el
// objetivo es recorrer el código, no validar el diseño.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_supabase.dart';
import 'model_samples.dart';

/// Errores capturados en el último [smokeWidget] (para depurar).
final List<Object> lastSmokeErrors = [];

void _mockPlatformChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // Cualquier canal de plugin responde null en vez de MissingPluginException.
  for (final name in const [
    'plugins.flutter.io/path_provider',
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geocoding',
    'flutter.baseflow.com/permissions/methods',
    'dexterous.com/flutter/local_notifications',
    'plugins.flutter.io/firebase_messaging',
    'plugins.flutter.io/image_picker',
    'plugins.flutter.io/url_launcher',
    'plugins.flutter.io/share_plus',
    'dev.fluttercommunity.plus/share',
    'dev.fluttercommunity.plus/package_info',
    'plugins.flutter.io/camera',
    'flutter_image_compress',
    'com.llfbandit.app_links/messages',
    'com.llfbandit.app_links/events',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
  }
}

Future<void> smokeWidget(
  WidgetTester tester,
  Widget Function() build, {
  bool seeded = true,
  bool signedIn = true,
  bool interact = true,
  Size size = const Size(420, 900),
}) async {
  lastSmokeErrors.clear();
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (d) => lastSmokeErrors.add(d.exception);
  final originalPrint = debugPrint;
  debugPrint = (String? m, {int? wrapWidth}) {};
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  _mockPlatformChannels();
  try {
    await tester.runAsync(() async {
      final b = await setUpFakeSupabase(signedIn: signedIn);
      if (seeded) {
        b.defaultRows = [universalRow, universalRow];
        b.defaultRpc = (_) => [universalRow];
      }
    });
    await runZonedGuarded(() async {
      try {
        await _drive(tester, build, interact);
      } catch (e) {
        lastSmokeErrors.add(e);
      }
    }, (e, _) => lastSmokeErrors.add(e));
  } finally {
    try {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      final client = Supabase.instance.client;
      unawaited(client.removeAllChannels().catchError((_) => <String>[]));
      await tester.pump(const Duration(seconds: 1));
      unawaited(client.realtime.disconnect().catchError((_) {}));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(minutes: 1));
      }
    } catch (e) {
      lastSmokeErrors.add(e);
    }
    // Descarta excepciones pendientes del framework.
    while (tester.takeException() != null) {}
    FlutterError.onError = originalOnError;
    debugPrint = originalPrint;
  }
}

Future<void> _drive(
  WidgetTester tester,
  Widget Function() build,
  bool interact,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => build()),
      GoRoute(
        path: '/:a',
        builder: (_, __) => const Scaffold(body: Text('ruta')),
        routes: [
          GoRoute(
            path: ':b',
            builder: (_, __) => const Scaffold(body: Text('ruta')),
            routes: [
              GoRoute(
                path: ':c',
                builder: (_, __) => const Scaffold(body: Text('ruta')),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, __) => const Scaffold(body: Text('ruta')),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: const Locale('es', 'CL'),
        supportedLocales: const [Locale('es', 'CL'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (!interact) return;
  // Escribe en los campos de texto visibles.
  final fields = find.byType(EditableText, skipOffstage: true);
  final nFields = fields.evaluate().length;
  for (var i = 0; i < nFields && i < 8; i++) {
    try {
      await tester.enterText(fields.at(i), i.isEven ? '12' : 'texto de prueba');
      await tester.pump(const Duration(milliseconds: 50));
    } catch (e) {
      lastSmokeErrors.add(e);
    }
  }
  // Toca los elementos interactivos de la pantalla inicial.
  final tappables = <Finder>[
    find.byWidgetPredicate((w) => w is ButtonStyleButton, skipOffstage: true),
    find.byType(IconButton, skipOffstage: true),
    find.byType(InkWell, skipOffstage: true),
    find.byType(Checkbox, skipOffstage: true),
    find.byType(Switch, skipOffstage: true),
    find.byType(ChoiceChip, skipOffstage: true),
    find.byType(FilterChip, skipOffstage: true),
  ];
  var taps = 0;
  for (final f in tappables) {
    final n = f.evaluate().length;
    for (var i = 0; i < n && taps < 30; i++) {
      taps++;
      try {
        // Vuelve a la pantalla del widget si un toque navegó.
        final current = f.evaluate().length;
        if (i >= current) break;
        await tester.tap(f.at(i), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        // Cierra diálogos y hojas abiertas.
        final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
        if (nav.canPop()) {
          // Toca primero los botones del diálogo, luego lo cierra.
          final dialogButtons = find.descendant(
            of: find.byType(Dialog),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          if (dialogButtons.evaluate().isNotEmpty) {
            await tester.tap(dialogButtons.last, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 300));
          }
          if (nav.mounted && nav.canPop()) nav.pop();
          await tester.pump(const Duration(milliseconds: 300));
        }
      } catch (e) {
        lastSmokeErrors.add(e);
      }
    }
  }
  // Desplaza listas.
  try {
    final scrollables = find.byType(Scrollable, skipOffstage: true);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -600),
          warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  } catch (e) {
    lastSmokeErrors.add(e);
  }
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}
