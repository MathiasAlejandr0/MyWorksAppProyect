import '../models/ranking_models.dart';
import '../supabase_db.dart';

class RankingRepository {
  Future<RankingConfig> fetchConfig() async {
    final raw = await supabase.rpc('obtener_config_ranking');
    if (raw is Map<String, dynamic>) {
      return RankingConfig.fromMap(raw);
    }
    if (raw is Map) {
      return RankingConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    return const RankingConfig();
  }

  Future<RankingConfig> saveConfig(RankingConfig config) async {
    final raw = await supabase.rpc(
      'guardar_config_ranking',
      params: {'p_cfg': config.toRpcMap()},
    );
    if (raw is Map<String, dynamic>) {
      return RankingConfig.fromMap(raw);
    }
    if (raw is Map) {
      return RankingConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    return config;
  }

  Future<void> setWorkerPriority(String workerId, int priority) async {
    await supabase.rpc(
      'fijar_prioridad_trabajador',
      params: {
        'p_id': workerId,
        'p_prioridad': priority,
      },
    );
  }

  Future<List<ReviewSignal>> listSignals({
    String status = 'pendiente',
    int limit = 80,
  }) async {
    final raw = await supabase.rpc(
      'listar_senales_resena',
      params: {
        'p_estado': status,
        'p_limit': limit,
      },
    );
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((row) => ReviewSignal.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> resolveSignal(String signalId, String status) async {
    await supabase.rpc(
      'resolver_senal_resena',
      params: {
        'p_id': signalId,
        'p_estado': status,
      },
    );
  }

  Future<Map<String, dynamic>> learnWeights() async {
    final raw = await supabase.rpc('aprender_pesos_ranking_admin');
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'ok': false};
  }

  Future<int> refreshAll() async {
    final raw = await supabase.rpc('refrescar_ranking_todos_admin');
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<int> pendingSignalCount() async {
    final rows = await supabase
        .from('senales_resena')
        .select('id')
        .eq('estado', 'pendiente');
    return (rows as List).length;
  }
}
