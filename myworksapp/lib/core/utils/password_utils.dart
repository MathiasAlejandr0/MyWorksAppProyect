import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilidades para manejo seguro de contraseñas
class PasswordUtils {
  /// Genera un hash SHA-256 de la contraseña
  /// En producción, usar bcrypt o argon2
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica si una contraseña coincide con el hash
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Genera un código de recuperación de 6 dígitos
  static String generateResetCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = (random % 900000 + 100000).toString();
    return code;
  }

  /// Valida formato de código (6 dígitos)
  static bool isValidResetCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }
}

