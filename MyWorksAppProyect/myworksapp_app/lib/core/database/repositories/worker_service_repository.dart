import '../supabase_db.dart';

/// Relación N:M entre trabajadores y categorías de servicio.
class WorkerServiceRepository {
  static const String _table = 'trabajador_servicios';

  Future<void> linkWorkerToCategory(
      String workerId, String serviceCategory) async {
    await supabase.from(_table).upsert({
      'id_trabajador': workerId,
      'categoria_servicio': serviceCategory,
    });
  }

  Future<void> clearWorkerLinks(String workerId) async {
    await supabase.from(_table).delete().eq('id_trabajador', workerId);
  }

  Future<List<String>> getCategoriesForWorker(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select('categoria_servicio')
        .eq('id_trabajador', workerId);
    return rows.map<String>((m) => m['categoria_servicio'] as String).toList();
  }
}
