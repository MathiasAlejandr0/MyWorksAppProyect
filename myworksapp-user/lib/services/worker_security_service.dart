import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';

class WorkerSecurityService {
  static final WorkerSecurityService _instance =
      WorkerSecurityService._internal();
  factory WorkerSecurityService() => _instance;
  WorkerSecurityService._internal();

  static const String _sessionKey = 'worker_session';
  static const String _workerIdKey = 'worker_id';

  // Hash de contraseña usando SHA-256
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verificar contraseña
  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  // Validar email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validar teléfono
  bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone);
  }

  // Validar contraseña
  bool isValidPassword(String password) {
    // Mínimo 8 caracteres, al menos una letra y un número
    return password.length >= 8 &&
        RegExp(r'[a-zA-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Guardar sesión del trabajador
  Future<void> saveWorkerSession(Worker worker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(worker.toMap()));
    await prefs.setInt(_workerIdKey, worker.id!);
  }

  // Obtener sesión del trabajador
  Future<Worker?> getWorkerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_sessionKey);
    if (sessionData != null) {
      return Worker.fromMap(jsonDecode(sessionData));
    }
    return null;
  }

  // Obtener ID del trabajador actual
  Future<int?> getCurrentWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workerIdKey);
  }

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    final worker = await getWorkerSession();
    return worker != null;
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_workerIdKey);
  }

  // Validar datos del trabajador
  Map<String, String> validateWorkerData({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String profession,
    String? title,
    String? titleInstitution,
    int? titleYear,
    String? description,
    String? address,
    double? hourlyRate,
  }) {
    Map<String, String> errors = {};

    // Validar nombre
    if (name.trim().isEmpty) {
      errors['name'] = 'El nombre es requerido';
    } else if (name.trim().length < 2) {
      errors['name'] = 'El nombre debe tener al menos 2 caracteres';
    }

    // Validar email
    if (email.trim().isEmpty) {
      errors['email'] = 'El email es requerido';
    } else if (!isValidEmail(email)) {
      errors['email'] = 'El email no es válido';
    }

    // Validar teléfono
    if (phone.trim().isEmpty) {
      errors['phone'] = 'El teléfono es requerido';
    } else if (!isValidPhone(phone)) {
      errors['phone'] = 'El teléfono no es válido';
    }

    // Validar contraseña
    if (password.isEmpty) {
      errors['password'] = 'La contraseña es requerida';
    } else if (!isValidPassword(password)) {
      errors['password'] =
          'La contraseña debe tener al menos 8 caracteres, una letra y un número';
    }

    // Validar profesión
    if (profession.trim().isEmpty) {
      errors['profession'] = 'La profesión es requerida';
    }

    // Validar título si se proporciona
    if (title != null && title.isNotEmpty) {
      if (titleInstitution == null || titleInstitution!.trim().isEmpty) {
        errors['titleInstitution'] = 'La institución del título es requerida';
      }
      if (titleYear == null ||
          titleYear < 1950 ||
          titleYear > DateTime.now().year) {
        errors['titleYear'] = 'El año del título debe ser válido';
      }
    }

    // Validar tarifa por hora
    if (hourlyRate != null && hourlyRate <= 0) {
      errors['hourlyRate'] = 'La tarifa por hora debe ser mayor a 0';
    }

    return errors;
  }

  // Generar token de sesión simple
  String generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return base64Encode(utf8.encode('$timestamp-$random'));
  }

  // Validar token de sesión
  bool isValidSessionToken(String token) {
    try {
      final decoded = utf8.decode(base64Decode(token));
      final parts = decoded.split('-');
      if (parts.length != 2) return false;

      final timestamp = int.parse(parts[0]);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Token válido por 24 horas
      return (now - timestamp) < (24 * 60 * 60 * 1000);
    } catch (e) {
      return false;
    }
  }
}
