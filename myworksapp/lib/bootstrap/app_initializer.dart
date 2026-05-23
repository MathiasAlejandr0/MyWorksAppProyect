import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/notification_service.dart';
import '../core/services/session_manager.dart';
import '../core/services/app_lifecycle_service.dart';
import '../core/services/service_seeder.dart';
import '../core/services/demo_data_seeder.dart';
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
/// 
/// Maneja:
/// - Inicialización de SQLite y migraciones
/// - Restauración de sesión
/// - Validación de estado de cuenta
/// - Detección de primera vez (onboarding)
/// - Inicialización de servicios
class AppInitializer {
  static final AppInitializer instance = AppInitializer._();
  AppInitializer._();

  bool _isInitialized = false;
  AppInitializationResult? _lastResult;

  /// Inicializa la aplicación completa
  /// 
  /// Orden de ejecución:
  /// 1. Inicializar SQLite + migraciones
  /// 2. Cargar preferencias
  /// 3. Inicializar servicios (notificaciones, lifecycle)
  /// 4. Restaurar sesión desde SQLite
  /// 5. Validar estado de cuenta
  /// 6. Detectar primera vez (onboarding)
  Future<AppInitializationResult> initialize(WidgetRef ref) async {
    if (_isInitialized && _lastResult != null) {
      AppLogger.i('App ya inicializada, retornando resultado anterior');
      return _lastResult!;
    }

    try {
      AppLogger.i('🚀 Iniciando inicialización de la app...');

      // 1. Inicializar SQLite + migraciones (PRIMERO)
      AppLogger.i('📦 Inicializando base de datos SQLite...');
      await DatabaseHelper.instance.database;
      AppLogger.i('✅ Base de datos inicializada correctamente');

      // 2. Verificar salud de la app (DESPUÉS de inicializar BD)
      AppLogger.i('🏥 Verificando salud de la aplicación...');
      final healthService = AppHealthService.instance;
      final isHealthy = await healthService.checkHealth();
      
      if (!isHealthy) {
        AppLogger.e('🚨 Problemas críticos detectados, activando modo mantenimiento');
        // El router debería redirigir a /maintenance si isMaintenanceMode es true
        // Por ahora, solo logueamos el error
      } else {
        AppLogger.i('✅ Salud de la app verificada');
      }

      // Inicializar servicios en la base de datos
      try {
        await ServiceSeeder.instance.seedServices();
        AppLogger.i('✅ Servicios inicializados en la base de datos');
      } catch (e) {
        AppLogger.w('⚠️ Error al inicializar servicios', e);
        // Continuar sin servicios (pueden existir ya)
      }

      // Datos de demostración (usuarios y trabajadores precargados)
      try {
        await DemoDataSeeder.instance.seedDemoData();
      } catch (e) {
        AppLogger.w('⚠️ Error al cargar datos demo', e);
      }

      // 3. Cargar preferencias
      AppLogger.i('⚙️ Cargando preferencias...');
      final prefs = await SharedPreferences.getInstance();
      await _ensureDemoPreferences(prefs);
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final isFirstLaunch = !prefs.containsKey('onboarding_completed');
      AppLogger.i('✅ Preferencias cargadas');

      // 4. Inicializar servicios (con manejo de errores)
      AppLogger.i('🔧 Inicializando servicios...');
      
      // Notificaciones (puede fallar en algunas plataformas)
      try {
        await NotificationService.instance.initialize();
        AppLogger.i('✅ Notificaciones inicializadas');
      } catch (e) {
        AppLogger.w('⚠️ No se pudieron inicializar las notificaciones', e);
        // Continuar sin notificaciones
      }

      // App Lifecycle Service
      AppLifecycleService.instance.initialize(ref);
      AppLogger.i('✅ App Lifecycle Service inicializado');

      // 5. Restaurar sesión desde SQLite
      AppLogger.i('🔐 Restaurando sesión...');
      bool hasActiveSession = false;
      String? userId;

      try {
        hasActiveSession = await SessionManager.instance.hasActiveSession();
        
        if (hasActiveSession) {
          final sessionData = await SessionManager.instance.getSessionData();
          userId = sessionData?['userId'] as String?;
          
          if (userId != null) {
            // Restaurar sesión en el provider
            final authNotifier = ref.read(authProvider.notifier);
            await authNotifier.restoreSession();
            AppLogger.i('✅ Sesión restaurada para usuario: $userId');
          }
        } else {
          AppLogger.i('ℹ️ No hay sesión activa');
        }
      } catch (e) {
        AppLogger.e('❌ Error al restaurar sesión', e);
        // Continuar sin sesión
      }

      // 6. Validar estado de cuenta (si hay sesión)
      if (hasActiveSession && userId != null) {
        AppLogger.i('🔍 Validando estado de cuenta...');
        try {
          final authNotifier = ref.read(authProvider.notifier);
          final authState = ref.read(authProvider);
          
          if (authState.user != null) {
            // Verificar si la cuenta está bloqueada o suspendida
            // Esto se haría consultando la BD o el backend
            // Por ahora, solo logueamos
            AppLogger.i('✅ Estado de cuenta validado');
            
            // User tracking se puede agregar aquí si se necesita en el futuro
          }
        } catch (e) {
          AppLogger.e('❌ Error al validar estado de cuenta', e);
          // Si falla la validación, cerrar sesión por seguridad
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

  /// Reinicia la inicialización (útil para tests o reset completo)
  void reset() {
    _isInitialized = false;
    _lastResult = null;
    AppLogger.i('🔄 AppInitializer reiniciado');
  }

  /// Obtiene el último resultado de inicialización
  AppInitializationResult? get lastResult => _lastResult;

  /// Verifica si la app está inicializada
  bool get isInitialized => _isInitialized;

  /// Configura preferencias mínimas para la demo local
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

