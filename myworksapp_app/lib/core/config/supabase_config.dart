import 'package:flutter/foundation.dart';

/// Configuración del backend Supabase.
///
/// Preferir `--dart-define=SUPABASE_URL=...` y
/// `--dart-define=SUPABASE_ANON_KEY=...` en builds de release.
/// Los valores por defecto mantienen la demo local funcional.
///
/// NUNCA coloques aquí la `service_role` / secret key.
class SupabaseConfig {
  SupabaseConfig._();

  static const bool _hasUrlDefine = bool.hasEnvironment('SUPABASE_URL');
  static const bool _hasAnonKeyDefine =
      bool.hasEnvironment('SUPABASE_ANON_KEY');

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wxqrfcqifkfgawrnqmnj.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_WN_cTANRJ4nCuPw_6HWd7w_iDJjRA8O',
  );

  static void validateForCurrentBuild() {
    if (!kReleaseMode) return;
    if (!_hasUrlDefine ||
        !_hasAnonKeyDefine ||
        url.isEmpty ||
        publishableKey.isEmpty) {
      throw StateError(
        'Release build requires --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
