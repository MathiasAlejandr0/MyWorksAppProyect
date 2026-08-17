import '../models/report_model.dart';
import '../supabase_db.dart';

class ReportRepository {
  static const String _table = 'reports';

  Future<void> createReport(ReportModel report) async {
    await supabase.from(_table).insert(report.toMap());
  }

  Future<List<ReportModel>> getReportsByReporterId(String reporterId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('reporterId', reporterId)
        .order('createdAt', ascending: false);
    return rows.map<ReportModel>((m) => ReportModel.fromMap(m)).toList();
  }

  Future<List<ReportModel>> getReportsByReportedUserId(
      String reportedUserId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('reportedUserId', reportedUserId)
        .order('createdAt', ascending: false);
    return rows.map<ReportModel>((m) => ReportModel.fromMap(m)).toList();
  }

  Future<void> updateReportStatus(String id, String status) async {
    await supabase.from(_table).update({'status': status}).eq('id', id);
  }
}
