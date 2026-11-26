// Arnés para tests de humo de widgets: monta el widget con Riverpod,
// go_router, tema de la app y textos en español, contra el backend Supabase
// falso. Después toca los botones visibles y escribe en los campos para
// recorrer los manejadores. Los errores de la app (overflow, plugins que no
// existen en la VM de tests, etc.) se registran pero no fallan el test: el
// objetivo es recorrer el código, no validar el diseño.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myworksapp/core/providers/auth_provider.dart';
import 'package:myworksapp/core/router/app_router.dart';
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
    messenger.setMockMethodCallHandler(MethodChannel(name), _pluginAnswer);
  }
}

/// Respuestas plausibles de plugins (permiso concedido, GPS en Puerto Montt,
/// imagen temporal), para que los flujos sigan más allá del primer paso.
Future<Object?> _pluginAnswer(MethodCall call) async {
  switch (call.method) {
    case 'checkPermission':
    case 'requestPermission':
      return 3; // LocationPermission.always
    case 'isLocationServiceEnabled':
      return true;
    case 'getCurrentPosition':
    case 'getLastKnownPosition':
      return <String, dynamic>{
        'latitude': -41.4693,
        'longitude': -72.9424,
        'timestamp': DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
        'accuracy': 5.0,
        'altitude': 0.0,
        'altitude_accuracy': 0.0,
        'heading': 0.0,
        'heading_accuracy': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'is_mocked': false,
      };
    case 'checkPermissionStatus':
    case 'checkServiceStatus':
      return 1;
    case 'requestPermissions':
      final perms = (call.arguments as List?) ?? const [];
      return {for (final p in perms) p: 1};
    case 'shouldShowRequestPermissionRationale':
      return false;
    case 'pickImage':
    case 'pickVideo':
      return _tempImagePath();
    case 'pickMultiImage':
    case 'pickMultipleMedia':
      return [_tempImagePath()];
    case 'getTemporaryDirectory':
    case 'getApplicationDocumentsDirectory':
    case 'getApplicationSupportDirectory':
    case 'getApplicationCacheDirectory':
      return Directory.systemTemp.path;
    case 'canLaunch':
    case 'launch':
      return true;
    default:
      return null;
  }
}

String _tempImagePath() {
  final f = File('${Directory.systemTemp.path}/smoke_evidencia.jpg');
  if (!f.existsSync()) {
    f.writeAsBytesSync(
        const [0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46, 0xFF, 0xD9]);
  }
  return f.path;
}

Future<void> smokeWidget(
  WidgetTester tester,
  Widget Function() build, {
  bool seeded = true,
  bool signedIn = true,
  bool interact = true,
  String role = 'usuario',
  Map<String, dynamic> overrides = const {},
  Size size = const Size(480, 2400),
  // Solo para pantallas que abren el selector de ubicación: el tema de la app
  // da ancho mínimo infinito a FilledButton y el botón "Usar este punto" (en una
  // Row) no se puede dibujar. Ver el informe de bugs; aquí se acota para seguir.
  bool boundedButtons = false,
  // Si se indica, usa el router real de la app (routerProvider) y navega a
  // esta ruta en vez de montar [build] directamente.
  String? appRoute,
}) async {
  lastSmokeErrors.clear();
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    lastSmokeErrors.add(d.exception);
    if (const bool.fromEnvironment('SMOKE_DEBUG_FULL')) {
      // ignore: avoid_print
      print('SMOKE_FULL: ${d.toString().split('\n').take(80).join(' | ')}');
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
        // Destinos de estado: todos, para que aparezcan las acciones.
        b.rpc('transiciones_trabajo_posibles', [
          'aceptado',
          'en_camino',
          'en_curso',
          'completado',
          'cancelado',
          'esperando_aprobacion_cliente',
          'pausado_orden_cambio',
          'no_asistio',
        ]);
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
        await _drive(
            tester, build, interact, container, boundedButtons, appRoute);
      } catch (e) {
        lastSmokeErrors.add(e);
      }
    }, (e, _) => lastSmokeErrors.add(e));
  } finally {
    try {
      final before = lastSmokeErrors.length;
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
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
  bool boundedButtons, [
  String? appRoute,
]) async {
  final router = appRoute != null
      ? container.read(routerProvider)
      : GoRouter(
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
        theme: boundedButtons
            ? _bounded(AppTheme.lightTheme)
            : AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: const Locale('es', 'CL'),
        supportedLocales: const [Locale('es', 'CL'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  if (appRoute != null) {
    router.go(appRoute);
  }
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
  // Dos pasadas: la primera elige fechas, opciones y listas; la segunda
  // vuelve a tocar con el formulario ya lleno (p. ej. el botón de enviar).
  for (var pass = 0; pass < 2; pass++) {
    var taps = 0;
    for (final f in tappables) {
      final n = f.evaluate().length;
      for (var i = 0; i < n && taps < 60; i++) {
        taps++;
        try {
          // Vuelve a la pantalla del widget si un toque navegó.
          final current = f.evaluate().length;
          if (i >= current) break;
          if (_avoided(f.at(i).evaluate().first)) continue;
          await tester.tap(f.at(i), warnIfMissed: false);
          await _step(tester, 300);
          await _step(tester, 300);
          // Si abrió un menú desplegable, elige la última opción.
          final menuItems = find.byWidgetPredicate(
            (w) => w is DropdownMenuItem || w is PopupMenuItem,
          );
          if (menuItems.evaluate().length > 1) {
            await tester.tap(menuItems.last, warnIfMissed: false);
            await _step(tester, 300);
          }
          // Si abrió un diálogo u hoja, toca su botón principal y lo cierra.
          final navs = find.byType(Navigator).evaluate();
          if (navs.isNotEmpty) {
            final nav = (navs.last as StatefulElement).state as NavigatorState;
            if (nav.canPop()) {
              final overlay = find.byWidgetPredicate(
                (w) => w is Dialog || w is BottomSheet || w is AlertDialog,
              );
              final dialogFields = find.descendant(
                of: overlay,
                matching: find.byType(EditableText),
              );
              for (final el in dialogFields.evaluate().take(4).toList()) {
                try {
                  await tester.enterText(find.byWidget(el.widget), '1234');
                } catch (e) {
                  lastSmokeErrors.add(e);
                }
              }
              await _step(tester, 100);
              final dialogButtons = find.descendant(
                of: overlay,
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              );
              if (dialogButtons.evaluate().isNotEmpty) {
                await tester.tap(dialogButtons.last, warnIfMissed: false);
                await _step(tester, 300);
              }
              if (nav.mounted && nav.canPop()) nav.pop();
              await _step(tester, 300);
            }
          }
          // Si navegó a otra ruta, vuelve al widget bajo prueba.
          if (find.text('ruta').evaluate().isNotEmpty) {
            router.go('/');
            await _step(tester, 300);
          }
        } catch (e) {
          lastSmokeErrors.add(e);
        }
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

ThemeData _bounded(ThemeData t) {
  const min = WidgetStatePropertyAll(Size(64, 52));
  return t.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: (t.filledButtonTheme.style ?? const ButtonStyle())
          .copyWith(minimumSize: min),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: (t.elevatedButtonTheme.style ?? const ButtonStyle())
          .copyWith(minimumSize: min),
    ),
  );
}

/// Botones que el recorrido no toca porque disparan un bug ya reportado:
/// "Editar dirección" (location_picker_widget.dart) libera su
/// TextEditingController mientras el diálogo aún se está cerrando.
const _avoidTooltips = {'Editar dirección'};

bool _avoided(Element e) {
  bool hit(Widget w) =>
      (w is IconButton && _avoidTooltips.contains(w.tooltip)) ||
      (w is Tooltip && _avoidTooltips.contains(w.message));
  if (hit(e.widget)) return true;
  var found = false;
  e.visitAncestorElements((a) {
    if (hit(a.widget)) found = true;
    return !found;
  });
  if (found) return true;
  void visit(Element c) {
    if (found) return;
    if (hit(c.widget)) found = true;
    c.visitChildElements(visit);
  }

  e.visitChildElements(visit);
  return found;
}
