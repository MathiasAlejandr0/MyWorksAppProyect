import '../supabase_db.dart';

/// Relación N:M entre trabajadores y categorías de servicio.
class WorkerServiceRepository {
  static const String _table = 'worker_services';

  Future<void> linkWorkerToCategory(
      String workerId, String serviceCategory) async {
    await supabase.from(_table).upsert({
      'workerId': workerId,
      'serviceCategory': serviceCategory,
    });
  }

  Future<void> clearWorkerLinks(String workerId) async {
    await supabase.from(_table).delete().eq('workerId', workerId);
  }

  Future<List<String>> getCategoriesForWorker(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select('serviceCategory')
        .eq('workerId', workerId);
    return rows.map<String>((m) => m['serviceCategory'] as String).toList();
  }
}
