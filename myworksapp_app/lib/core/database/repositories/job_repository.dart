import 'dart:convert';

import '../../utils/worker_job_status.dart';
import '../models/job_model.dart';
import '../supabase_db.dart';
class JobRepository {
  static const String _table = 'trabajos';

  Future<String> createJob(JobModel job) async {
    await supabase.from(_table).insert(job.toMap());
    return job.id;
  }

  Future<JobModel?> getJobById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return JobModel.fromMap(row);
  }

  Future<List<JobModel>> getJobsByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_usuario', userId)
        .order('creado_en', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<List<JobModel>> getJobsByWorkerId(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .order('creado_en', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<List<JobModel>> getPendingJobsForWorker(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .eq('estado', 'pendiente')
        .order('creado_en', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  /// Trabajos asignados al profesional que aún no están completados ni cancelados.
  Future<List<JobModel>> getActiveJobsByWorkerId(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .inFilter('estado', WorkerJobStatus.activeStatuses)
        .order('creado_en', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  // Verificar si un trabajador tiene trabajos activos
  Future<bool> hasActiveJobs(String workerId) async {
    final activeJobs = await getActiveJobsByWorkerId(workerId);
    return activeJobs.isNotEmpty;
  }

  Future<List<JobModel>> getJobsByStatus(String status) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('estado', status)
        .order('creado_en', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<void> updateJob(JobModel job) async {
    // Metadatos/campos no-estado: solo admin vía policy; estado vía RPC.
    await updateJobStatus(job.id, job.status);
  }

  /// Rechazo del profesional: mantiene [workerId] para cumplir RLS en Supabase.
  Future<bool> rejectPendingJobByWorker({
    required String jobId,
    required String workerId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final row = await supabase.rpc(
        'rechazar_trabajo_pendiente',
        params: {
          'p_trabajo_id': jobId,
          'p_metadatos': jsonEncode(metadata),
        },
      );
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateJobStatus(String id, String status, {String? pin}) async {
    await supabase.rpc(
      'transicionar_trabajo',
      params: {
        'p_trabajo_id': id,
        'p_nuevo_estado': status,
        if (pin != null) 'p_pin': pin,
      },
    );
  }

  Future<void> assignWorker(String jobId, String workerId) async {
    await supabase.rpc(
      'asignar_trabajador_trabajo',
      params: {
        'p_trabajo_id': jobId,
        'p_trabajador_id': workerId,
      },
    );
  }

  Future<void> deleteJob(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  /// Obtiene todos los trabajos de un trabajador (alias para getJobsByWorkerId)
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    return await getJobsByWorkerId(workerId);
  }
}
