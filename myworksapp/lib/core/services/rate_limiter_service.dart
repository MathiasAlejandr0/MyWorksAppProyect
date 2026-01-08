import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Servicio para rate limiting local (anti-spam)
class RateLimiterService {
  static final RateLimiterService instance = RateLimiterService._();
  RateLimiterService._();

  // Límites por tipo de acción
  static const int maxMessagesPerMinute = 5;
  static const int maxJobsPerHour = 3;
  static const int maxReportsPerDay = 2;

  // Ventanas de tiempo
  static const Duration messageWindow = Duration(minutes: 1);
  static const Duration jobWindow = Duration(hours: 1);
  static const Duration reportWindow = Duration(days: 1);

  /// Verifica si se puede realizar una acción
  Future<RateLimitResult> canPerformAction({
    required String userId,
    required RateLimitAction action,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId, action);
      final timestamps = _getTimestamps(prefs, key);

      // Filtrar timestamps fuera de la ventana de tiempo
      final window = _getWindow(action);
      final now = DateTime.now();
      final validTimestamps = timestamps.where((ts) {
        final timestamp = DateTime.parse(ts);
        return now.difference(timestamp) < window;
      }).toList();

      // Verificar límite
      final limit = _getLimit(action);
      if (validTimestamps.length >= limit) {
        final oldestTimestamp = DateTime.parse(validTimestamps.first);
        final timeUntilReset = window - now.difference(oldestTimestamp);
        
        return RateLimitResult(
          allowed: false,
          timeUntilReset: timeUntilReset,
          limit: limit,
          window: window,
        );
      }

      // Agregar timestamp actual
      validTimestamps.add(now.toIso8601String());
      await prefs.setStringList(key, validTimestamps);

      return RateLimitResult(
        allowed: true,
        timeUntilReset: Duration.zero,
        limit: limit,
        window: window,
      );
    } catch (e) {
      AppLogger.e('Error al verificar rate limit', e);
      // En caso de error, permitir la acción (fail-open)
      return RateLimitResult(
        allowed: true,
        timeUntilReset: Duration.zero,
        limit: 0,
        window: Duration.zero,
      );
    }
  }

  /// Registra que se realizó una acción
  Future<void> recordAction({
    required String userId,
    required RateLimitAction action,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId, action);
      final timestamps = _getTimestamps(prefs, key);
      
      timestamps.add(DateTime.now().toIso8601String());
      await prefs.setStringList(key, timestamps);
    } catch (e) {
      AppLogger.e('Error al registrar acción', e);
    }
  }

  /// Limpia el historial de acciones (útil para testing o reset manual)
  Future<void> clearHistory({
    required String userId,
    required RateLimitAction action,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(userId, action);
      await prefs.remove(key);
      AppLogger.i('Historial de rate limit limpiado para $action');
    } catch (e) {
      AppLogger.e('Error al limpiar historial', e);
    }
  }

  /// Obtiene la clave para SharedPreferences
  String _getKey(String userId, RateLimitAction action) {
    return 'rate_limit_${action.name}_$userId';
  }

  /// Obtiene los timestamps desde SharedPreferences
  List<String> _getTimestamps(SharedPreferences prefs, String key) {
    return prefs.getStringList(key) ?? [];
  }

  /// Obtiene la ventana de tiempo según la acción
  Duration _getWindow(RateLimitAction action) {
    switch (action) {
      case RateLimitAction.sendMessage:
        return messageWindow;
      case RateLimitAction.createJob:
        return jobWindow;
      case RateLimitAction.createReport:
        return reportWindow;
    }
  }

  /// Obtiene el límite según la acción
  int _getLimit(RateLimitAction action) {
    switch (action) {
      case RateLimitAction.sendMessage:
        return maxMessagesPerMinute;
      case RateLimitAction.createJob:
        return maxJobsPerHour;
      case RateLimitAction.createReport:
        return maxReportsPerDay;
    }
  }

  /// Obtiene mensaje amigable para el usuario
  static String getRateLimitMessage(RateLimitResult result) {
    if (result.allowed) return '';

    final minutes = result.timeUntilReset.inMinutes;
    final hours = result.timeUntilReset.inHours;
    final days = result.timeUntilReset.inDays;

    String timeText;
    if (days > 0) {
      timeText = '$days ${days == 1 ? 'día' : 'días'}';
    } else if (hours > 0) {
      timeText = '$hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (minutes > 0) {
      timeText = '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      timeText = 'un momento';
    }

    return 'Has alcanzado el límite de acciones. Por favor espera $timeText antes de intentar nuevamente.';
  }
}

/// Tipos de acciones con rate limiting
enum RateLimitAction {
  sendMessage,
  createJob,
  createReport,
}

/// Resultado de verificación de rate limit
class RateLimitResult {
  final bool allowed;
  final Duration timeUntilReset;
  final int limit;
  final Duration window;

  RateLimitResult({
    required this.allowed,
    required this.timeUntilReset,
    required this.limit,
    required this.window,
  });
}

