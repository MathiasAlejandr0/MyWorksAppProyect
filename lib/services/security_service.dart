import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _salt = "MyWorksApp2024!";
  static const String _keyToken = "auth_token";
  static const String _keyUserId = "user_id";
  static const String _keyUserData = "user_data";

  // Encriptar contraseña con salt
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verificar contraseña
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  // Generar token de sesión
  static String generateSessionToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = "$userId:$timestamp:$_salt";
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validar email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validar teléfono (formato chileno)
  static bool isValidPhone(String phone) {
    // Acepta formatos: +56912345678, 912345678, 91234567
    final phoneRegex = RegExp(r'^(\+56)?[9][0-9]{8}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Validar contraseña
  static bool isValidPassword(String password) {
    // Mínimo 8 caracteres, al menos una letra y un número
    return password.length >= 8 &&
        RegExp(r'[a-zA-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Guardar token de autenticación
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  // Obtener token de autenticación
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Guardar ID de usuario
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  // Obtener ID de usuario
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Guardar datos de usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(userData);
    await prefs.setString(_keyUserData, jsonData);
  }

  // Obtener datos de usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_keyUserData);
    if (jsonData != null) {
      return jsonDecode(jsonData) as Map<String, dynamic>;
    }
    return null;
  }

  // Limpiar datos de sesión
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserData);
  }

  // Verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null;
  }

  // Sanitizar entrada de texto
  static String sanitizeInput(String input) {
    // Remover caracteres peligrosos para SQL injection
    return input
        .replaceAll("'", "''")
        .replaceAll('"', '""')
        .replaceAll(';', '')
        .replaceAll('--', '')
        .replaceAll('/*', '')
        .replaceAll('*/', '')
        .trim();
  }

  // Validar dirección
  static bool isValidAddress(String address) {
    return address.length >= 10 && address.length <= 200;
  }

  // Validar descripción de trabajo
  static bool isValidWorkDescription(String description) {
    return description.length >= 10 && description.length <= 1000;
  }

  // Generar ID único
  static String generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final data = "$timestamp:$random:$_salt";
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Validar precio
  static bool isValidPrice(double price) {
    return price > 0 && price <= 10000000; // Máximo 10 millones
  }

  // Validar calificación (1-5 estrellas)
  static bool isValidRating(double rating) {
    return rating >= 1.0 && rating <= 5.0;
  }

  // Encriptar datos sensibles
  static String encryptSensitiveData(String data) {
    final bytes = utf8.encode(data + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validar formato de fecha
  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now.subtract(const Duration(days: 365))) &&
        date.isBefore(now.add(const Duration(days: 365)));
  }

  // Validar horario de trabajo (8:00 - 20:00)
  static bool isValidWorkTime(DateTime time) {
    final hour = time.hour;
    return hour >= 8 && hour <= 20;
  }

  // Obtener nivel de seguridad de la contraseña
  static int getPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return strength; // 0-6
  }

  // Obtener mensaje de fortaleza de contraseña
  static String getPasswordStrengthMessage(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return "Muy débil";
      case 2:
        return "Débil";
      case 3:
        return "Regular";
      case 4:
        return "Buena";
      case 5:
        return "Fuerte";
      case 6:
        return "Muy fuerte";
      default:
        return "Desconocida";
    }
  }
}
