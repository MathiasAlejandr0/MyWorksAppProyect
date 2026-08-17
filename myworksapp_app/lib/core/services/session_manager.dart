import 'package:shared_preferences/shared_preferences.dart';
import '../database/supabase_db.dart';
import '../utils/app_logger.dart';

/// Gestor de sesión apoyado en Supabase Auth.
///
/// La sesión (token + refresh) la persiste `supabase_flutter` automáticamente.
/// Aquí solo cacheamos el rol del usuario para enrutamiento rápido.
class SessionManager {
  static const String _keyUserRole = 'session_user_role';

  static final SessionManager instance = SessionManager._();
  SessionManager._();

  /// Guarda el rol en caché local (la sesión la maneja Supabase).
  Future<void> saveSession(String userId, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserRole, role);
      AppLogger.i('Sesión guardada: userId=$userId, role=$role');
    } catch (e) {
      AppLogger.e('Error al guardar sesión', e);
    }
  }

  /// Retorna el userId si hay una sesión válida en Supabase, null si no.
  Future<String?> restoreSession() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        AppLogger.i('No hay sesión activa en Supabase');
        return null;
      }
      AppLogger.i('Sesión restaurada exitosamente: userId=${user.id}');
      return user.id;
    } catch (e) {
      AppLogger.e('Error al restaurar sesión', e);
      return null;
    }
  }

  /// Obtiene el rol guardado en caché (o el de los metadatos del usuario).
  Future<String?> getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_keyUserRole);
      if (cached != null && cached.isNotEmpty) return cached;
      final meta = supabase.auth.currentUser?.userMetadata;
      return meta?['role'] as String?;
    } catch (e) {
      AppLogger.e('Error al obtener rol guardado', e);
      return null;
    }
  }

  /// Cierra la sesión en Supabase y limpia la caché local.
  Future<void> clearSession() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      AppLogger.e('Error al cerrar sesión en Supabase', e);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserRole);
      AppLogger.i('Sesión limpiada');
    } catch (e) {
      AppLogger.e('Error al limpiar sesión', e);
    }
  }

  /// Verifica si hay una sesión activa en Supabase.
  Future<bool> hasActiveSession() async {
    try {
      return supabase.auth.currentSession != null;
    } catch (e) {
      AppLogger.e('Error general al verificar sesión activa', e);
      return false;
    }
  }

  /// Obtiene los datos de la sesión actual.
  Future<Map<String, String>?> getSessionData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;
      final role = await getSavedRole();
      return {
        'userId': user.id,
        'role': role ?? '',
      };
    } catch (e) {
      AppLogger.e('Error al obtener datos de sesión', e);
      return null;
    }
  }
}
