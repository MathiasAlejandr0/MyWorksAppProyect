import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/models/user_model.dart';
import '../domain/user_role.dart';
import '../exceptions/auth_exceptions.dart';
import '../services/auth_service.dart';
import '../services/notification_realtime_service.dart';
import '../utils/app_logger.dart';
import 'repository_providers.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  UserRole get role => user?.userRole ?? UserRole.cliente;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  StreamSubscription<AuthSessionEvent>? _sessionSub;
  bool _handlingRemoteSignOut = false;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _sessionSub = _authService.sessionChanges.listen(
      _onSessionEvent,
      onError: (Object e, StackTrace st) {
        AppLogger.e('Error en auth stream', e, st);
      },
    );
    ref.onDispose(() => _sessionSub?.cancel());
    return const AuthState();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: UserRole.fromDb(role),
      );

      if (result.emailConfirmationRequired) {
        state = state.copyWith(
          isLoading: false,
          error: const EmailConfirmationRequiredException().userMessage,
        );
        return false;
      }

      final user = result.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: const RegistrationFailedException().userMessage,
        );
        return false;
      }

      await NotificationRealtimeService.instance.subscribe(user.id);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al registrar usuario: $e',
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email: email, password: password);
      await NotificationRealtimeService.instance.subscribe(user.id);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión: $e',
      );
      return false;
    }
  }

  /// Abre el navegador del sistema para Google o Apple (Supabase OAuth).
  Future<bool> loginWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.loginWithOAuth(
        provider == OAuthProvider.apple
            ? SocialAuthProvider.apple
            : SocialAuthProvider.google,
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión social: $e',
      );
      return false;
    }
  }

  /// Completa el inicio de sesión tras el deep link OAuth.
  Future<bool> completeOAuthSession() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.completeOAuthSession();
      await NotificationRealtimeService.instance.subscribe(user.id);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al completar inicio de sesión: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    _handlingRemoteSignOut = true;
    try {
      await NotificationRealtimeService.instance.unsubscribe();
      await _authService.logout();
    } finally {
      state = const AuthState();
      _handlingRemoteSignOut = false;
    }
  }

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.restoreSession();
      if (user == null) {
        state = state.copyWith(isLoading: false, clearUser: true);
        return false;
      }
      await NotificationRealtimeService.instance.subscribe(user.id);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.userMessage,
        clearUser: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al restaurar sesión: $e',
        clearUser: true,
      );
      return false;
    }
  }

  Future<void> loadCurrentUser(String userId, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final user = await _authService.loadUser(userId);
      state = state.copyWith(user: user, isLoading: false);
    } on AppAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar usuario: $e',
      );
    }
  }

  Future<bool> changePassword({required String newPassword}) async {
    try {
      await _authService.changePassword(newPassword);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.userMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cambiar contraseña: $e',
      );
      return false;
    }
  }

  Future<void> _onSessionEvent(AuthSessionEvent event) async {
    if (_handlingRemoteSignOut) return;

    if (!event.isSignedIn) {
      if (state.user != null) {
        await NotificationRealtimeService.instance.unsubscribe();
        state = const AuthState();
      }
      return;
    }

    final userId = event.userId;
    if (userId == null) return;
    if (state.user?.id == userId) return;

    await loadCurrentUser(userId, silent: true);
    await NotificationRealtimeService.instance.subscribe(userId);
  }

}

final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService(
    userRepository: ref.read(userRepositoryProvider),
  );
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
