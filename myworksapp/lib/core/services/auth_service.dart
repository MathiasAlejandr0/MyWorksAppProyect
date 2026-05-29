import 'package:uuid/uuid.dart';
import '../database/repositories/user_repository.dart';
import '../database/models/user_model.dart';
import '../utils/password_hasher.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import '../utils/constants.dart';
import 'session_manager.dart';

/// Servicio de autenticación
/// 
/// Maneja toda la lógica de autenticación:
/// - Registro de usuarios
/// - Login
/// - Restauración de sesión
/// - Logout
/// - Validación de cuentas bloqueadas/suspendidas
/// 
/// Usa SHA-256 para hash de contraseñas y SessionManager para persistencia.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final UserRepository _userRepository = UserRepository();
  final SessionManager _sessionManager = SessionManager.instance;

  /// Registra un nuevo usuario
  /// 
  /// Retorna el usuario creado o null si falla.
  /// Lanza AppError si hay problemas de validación.
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      AppLogger.i('Iniciando registro para: $email');

      // Validar rol
      if (role != AppConstants.roleUser && role != AppConstants.roleWorker) {
        throw AppError.validation('Rol inválido: $role');
      }

      // Verificar si el usuario ya existe
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser != null) {
        throw AppError.validation('El email ya está registrado');
      }

      // Validar contraseña (mínimo 6 caracteres)
      if (password.length < 6) {
        throw AppError.validation('La contraseña debe tener al menos 6 caracteres');
      }

      // Crear nuevo usuario con contraseña hasheada (bcrypt)
      final passwordHash = PasswordHasher.hashPassword(password);
      final user = UserModel(
        id: const Uuid().v4(),
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password: passwordHash,
        role: role,
        accountStatus: 'active',
        createdAt: DateTime.now(),
      );

      // Guardar en base de datos
      await _userRepository.createUser(user);
      
      // Guardar sesión
      await _sessionManager.saveSession(user.id, user.role);
      
      AppLogger.i('Usuario registrado exitosamente: ${user.id}');
      return user;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al registrar usuario', e);
      throw AppError.authentication('Error al registrar usuario: ${e.toString()}');
    }
  }

  /// Inicia sesión con email y contraseña
  /// 
  /// Retorna el usuario si las credenciales son correctas.
  /// Lanza AppError si las credenciales son incorrectas o la cuenta está bloqueada.
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Iniciando login para: $email');

      // Buscar usuario por email
      final user = await _userRepository.getUserByEmail(email);
      if (user == null) {
        throw AppError.authentication('Email o contraseña incorrectos');
      }

      // Verificar contraseña (soporta bcrypt y SHA-256 legacy)
      if (user.password == null || user.password!.isEmpty) {
        throw AppError.authentication('Email o contraseña incorrectos');
      }
      
      final isValidPassword = PasswordHasher.verifyPassword(password, user.password!);
      if (!isValidPassword) {
        throw AppError.authentication('Email o contraseña incorrectos');
      }

      // Migración automática: Si el hash es SHA-256 (legacy), migrar a bcrypt
      if (PasswordHasher.needsMigration(user.password!)) {
        AppLogger.i('Migrando hash de contraseña de SHA-256 a bcrypt para usuario: ${user.id}');
        try {
          final newHash = PasswordHasher.migrateToBcrypt(password, user.password!);
          if (newHash != null) {
            // Actualizar el hash en la base de datos
            final updatedUser = user.copyWith(password: newHash);
            await _userRepository.updateUser(updatedUser);
            AppLogger.i('Hash migrado exitosamente a bcrypt');
          }
        } catch (e) {
          AppLogger.e('Error al migrar hash, continuando con login', e);
          // No fallar el login si la migración falla
        }
      }

      // Verificar estado de cuenta
      if (user.accountStatus == 'blocked') {
        throw AppError.authentication('Tu cuenta ha sido bloqueada. Contacta al soporte.');
      }

      if (user.accountStatus == 'suspended') {
        throw AppError.authentication('Tu cuenta ha sido suspendida temporalmente.');
      }

      // Guardar sesión
      await _sessionManager.saveSession(user.id, user.role);
      
      AppLogger.i('Login exitoso para usuario: ${user.id}');
      return user;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al hacer login', e);
      throw AppError.authentication('Error al iniciar sesión: ${e.toString()}');
    }
  }

  /// Restaura la sesión desde el almacenamiento persistente
  /// 
  /// Retorna el usuario si hay una sesión activa válida.
  Future<UserModel?> restoreSession() async {
    try {
      AppLogger.i('Restaurando sesión...');

      // Verificar si hay sesión activa
      final hasActiveSession = await _sessionManager.hasActiveSession();
      if (!hasActiveSession) {
        AppLogger.i('No hay sesión activa');
        return null;
      }

      // Obtener datos de sesión
      final sessionData = await _sessionManager.getSessionData();
      if (sessionData == null) {
        AppLogger.w('Datos de sesión no encontrados');
        return null;
      }

      final userId = sessionData['userId'];
      if (userId == null) {
        AppLogger.w('UserId no encontrado en sesión');
        return null;
      }

      // Cargar usuario desde BD
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        AppLogger.w('Usuario no encontrado en BD, limpiando sesión');
        await _sessionManager.clearSession();
        return null;
      }

      // Verificar estado de cuenta
      if (user.accountStatus == 'blocked' || user.accountStatus == 'suspended') {
        AppLogger.w('Cuenta bloqueada/suspendida, limpiando sesión');
        await _sessionManager.clearSession();
        return null;
      }

      AppLogger.i('Sesión restaurada para usuario: ${user.id}');
      return user;
    } catch (e) {
      AppLogger.e('Error al restaurar sesión', e);
      // Limpiar sesión en caso de error
      await _sessionManager.clearSession();
      return null;
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    try {
      AppLogger.i('Cerrando sesión...');
      await _sessionManager.clearSession();
      AppLogger.i('Sesión cerrada');
    } catch (e) {
      AppLogger.e('Error al cerrar sesión', e);
      // Intentar limpiar de todas formas
      await _sessionManager.clearSession();
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    return await _sessionManager.hasActiveSession();
  }

  /// Obtiene el usuario actual desde la sesión
  Future<UserModel?> getCurrentUser() async {
    final sessionData = await _sessionManager.getSessionData();
    if (sessionData == null) return null;

    final userId = sessionData['userId'];
    if (userId == null) return null;

    return await _userRepository.getUserById(userId);
  }

  /// Valida si un email está disponible
  Future<bool> isEmailAvailable(String email) async {
    try {
      final user = await _userRepository.getUserByEmail(email);
      return user == null;
    } catch (e) {
      AppLogger.e('Error al verificar disponibilidad de email', e);
      return false;
    }
  }
}

