import '../../models/dispute_model.dart';
import '../../models/job_model.dart';
import '../../models/message_model.dart';
import '../../models/payment_model.dart';
import '../../models/rating_model.dart';
import '../../supabase_db.dart';
import 'admin_models.dart';

class AdminJobsRepository {
  Future<List<JobModel>> listJobs({
    String? status,
    String? search,
    int limit = 100,
  }) async {
    var query = supabase.from('jobs').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or(
        'address.ilike.$q,id.ilike.$q,description.ilike.$q,comunaId.ilike.$q',
      );
    }
    final rows =
        await query.order('createdAt', ascending: false).limit(limit);
    return rows
        .map<JobModel>((m) => JobModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await supabase.from('jobs').update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<AdminJobDetail?> getJobDetail(String jobId) async {
    final jobRow =
        await supabase.from('jobs').select().eq('id', jobId).maybeSingle();
    if (jobRow == null) return null;
    final job = JobModel.fromMap(Map<String, dynamic>.from(jobRow));

    final profileIds = <String>{job.userId};
    if (job.workerId != null) profileIds.add(job.workerId!);

    final profiles = await supabase
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', profileIds.toList());
    final profileMap = {
      for (final p in profiles)
        p['id'] as String: Map<String, dynamic>.from(p),
    };

    String? serviceName;
    if (job.serviceId.isNotEmpty) {
      final svc = await supabase
          .from('services')
          .select('name')
          .eq('id', job.serviceId)
          .maybeSingle();
      serviceName = svc?['name'] as String?;
    }

    final messageRows = await supabase
        .from('messages')
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: true);
    final messages = messageRows
        .map<MessageModel>(
          (m) => MessageModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final paymentRows =
        await supabase.from('payments').select().eq('jobId', jobId);
    final payments = paymentRows
        .map<PaymentModel>(
          (m) => PaymentModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final disputeRows = await supabase
        .from('disputes')
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: false)
        .limit(1);
    final dispute = disputeRows.isNotEmpty
        ? DisputeModel.fromMap(
            Map<String, dynamic>.from(disputeRows.first),
          )
        : null;

    final ratingRow = await supabase
        .from('ratings')
        .select()
        .eq('jobId', jobId)
        .maybeSingle();
    final rating = ratingRow != null
        ? RatingModel.fromMap(Map<String, dynamic>.from(ratingRow))
        : null;

    final cancelRow = await supabase
        .from('job_cancellations')
        .select()
        .eq('jobId', jobId)
        .maybeSingle();
    AdminJobCancellation? cancellation;
    if (cancelRow != null) {
      cancellation = AdminJobCancellation(
        reason: cancelRow['reason'] as String,
        cancelledBy: cancelRow['cancelledBy'] as String,
        cancelledAt: DateTime.parse(cancelRow['cancelledAt'] as String),
      );
    }

    final client = profileMap[job.userId];
    final worker =
        job.workerId != null ? profileMap[job.workerId!] : null;

    return AdminJobDetail(
      job: job,
      clientName: client?['name'] as String?,
      clientEmail: client?['email'] as String?,
      workerName: worker?['name'] as String?,
      workerEmail: worker?['email'] as String?,
      serviceName: serviceName,
      messages: messages,
      payments: payments,
      dispute: dispute,
      rating: rating,
      cancellation: cancellation,
    );
  }
}
