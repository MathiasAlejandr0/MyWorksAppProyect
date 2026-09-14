import '../models/report_model.dart';
import '../supabase_db.dart';

class ReportRepository {
  static const String _table = 'reportes';

  Future<void> createReport(ReportModel report) async {
    await supabase.from(_table).insert(report.toMap());
  }

  Future<List<ReportModel>> getReportsByReporterId(String reporterId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_reportante', reporterId)
        .order('creado_en', ascending: false);
    return rows.map<ReportModel>((m) => ReportModel.fromMap(m)).toList();
  }

  Future<List<ReportModel>> getReportsByReportedUserId(
      String reportedUserId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_usuario_reportado', reportedUserId)
        .order('creado_en', ascending: false);
    return rows.map<ReportModel>((m) => ReportModel.fromMap(m)).toList();
  }

  Future<void> updateReportStatus(String id, String status) async {
    await supabase.from(_table).update({'estado': status}).eq('id', id);
  }
}
