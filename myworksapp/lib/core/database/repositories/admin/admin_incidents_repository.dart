import '../../models/abuse_event_model.dart';
import '../../models/app_error_log_model.dart';
import '../../models/dispute_model.dart';
import '../../models/pending_action_model.dart';
import '../../models/report_model.dart';
import '../../supabase_db.dart';
import '../app_error_log_repository.dart';
import 'admin_models.dart';

class AdminIncidentsRepository {
  final AppErrorLogRepository _errorLogRepo = AppErrorLogRepository();

  Future<List<DisputeModel>> listDisputes({
    String? status,
    String? search,
    int limit = 100,
  }) async {
    var query = supabase.from('disputes').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or('reason.ilike.$q,description.ilike.$q,jobId.ilike.$q');
    }
    final rows =
        await query.order('createdAt', ascending: false).limit(limit);
    return rows
        .map<DisputeModel>(
          (m) => DisputeModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<void> markDisputeUnderReview(String disputeId) async {
    await supabase.from('disputes').update({
      'status': 'under_review',
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', disputeId);
  }

  Future<List<AdminReportEntry>> listReports({
    String? status,
    String? search,
    int limit = 100,
  }) async {
    var query = supabase.from('reports').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or('reason.ilike.$q,description.ilike.$q');
    }
    final rows =
        await query.order('createdAt', ascending: false).limit(limit);
    final reports = rows
        .map<ReportModel>(
          (m) => ReportModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final userIds = <String>{};
    for (final r in reports) {
      userIds.add(r.reporterId);
      userIds.add(r.reportedUserId);
    }
    final nameById = await _profileNamesByIds(userIds);

    return reports
        .map(
          (r) => AdminReportEntry(
            report: r,
            reporterName: nameById[r.reporterId],
            reportedName: nameById[r.reportedUserId],
          ),
        )
        .toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await supabase.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<List<AppErrorLogModel>> listErrorLogs({
    String? status,
    String? search,
  }) async {
    final logs = await _errorLogRepo.listLogs(status: status);
    if (search == null || search.isEmpty) return logs;
    final lower = search.toLowerCase();
    return logs
        .where(
          (l) =>
              l.message.toLowerCase().contains(lower) ||
              l.errorType.toLowerCase().contains(lower) ||
              (l.platform?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  Future<void> updateErrorLogStatus(String id, String status) =>
      _errorLogRepo.updateStatus(id, status);

  Future<List<PendingActionModel>> listPendingActions({
    String? status,
    String? search,
    int limit = 100,
  }) async {
    var query = supabase.from('pending_actions').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or(
        'actionType.ilike.$q,entityType.ilike.$q,errorMessage.ilike.$q',
      );
    }
    final rows =
        await query.order('createdAt', ascending: false).limit(limit);
    return rows
        .map<PendingActionModel>(
          (m) => PendingActionModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<List<AbuseEventModel>> listAbuseEvents({
    bool unresolvedOnly = false,
    String? search,
    int limit = 100,
  }) async {
    var query = supabase.from('abuse_events').select();
    if (unresolvedOnly) {
      query = query.eq('isResolved', 0);
    }
    final rows =
        await query.order('detectedAt', ascending: false).limit(limit);
    var events = rows
        .map<AbuseEventModel>(
          (m) => AbuseEventModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      events = events
          .where(
            (e) =>
                e.abuseType.toLowerCase().contains(lower) ||
                e.userId.toLowerCase().contains(lower) ||
                (e.actionTaken?.toLowerCase().contains(lower) ?? false),
          )
          .toList();
    }
    return events;
  }

  Future<void> resolveAbuseEvent(String eventId) async {
    await supabase.from('abuse_events').update({
      'isResolved': 1,
      'actionTakenAt': DateTime.now().toIso8601String(),
    }).eq('id', eventId);
  }

  Future<Map<String, String>> _profileNamesByIds(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await supabase
        .from('profiles')
        .select('id, name')
        .inFilter('id', ids.toList());
    return {
      for (final row in rows)
        row['id'] as String: row['name'] as String? ?? 'Usuario',
    };
  }
}
