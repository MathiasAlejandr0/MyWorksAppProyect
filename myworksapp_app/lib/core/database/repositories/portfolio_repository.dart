import '../models/portfolio_model.dart';
import '../supabase_db.dart';

class PortfolioRepository {
  static const String _table = 'portafolio_trabajador';

  Future<void> createPortfolioItem(PortfolioModel item) async {
    await supabase.from(_table).insert(item.toMap());
  }

  Future<List<PortfolioModel>> getPortfolioByWorkerId(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .order('creado_en', ascending: false);
    return rows.map<PortfolioModel>((m) => PortfolioModel.fromMap(m)).toList();
  }

  Future<void> deletePortfolioItem(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
