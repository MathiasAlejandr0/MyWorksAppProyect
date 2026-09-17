import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/oauth_config.dart';
import '../database/models/user_model.dart';
import '../database/repositories/user_repository.dart';
import '../database/supabase_db.dart';
import '../domain/user_role.dart';
import '../exceptions/auth_exceptions.dart';
import 'session_manager.dart';

/// Resultado de un registro. [user] es null si hace falta confirmar el correo.
class AuthRegistrationResult {
  const AuthRegistrationResult({
    this.user,
    this.emailConfirmationRequired = false,
  });

  final UserModel? user;
  final bool emailConfirmationRequired;
}

/// Evento de sesión desacoplado del SDK de Supabase.
class AuthSessionEvent {
  const AuthSessionEvent({
    required this.isSignedIn,
    this.userId,
    this.isInitial = false,
  });

  final bool isSignedIn;
  final String? userId;
  final bool isInitial;
}

enum SocialAuthProvider { google, apple }

/// Contrato de autenticación (capa de datos). La UI no habla con Supabase.
abstract class AuthService {
  Stream<AuthSessionEvent> get sessionChanges;

  String? get currentUserId;

  Future<AuthRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> loginWithOAuth(SocialAuthProvider provider);

  Future<UserModel> completeOAuthSession();

  Future<void> logout();

  Future<UserModel?> restoreSession();

  Future<UserModel?> loadUser(String userId);

  Future<void> changePassword(String newPassword);
}

/// Implementación sobre Supabase Auth + tabla `perfiles`.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({
    required UserRepository userRepository,
    SessionManager? sessionManager,
    SupabaseClient? client,
  })  : _userRepository = userRepository,
        _sessionManager = sessionManager ?? SessionManager.instance,
        _client = client ?? supabase;

  final UserRepository _userRepository;
  final SessionManager _sessionManager;
  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<AuthSessionEvent> get sessionChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final session = data.session;
      return AuthSessionEvent(
        isSignedIn: session != null,
        userId: session?.user.id,
        isInitial: data.event == AuthChangeEvent.initialSession,
      );
    });
  }

  @override
  Future<AuthRegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final safeRole = UserRole.sanitizeForRegistration(role);
    final trimmedName = name.trim();
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final res = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': trimmedName,
          'nombre': trimmedName,
          'role': safeRole.dbValue,
        },
      );

      final authUser = res.user;
      if (authUser == null) {
        throw const RegistrationFailedException();
      }

      if (res.session == null) {
        return const AuthRegistrationResult(emailConfirmationRequired: true);
      }

      await _ensureProfile(
        authUserId: authUser.id,
        name: trimmedName,
        email: normalizedEmail,
        role: safeRole,
      );
      await _sessionManager.saveSession(authUser.id, safeRole.dbValue);
      final profile = await _requireProfile(authUser.id, fallbackRole: safeRole);
      return AuthRegistrationResult(user: profile);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );
      final authUser = res.user;
      if (authUser == null) {
        throw const InvalidCredentialsException();
      }
      return await _finalizeAuthenticatedUser(authUser.id);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> loginWithOAuth(SocialAuthProvider provider) async {
    try {
      await _client.auth.signInWithOAuth(
        provider == SocialAuthProvider.apple
            ? OAuthProvider.apple
            : OAuthProvider.google,
        redirectTo: OAuthConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserModel> completeOAuthSession() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw const SessionExpiredException();
      }
      return await _finalizeAuthenticatedUser(authUser.id);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> logout() async {
    await _sessionManager.clearSession();
  }

  @override
  Future<UserModel?> restoreSession() async {
    try {
      final userId = await _sessionManager.restoreSession();
      if (userId == null) return null;
      return await _finalizeAuthenticatedUser(userId);
    } on AccountInactiveException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserModel?> loadUser(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<UserModel> _finalizeAuthenticatedUser(String authUserId) async {
    final user = await _userRepository.getUserById(authUserId);
    if (user != null && !user.isActive) {
      await _sessionManager.clearSession();
      throw user.isBlocked
          ? AccountInactiveException.blocked()
          : AccountInactiveException.suspended();
    }

    final resolved = user ??
        await _ensureProfileFromAuthUser(authUserId);
    await _sessionManager.saveSession(authUserId, resolved.userRole.dbValue);
    return resolved;
  }

  Future<UserModel> _requireProfile(
    String authUserId, {
    required UserRole fallbackRole,
  }) async {
    final existing = await _userRepository.getUserById(authUserId);
    if (existing != null) return existing;
    final authUser = _client.auth.currentUser;
    return _ensureProfile(
      authUserId: authUserId,
      name: (authUser?.userMetadata?['name'] as String?) ??
          authUser?.email?.split('@').first ??
          'Usuario',
      email: authUser?.email ?? '',
      role: fallbackRole,
    );
  }

  Future<UserModel> _ensureProfileFromAuthUser(String authUserId) async {
    final authUser = _client.auth.currentUser;
    final meta = authUser?.userMetadata ?? const <String, dynamic>{};
    final role = UserRole.sanitizeForRegistration(
      UserRole.fromDb(meta['role'] as String?),
    );
    return _ensureProfile(
      authUserId: authUserId,
      name: (meta['name'] as String?) ??
          (meta['nombre'] as String?) ??
          authUser?.email?.split('@').first ??
          'Usuario',
      email: authUser?.email ?? '',
      role: role,
    );
  }

  Future<UserModel> _ensureProfile({
    required String authUserId,
    required String name,
    required String email,
    required UserRole role,
  }) async {
    final profile = UserModel(
      id: authUserId,
      name: name,
      email: email,
      role: role.dbValue,
      createdAt: DateTime.now().toUtc(),
    );
    await _userRepository.createUser(profile);
    return await _userRepository.getUserById(authUserId) ?? profile;
  }

  AppAuthException _mapError(Object error) {
    if (error is AppAuthException) return error;

    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login') ||
          message.contains('invalid credentials') ||
          message.contains('invalid email or password') ||
          error.statusCode == '400') {
        return InvalidCredentialsException(error);
      }
      if (message.contains('email not confirmed')) {
        return EmailConfirmationRequiredException(error);
      }
      if (message.contains('already registered') ||
          message.contains('user already')) {
        return EmailAlreadyRegisteredException(error);
      }
      if (message.contains('network') ||
          message.contains('failed host lookup') ||
          message.contains('socket')) {
        return AuthNetworkException(error);
      }
      return AuthUnexpectedException(error.message, error);
    }

    if (error is TimeoutException) {
      return AuthNetworkException(error);
    }

    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup') ||
        text.contains('clientexception')) {
      return AuthNetworkException(error);
    }

    return AuthUnexpectedException(
      'Ocurrió un error inesperado. Intenta nuevamente.',
      error,
    );
  }

}
