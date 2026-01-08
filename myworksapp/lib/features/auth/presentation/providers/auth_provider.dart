import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/utils/password_utils.dart';
import '../../../../core/services/session_manager.dart';
import 'package:uuid/uuid.dart';

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
      // Verificar si el usuario ya existe
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser != null) {
        state = state.copyWith(
          isLoading: false,
          error: 'El email ya está registrado',
        );
        return false;
      }

      // Crear nuevo usuario con contraseña hasheada
      final passwordHash = PasswordUtils.hashPassword(password);
      final user = UserModel(
        id: const Uuid().v4(),
        name: name,
        email: email.toLowerCase().trim(),
        password: passwordHash,
        role: role,
        accountStatus: 'active',
        createdAt: DateTime.now(),
      );

      await _userRepository.createUser(user);
      
      // Guardar sesión
      await _sessionManager.saveSession(user.id, user.role);
      
      state = state.copyWith(user: user, isLoading: false);
      return true;
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
      final user = await _userRepository.getUserByEmail(email);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email o contraseña incorrectos',
        );
        return false;
      }

      // Verificar estado de cuenta
      if (!user.isActive) {
        String errorMessage = 'Tu cuenta está suspendida';
        if (user.isBlocked) {
          errorMessage = 'Tu cuenta está bloqueada. Contacta con soporte';
        }
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
        return false;
      }

      // Verificar contraseña
      if (user.password == null) {
        // Usuario antiguo sin contraseña (compatibilidad)
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }

      if (!PasswordUtils.verifyPassword(password, user.password!)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email o contraseña incorrectos',
        );
        return false;
      }

      // Guardar sesión
      await _sessionManager.saveSession(user.id, user.role);

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al iniciar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Limpiar sesión
    await _sessionManager.clearSession();
    
    // Limpiar estado
    state = AuthState();
  }

  /// Restaura la sesión desde SharedPreferences
  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final userId = await _sessionManager.restoreSession();
      
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Cargar usuario desde la base de datos
      final user = await _userRepository.getUserById(userId);
      
      if (user == null || user.accountStatus != 'active') {
        // Si el usuario no existe o no está activo, limpiar sesión
        await _sessionManager.clearSession();
        state = state.copyWith(isLoading: false);
        return false;
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      await _sessionManager.clearSession();
      state = state.copyWith(
        isLoading: false,
        error: 'Error al restaurar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> loadCurrentUser(String userId) async {
    state = state.copyWith(isLoading: true);
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

  /// Cambia la contraseña de un usuario
  Future<bool> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final passwordHash = PasswordUtils.hashPassword(newPassword);
      await _userRepository.updatePassword(userId, passwordHash);
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

