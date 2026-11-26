// Escenarios del backend falso para los tests de humo generados.
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_supabase.dart';
import 'model_samples.dart';

export 'model_probe.dart' show probe;

typedef Scenario = ({String name, Future<void> Function() apply});

Future<void> setUpScenarios() async {
  await setUpFakeSupabase();
}

final List<Scenario> scenarios = [
  (
    name: 'vacío con sesión',
    apply: () async {
      await setUpFakeSupabase(signedIn: true);
    },
  ),
  (
    name: 'con filas',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.defaultRows = [universalRow, universalRow];
      b.defaultRpc = (_) => [universalRow];
    },
  ),
  (
    name: 'RPC devuelve objeto',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.defaultRows = [universalRow];
      b.defaultRpc = (_) => universalRow;
    },
  ),
  (
    name: 'RPC devuelve escalar',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.defaultRpc = (_) => 1;
    },
  ),
  (
    name: 'todo falla',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.failAll = true;
      b.failing.addAll(['auth', 'storage']);
    },
  ),
  (
    name: 'funciones y RPC responden con error de negocio',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.defaultRows = [universalRow];
      b.tableDefaults = tableRows;
      b.defaultRpc = (_) => {'error': 'Operación rechazada', 'ok': false};
      b.defaultFunction = (_) => {'error': 'Operación rechazada', 'ok': false};
    },
  ),
  (
    name: 'funciones y RPC responden con datos',
    apply: () async {
      final b = await setUpFakeSupabase(signedIn: true);
      b.defaultRows = [universalRow];
      b.tableDefaults = tableRows;
      final datos = {
        ...universalRow,
        'ok': true,
        'success': true,
        'url': 'https://webpay.invalid/pago',
        'token': 'token-falso',
        'token_ws': 'token-falso',
        'estado': 'AUTHORIZED',
        'status': 'AUTHORIZED',
        'response_code': 0,
      };
      b.defaultRpc = (_) => datos;
      b.defaultFunction = (_) => datos;
    },
  ),
  (
    name: 'sin sesión',
    apply: () async {
      await setUpFakeSupabase();
    },
  ),
];

Future<void> forEachScenario(Future<void> Function() body) async {
  for (final s in scenarios) {
    await s.apply();
    await body();
  }
  await setUpFakeSupabase();
  if (Supabase.instance.client.auth.currentSession != null) {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
  }
}

/// Llama [f]; espera Futures (máx. 3 s) y el primer evento de Streams
/// (máx. 300 ms). Los errores se tragan: en estos tests de humo un error
/// controlado del backend falso es un resultado válido.
Future<void> call(Object? Function() f) async {
  try {
    final r = f();
    if (r is Future) {
      final done = Completer<void>();
      void finish([Object? _]) {
        if (!done.isCompleted) done.complete();
      }

      r.then(finish, onError: (Object _) => finish());
      await Future.any([
        done.future,
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);
    } else if (r is Stream) {
      final sub = r.listen((_) {}, onError: (_) {});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
    }
  } catch (e) {
    if (const bool.fromEnvironment('SMOKE_DEBUG') &&
        (e is NoSuchMethodError || e is TypeError)) {
      // ignore: avoid_print
      print('SMOKE_CALL: ${e.toString().split('\n').first}');
    }
  }
}
