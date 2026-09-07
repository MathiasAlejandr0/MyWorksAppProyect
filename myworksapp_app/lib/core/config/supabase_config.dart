/// Configuración del backend Supabase.
///
/// La `publishableKey` es la clave pública (segura para el cliente): el acceso
/// real a los datos está protegido por las políticas RLS de la base de datos.
/// NUNCA coloques aquí la `service_role` / secret key.
///
/// En CI/prod preferir `--dart-define=SUPABASE_URL=...` y
/// `--dart-define=SUPABASE_ANON_KEY=...`. Los defaultValue son solo para demo
/// local académica.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wxqrfcqifkfgawrnqmnj.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_WN_cTANRJ4nCuPw_6HWd7w_iDJjRA8O',
  );
}
