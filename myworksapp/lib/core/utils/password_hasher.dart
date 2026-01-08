import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import '../utils/app_logger.dart';

/// Hasher unificado de contraseñas con soporte para múltiples algoritmos
/// 
/// Algoritmos soportados:
/// - bcrypt (actual, recomendado) - Prefijo: $2a$ o $2b$
/// - SHA-256 (legacy, compatibilidad) - Prefijo: sha256:
/// 
/// Migración automática:
/// - Detecta contraseñas SHA-256 en login
/// - Re-hashea automáticamente con bcrypt
/// - Actualiza el hash en la base de datos
class PasswordHasher {
  // Prefijos para identificar el algoritmo
  static const String _bcryptPrefix = r'$2';
  static const String _sha256Prefix = 'sha256:';
  
  // Cost factor para bcrypt (10-12 recomendado, 10 es balance entre seguridad y performance)
  static const int _bcryptRounds = 10;

  /// Genera un hash seguro de la contraseña usando bcrypt
  /// 
  /// Retorna un hash bcrypt con formato: $2a$10$salt+hash
  /// Este hash incluye el salt y es único para cada contraseña.
  static String hashPassword(String password) {
    try {
      AppLogger.i('Generando hash bcrypt para contraseña');
      
      // Validar que la contraseña no esté vacía
      if (password.isEmpty) {
        throw ArgumentError('La contraseña no puede estar vacía');
      }

      // Generar hash bcrypt con salt automático
      // BCrypt genera un salt único por defecto
      // Nota: BCrypt.gensalt() no acepta rounds directamente, usa el default
      final salt = BCrypt.gensalt();
      final hash = BCrypt.hashpw(password, salt);
      
      AppLogger.i('Hash bcrypt generado exitosamente');
      return hash;
    } catch (e) {
      AppLogger.e('Error al generar hash bcrypt', e);
      rethrow;
    }
  }

  /// Verifica si una contraseña coincide con el hash
  /// 
  /// Soporta:
  /// - Hash bcrypt (formato actual)
  /// - Hash SHA-256 (formato legacy, para compatibilidad)
  /// 
  /// Retorna true si la contraseña es correcta, false en caso contrario.
  static bool verifyPassword(String password, String storedHash) {
    try {
      if (password.isEmpty || storedHash.isEmpty) {
        return false;
      }

      // Detectar el tipo de hash
      if (_isBcryptHash(storedHash)) {
        // Hash bcrypt (formato actual)
        return BCrypt.checkpw(password, storedHash);
      } else if (_isSha256Hash(storedHash)) {
        // Hash SHA-256 (formato legacy)
        return _verifySha256Password(password, storedHash);
      } else {
        // Hash sin prefijo (asumir SHA-256 legacy sin prefijo)
        // Esto es para compatibilidad con usuarios existentes
        AppLogger.w('Hash sin prefijo detectado, asumiendo SHA-256 legacy');
        return _verifySha256PasswordLegacy(password, storedHash);
      }
    } catch (e) {
      AppLogger.e('Error al verificar contraseña', e);
      return false;
    }
  }

  /// Verifica si un hash es de tipo bcrypt
  /// 
  /// Los hashes bcrypt comienzan con $2a$, $2b$, $2x$ o $2y$
  static bool _isBcryptHash(String hash) {
    return hash.startsWith(_bcryptPrefix);
  }

  /// Verifica si un hash es de tipo SHA-256 (con prefijo)
  static bool _isSha256Hash(String hash) {
    return hash.startsWith(_sha256Prefix);
  }

  /// Verifica una contraseña con hash SHA-256 (formato con prefijo)
  static bool _verifySha256Password(String password, String storedHash) {
    // Remover el prefijo
    final hashWithoutPrefix = storedHash.substring(_sha256Prefix.length);
    
    // Generar hash SHA-256 de la contraseña
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final passwordHash = digest.toString();
    
    // Comparar
    return passwordHash == hashWithoutPrefix;
  }

  /// Verifica una contraseña con hash SHA-256 (formato legacy sin prefijo)
  /// 
  /// Esto es para compatibilidad con usuarios existentes que tienen
  /// hashes SHA-256 sin el prefijo "sha256:"
  static bool _verifySha256PasswordLegacy(String password, String storedHash) {
    // Generar hash SHA-256 de la contraseña
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final passwordHash = digest.toString();
    
    // Comparar directamente (sin prefijo)
    return passwordHash == storedHash;
  }

  /// Migra un hash SHA-256 a bcrypt
  /// 
  /// Este método se usa cuando se detecta un hash SHA-256 en login.
  /// Se verifica la contraseña, y si es correcta, se genera un nuevo hash bcrypt.
  /// 
  /// Retorna el nuevo hash bcrypt, o null si la contraseña no es correcta.
  static String? migrateToBcrypt(String password, String oldHash) {
    try {
      // Verificar que la contraseña sea correcta con el hash antiguo
      if (!verifyPassword(password, oldHash)) {
        AppLogger.w('Contraseña incorrecta, no se puede migrar');
        return null;
      }

      // Generar nuevo hash bcrypt
      final newHash = hashPassword(password);
      AppLogger.i('Hash migrado de SHA-256 a bcrypt exitosamente');
      return newHash;
    } catch (e) {
      AppLogger.e('Error al migrar hash a bcrypt', e);
      return null;
    }
  }

  /// Verifica si un hash necesita migración
  /// 
  /// Retorna true si el hash es SHA-256 (legacy) y debe migrarse a bcrypt.
  static bool needsMigration(String storedHash) {
    return !_isBcryptHash(storedHash);
  }

  /// Obtiene información sobre el algoritmo usado en un hash
  static String getHashAlgorithm(String storedHash) {
    if (_isBcryptHash(storedHash)) {
      return 'bcrypt';
    } else if (_isSha256Hash(storedHash)) {
      return 'sha256 (con prefijo)';
    } else {
      return 'sha256 (legacy sin prefijo)';
    }
  }
}

