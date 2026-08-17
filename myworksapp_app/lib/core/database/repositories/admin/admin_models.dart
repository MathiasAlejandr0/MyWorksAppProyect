import '../../models/dispute_model.dart';
import '../../models/job_model.dart';
import '../../models/message_model.dart';
import '../../models/payment_model.dart';
import '../../models/rating_model.dart';
import '../../models/report_model.dart';
import '../../models/worker_model.dart';

class AdminMetrics {
  final int usersCount;
  final int workersCount;
  final int jobsCount;
  final int openDisputesCount;
  final int pendingReportsCount;
  final int underReviewDisputesCount;
  final int activeJobsCount;
  final int newErrorsCount;
  final int unresolvedAbuseCount;
  final int failedSyncCount;

  const AdminMetrics({
    required this.usersCount,
    required this.workersCount,
    required this.jobsCount,
    required this.openDisputesCount,
    required this.pendingReportsCount,
    required this.underReviewDisputesCount,
    required this.activeJobsCount,
    required this.newErrorsCount,
    required this.unresolvedAbuseCount,
    required this.failedSyncCount,
  });

  int get totalIncidents =>
      openDisputesCount +
      pendingReportsCount +
      newErrorsCount +
      unresolvedAbuseCount +
      failedSyncCount;
}

class AdminWorkerEntry {
  final WorkerModel worker;
  final String name;
  final String? email;
  final String accountStatus;

  const AdminWorkerEntry({
    required this.worker,
    required this.name,
    this.email,
    required this.accountStatus,
  });
}

class AdminReportEntry {
  final ReportModel report;
  final String? reporterName;
  final String? reportedName;

  const AdminReportEntry({
    required this.report,
    required this.reporterName,
    required this.reportedName,
  });
}

class AdminJobCancellation {
  final String reason;
  final String cancelledBy;
  final DateTime cancelledAt;

  const AdminJobCancellation({
    required this.reason,
    required this.cancelledBy,
    required this.cancelledAt,
  });
}

class AdminJobDetail {
  final JobModel job;
  final String? clientName;
  final String? clientEmail;
  final String? workerName;
  final String? workerEmail;
  final String? serviceName;
  final List<MessageModel> messages;
  final List<PaymentModel> payments;
  final DisputeModel? dispute;
  final RatingModel? rating;
  final AdminJobCancellation? cancellation;

  const AdminJobDetail({
    required this.job,
    this.clientName,
    this.clientEmail,
    this.workerName,
    this.workerEmail,
    this.serviceName,
    this.messages = const [],
    this.payments = const [],
    this.dispute,
    this.rating,
    this.cancellation,
  });
}
