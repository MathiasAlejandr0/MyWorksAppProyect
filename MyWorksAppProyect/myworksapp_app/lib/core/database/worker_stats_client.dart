import '../domain/worker_public_stats.dart';
import 'models/worker_model.dart';
import 'supabase_db.dart';

/// Superpone las cifras canónicas de `stats_profesionales` si la RPC existe.
/// Si aún no está desplegada, deja los valores que ya trae la ficha.
Future<List<WorkerModel>> overlayWorkerPublicStats(
  List<WorkerModel> workers,
) async {
  if (workers.isEmpty) return workers;
  try {
    final rows = await supabase.rpc(
      'stats_profesionales',
      params: {'p_ids': workers.map((w) => w.userId).toList()},
    );
    if (rows is! List || rows.isEmpty) return workers;
    final byId = <String, WorkerPublicStats>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final id = map['id_usuario'] as String?;
      if (id == null) continue;
      byId[id] = WorkerPublicStats.fromMap(map);
    }
    if (byId.isEmpty) return workers;
    return [
      for (final worker in workers)
        if (byId[worker.userId] == null)
          worker
        else
          worker.copyWith(
            rating: byId[worker.userId]!.averageRating ?? 0,
            completedJobs: byId[worker.userId]!.completedJobs,
            isElite: byId[worker.userId]!.isElite,
          ),
    ];
  } catch (_) {
    return workers;
  }
}

WorkerModel applyWorkerPublicStats(
  WorkerModel worker,
  WorkerPublicStats stats,
) {
  return worker.copyWith(
    rating: stats.averageRating ?? 0,
    completedJobs: stats.completedJobs,
    isElite: stats.isElite,
  );
}
