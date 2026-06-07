import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';
import '../core/services/session_manager.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/services/app_health_service.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de la inicialización de la app
class AppInitializationResult {
  final bool success;
  final String? error;
  final bool hasActiveSession;
  final String? userId;
  final bool isFirstLaunch;
  final bool onboardingCompleted;

  AppInitializationResult({
    required this.success,
    this.error,
    required this.hasActiveSession,
    this.userId,
    required this.isFirstLaunch,
    required this.onboardingCompleted,
  });
}

/// Inicializador centralizado de la aplicación
class AppInitializer {
  static final AppInitializer instance = AppInitializer._();
  AppInitializer._();

  bool _isInitialized = false;
  AppInitializationResult? _lastResult;

  Future<AppInitializationResult> initialize(WidgetRef ref) async {
    if (_isInitialized && _lastResult != null) {
      AppLogger.i('App ya inicializada, retornando resultado anterior');
      return _lastResult!;
    }

    try {
      AppLogger.i('🚀 Iniciando inicialización de la app...');

      // 1. Verificar conectividad con Supabase
      AppLogger.i('🏥 Verificando conexión con Supabase...');
      final healthService = AppHealthService.instance;
      final isHealthy = await healthService.checkHealth();

      if (!isHealthy) {
        AppLogger.e('🚨 No se pudo conectar con Supabase');
      } else {
        AppLogger.i('✅ Supabase accesible');
      }

      // 2. Cargar preferencias
      AppLogger.i('⚙️ Cargando preferencias...');
      final prefs = await SharedPreferences.getInstance();
      await _ensureDemoPreferences(prefs);
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final isFirstLaunch = !prefs.containsKey('onboarding_completed');
      AppLogger.i('✅ Preferencias cargadas');

      // 3. Inicializar servicios locales (notificaciones, lifecycle)
      AppLogger.i('🔧 Inicializando servicios...');

      try {
        await NotificationService.instance.initialize();
        AppLogger.i('✅ Notificaciones inicializadas');
      } catch (e) {
        AppLogger.w('⚠️ No se pudieron inicializar las notificaciones', e);
      }

      AppLifecycleService.instance.initialize(ref);
      AppLogger.i('✅ App Lifecycle Service inicializado');

      // 4. Restaurar sesión desde Supabase Auth
      AppLogger.i('🔐 Restaurando sesión...');
      bool hasActiveSession = false;
      String? userId;

      try {
        hasActiveSession = await SessionManager.instance.hasActiveSession();

        if (hasActiveSession) {
          final sessionData = await SessionManager.instance.getSessionData();
          userId = sessionData?['userId'];

          if (userId != null) {
            final authNotifier = ref.read(authProvider.notifier);
            await authNotifier.restoreSession();
            await authNotifier.loadCurrentUser(userId, silent: true);
            AppLogger.i('✅ Sesión restaurada para usuario: $userId');
          }
        } else {
          AppLogger.i('ℹ️ No hay sesión activa');
        }
      } catch (e) {
        AppLogger.e('❌ Error al restaurar sesión', e);
      }

      // 5. Validar estado de cuenta (si hay sesión)
      if (hasActiveSession && userId != null) {
        AppLogger.i('🔍 Validando estado de cuenta...');
        try {
          final authState = ref.read(authProvider);

          if (authState.user != null) {
            AppLogger.i('✅ Estado de cuenta validado');
          }
        } catch (e) {
          AppLogger.e('❌ Error al validar estado de cuenta', e);
          await SessionManager.instance.clearSession();
          hasActiveSession = false;
          userId = null;
        }
      }

      _isInitialized = true;
      _lastResult = AppInitializationResult(
        success: true,
        hasActiveSession: hasActiveSession,
        userId: userId,
        isFirstLaunch: isFirstLaunch,
        onboardingCompleted: onboardingCompleted,
      );

      AppLogger.i('✅ Inicialización completada exitosamente');
      AppLogger.i('   - Sesión activa: $hasActiveSession');
      AppLogger.i('   - Usuario: ${userId ?? "N/A"}');
      AppLogger.i('   - Primera vez: $isFirstLaunch');
      AppLogger.i('   - Onboarding completado: $onboardingCompleted');

      return _lastResult!;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error crítico en inicialización', e, stackTrace);

      _lastResult = AppInitializationResult(
        success: false,
        error: e.toString(),
        hasActiveSession: false,
        isFirstLaunch: true,
        onboardingCompleted: false,
      );

      return _lastResult!;
    }
  }

  void reset() {
    _isInitialized = false;
    _lastResult = null;
    AppLogger.i('🔄 AppInitializer reiniciado');
  }

  AppInitializationResult? get lastResult => _lastResult;
  bool get isInitialized => _isInitialized;

  Future<void> _ensureDemoPreferences(SharedPreferences prefs) async {
    if (!prefs.containsKey('privacy_policy_url')) {
      await prefs.setString(
        'privacy_policy_url',
        'https://myworksapp.demo/privacy',
      );
    }
    if (!prefs.containsKey('terms_accepted')) {
      await prefs.setBool('terms_accepted', true);
    }
    if (!prefs.containsKey('permissions_explained')) {
      await prefs.setBool('permissions_explained', true);
    }
  }
}
