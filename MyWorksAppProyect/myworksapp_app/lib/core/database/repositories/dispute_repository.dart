import '../models/dispute_model.dart';
import '../supabase_db.dart';

class DisputeRepository {
  static const String _table = 'disputas';

  Future<void> createDispute(DisputeModel dispute) async {
    await supabase.rpc('abrir_disputa', params: {
      'p_id': dispute.id,
      'p_id_trabajo': dispute.jobId,
      'p_motivo': dispute.reason,
      'p_descripcion': dispute.description,
    });
  }

  Future<void> appeal(String disputeId, String motivo) async {
    await supabase.rpc('apelar_disputa', params: {
      'p_id': disputeId,
      'p_motivo': motivo,
    });
  }

  Future<void> addComment(String disputeId, String comment) async {
    await supabase.rpc('comentar_disputa', params: {
      'p_id': disputeId,
      'p_comentario': comment,
    });
  }

  Future<DisputeModel?> getDisputeById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return DisputeModel.fromMap(row);
  }

  Future<DisputeModel?> getDisputeByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return DisputeModel.fromMap(rows.first);
  }

  Future<void> updateDispute(DisputeModel dispute) async {
    await supabase.from(_table).update(dispute.toMap()).eq('id', dispute.id);
  }

  Future<Map<String, dynamic>?> pendingAgreement(String jobId) async {
    final rows = await supabase.rpc('acuerdo_pendiente', params: {
      'p_id_trabajo': jobId,
    });
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  Future<void> proposeAgreement({
    required String id,
    required String jobId,
    required String type,
  }) async {
    await supabase.rpc('proponer_acuerdo', params: {
      'p_id': id,
      'p_id_trabajo': jobId,
      'p_tipo': type,
    });
  }

  Future<void> respondAgreement({
    required String id,
    required bool accept,
  }) async {
    await supabase.rpc('responder_acuerdo', params: {
      'p_id': id,
      'p_acepta': accept,
    });
  }

  Future<List<DisputeModel>> listForParticipant(String userId) async {
    final asClient =
        await supabase.from('trabajos').select('id').eq('id_usuario', userId);
    final asWorker = await supabase
        .from('trabajos')
        .select('id')
        .eq('id_trabajador', userId);
    final ids = <String>{
      for (final row in [...asClient as List, ...asWorker as List])
        (row as Map)['id'] as String,
    };
    if (ids.isEmpty) return [];
    final rows = await supabase
        .from(_table)
        .select()
        .inFilter('id_trabajo', ids.toList())
        .order('creado_en', ascending: false);
    return rows.map<DisputeModel>((m) => DisputeModel.fromMap(m)).toList();
  }

  Future<List<DisputeModel>> getOpenDisputes() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('estado', 'abierta')
        .order('creado_en', ascending: false);
    return rows.map<DisputeModel>((m) => DisputeModel.fromMap(m)).toList();
  }
}
