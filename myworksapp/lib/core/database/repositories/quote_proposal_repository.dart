import '../database_helper.dart';
import '../models/quote_proposal_model.dart';

class QuoteProposalRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> create(QuoteProposalModel proposal) async {
    final database = await _db.database;
    await database.insert('quote_proposals', proposal.toMap());
  }

  Future<List<QuoteProposalModel>> getByJobId(String jobId) async {
    final database = await _db.database;
    final rows = await database.query(
      'quote_proposals',
      where: 'jobId = ?',
      whereArgs: [jobId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(QuoteProposalModel.fromMap).toList();
  }

  Future<QuoteProposalModel?> getById(String id) async {
    final database = await _db.database;
    final rows = await database.query(
      'quote_proposals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return QuoteProposalModel.fromMap(rows.first);
  }

  Future<void> update(QuoteProposalModel proposal) async {
    final database = await _db.database;
    await database.update(
      'quote_proposals',
      proposal.toMap(),
      where: 'id = ?',
      whereArgs: [proposal.id],
    );
  }
}
