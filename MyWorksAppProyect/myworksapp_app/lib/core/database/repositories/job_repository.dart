import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../domain/pricing_constants.dart';
import '../../utils/app_error.dart';
import '../../utils/constants.dart';
import '../../utils/json_map.dart';
import '../../utils/worker_job_status.dart';
import '../job_insert_policy.dart';
import '../models/job_model.dart';
import '../supabase_db.dart';

class JobRepository {
  static const String _table = 'trabajos';

  Future<String> createJob(JobModel job) async {
    if (!jobInsertMatchesPolicy(workerId: job.workerId, status: job.status)) {
      throw AppError.validation(
        'Un trabajo nuevo empieza pendiente sin profesional, esperando pago o esperando cotizaciones.',
      );
    }
    final data = job.toMap();
    data['instantanea_precio'] = null;
    data['id_cotizacion_seleccionada'] = null;
    await supabase.from(_table).insert(data);
    return job.id;
  }

  Future<JobModel?> getJobById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row != null) return JobModel.fromMap(row);
    final pub = await supabase.rpc(
      'obtener_trabajo_sin_direccion',
      params: {'p_id': id},
    );
    if (pub == null) return null;
    if (pub is! Map) return null;
    return _openListing(Map<String, dynamic>.from(pub));
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

  /// Una página del historial (más recientes primero). Para «Mis Proyectos»:
  /// un cliente con 88 trabajos ya no baja todo de una vez.
  Future<List<JobModel>> getJobsPage({
    required String userId,
    required bool asWorker,
    required int offset,
    int limit = 20,
  }) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq(asWorker ? 'id_trabajador' : 'id_usuario', userId)
        .order('creado_en', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
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

  /// Pedidos asignados al profesional: pagados (`pendiente`) o con checkout
  /// iniciado desde la web (`esperando_pago`).
  Future<List<JobModel>> getIncomingJobsForWorker(String workerId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('id_trabajador', workerId)
        .inFilter('estado', [
      AppConstants.jobStatusPending,
      PricingConstants.jobAwaitingPayment,
    ]).order('creado_en', ascending: false);
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

  /// True si el profesional tiene al menos un trabajo en curso (sin bajar filas).
  Future<bool> hasActiveJobs(String workerId) async {
    final row = await supabase
        .from(_table)
        .select('id')
        .eq('id_trabajador', workerId)
        .inFilter('estado', WorkerJobStatus.busyStatuses)
        .limit(1)
        .maybeSingle();
    return row != null;
  }

  /// IDs de profesionales con al menos un trabajo activo (una consulta, no N+1).
  ///
  /// Usa la RPC `profesionales_ocupados`, que ve los trabajos de todos los
  /// clientes y devuelve solo ids. Si la RPC aún no existe en la base, cae a
  /// la consulta directa (que por RLS solo ve los trabajos propios).
  Future<Set<String>> getBusyWorkerIds(List<String> workerIds) async {
    if (workerIds.isEmpty) return {};
    const chunkSize = 200;
    final busy = <String>{};
    for (var i = 0; i < workerIds.length; i += chunkSize) {
      final end =
          i + chunkSize > workerIds.length ? workerIds.length : i + chunkSize;
      final chunk = workerIds.sublist(i, end);
      try {
        final rows = await supabase.rpc(
          'profesionales_ocupados',
          params: {'p_ids': chunk},
        );
        busy.addAll(parseBusyWorkerIds(rows));
      } catch (_) {
        busy.addAll(await _busyWorkerIdsDirect(chunk));
      }
    }
    return busy;
  }

  Future<Set<String>> _busyWorkerIdsDirect(List<String> chunk) async {
    final rows = await supabase
        .from(_table)
        .select('id_trabajador')
        .inFilter('id_trabajador', chunk)
        .inFilter('estado', WorkerJobStatus.busyStatuses);
    return {
      for (final row in rows)
        if (row['id_trabajador'] is String) row['id_trabajador'] as String,
    };
  }

  /// La RPC devuelve `SETOF uuid`: PostgREST lo entrega como lista de
  /// strings (o de mapas `{profesionales_ocupados: id}` según la versión).
  @visibleForTesting
  static Set<String> parseBusyWorkerIds(dynamic rows) {
    if (rows is! List) return {};
    final ids = <String>{};
    for (final row in rows) {
      if (row is String && row.isNotEmpty) {
        ids.add(row);
      } else if (row is Map) {
        final value = row['profesionales_ocupados'] ?? row.values.firstOrNull;
        if (value is String && value.isNotEmpty) ids.add(value);
      }
    }
    return ids;
  }

  /// Conteos de historial sin bajar filas completas.
  Future<({int total, int completed})> countJobsByUserId(String userId) {
    return _countJobs('id_usuario', userId);
  }

  Future<({int total, int completed})> countJobsByWorkerId(String workerId) {
    return _countJobs('id_trabajador', workerId);
  }

  Future<({int total, int completed})> _countJobs(
    String column,
    String id,
  ) async {
    final rows = await supabase.from(_table).select('estado').eq(column, id);
    var completed = 0;
    for (final row in rows) {
      if (row['estado'] == AppConstants.jobStatusCompleted) completed++;
    }
    return (total: rows.length, completed: completed);
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
    } catch (e) {
      throw AppError.database('No se pudo rechazar el trabajo: $e');
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

  Future<void> requestWorker({
    required String jobId,
    required String workerId,
  }) async {
    await supabase.rpc(
      'vincular_trabajador_solicitud',
      params: {
        'p_trabajo_id': jobId,
        'p_trabajador_id': workerId,
      },
    );
  }

  /// El cliente recibe conforme: completa el trabajo y libera el pago retenido.
  Future<void> closeOnClientApproval(String jobId) async {
    await supabase.rpc(
      'cerrar_trabajo_conforme',
      params: {'p_trabajo_id': jobId},
    );
  }

  Future<void> linkQuotedWorker({
    required String jobId,
    required String workerId,
  }) async {
    await supabase.rpc(
      'vincular_trabajador_cotizacion',
      params: {
        'p_trabajo_id': jobId,
        'p_trabajador_id': workerId,
      },
    );
  }

  Future<void> syncPaymentStatusFromLedger(String jobId) async {
    await supabase.rpc(
      'sincronizar_estado_pago_trabajo',
      params: {'p_trabajo_id': jobId},
    );
  }

  Future<List<JobModel>> listOpenMarketplaceJobs() async {
    final rows = await supabase.rpc(
      'listar_trabajos_marketplace',
      params: {'p_limite': 50},
    );
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => _openListing(Map<String, dynamic>.from(row)))
        .toList();
  }

  JobModel _openListing(Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();
    DateTime parse(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? now;
      }
      return now;
    }

    final metadata = decodeJsonMap(map['metadatos_servicio']);

    return JobModel(
      id: map['id'] as String,
      userId: '',
      serviceId: (map['id_servicio'] as String?) ?? '',
      status: (map['estado'] as String?) ?? 'pendiente',
      address: 'La dirección se muestra al aceptar el trabajo',
      description: map['descripcion'] as String?,
      serviceMetadata: metadata,
      pricingMode: (map['modalidad_cobro'] as String?) ?? 'legado',
      createdAt: parse(map['creado_en']),
      updatedAt: parse(map['actualizado_en']),
    );
  }

  /// Cancelaciones y última actividad de varios profesionales en una sola
  /// consulta (solo 3 columnas), en vez de bajar todo el historial por cada uno.
  Future<Map<String, WorkerJobStats>> getWorkerJobStats(
    List<String> workerIds,
  ) async {
    final ids = workerIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return {};
    final rows = await supabase
        .from(_table)
        .select('id_trabajador, estado, creado_en')
        .inFilter('id_trabajador', ids);
    final out = <String, WorkerJobStats>{};
    for (final row in rows) {
      final id = row['id_trabajador'] as String?;
      if (id == null) continue;
      final current = out[id] ?? const WorkerJobStats();
      final created = DateTime.tryParse(row['creado_en'] as String? ?? '');
      out[id] = WorkerJobStats(
        cancelled: current.cancelled +
            (row['estado'] == AppConstants.jobStatusCancelled ? 1 : 0),
        lastActivity: created == null ||
                (current.lastActivity != null &&
                    !created.isAfter(current.lastActivity!))
            ? current.lastActivity
            : created,
      );
    }
    return out;
  }

  /// Obtiene todos los trabajos de un trabajador (alias para getJobsByWorkerId)
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    return await getJobsByWorkerId(workerId);
  }
}

class WorkerJobStats {
  const WorkerJobStats({this.cancelled = 0, this.lastActivity});

  final int cancelled;
  final DateTime? lastActivity;
}
