import '../models/dispute_model.dart';
import '../supabase_db.dart';

class DisputeRepository {
  static const String _table = 'disputes';

  Future<void> createDispute(DisputeModel dispute) async {
    await supabase.from(_table).insert(dispute.toMap());
  }

  Future<DisputeModel?> getDisputeById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return DisputeModel.fromMap(row);
  }

  Future<DisputeModel?> getDisputeByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return DisputeModel.fromMap(rows.first);
  }

  Future<void> updateDispute(DisputeModel dispute) async {
    await supabase.from(_table).update(dispute.toMap()).eq('id', dispute.id);
  }

  Future<List<DisputeModel>> getOpenDisputes() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('status', 'open')
        .order('createdAt', ascending: false);
    return rows.map<DisputeModel>((m) => DisputeModel.fromMap(m)).toList();
  }
}
