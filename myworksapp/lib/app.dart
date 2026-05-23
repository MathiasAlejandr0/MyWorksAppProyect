import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bootstrap/app_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/utils/app_logger.dart';

/// Widget principal de la aplicación
/// 
/// Maneja:
/// - Tema (claro/oscuro)
/// - Inicialización completa mediante AppInitializer
/// - Configuración del router
/// - Lifecycle de la app
class MyWorksApp extends ConsumerStatefulWidget {
  const MyWorksApp({super.key});

  @override
  ConsumerState<MyWorksApp> createState() => _MyWorksAppState();
}

class _MyWorksAppState extends ConsumerState<MyWorksApp> {
  bool _isDarkMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    AppLifecycleService.instance.dispose();
    super.dispose();
  }

  /// Inicializa la aplicación completa
  /// 
  /// Usa AppInitializer para:
  /// - Inicializar SQLite + migraciones
  /// - Cargar preferencias
  /// - Inicializar servicios
  /// - Restaurar sesión
  /// - Validar estado de cuenta
  /// - Detectar primera vez (onboarding)
  Future<void> _initialize() async {
    try {
      // 1. Cargar tema desde preferencias
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
      });

      // 2. Inicializar app completa mediante AppInitializer
      AppLogger.i('🔄 Inicializando app mediante AppInitializer...');
      final result = await AppInitializer.instance.initialize(ref);
      
      setState(() {
        _isInitialized = true;
      });

      // 3. Inicializar AppLifecycleService (después de tener ref)
      AppLifecycleService.instance.initialize(ref);
      
      if (!result.success) {
        AppLogger.e('❌ Inicialización falló: ${result.error}');
      } else {
        AppLogger.i('✅ App inicializada correctamente');
      }
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error crítico en inicialización de MyWorksApp', e, stackTrace);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MyWorksApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      // Agregar error builder para capturar errores de renderizado
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

