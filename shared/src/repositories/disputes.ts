import type { AppSupabase } from '../client';
import type { DisputeRow, DisputeStatus, DisputeWithContext } from '../types';

interface JobSummary {
  id: string;
  id_usuario?: string | null;
  id_trabajador?: string | null;
  descripcion?: string | null;
}

/** Payload tipado del RPC `admin_actualizar_estado_disputa`. */
export interface AdminActualizarEstadoDisputaArgs {
  p_id: string;
  p_estado: DisputeStatus | string;
  p_resolucion?: string | null;
}

export interface AdminActualizarEstadoDisputaResult {
  id: string;
  id_trabajo: string;
  estado: string;
  resolucion: string | null;
  resuelta_por: string | null;
  resuelta_en: string | null;
  actualizado_en: string;
}

function mapDispute(row: Record<string, unknown>): DisputeRow {
  return {
    id: row.id as string,
    jobId: row.id_trabajo as string,
    openedBy: row.abierta_por as string,
    reason: row.motivo as string,
    description: row.descripcion as string | null,
    status: row.estado as DisputeStatus,
    resolution: row.resolucion as string | null,
    createdAt: row.creado_en as string,
    updatedAt: row.actualizado_en as string,
  };
}

export async function fetchOpenDisputes(
  supabase: AppSupabase,
): Promise<DisputeWithContext[]> {
  const { data, error } = await supabase
    .from('disputas')
    .select('id, id_trabajo, abierta_por, motivo, descripcion, estado, resolucion, creado_en, actualizado_en')
    .in('estado', ['abierta', 'en_revision'])
    .order('creado_en', { ascending: false });

  if (error) throw error;
  const disputes = ((data ?? []) as Record<string, unknown>[]).map(mapDispute);
  if (disputes.length === 0) return [];

  const jobIds = [...new Set(disputes.map((d) => d.jobId))];
  const { data: jobs, error: jobsError } = await supabase
    .from('trabajos')
    .select('id, id_usuario, id_trabajador, descripcion')
    .in('id', jobIds);

  if (jobsError) throw jobsError;

  const { data: payments } = await supabase
    .from('pagos')
    .select('id_trabajo, monto, estado')
    .in('id_trabajo', jobIds)
    .in('estado', ['autorizado', 'retenido', 'pendiente']);

  const escrowByJob = new Map<string, number>();
  for (const p of payments ?? []) {
    const row = p as { id_trabajo: string; monto: number };
    const prev = escrowByJob.get(row.id_trabajo) ?? 0;
    escrowByJob.set(row.id_trabajo, Math.max(prev, Number(row.monto) || 0));
  }

  const jobRows = (jobs ?? []) as JobSummary[];
  const userIds = new Set<string>();
  for (const job of jobRows) {
    if (job.id_usuario) userIds.add(job.id_usuario);
    if (job.id_trabajador) userIds.add(job.id_trabajador);
  }

  const { data: profiles, error: profilesError } = await supabase
    .from('perfiles')
    .select('id, nombre')
    .in('id', [...userIds]);

  if (profilesError) throw profilesError;

  const profileMap = new Map<string, string>(
    (profiles ?? []).map((p: { id: string; nombre: string }) => [p.id, p.nombre]),
  );
  const jobMap = new Map<string, JobSummary>(jobRows.map((j) => [j.id, j]));

  return disputes.map((dispute) => {
    const job = jobMap.get(dispute.jobId);
    const clientName = job?.id_usuario ? profileMap.get(job.id_usuario) ?? 'Cliente' : 'Cliente';
    const workerName = job?.id_trabajador
      ? profileMap.get(job.id_trabajador) ?? 'Profesional'
      : 'Profesional';

    return {
      ...dispute,
      clientName,
      workerName,
      escrowAmount: escrowByJob.get(dispute.jobId) ?? 0,
    };
  });
}

/**
 * Actualiza estado/resolución vía RPC admin (SECURITY DEFINER + is_admin).
 * Requiere migración `20260914000005_rls_politicas_negocio.sql`.
 * `resolvedBy` se ignora: el servidor usa auth.uid().
 */
export async function updateDisputeStatus(
  supabase: AppSupabase,
  disputeId: string,
  status: DisputeStatus,
  resolution: string,
  _resolvedBy?: string,
): Promise<AdminActualizarEstadoDisputaResult> {
  const args: AdminActualizarEstadoDisputaArgs = {
    p_id: disputeId,
    p_estado: status,
    p_resolucion: resolution,
  };

  const { data, error } = await supabase.rpc('admin_actualizar_estado_disputa', args);

  if (error) throw error;

  const row = (data ?? {}) as Record<string, unknown>;
  return {
    id: String(row.id ?? disputeId),
    id_trabajo: String(row.id_trabajo ?? ''),
    estado: String(row.estado ?? status),
    resolucion: (row.resolucion as string | null) ?? resolution,
    resuelta_por: (row.resuelta_por as string | null) ?? null,
    resuelta_en: (row.resuelta_en as string | null) ?? null,
    actualizado_en: String(row.actualizado_en ?? new Date().toISOString()),
  };
}
