import '../../supabase_db.dart';
import 'admin_models.dart';

class AdminMetricsRepository {
  Future<AdminMetrics> getMetrics() async {
    final results = await Future.wait([
      supabase.from('profiles').select('id'),
      supabase.from('workers').select('userId'),
      supabase.from('jobs').select('id'),
      supabase.from('disputes').select('id').eq('status', 'open'),
      supabase.from('disputes').select('id').eq('status', 'under_review'),
      supabase.from('reports').select('id').eq('status', 'pending'),
      supabase
          .from('jobs')
          .select('id')
          .inFilter('status', ['pending', 'accepted', 'in_progress']),
      supabase.from('app_error_logs').select('id').eq('status', 'new'),
      supabase.from('abuse_events').select('id').eq('isResolved', 0),
      supabase.from('pending_actions').select('id').eq('status', 'failed'),
    ]);

    return AdminMetrics(
      usersCount: (results[0] as List).length,
      workersCount: (results[1] as List).length,
      jobsCount: (results[2] as List).length,
      openDisputesCount: (results[3] as List).length,
      underReviewDisputesCount: (results[4] as List).length,
      pendingReportsCount: (results[5] as List).length,
      activeJobsCount: (results[6] as List).length,
      newErrorsCount: (results[7] as List).length,
      unresolvedAbuseCount: (results[8] as List).length,
      failedSyncCount: (results[9] as List).length,
    );
  }
}
