import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/utils/app_logger.dart';
import 'app.dart';

/// Punto de entrada de la aplicación
/// 
/// Orden de inicialización:
/// 1. WidgetsFlutterBinding.ensureInitialized()
/// 2. AppInitializer (SQLite, servicios, sesión, onboarding)
/// 3. ProviderScope (Riverpod)
/// 4. MyWorksApp (Widget principal)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);
  
  AppLogger.i('🚀 Iniciando MyWorksApp...');
  
  // La inicialización completa se hace en AppInitializer
  // que se ejecuta dentro de MyWorksApp usando el WidgetRef
  // Esto permite usar Riverpod providers durante la inicialización
  
  runApp(
    const ProviderScope(
      child: MyWorksApp(),
    ),
  );
}


