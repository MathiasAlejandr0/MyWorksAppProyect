// Backend Supabase falso para tests. Nunca sale a la red: todas las
// peticiones (REST, RPC, Auth, Storage, Functions) se responden en memoria.
// La URL apunta a un host inexistente para que, si algo escapara del cliente
// falso, no pueda llegar a producción.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myworksapp/core/database/repositories/service_repository.dart';
import 'package:myworksapp/core/database/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_geocoding.dart';
import 'fake_plugins.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const fakeSupabaseUrl = 'http://fake-supabase.invalid';
const fakeUserId = '00000000-0000-4000-8000-000000000001';
const fakeUserEmail = 'cliente@test.invalid';

/// Petición registrada por el backend falso.
class FakeRequest {
  FakeRequest(this.method, this.url, this.body, this.headers);
  final String method;
  final Uri url;
  final String body;
  final Map<String, String> headers;

  String get path => url.path;
  dynamic get json => body.isEmpty ? null : jsonDecode(body);
  @override
  String toString() => '$method $url $body';
}

typedef FakeHandler = Object? Function(FakeRequest req);

/// Estado mutable del backend falso. Se reinicia con [reset].
class FakeBackend {
  FakeBackend._();
  static final FakeBackend instance = FakeBackend._();

  final Map<String, List<Map<String, dynamic>>> tables = {};
  final Map<String, FakeHandler> rpcs = {};
  final Map<String, FakeHandler> functions = {};

  /// Respuesta de las Edge Functions sin manejador propio (null: {'ok': true}).
  FakeHandler? defaultFunction;
  final List<FakeRequest> requests = [];

  /// Tablas creadas desde [defaultRows]: sus filas aceptan cualquier filtro.
  final Set<String> lenient = {};

  /// Tablas o RPC que deben responder con error 400 (para ramas de error).
  final Set<String> failing = {};

  /// Si es true, toda petición REST/RPC responde 500.
  bool failAll = false;

  /// RPC que responden error de negocio con este mensaje.
  final Map<String, String> rpcErrors = {};

  /// Respuesta de error propia para Auth: (status HTTP, mensaje).
  (int, String)? authFailure;

  Map<String, dynamic>? user;

  /// Filas que devuelve una tabla no sembrada (null = lista vacía).
  List<Map<String, dynamic>>? defaultRows;

  /// Fila de ejemplo por tabla; si hay [defaultRows], la tabla devuelve dos
  /// copias de su fila (con ids distintos) en vez de [defaultRows].
  Map<String, Map<String, dynamic>> tableDefaults = const {};

  /// Cambios que se aplican a cada fila por defecto (p. ej. el rol).
  Map<String, dynamic> rowOverrides = const {};

  /// Respuesta de RPC no registradas (null = devuelve null).
  FakeHandler? defaultRpc;

  void reset() {
    defaultRows = null;
    defaultRpc = null;
    tableDefaults = const {};
    rowOverrides = const {};
    lenient.clear();
    tables.clear();
    rpcs.clear();
    functions.clear();
    defaultFunction = null;
    requests.clear();
    failing.clear();
    failAll = false;
    authFailure = null;
    rpcErrors.clear();
    user = null;
  }

  void seed(String table, List<Map<String, dynamic>> rows) {
    tables[table] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  void rpc(String name, Object? result) => rpcs[name] = (_) => result;

  Iterable<FakeRequest> calls(String pathPart) =>
      requests.where((r) => r.url.toString().contains(pathPart));

  Future<http.Response> handle(http.Request req) async {
    final r = FakeRequest(req.method, req.url, req.body, req.headers);
    requests.add(r);
    final path = req.url.path;
    if (path.startsWith('/rest/v1/rpc/')) {
      return _rpc(r, path.substring('/rest/v1/rpc/'.length));
    }
    if (path.startsWith('/rest/v1/')) {
      return _rest(r, path.substring('/rest/v1/'.length));
    }
    if (path.startsWith('/auth/v1/')) return _auth(r, path.substring(9));
    if (path.startsWith('/storage/v1/')) return _storage(r, path.substring(12));
    if (path.startsWith('/functions/v1/')) {
      final name = path.substring(14);
      if (failing.contains('fn:$name')) return _err(500, 'falla simulada');
      final h = functions[name];
      if (h != null) return _json(h(r));
      return _json(
          defaultFunction == null ? {'ok': true} : defaultFunction!(r));
    }
    return _json({});
  }

  http.Response _json(Object? body,
      {int status = 200, Map<String, String>? h}) {
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8', ...?h},
    );
  }

  http.Response _err(int status, String msg, {String code = 'XX000'}) =>
      _json({'message': msg, 'code': code, 'details': null, 'hint': null},
          status: status);

  http.Response _rpc(FakeRequest r, String name) {
    if (failAll || failing.contains(name)) return _err(400, 'rpc falla: $name');
    final negocio = rpcErrors[name];
    if (negocio != null) return _err(400, negocio, code: 'P0001');
    final h = rpcs[name] ?? defaultRpc;
    final result = h == null ? null : h(r);
    return _json(result);
  }

  List<Map<String, dynamic>> _defaultsFor(String table) {
    final base = defaultRows;
    if (base == null) return [];
    final row = tableDefaults[table];
    if (row == null) {
      return [
        for (final d in base) {...d, ...rowOverrides},
      ];
    }
    return [
      {...row, ...rowOverrides},
      {...row, ...rowOverrides, 'id': '${row['id']}-2'},
    ];
  }

  bool _matches(Map<String, dynamic> row, String key, String value) {
    if (!row.containsKey(key)) return true;
    final cell = row[key];
    String s(Object? v) => v == null ? 'null' : '$v';
    if (value.startsWith('eq.')) return s(cell) == value.substring(3);
    if (value.startsWith('neq.')) return s(cell) != value.substring(4);
    if (value.startsWith('is.')) {
      final want = value.substring(3);
      if (want == 'null') return cell == null;
      return s(cell) == want;
    }
    if (value.startsWith('in.(')) {
      final inner = value.substring(4, value.length - 1);
      final opts = inner.split(',').map((e) => e.replaceAll('"', '')).toSet();
      return opts.contains(s(cell));
    }
    return true;
  }

  http.Response _rest(FakeRequest r, String table) {
    // 'tabla:patch', 'tabla:post'… hace fallar solo ese método.
    if (failAll ||
        failing.contains(table) ||
        failing.contains('$table:${r.method.toLowerCase()}')) {
      return _err(400, 'tabla falla: $table');
    }
    if (!tables.containsKey(table) && defaultRows != null) {
      lenient.add(table);
    }
    final rows = tables.putIfAbsent(table, () => _defaultsFor(table));
    final isLenient = lenient.contains(table);
    final params = r.url.queryParameters;
    final filters = Map.of(params)
      ..remove('select')
      ..remove('order')
      ..remove('limit')
      ..remove('offset')
      ..remove('on_conflict')
      ..remove('columns');
    final accept = r.headers['Accept'] ?? r.headers['accept'] ?? '';
    final single = accept.contains('vnd.pgrst.object');
    final prefer = r.headers['Prefer'] ?? r.headers['prefer'] ?? '';

    List<Map<String, dynamic>> selected() {
      if (!isLenient) {
        return rows
            .where(
              (row) =>
                  filters.entries.every((e) => _matches(row, e.key, e.value)),
            )
            .toList();
      }
      // Tablas por defecto: las filas se adaptan a los filtros `eq`.
      for (final row in rows) {
        for (final e in filters.entries) {
          if (e.value.startsWith('eq.')) {
            final v = e.value.substring(3);
            final old = row[e.key];
            row[e.key] = old is int
                ? int.tryParse(v) ?? old
                : old is bool
                    ? v == 'true'
                    : v;
          }
        }
      }
      // Un filtro por id devuelve una sola fila (como una clave única).
      final byId = filters.entries.any(
        (e) =>
            (e.key == 'id' || e.key.startsWith('id_')) &&
            e.value.startsWith('eq.'),
      );
      return byId ? rows.take(1).toList() : rows;
    }

    switch (r.method) {
      case 'GET':
      case 'HEAD':
        var out = selected();
        final limit = int.tryParse(params['limit'] ?? '');
        if (limit != null && out.length > limit) out = out.sublist(0, limit);
        final headers = <String, String>{
          'content-range':
              '0-${out.isEmpty ? 0 : out.length - 1}/${out.length}',
        };
        if (single && isLenient && out.isNotEmpty) {
          return _json(out.first, h: headers);
        }
        if (single) {
          if (out.length != 1) {
            return _json({
              'code': 'PGRST116',
              'details': 'The result contains ${out.length} rows',
              'hint': null,
              'message':
                  'JSON object requested, multiple (or no) rows returned',
            }, status: 406);
          }
          return _json(out.first, h: headers);
        }
        if (r.method == 'HEAD') {
          return http.Response('', 200, headers: headers);
        }
        return _json(out, h: headers);
      case 'POST':
        final body = r.json;
        final list = body is List ? body : [body];
        final inserted = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            m.putIfAbsent('id', () => 'gen-${rows.length + 1}');
            rows.add(m);
            inserted.add(m);
          }
        }
        if (!prefer.contains('return=representation')) {
          return http.Response('', 201);
        }
        if (single)
          return _json(inserted.isEmpty ? {} : inserted.first, status: 201);
        return _json(inserted, status: 201);
      case 'PATCH':
        final patch = Map<String, dynamic>.from((r.json as Map?) ?? {});
        final hit = selected();
        for (final row in hit) {
          row.addAll(patch);
        }
        if (!prefer.contains('return=representation')) {
          return http.Response('', 204);
        }
        if (single) return _json(hit.isEmpty ? patch : hit.first);
        return _json(hit);
      case 'DELETE':
        final hit = selected();
        rows.removeWhere(hit.contains);
        if (!prefer.contains('return=representation')) {
          return http.Response('', 204);
        }
        return _json(hit);
    }
    return _json([]);
  }

  Map<String, dynamic> get _userJson =>
      user ??
      {
        'id': fakeUserId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': fakeUserEmail,
        'phone': '',
        'app_metadata': {'provider': 'email'},
        'user_metadata': {'nombre': 'Cliente Test', 'rol': 'cliente'},
        'created_at': '2026-01-01T00:00:00Z',
        'email_confirmed_at': '2026-01-01T00:00:00Z',
      };

  Map<String, dynamic> get sessionJson => {
        'access_token': fakeJwt(),
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'refresh_token': 'refresh-fake',
        'user': _userJson,
      };

  http.Response _auth(FakeRequest r, String path) {
    final custom = authFailure;
    if (custom != null && !path.startsWith('logout')) {
      return _json({
        'code': custom.$1,
        'msg': custom.$2,
        'message': custom.$2,
      }, status: custom.$1);
    }
    if (failing.contains('auth') || failing.contains('auth:$path')) {
      return _json({
        'code': 400,
        'error_code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
        'message': 'Invalid login credentials'
      }, status: 400);
    }
    if (path.startsWith('token')) return _json(sessionJson);
    if (path.startsWith('signup')) return _json(sessionJson);
    if (path.startsWith('user')) return _json(_userJson);
    if (path.startsWith('logout')) return http.Response('', 204);
    if (path.startsWith('otp') ||
        path.startsWith('recover') ||
        path.startsWith('resend')) {
      return _json({});
    }
    if (path.startsWith('verify')) return _json(sessionJson);
    return _json({});
  }

  http.Response _storage(FakeRequest r, String path) {
    if (failing.contains('storage')) return _err(400, 'storage falla');
    if (path.startsWith('object/sign/')) {
      return _json({'signedURL': '/object/sign/fake?token=t'});
    }
    if (path.startsWith('object/list/')) return _json([]);
    if (path.startsWith('object/') && r.method == 'DELETE') return _json([]);
    if (path.startsWith('object/')) {
      if (r.method == 'GET') return http.Response.bytes([1, 2, 3], 200);
      return _json({'Key': path, 'Id': 'obj-1'});
    }
    if (path.startsWith('bucket')) return _json([]);
    return _json({});
  }
}

String fakeJwt({String sub = fakeUserId}) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch ~/
          1000;
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${b64({
        'sub': sub,
        'exp': exp,
        'role': 'authenticated',
        'email': fakeUserEmail
      })}.'
      'firma';
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final req = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    final res = await FakeBackend.instance.handle(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}

class _MemoryStorage extends LocalStorage {
  String? _value;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() async => _value;
  @override
  Future<bool> hasAccessToken() async => _value != null;
  @override
  Future<void> persistSession(String persistSessionString) async =>
      _value = persistSessionString;
  @override
  Future<void> removePersistedSession() async => _value = null;
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _m = {};
  @override
  Future<String?> getItem({required String key}) async => _m[key];
  @override
  Future<void> removeItem({required String key}) async => _m.remove(key);
  @override
  Future<void> setItem({required String key, required String value}) async =>
      _m[key] = value;
}

bool _initialized = false;

/// Inicializa Supabase con el backend falso (una sola vez por isolate) y
/// reinicia su estado. Llamar en `setUp`.
/// Preferencias iniciales que usa [setUpFakeSupabase] (p. ej. onboarding).
Map<String, Object> fakePrefs = {};

Future<FakeBackend> setUpFakeSupabase({bool signedIn = false}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(fakePrefs);
  FakeBackend.instance.reset();
  installFakeGeocoding();
  installFakePlugins();
  geoModo = GeoModo.lugar;
  // Las cachés estáticas de los repositorios guardarían el resultado de un
  // escenario anterior (p. ej. "no encontrado"): se limpian en cada escenario.
  ServiceRepository.clearCache();
  for (final id in const [
    fakeUserId,
    '00000000-0000-4000-8000-0000000000aa',
    'id-1',
    'v_id',
    'v_id_usuario',
    'v_id_trabajador',
  ]) {
    UserRepository.invalidateCachedUser(id);
  }
  if (!_initialized) {
    _initialized = true;
    await Supabase.initialize(
      url: fakeSupabaseUrl,
      publishableKey: 'anon-fake',
      httpClient: _FakeHttpClient(),
      authOptions: FlutterAuthClientOptions(
        localStorage: _MemoryStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      debug: false,
    );
  }
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null && !signedIn) {
    try {
      await auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }
  if (signedIn) await signInFake();
  return FakeBackend.instance;
}

Future<void> signInFake() async {
  await Supabase.instance.client.auth
      .signInWithPassword(email: fakeUserEmail, password: 'valor-de-prueba');
}
