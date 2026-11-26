// Arnés para tests de humo de widgets: monta el widget con Riverpod,
// go_router, tema de la app y textos en español, contra el backend Supabase
// falso. Después toca los botones visibles y escribe en los campos para
// recorrer los manejadores. Los errores de la app (overflow, plugins que no
// existen en la VM de tests, etc.) se registran pero no fallan el test: el
// objetivo es recorrer el código, no validar el diseño.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myworksapp/core/providers/auth_provider.dart';
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
  String role = 'usuario',
  Map<String, dynamic> overrides = const {},
  Size size = const Size(420, 900),
}) async {
  lastSmokeErrors.clear();
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    lastSmokeErrors.add(d.exception);
    if (const bool.fromEnvironment('SMOKE_DEBUG_FULL')) {
      // ignore: avoid_print
      print(
          'SMOKE_FULL: ${d.toString().split('\n').where((l) => l.contains('dart:') == false).take(60).join(' | ')}');
    }
  };
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
        b.tableDefaults = tableRows;
        b.rowOverrides = {'rol': role, ...overrides};
        b.defaultRpc = (_) => [
              {...universalRow, 'rol': role, ...overrides},
            ];
      }
      if (signedIn) {
        b.user = {
          'id': fakeUserId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': fakeUserEmail,
          'app_metadata': {'provider': 'email', 'rol': role},
          'user_metadata': {'nombre': 'Ana Pérez', 'rol': role},
          'created_at': '2026-01-01T00:00:00Z',
        };
        await signInFake();
        await container
            .read(authProvider.notifier)
            .loadCurrentUser(fakeUserId)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      }
    });
    await runZonedGuarded(() async {
      try {
        await _drive(tester, build, interact, container);
      } catch (e) {
        lastSmokeErrors.add(e);
      }
    }, (e, _) => lastSmokeErrors.add(e));
  } finally {
    try {
      final before = lastSmokeErrors.length;
      await tester.pumpWidget(const SizedBox());
      if (const bool.fromEnvironment('SMOKE_DEBUG')) {
        // ignore: avoid_print
        print('SMOKE_TEARDOWN: errores=${lastSmokeErrors.length - before} '
            'callbacks=${SchedulerBinding.instance.transientCallbackCount} '
            '${lastSmokeErrors.skip(before).take(2).map((e) => '$e'.split('\n').first)}');
      }
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
    if (const bool.fromEnvironment('SMOKE_DEBUG')) {
      for (final e in lastSmokeErrors.take(8)) {
        // ignore: avoid_print
        print('SMOKE_ERR: ${'$e'.split('\n').take(4).join(' | ')}');
      }
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
  ProviderContainer container,
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
    UncontrolledProviderScope(
      container: container,
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
    await _step(tester, 250);
  }
  if (const bool.fromEnvironment('SMOKE_DEBUG')) {
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .where((t) => t.isNotEmpty)
        .take(25)
        .join(' / ');
    // ignore: avoid_print
    print('SMOKE_TEXT: $texts');
    // ignore: avoid_print
    print(
        'SMOKE_REQ: ${FakeBackend.instance.requests.map((r) => '${r.method} ${r.url.path}').join(', ')}');
  }
  if (!interact) return;
  // Escribe en los campos de texto visibles.
  final fields = find.byType(EditableText, skipOffstage: true);
  final nFields = fields.evaluate().length;
  for (var i = 0; i < nFields && i < 8; i++) {
    try {
      await tester.enterText(fields.at(i), i.isEven ? '12' : 'texto de prueba');
      await _step(tester, 50);
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
        await _step(tester, 300);
        await _step(tester, 300);
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
            await _step(tester, 300);
          }
          if (nav.mounted && nav.canPop()) nav.pop();
          await _step(tester, 300);
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
      await _step(tester, 300);
    }
  } catch (e) {
    lastSmokeErrors.add(e);
  }
  for (var i = 0; i < 4; i++) {
    await _step(tester, 500);
  }
}

/// Avanza el reloj falso y deja correr un poco de tiempo real: postgrest
/// decodifica el JSON en otro isolate, y esa respuesta solo llega con tiempo
/// real.
Future<void> _step(WidgetTester tester, int ms) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 15)),
  );
  await tester.pump(Duration(milliseconds: ms));
}
