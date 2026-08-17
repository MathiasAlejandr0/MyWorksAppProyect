import '../models/abuse_event_model.dart';
import '../models/app_error_log_model.dart';
import '../models/dispute_model.dart';
import '../models/feature_flag_model.dart';
import '../models/job_model.dart';
import '../models/pending_action_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import 'admin/admin_catalog_repository.dart';
import 'admin/admin_incidents_repository.dart';
import 'admin/admin_jobs_repository.dart';
import 'admin/admin_metrics_repository.dart';
import 'admin/admin_models.dart';
import 'admin/admin_users_repository.dart';

export 'admin/admin_models.dart';

/// Fachada del panel admin; delega en repositorios por dominio.
class AdminRepository {
  final AdminMetricsRepository _metrics = AdminMetricsRepository();
  final AdminUsersRepository _users = AdminUsersRepository();
  final AdminIncidentsRepository _incidents = AdminIncidentsRepository();
  final AdminJobsRepository _jobs = AdminJobsRepository();
  final AdminCatalogRepository _catalog = AdminCatalogRepository();

  Future<AdminMetrics> getMetrics() => _metrics.getMetrics();

  Future<List<UserModel>> listUsers({
    int limit = 100,
    String? role,
    String? search,
    String? accountStatus,
  }) =>
      _users.listUsers(
        limit: limit,
        role: role,
        search: search,
        accountStatus: accountStatus,
      );

  Future<void> updateAccountStatus(String userId, String status) =>
      _users.updateAccountStatus(userId, status);

  Future<List<DisputeModel>> listDisputes({
    String? status,
    String? search,
    int limit = 100,
  }) =>
      _incidents.listDisputes(status: status, search: search, limit: limit);

  Future<void> markDisputeUnderReview(String disputeId) =>
      _incidents.markDisputeUnderReview(disputeId);

  Future<List<AdminReportEntry>> listReports({
    String? status,
    String? search,
    int limit = 100,
  }) =>
      _incidents.listReports(status: status, search: search, limit: limit);

  Future<void> updateReportStatus(String reportId, String status) =>
      _incidents.updateReportStatus(reportId, status);

  Future<List<JobModel>> listJobs({
    String? status,
    String? search,
    int limit = 100,
  }) =>
      _jobs.listJobs(status: status, search: search, limit: limit);

  Future<void> updateJobStatus(String jobId, String status) =>
      _jobs.updateJobStatus(jobId, status);

  Future<AdminJobDetail?> getJobDetail(String jobId) =>
      _jobs.getJobDetail(jobId);

  Future<List<AdminWorkerEntry>> listWorkers({
    int limit = 100,
    String? search,
    bool? availableOnly,
  }) =>
      _catalog.listWorkers(
        limit: limit,
        search: search,
        availableOnly: availableOnly,
      );

  Future<void> setWorkerAvailability(String userId, bool available) =>
      _catalog.setWorkerAvailability(userId, available);

  Future<List<AppErrorLogModel>> listErrorLogs({
    String? status,
    String? search,
  }) =>
      _incidents.listErrorLogs(status: status, search: search);

  Future<void> updateErrorLogStatus(String id, String status) =>
      _incidents.updateErrorLogStatus(id, status);

  Future<List<PendingActionModel>> listPendingActions({
    String? status,
    String? search,
    int limit = 100,
  }) =>
      _incidents.listPendingActions(
        status: status,
        search: search,
        limit: limit,
      );

  Future<List<AbuseEventModel>> listAbuseEvents({
    bool unresolvedOnly = false,
    String? search,
    int limit = 100,
  }) =>
      _incidents.listAbuseEvents(
        unresolvedOnly: unresolvedOnly,
        search: search,
        limit: limit,
      );

  Future<void> resolveAbuseEvent(String eventId) =>
      _incidents.resolveAbuseEvent(eventId);

  Future<List<FeatureFlagModel>> listFeatureFlags() =>
      _catalog.listFeatureFlags();

  Future<void> upsertFeatureFlag(FeatureFlagModel flag) =>
      _catalog.upsertFeatureFlag(flag);

  Future<void> deleteFeatureFlag(String flagId) =>
      _catalog.deleteFeatureFlag(flagId);

  Future<List<ServiceModel>> listAllServices() => _catalog.listAllServices();

  Future<void> setServiceActive(String serviceId, bool active) =>
      _catalog.setServiceActive(serviceId, active);
}
