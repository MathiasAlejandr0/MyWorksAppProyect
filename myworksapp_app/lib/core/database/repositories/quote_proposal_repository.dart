import '../models/quote_proposal_model.dart';
import '../supabase_db.dart';

class QuoteProposalRepository {
  static const String _table = 'quote_proposals';

  Future<void> create(QuoteProposalModel proposal) async {
    await supabase.from(_table).insert(proposal.toMap());
  }

  Future<List<QuoteProposalModel>> getByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: false);
    return rows
        .map<QuoteProposalModel>((m) => QuoteProposalModel.fromMap(m))
        .toList();
  }

  Future<QuoteProposalModel?> getById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return QuoteProposalModel.fromMap(row);
  }

  Future<void> update(QuoteProposalModel proposal) async {
    await supabase.from(_table).update(proposal.toMap()).eq('id', proposal.id);
  }
}
