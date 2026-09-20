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
    var query = supabase.from('trabajos').select();
    if (status != null) {
      query = query.eq('estado', status);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or(
        'direccion.ilike.$q,id.ilike.$q,descripcion.ilike.$q,id_comuna.ilike.$q',
      );
    }
    final rows = await query.order('creado_en', ascending: false).limit(limit);
    return rows
        .map<JobModel>((m) => JobModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await supabase.rpc(
      'transicionar_trabajo',
      params: {
        'p_trabajo_id': jobId,
        'p_nuevo_estado': status,
      },
    );
  }

  Future<AdminJobDetail?> getJobDetail(String jobId) async {
    final jobRow =
        await supabase.from('trabajos').select().eq('id', jobId).maybeSingle();
    if (jobRow == null) return null;
    final job = JobModel.fromMap(Map<String, dynamic>.from(jobRow));

    final profileIds = <String>{job.userId};
    if (job.workerId != null) profileIds.add(job.workerId!);

    final profiles = await supabase
        .from('perfiles')
        .select('id, nombre, correo')
        .inFilter('id', profileIds.toList());
    final profileMap = {
      for (final p in profiles) p['id'] as String: Map<String, dynamic>.from(p),
    };

    String? serviceName;
    if (job.serviceId.isNotEmpty) {
      final svc = await supabase
          .from('servicios')
          .select('nombre')
          .eq('id', job.serviceId)
          .maybeSingle();
      serviceName = svc?['nombre'] as String?;
    }

    final messageRows = await supabase
        .from('mensajes')
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: true);
    final messages = messageRows
        .map<MessageModel>(
          (m) => MessageModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final paymentRows =
        await supabase.from('pagos').select().eq('id_trabajo', jobId);
    final payments = paymentRows
        .map<PaymentModel>(
          (m) => PaymentModel.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final disputeRows = await supabase
        .from('disputas')
        .select()
        .eq('id_trabajo', jobId)
        .order('creado_en', ascending: false)
        .limit(1);
    final dispute = disputeRows.isNotEmpty
        ? DisputeModel.fromMap(
            Map<String, dynamic>.from(disputeRows.first),
          )
        : null;

    final ratingRow = await supabase
        .from('calificaciones')
        .select()
        .eq('id_trabajo', jobId)
        .maybeSingle();
    final rating = ratingRow != null
        ? RatingModel.fromMap(Map<String, dynamic>.from(ratingRow))
        : null;

    final cancelRow = await supabase
        .from('cancelaciones_trabajo')
        .select()
        .eq('id_trabajo', jobId)
        .maybeSingle();
    AdminJobCancellation? cancellation;
    if (cancelRow != null) {
      cancellation = AdminJobCancellation(
        reason: cancelRow['motivo'] as String,
        cancelledBy: cancelRow['cancelado_por'] as String,
        cancelledAt: DateTime.parse(cancelRow['cancelado_en'] as String),
      );
    }

    final client = profileMap[job.userId];
    final worker = job.workerId != null ? profileMap[job.workerId!] : null;

    return AdminJobDetail(
      job: job,
      clientName: client?['nombre'] as String?,
      clientEmail: client?['correo'] as String?,
      workerName: worker?['nombre'] as String?,
      workerEmail: worker?['correo'] as String?,
      serviceName: serviceName,
      messages: messages,
      payments: payments,
      dispute: dispute,
      rating: rating,
      cancellation: cancellation,
    );
  }
}
