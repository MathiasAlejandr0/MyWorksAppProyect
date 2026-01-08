import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../database/repositories/user_repository.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';

/// Gestor de sesión persistente
class SessionManager {
  static const String _keyUserId = 'session_user_id';
  static const String _keyUserRole = 'session_user_role';
  
  static final SessionManager instance = SessionManager._();
  SessionManager._();

  final UserRepository _userRepository = UserRepository();

  /// Guarda la sesión del usuario
  Future<void> saveSession(String userId, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserRole, role);
      AppLogger.i('Sesión guardada: userId=$userId, role=$role');
    } catch (e) {
      AppLogger.e('Error al guardar sesión', e);
      rethrow;
    }
  }

  /// Restaura la sesión del usuario
  /// Retorna el userId si la sesión es válida, null si no hay sesión o es inválida
  Future<String?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      
      if (userId == null) {
        AppLogger.i('No hay sesión guardada');
        return null;
      }

      // Verificar que el usuario existe y está activo
      final user = await _userRepository.getUserById(userId);
      
      if (user == null) {
        AppLogger.w('Usuario de sesión no encontrado, limpiando sesión');
        await clearSession();
        return null;
      }

      // Verificar estado de cuenta
      if (user.accountStatus != 'active') {
        AppLogger.w('Usuario suspendido/bloqueado, limpiando sesión');
        await clearSession();
        return null;
      }

      AppLogger.i('Sesión restaurada exitosamente: userId=$userId');
      return userId;
    } catch (e) {
      AppLogger.e('Error al restaurar sesión', e);
      await clearSession();
      return null;
    }
  }

  /// Obtiene el rol guardado en la sesión
  Future<String?> getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserRole);
    } catch (e) {
      AppLogger.e('Error al obtener rol guardado', e);
      return null;
    }
  }

  /// Limpia la sesión
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserRole);
      AppLogger.i('Sesión limpiada');
    } catch (e) {
      AppLogger.e('Error al limpiar sesión', e);
    }
  }

  /// Verifica si hay una sesión activa
  /// 
  /// Con manejo robusto de errores y reintentos para evitar falsos negativos.
  Future<bool> hasActiveSession() async {
    try {
      // Primero verificar SharedPreferences (rápido y confiable)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      if (userId == null) {
        AppLogger.d('No hay userId en SharedPreferences');
        return false;
      }

      // Asegurar que la base de datos esté lista antes de hacer queries
      final dbHelper = DatabaseHelper.instance;
      if (!await dbHelper.isReady()) {
        AppLogger.w('Base de datos no está lista, esperando inicialización...');
        // Esperar a que la BD esté lista (con timeout)
        try {
          await dbHelper.database.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Timeout esperando inicialización de BD');
            },
          );
        } catch (e) {
          AppLogger.e('Error al esperar inicialización de BD', e);
          // Si hay datos de sesión guardados, asumir que la sesión es válida
          // en lugar de retornar false y cerrar sesión
          AppLogger.w('Asumiendo sesión válida basada en SharedPreferences');
          return true;
        }
      }
      
      // Verificar que el usuario existe y está activo
      try {
        final user = await _userRepository.getUserById(userId).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            AppLogger.w('Timeout al obtener usuario de BD');
            return null;
          },
        );
        
        if (user == null) {
          AppLogger.w('Usuario no encontrado en BD: $userId');
          return false;
        }
        
        if (user.accountStatus != 'active') {
          AppLogger.w('Usuario no está activo: ${user.accountStatus}');
          return false;
        }
        
        return true;
      } catch (e) {
        AppLogger.e('Error al obtener usuario de BD', e);
        // Si hay userId guardado pero hay error temporal, asumir sesión válida
        // para evitar cerrar sesión por errores temporales
        AppLogger.w('Error temporal al verificar usuario, asumiendo sesión válida');
        return true;
      }
    } catch (e) {
      AppLogger.e('Error general al verificar sesión activa', e);
      // En caso de error general, verificar si hay datos de sesión guardados
      // Si hay, asumir que la sesión es válida para evitar logout innecesario
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(_keyUserId);
        if (userId != null && userId.isNotEmpty) {
          AppLogger.w('Error al verificar sesión pero hay datos guardados, asumiendo válida');
          return true;
        }
      } catch (_) {
        // Ignorar errores al acceder a SharedPreferences
      }
      return false;
    }
  }

  /// Obtiene los datos de la sesión
  Future<Map<String, String>?> getSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_keyUserId);
      final role = prefs.getString(_keyUserRole);
      
      if (userId == null) return null;
      
      return {
        'userId': userId,
        'role': role ?? '',
      };
    } catch (e) {
      AppLogger.e('Error al obtener datos de sesión', e);
      return null;
    }
  }
}

