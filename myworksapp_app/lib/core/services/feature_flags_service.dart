import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../database/repositories/feature_flag_repository.dart';
import '../database/models/feature_flag_model.dart';
import '../utils/app_logger.dart';
import 'session_manager.dart';

/// Servicio de feature flags reales
/// 
/// Soporta:
/// - Flags por versión de app
/// - Flags por rol (user/worker)
/// - Flags por usuario específico
/// - Evaluación en runtime
/// - Persistencia en SQLite
class FeatureFlagsService {
  static final FeatureFlagsService instance = FeatureFlagsService._();
  FeatureFlagsService._();

  final FeatureFlagRepository _repository = FeatureFlagRepository();
  final SessionManager _sessionManager = SessionManager.instance;

  // Feature flags disponibles
  static const String flagMatchingAutomatic = 'matching_automatic';
  static const String flagPaymentsEnabled = 'payments_enabled';
  static const String flagSubscriptionsEnabled = 'subscriptions_enabled';
  static const String flagBoostsEnabled = 'boosts_enabled';
  static const String flagDisputesEnabled = 'disputes_enabled';
  static const String flagTrustScoreEnabled = 'trust_score_enabled';
  static const String flagDynamicPricing = 'dynamic_pricing';
  static const String flagAnalyticsEnabled = 'analytics_enabled';

  // Valores por defecto (globales)
  static const Map<String, bool> _defaultFlags = {
    flagMatchingAutomatic: true,
    flagPaymentsEnabled: false,
    flagSubscriptionsEnabled: false,
    flagBoostsEnabled: false,
    flagDisputesEnabled: true,
    flagTrustScoreEnabled: true,
    flagDynamicPricing: false,
    flagAnalyticsEnabled: true,
  };

  String? _cachedAppVersion;

  /// Obtiene la versión de la app
  Future<String> _getAppVersion() async {
    if (_cachedAppVersion != null) {
      return _cachedAppVersion!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedAppVersion = packageInfo.version;
      return _cachedAppVersion!;
    } catch (e) {
      AppLogger.e('Error getting app version', e);
      return '1.0.0'; // Fallback
    }
  }

  /// Verifica si un feature está habilitado
  /// 
  /// Evalúa en este orden:
  /// 1. Flag específico para el usuario actual
  /// 2. Flag específico para el rol del usuario
  /// 3. Flag específico para la versión de la app
  /// 4. Flag global
  /// 5. Valor por defecto
  Future<bool> isEnabled(String flagName) async {
    try {
      // Obtener contexto actual
      final appVersion = await _getAppVersion();
      final sessionData = await _sessionManager.getSessionData();
      final role = sessionData?['role'];
      final userId = sessionData?['userId'];

      // Buscar flag más específico
      final flag = await _repository.getFlag(
        flagName: flagName,
        appVersion: appVersion,
        role: role,
        userId: userId,
      );

      if (flag != null) {
        return flag.isEnabled;
      }

      // Si no existe, usar valor por defecto
      return _defaultFlags[flagName] ?? false;
    } catch (e) {
      AppLogger.e('Error verificando feature flag: $flagName', e);
      return _defaultFlags[flagName] ?? false;
    }
  }

  /// Verifica si un feature está habilitado para un contexto específico
  Future<bool> isEnabledFor({
    required String flagName,
    String? appVersion,
    String? role,
    String? userId,
  }) async {
    try {
      final flag = await _repository.getFlag(
        flagName: flagName,
        appVersion: appVersion,
        role: role,
        userId: userId,
      );

      if (flag != null) {
        return flag.isEnabled;
      }

      return _defaultFlags[flagName] ?? false;
    } catch (e) {
      AppLogger.e('Error verificando feature flag con contexto', e);
      return _defaultFlags[flagName] ?? false;
    }
  }

  /// Establece un feature flag global
  Future<void> setGlobalFlag(String flagName, bool enabled) async {
    try {
      final now = DateTime.now();
      final flag = FeatureFlagModel(
        id: const Uuid().v4(),
        flagName: flagName,
        isEnabled: enabled,
        appVersion: null, // Global
        role: null,
        userId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.upsertFlag(flag);
      AppLogger.i('Feature flag global actualizado: $flagName = $enabled');
    } catch (e) {
      AppLogger.e('Error estableciendo feature flag global', e);
      rethrow;
    }
  }

  /// Establece un feature flag por versión
  Future<void> setVersionFlag(String flagName, String appVersion, bool enabled) async {
    try {
      final now = DateTime.now();
      final flag = FeatureFlagModel(
        id: const Uuid().v4(),
        flagName: flagName,
        isEnabled: enabled,
        appVersion: appVersion,
        role: null,
        userId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.upsertFlag(flag);
      AppLogger.i('Feature flag por versión actualizado: $flagName ($appVersion) = $enabled');
    } catch (e) {
      AppLogger.e('Error estableciendo feature flag por versión', e);
      rethrow;
    }
  }

  /// Establece un feature flag por rol
  Future<void> setRoleFlag(String flagName, String role, bool enabled) async {
    try {
      final now = DateTime.now();
      final flag = FeatureFlagModel(
        id: const Uuid().v4(),
        flagName: flagName,
        isEnabled: enabled,
        appVersion: null,
        role: role,
        userId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.upsertFlag(flag);
      AppLogger.i('Feature flag por rol actualizado: $flagName ($role) = $enabled');
    } catch (e) {
      AppLogger.e('Error estableciendo feature flag por rol', e);
      rethrow;
    }
  }

  /// Establece un feature flag por usuario
  Future<void> setUserFlag(String flagName, String userId, bool enabled) async {
    try {
      final now = DateTime.now();
      final flag = FeatureFlagModel(
        id: const Uuid().v4(),
        flagName: flagName,
        isEnabled: enabled,
        appVersion: null,
        role: null,
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.upsertFlag(flag);
      AppLogger.i('Feature flag por usuario actualizado: $flagName ($userId) = $enabled');
    } catch (e) {
      AppLogger.e('Error estableciendo feature flag por usuario', e);
      rethrow;
    }
  }

  /// Obtiene todos los feature flags
  Future<Map<String, bool>> getAllFlags() async {
    try {
      final flags = await _repository.getAllFlags();
      final result = <String, bool>{};

      // Agregar flags de la base de datos
      for (final flag in flags) {
        // Solo agregar si es global o coincide con el contexto actual
        if (flag.appVersion == null && flag.role == null && flag.userId == null) {
          result[flag.flagName] = flag.isEnabled;
        }
      }

      // Agregar valores por defecto para flags que no existen
      for (final entry in _defaultFlags.entries) {
        if (!result.containsKey(entry.key)) {
          result[entry.key] = entry.value;
        }
      }

      return result;
    } catch (e) {
      AppLogger.e('Error obteniendo feature flags', e);
      return _defaultFlags;
    }
  }

  /// Inicializa flags por defecto (solo si no existen)
  Future<void> initializeDefaultFlags() async {
    try {
      final existingFlags = await _repository.getAllFlags();
      final existingFlagNames = existingFlags.map((f) => f.flagName).toSet();

      final now = DateTime.now();
      for (final entry in _defaultFlags.entries) {
        if (!existingFlagNames.contains(entry.key)) {
          final flag = FeatureFlagModel(
            id: const Uuid().v4(),
            flagName: entry.key,
            isEnabled: entry.value,
            appVersion: null,
            role: null,
            userId: null,
            createdAt: now,
            updatedAt: now,
          );

          await _repository.upsertFlag(flag);
        }
      }

      AppLogger.i('Feature flags por defecto inicializados');
    } catch (e) {
      AppLogger.e('Error inicializando feature flags por defecto', e);
    }
  }

  /// Sincroniza flags desde servidor (preparado para futuro)
  Future<void> syncFromServer() async {
    try {
      // TODO: Implementar cuando tengamos backend
      // final flags = await apiClient.getFeatureFlags();
      // for (final flag in flags) {
      //   await _repository.upsertFlag(flag);
      // }
      AppLogger.i('Sync de feature flags desde servidor (no implementado aún)');
    } catch (e) {
      AppLogger.e('Error sincronizando feature flags', e);
    }
  }
}
