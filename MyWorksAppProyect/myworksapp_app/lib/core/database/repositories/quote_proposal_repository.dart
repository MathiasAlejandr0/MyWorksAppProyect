import '../models/quote_proposal_model.dart';
import '../supabase_db.dart';

class QuoteProposalRepository {
  static const String _table = 'propuestas_cotizacion';

  static const String _columns =
      '*, propuesta_cotizacion_items(linea, concepto, monto)';

  Future<void> create(QuoteProposalModel proposal) async {
    await supabase.from(_table).insert(proposal.toMap());
    final items = proposal.itemRows();
    if (items.isNotEmpty) {
      await supabase.from('propuesta_cotizacion_items').insert(items);
    }
  }

  Future<List<QuoteProposalModel>> getByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select(_columns)
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: false);
    return rows
        .map<QuoteProposalModel>((m) => QuoteProposalModel.fromMap(m))
        .toList();
  }

  Future<QuoteProposalModel?> getById(String id) async {
    final row =
        await supabase.from(_table).select(_columns).eq('id', id).maybeSingle();
    if (row == null) return null;
    return QuoteProposalModel.fromMap(row);
  }

  Future<void> selectAsClient(String proposalId) async {
    await supabase.rpc(
      'seleccionar_cotizacion',
      params: {'p_id_cotizacion': proposalId},
    );
  }

  Future<void> update(QuoteProposalModel proposal) async {
    await supabase.from(_table).update(proposal.toMap()).eq('id', proposal.id);
  }
}
