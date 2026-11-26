// Pruebas de AuthNotifier (authProvider) con un AuthService falso: registro,
// login, OAuth, restauración de sesión, carga de usuario, cambio de clave,
// logout y eventos de sesión, en sus caminos de éxito y de error.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/user_model.dart';
import 'package:myworksapp/core/exceptions/auth_exceptions.dart';
import 'package:myworksapp/core/providers/auth_provider.dart';
import 'package:myworksapp/core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

enum _Modo { ok, appError, otroError, sinUsuario, confirmar }

class _FakeAuth implements AuthService {
  _Modo modo = _Modo.ok;
  final events = StreamController<AuthSessionEvent>.broadcast();
  int logouts = 0;

  UserModel get _user => UserModel.fromMap(sampleUserModel);

  Future<T> _run<T>(T Function() ok) async {
    switch (modo) {
      case _Modo.appError:
        throw const InvalidCredentialsException();
      case _Modo.otroError:
        throw StateError('falla');
      default:
        return ok();
    }
  }

  @override
  Stream<AuthSessionEvent> get sessionChanges => events.stream;

  @override
  String? get currentUserId => fakeUserId;

  @override
  Future<AuthRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required role,
  }) =>
      _run(() => switch (modo) {
            _Modo.sinUsuario => const AuthRegistrationResult(),
            _Modo.confirmar =>
              const AuthRegistrationResult(emailConfirmationRequired: true),
            _ => AuthRegistrationResult(user: _user),
          });

  @override
  Future<UserModel> login({required String email, required String password}) =>
      _run(() => _user);

  @override
  Future<void> loginWithOAuth(SocialAuthProvider provider) => _run(() {});

  @override
  Future<UserModel> completeOAuthSession() => _run(() => _user);

  @override
  Future<void> logout() async => logouts++;

  @override
  Future<UserModel?> restoreSession() =>
      _run(() => modo == _Modo.sinUsuario ? null : _user);

  @override
  Future<UserModel?> loadUser(String userId) => _run(() => _user);

  @override
  Future<void> changePassword(String newPassword) => _run(() {});
}

void main() {
  late _FakeAuth auth;
  late ProviderContainer c;
  AuthNotifier n() => c.read(authProvider.notifier);
  AuthState s() => c.read(authProvider);

  setUpAll(() async {
    await setUpFakeSupabase();
  });

  setUp(() {
    auth = _FakeAuth();
    c = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    c.read(authProvider);
  });

  tearDown(() => c.dispose());

  test('register: éxito, confirmación, sin usuario y errores', () async {
    Future<bool> reg() => n()
        .register(name: 'Ana', email: 'a@b.cl', password: 'x', role: 'usuario');
    expect(await reg(), isTrue);
    expect(s().user, isNotNull);
    auth.modo = _Modo.confirmar;
    expect(await reg(), isFalse);
    expect(s().error, isNotNull);
    auth.modo = _Modo.sinUsuario;
    expect(await reg(), isFalse);
    auth.modo = _Modo.appError;
    expect(await reg(), isFalse);
    auth.modo = _Modo.otroError;
    expect(await reg(), isFalse);
    expect(s().error, contains('Error al registrar usuario'));
  });

  test('login y OAuth en éxito y error', () async {
    for (final m in [_Modo.ok, _Modo.appError, _Modo.otroError]) {
      auth.modo = m;
      final ok = m == _Modo.ok;
      expect(await n().login(email: 'a@b.cl', password: 'x'), ok);
      expect(await n().loginWithOAuth(OAuthProvider.google), ok);
      expect(await n().loginWithOAuth(OAuthProvider.apple), ok);
      expect(await n().completeOAuthSession(), ok);
      expect(s().isLoading, ok ? isA<bool>() : isFalse);
    }
  });

  test('restoreSession, loadCurrentUser y changePassword', () async {
    expect(await n().restoreSession(), isTrue);
    auth.modo = _Modo.sinUsuario;
    expect(await n().restoreSession(), isFalse);
    expect(s().user, isNull);
    for (final m in [_Modo.ok, _Modo.appError, _Modo.otroError]) {
      auth.modo = m;
      if (m != _Modo.ok) expect(await n().restoreSession(), isFalse);
      await n().loadCurrentUser(fakeUserId);
      await n().loadCurrentUser(fakeUserId, silent: true);
      expect(
          await n().changePassword(newPassword: 'nueva-clave'), m == _Modo.ok);
    }
  });

  test('logout limpia el estado', () async {
    await n().login(email: 'a@b.cl', password: 'x');
    await n().logout();
    expect(s().user, isNull);
    expect(auth.logouts, 1);
  });

  test('eventos de sesión: recuperación, cierre remoto y nuevo usuario',
      () async {
    Future<void> emit(AuthSessionEvent e) async {
      auth.events.add(e);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    await emit(
        const AuthSessionEvent(isSignedIn: true, passwordRecovery: true));
    expect(s().recoveringPassword, isTrue);
    await emit(const AuthSessionEvent(isSignedIn: true, userId: fakeUserId));
    expect(s().user, isNotNull);
    // Mismo usuario: no recarga.
    await emit(const AuthSessionEvent(isSignedIn: true, userId: fakeUserId));
    await emit(const AuthSessionEvent(isSignedIn: false));
    expect(s().user, isNull);
    await emit(const AuthSessionEvent(isSignedIn: false));
    auth.events.addError(StateError('stream'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
}
