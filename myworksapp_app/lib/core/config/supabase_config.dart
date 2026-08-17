/// Configuración del backend Supabase.
///
/// La `publishableKey` es la clave pública (segura para el cliente): el acceso
/// real a los datos está protegido por las políticas RLS de la base de datos.
/// NUNCA coloques aquí la `service_role` / secret key.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://wxqrfcqifkfgawrnqmnj.supabase.co';

  static const String publishableKey =
      'sb_publishable_WN_cTANRJ4nCuPw_6HWd7w_iDJjRA8O';
}
