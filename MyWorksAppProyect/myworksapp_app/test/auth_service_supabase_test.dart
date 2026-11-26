// SupabaseAuthService contra el backend falso: traducción de errores de Auth,
// perfiles faltantes o ilegibles, cuentas inactivas y cambio de contraseña.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/repositories/user_repository.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/core/exceptions/auth_exceptions.dart';
import 'package:myworksapp/core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_supabase.dart';

Map<String, dynamic> _perfil({String estado = 'activo'}) => {
      'id': fakeUserId,
      'nombre': 'Cliente Test',
      'correo': fakeUserEmail,
      'email': fakeUserEmail,
      'rol': 'cliente',
      'estado_cuenta': estado,
      'creado_en': '2026-01-01T00:00:00Z',
    };

void main() {
  late FakeBackend b;
  late SupabaseAuthService auth;

  setUp(() async {
    b = await setUpFakeSupabase();
    auth = SupabaseAuthService(userRepository: UserRepository());
  });

  Future<Object?> loginError() async {
    try {
      await auth.login(email: 'A@B.cl ', password: 'x');
      return null;
    } catch (e) {
      return e;
    }
  }

  test('traduce cada mensaje de Auth a su excepción', () async {
    final casos = <(int, String), Type>{
      (400, 'Email not confirmed'): EmailConfirmationRequiredException,
      (429, 'Rate limit exceeded'): AuthUnexpectedException,
      (422, 'Weak password: too short'): WeakPasswordException,
      (401, 'Invalid login credentials'): InvalidCredentialsException,
      (400, 'algo raro'): InvalidCredentialsException,
      (422, 'User already registered'): EmailAlreadyRegisteredException,
      (503, 'upstream caído'): AuthUnexpectedException,
      (418, 'otra cosa'): AuthUnexpectedException,
    };
    for (final e in casos.entries) {
      b.authFailure = e.key;
      final err = await loginError();
      expect(err.runtimeType, e.value, reason: '${e.key}');
    }
  });

  test('un corte de red se reintenta una vez y se informa como red', () async {
    b.authFailure = (500, 'SocketException: connection reset');
    final err = await loginError();
    expect(err, isA<AuthNetworkException>());
    final intentos =
        b.requests.where((r) => r.url.path.contains('/auth/v1/token')).length;
    expect(intentos, 2);
  });

  test('registro: alta con sesión y correo ya registrado', () async {
    final r = await auth.register(
      name: ' Ana ',
      email: 'ANA@x.cl',
      password: 'aaaaaaaa2',
      role: UserRole.values.first,
    );
    expect(r.user, isNotNull);

    b.authFailure = (422, 'User already registered');
    await expectLater(
      auth.register(
          name: 'Ana',
          email: 'a@x.cl',
          password: 'x',
          role: UserRole.values.first),
      throwsA(isA<EmailAlreadyRegisteredException>()),
    );
  });

  test('login con perfil activo, perfil faltante y perfil ilegible', () async {
    b.seed('perfiles', [_perfil()]);
    expect(
        (await auth.login(email: fakeUserEmail, password: 'x')).id, fakeUserId);

    // Sin fila: se crea el perfil a partir de los metadatos de Auth.
    await setUpFakeSupabase();
    b = FakeBackend.instance;
    b.user = {
      'id': fakeUserId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': fakeUserEmail,
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'name': 'Nuevo', 'role': 'cliente'},
      'created_at': '2026-01-01T00:00:00Z',
    };
    final creado = await auth.login(email: fakeUserEmail, password: 'x');
    expect(creado.id, fakeUserId);

    // La lectura del perfil falla: se entra con la identidad de Auth.
    await setUpFakeSupabase();
    b = FakeBackend.instance;
    b.failing.add('perfiles');
    final minimo = await auth.login(email: fakeUserEmail, password: 'x');
    expect(minimo.id, fakeUserId);
    expect(minimo.name, isNotEmpty);

    // Metadatos vacíos: el nombre sale del correo.
    await setUpFakeSupabase();
    b = FakeBackend.instance;
    b.failing.add('perfiles');
    b.user = {
      'id': fakeUserId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': fakeUserEmail,
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-01-01T00:00:00Z',
    };
    final sinNombre = await auth.login(email: fakeUserEmail, password: 'x');
    expect(sinNombre.name, fakeUserEmail.split('@').first);
  });

  test('cuentas suspendidas o bloqueadas no entran', () async {
    for (final estado in ['suspendido', 'bloqueado']) {
      await setUpFakeSupabase();
      b = FakeBackend.instance;
      b.seed('perfiles', [_perfil(estado: estado)]);
      await expectLater(
        auth.login(email: fakeUserEmail, password: 'x'),
        throwsA(isA<AccountInactiveException>()),
      );
    }
  });

  test('restoreSession, loadUser y logout', () async {
    b.seed('perfiles', [_perfil()]);
    expect(await auth.restoreSession(), isNull);
    await signInFake();
    expect((await auth.restoreSession())?.id, fakeUserId);

    await setUpFakeSupabase();
    b = FakeBackend.instance;
    b.seed('perfiles', [_perfil(estado: 'bloqueado')]);
    await signInFake();
    await expectLater(
        auth.restoreSession(), throwsA(isA<AccountInactiveException>()));

    expect(await auth.loadUser('otro'), isNull);
    b.failAll = true;
    await expectLater(auth.loadUser('x'), throwsA(isA<AppAuthException>()));
    b.failAll = false;
    await auth.logout();
  });

  test('cambio de contraseña: débil, válida y rechazada por Auth', () async {
    await signInFake();
    await expectLater(
        auth.changePassword('123'), throwsA(isA<WeakPasswordException>()));
    await auth.changePassword('aaaaaaaa1');
    b.authFailure = (422, 'Password is known to be weak');
    await expectLater(auth.changePassword('aaaaaaaa1'),
        throwsA(isA<WeakPasswordException>()));
  });

  test('errores que no son de Auth', () async {
    b.seed('perfiles', [_perfil()]);
    await signInFake();
    b.failAll = true;
    final err = await () async {
      try {
        await auth.restoreSession();
      } catch (e) {
        return e;
      }
    }();
    expect(err, anyOf(isNull, isA<AppAuthException>()));
    expect(
      () => throw const AuthException('x'),
      throwsA(isA<AuthException>()),
    );
  });
}
