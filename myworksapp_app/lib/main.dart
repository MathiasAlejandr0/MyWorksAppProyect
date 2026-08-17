import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/platform_support.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/app_logger.dart';
import 'app.dart';

/// Punto de entrada de la aplicación
/// 
/// Orden de inicialización:
/// 1. WidgetsFlutterBinding.ensureInitialized()
/// 2. AppInitializer (Supabase, servicios, sesión, onboarding)
/// 3. ProviderScope (Riverpod)
/// 4. MyWorksApp (Widget principal)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppPlatform.isMobileNative) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  await initializeDateFormatting('es_CL', null);

  AppLogger.i('🚀 Iniciando MyWorksApp...');

  // Inicializar Supabase (auth + base de datos) antes de usar cualquier cliente.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey,
    );
    AppLogger.i('✅ Supabase inicializado');
  } catch (e) {
    AppLogger.e('❌ Error al inicializar Supabase', e);
  }
  
  // La inicialización completa se hace en AppInitializer
  // que se ejecuta dentro de MyWorksApp usando el WidgetRef
  // Esto permite usar Riverpod providers durante la inicialización
  
  runApp(
    const ProviderScope(
      child: MyWorksApp(),
    ),
  );
}


