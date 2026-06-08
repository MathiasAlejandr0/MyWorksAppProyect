import 'dart:convert';

import '../../domain/pricing_constants.dart';
import '../../utils/constants.dart';
import '../models/job_model.dart';
import '../supabase_db.dart';
class JobRepository {
  static const String _table = 'jobs';

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
        .eq('userId', userId)
        .order('createdAt', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<List<JobModel>> getJobsByWorkerId(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('workerId', workerId)
        .order('createdAt', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<List<JobModel>> getPendingJobsForWorker(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('workerId', workerId)
        .eq('status', 'pending')
        .order('createdAt', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  // Obtener trabajos activos (accepted o in_progress) de un trabajador
  Future<List<JobModel>> getActiveJobsByWorkerId(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('workerId', workerId)
        .inFilter('status', [
          'accepted',
          'in_progress',
          PricingConstants.jobAwaitingClientApproval,
        ])
        .order('createdAt', ascending: false);
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
        .eq('status', status)
        .order('createdAt', ascending: false);
    return rows.map<JobModel>((m) => JobModel.fromMap(m)).toList();
  }

  Future<void> updateJob(JobModel job) async {
    await supabase.from(_table).update(job.toMap()).eq('id', job.id);
  }

  /// Rechazo del profesional: mantiene [workerId] para cumplir RLS en Supabase.
  Future<bool> rejectPendingJobByWorker({
    required String jobId,
    required String workerId,
    required Map<String, dynamic> metadata,
  }) async {
    final rows = await supabase
        .from(_table)
        .update({
          'status': AppConstants.jobStatusCancelled,
          'serviceMetadata': jsonEncode(metadata),
          'updatedAt': DateTime.now().toIso8601String(),
        })
        .eq('id', jobId)
        .eq('workerId', workerId)
        .eq('status', AppConstants.jobStatusPending)
        .select('id');
    return rows.isNotEmpty;
  }

  Future<void> updateJobStatus(String id, String status) async {
    await supabase.from(_table).update({'status': status}).eq('id', id);
  }

  Future<void> assignWorker(String jobId, String workerId) async {
    await supabase
        .from(_table)
        .update({'workerId': workerId, 'status': 'accepted'}).eq('id', jobId);
  }

  Future<void> deleteJob(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  /// Obtiene todos los trabajos de un trabajador (alias para getJobsByWorkerId)
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    return await getJobsByWorkerId(workerId);
  }
}
