import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/supabase_db.dart';
import '../../../../core/services/session_manager.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final SessionManager _sessionManager = SessionManager.instance;

  AuthNotifier(this._userRepository) : super(AuthState());

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await supabase.auth.signUp(
        email: email.toLowerCase().trim(),
        password: password,
        data: {'name': name.trim(), 'role': role},
      );

      final authUser = res.user;
      if (authUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo registrar el usuario',
        );
        return false;
      }

      // Si el proyecto exige confirmación por email, no habrá sesión todavía.
      if (res.session == null) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Cuenta creada. Revisa tu correo para confirmarla antes de iniciar sesión.',
        );
        return false;
      }

      await _sessionManager.saveSession(authUser.id, role);
      await loadCurrentUser(authUser.id);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al registrar usuario: ${e.toString()}',
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
      final res = await supabase.auth.signInWithPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      final authUser = res.user;
      if (authUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email o contraseña incorrectos',
        );
        return false;
      }

      final user = await _userRepository.getUserById(authUser.id);
      if (user != null && !user.isActive) {
        await _sessionManager.clearSession();
        state = state.copyWith(
          isLoading: false,
          error: user.isBlocked
              ? 'Tu cuenta está bloqueada. Contacta con soporte'
              : 'Tu cuenta está suspendida',
        );
        return false;
      }

      await _sessionManager.saveSession(authUser.id, user?.role ?? 'user');
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.statusCode == '400'
            ? 'Email o contraseña incorrectos'
            : e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
    state = AuthState();
  }

  /// Restaura la sesión desde Supabase Auth.
  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = await _sessionManager.restoreSession();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final user = await _userRepository.getUserById(userId);
      if (user == null || user.accountStatus != 'active') {
        await _sessionManager.clearSession();
        state = state.copyWith(isLoading: false);
        return false;
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al restaurar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  /// Recarga el usuario desde Supabase. [silent] evita isLoading global.
  Future<void> loadCurrentUser(String userId, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final user = await _userRepository.getUserById(userId);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar usuario: ${e.toString()}',
      );
    }
  }

  /// Cambia la contraseña del usuario autenticado en Supabase Auth.
  Future<bool> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cambiar contraseña: ${e.toString()}',
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(UserRepository());
});
