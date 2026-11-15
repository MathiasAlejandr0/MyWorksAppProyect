import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/user_model.dart';
import 'package:myworksapp/core/domain/user_role.dart';
import 'package:myworksapp/core/exceptions/auth_exceptions.dart';
import 'package:myworksapp/core/services/auth_service.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService();

  final _controller = StreamController<AuthSessionEvent>.broadcast();
  UserModel? storedUser;
  AppAuthException? nextError;
  bool emailConfirmation = false;
  int logoutCalls = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _controller.stream;

  @override
  String? get currentUserId => storedUser?.id;

  @override
  Future<void> changePassword(String newPassword) async {}

  @override
  Future<UserModel> completeOAuthSession() {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> loadUser(String userId) async => storedUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (nextError != null) throw nextError!;
    storedUser = UserModel(
      id: 'u1',
      name: 'Ana',
      email: email,
      role: UserRole.cliente.dbValue,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    return storedUser!;
  }

  @override
  Future<void> loginWithOAuth(SocialAuthProvider provider) async {}

  @override
  Future<void> logout() async {
    logoutCalls++;
    storedUser = null;
  }

  @override
  Future<AuthRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (nextError != null) throw nextError!;
    if (emailConfirmation) {
      return const AuthRegistrationResult(emailConfirmationRequired: true);
    }
    storedUser = UserModel(
      id: 'u1',
      name: name,
      email: email,
      role: UserRole.sanitizeForRegistration(role).dbValue,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    return AuthRegistrationResult(user: storedUser);
  }

  @override
  Future<UserModel?> restoreSession() async => storedUser;
}

void main() {
  test('FakeAuthService registra con rol de especialista sanitizado', () async {
    final service = _FakeAuthService();
    final result = await service.register(
      name: 'Luis',
      email: 'luis@demo.com',
      password: List.filled(8, 'a').join(),
      role: UserRole.especialista,
    );
    expect(result.user?.userRole, UserRole.especialista);
  });

  test('FakeAuthService no permite admin por el enum de registro', () async {
    final service = _FakeAuthService();
    final result = await service.register(
      name: 'Hacker',
      email: 'h@demo.com',
      password: List.filled(8, 'a').join(),
      role: UserRole.administrador,
    );
    expect(result.user?.userRole, UserRole.cliente);
  });

  test('FakeAuthService traduce credenciales inválidas', () async {
    final service = _FakeAuthService()
      ..nextError = const InvalidCredentialsException();
    expect(
      () => service.login(email: 'a@a.com', password: 'x'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });
}
