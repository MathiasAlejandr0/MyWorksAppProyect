import '../models/boost_model.dart';
import '../supabase_db.dart';

class BoostRepository {
  static const String _table = 'impulsos';

  Future<void> createBoost(BoostModel boost) async {
    await supabase.from(_table).insert(boost.toMap());
  }

  Future<List<BoostModel>> getActiveBoosts(String workerId) async {
    final now = DateTime.now().toIso8601String();
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .lte('fecha_inicio', now)
        .gte('fecha_fin', now);
    return rows.map<BoostModel>((m) => BoostModel.fromMap(m)).toList();
  }

  Future<List<BoostModel>> getAllBoosts() async {
    final rows = await supabase.from(_table).select();
    return rows.map<BoostModel>((m) => BoostModel.fromMap(m)).toList();
  }

  Future<void> deleteBoost(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
