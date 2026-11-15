import '../database/supabase_db.dart';

/// Los destinos válidos los decide Postgres (`transiciones_trabajo_posibles`).
class JobTransitionMatrix {
  JobTransitionMatrix._();

  static Future<List<String>> allowedTargets(
    String pricingMode,
    String from,
  ) async {
    final data = await supabase.rpc(
      'transiciones_trabajo_posibles',
      params: {
        'p_desde': from,
        'p_modalidad': pricingMode,
      },
    );
    return targetsFromRpc(data);
  }

  static Future<bool> isAllowed(
    String pricingMode,
    String from,
    String to,
  ) async {
    final targets = await allowedTargets(pricingMode, from);
    return targets.contains(to);
  }
}

/// Normaliza el array que devuelve el RPC. Sirve para probar el cliente
/// sin abrir una sesión de base de datos.
List<String> targetsFromRpc(dynamic data) {
  if (data is! List) return const [];
  return data.map((row) => row.toString()).toList();
}
