import '../database/supabase_db.dart';
import '../utils/app_logger.dart';

/// No bloquea la pantalla: un fallo de red se traga.
Future<void> registrarEvento({
  required String tipo,
  String? entidadId,
  String? categoria,
  String? comuna,
  Map<String, dynamic>? metadata,
}) async {
  try {
    await supabase.rpc('registrar_evento', params: {
      'p_tipo': tipo,
      'p_entidad_id': entidadId,
      'p_categoria': categoria,
      'p_comuna': comuna,
      'p_metadata': metadata ?? <String, dynamic>{},
    });
  } catch (e) {
    AppLogger.w('evento no registrado');
  }
}
