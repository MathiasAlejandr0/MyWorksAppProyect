import 'package:flutter/foundation.dart';

/// Configuración centralizada de Supabase
///
/// Esta clase maneja la configuración de Supabase de manera segura
/// y proporciona diferentes configuraciones para desarrollo y producción.
class SupabaseConfig {
  // Configuración de producción
  static const String _productionUrl =
      'https://nyevopmlxcwqfuydgizd.supabase.co';
  static const String _productionAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55ZXZvcG1seGN3cWZ1eWRnaXpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMzQwNjksImV4cCI6MjA2ODkxMDA2OX0.1OVBDchkaEVfZOYp0UrPDYTfePu-oL-OUgw8D3qCx2M';

  // Configuración de desarrollo (ejemplo)
  static const String _developmentUrl =
      'https://nyevopmlxcwqfuydgizd.supabase.co';
  static const String _developmentAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55ZXZvcG1seGN3cWZ1eWRnaXpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMzQwNjksImV4cCI6MjA2ODkxMDA2OX0.1OVBDchkaEVfZOYp0UrPDYTfePu-oL-OUgw8D3qCx2M';

  /// URL de Supabase según el entorno
  static String get url {
    if (kDebugMode) {
      // En desarrollo, usa la URL de desarrollo
      return _developmentUrl;
    } else {
      // En producción, usa la URL de producción
      return _productionUrl;
    }
  }

  /// Clave anónima de Supabase según el entorno
  static String get anonKey {
    if (kDebugMode) {
      // En desarrollo, usa la clave de desarrollo
      return _developmentAnonKey;
    } else {
      // En producción, usa la clave de producción
      return _productionAnonKey;
    }
  }

  /// Valida que la configuración sea correcta
  static bool get isValid {
    return url.isNotEmpty &&
        url.contains('supabase.co') &&
        anonKey.isNotEmpty &&
        anonKey.startsWith('eyJ');
  }

  /// Obtiene información de configuración para debugging
  static Map<String, String> get debugInfo {
    return {
      'url': url,
      'anonKey': ' [${anonKey.substring(0, 20)}...]',
      'isValid': isValid.toString(),
      'isDebugMode': kDebugMode.toString(),
    };
  }
}
