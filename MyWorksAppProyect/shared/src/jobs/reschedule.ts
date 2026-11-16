import type { AppSupabase } from '../client';

/**
 * Reagendar un trabajo: una parte propone una hora publicada y libre del
 * profesional; la otra la acepta o la rechaza. La base valida todo
 * (proponer_reprogramacion / responder_reprogramacion); estas funciones solo
 * anticipan el resultado para la interfaz y traducen los textos.
 */

export const RESCHEDULABLE_JOB_STATUSES = ['pendiente', 'aceptado'] as const;

/** Antelación mínima que exige la base para la nueva hora. */
export const RESCHEDULE_MIN_LEAD_MS = 60 * 60 * 1000;

export type RescheduleStatus = 'pendiente' | 'aceptada' | 'rechazada' | 'retirada' | 'vencida';

export interface RescheduleProposal {
  id: string;
  jobId: string;
  proposedBy: string;
  proposerRole: 'cliente' | 'profesional';
  previousAt: string;
  proposedAt: string;
  reason: string | null;
  status: RescheduleStatus;
  respondedBy: string | null;
  respondedAt: string | null;
  createdAt: string;
}

export interface ReschedulableJob {
  status: string;
  scheduledAt: string | null;
  workerId: string | null;
}

/** El trabajo admite una propuesta nueva (antes de "en camino" y de su hora). */
export function canProposeReschedule(job: ReschedulableJob, now: Date = new Date()): boolean {
  if (!job.workerId || !job.scheduledAt) return false;
  if (!(RESCHEDULABLE_JOB_STATUSES as readonly string[]).includes(job.status)) return false;
  const at = Date.parse(normalizeDbTimestamp(job.scheduledAt));
  return Number.isFinite(at) && at > now.getTime();
}

/** Horas que se pueden ofrecer: libres, distintas de la actual y con 1 h de margen. */
export function rescheduleSlotOptions(
  freeSlots: readonly string[],
  currentAt: string | null,
  now: Date = new Date(),
): string[] {
  const current = currentAt ? Date.parse(normalizeDbTimestamp(currentAt)) : Number.NaN;
  const minimum = now.getTime() + RESCHEDULE_MIN_LEAD_MS;
  return freeSlots.filter((slot) => {
    const at = Date.parse(normalizeDbTimestamp(slot));
    return Number.isFinite(at) && at > minimum && at !== current;
  });
}

/** Quién debe responder la propuesta pendiente. */
export function canRespondReschedule(proposal: RescheduleProposal | null, userId: string | null | undefined): boolean {
  return Boolean(proposal && userId && proposal.status === 'pendiente' && proposal.proposedBy !== userId);
}

export function rescheduleStatusLabel(status: string): string {
  switch (status) {
    case 'pendiente':
      return 'Esperando respuesta';
    case 'aceptada':
      return 'Aceptada';
    case 'rechazada':
      return 'Rechazada';
    case 'retirada':
      return 'Retirada';
    case 'vencida':
      return 'Venció';
    default:
      return 'Sin estado';
  }
}

/** Postgres devuelve "2026-11-17 14:00:00+00"; Safari no lo parsea sin la T. */
export function normalizeDbTimestamp(value: string): string {
  const trimmed = value.trim();
  const withT = /^\d{4}-\d{2}-\d{2} \d/.test(trimmed) ? trimmed.replace(' ', 'T') : trimmed;
  return withT.replace(/([+-]\d{2})$/, '$1:00');
}

export function mapRescheduleRow(row: Record<string, unknown>): RescheduleProposal {
  return {
    id: String(row.id),
    jobId: String(row.id_trabajo),
    proposedBy: String(row.propuesta_por),
    proposerRole: row.rol_proponente === 'profesional' ? 'profesional' : 'cliente',
    previousAt: String(row.fecha_anterior),
    proposedAt: String(row.fecha_propuesta),
    reason: (row.motivo as string | null) ?? null,
    status: String(row.estado) as RescheduleStatus,
    respondedBy: (row.respondida_por as string | null) ?? null,
    respondedAt: (row.respondida_en as string | null) ?? null,
    createdAt: String(row.creado_en),
  };
}

export async function fetchRescheduleHistory(
  supabase: AppSupabase,
  jobId: string,
): Promise<RescheduleProposal[]> {
  const { data, error } = await supabase
    .from('reprogramaciones_trabajo')
    .select('*')
    .eq('id_trabajo', jobId)
    .order('creado_en', { ascending: false })
    .limit(20);
  if (error) throw new Error('No se pudo leer el historial de cambios de hora.');
  return ((data ?? []) as Record<string, unknown>[]).map(mapRescheduleRow);
}

function rpcMessage(error: { message?: string } | null, fallback: string): string {
  const message = error?.message?.trim();
  if (!message || /forbidden|permission|jwt/i.test(message)) return fallback;
  return message;
}

export async function proposeReschedule(
  supabase: AppSupabase,
  jobId: string,
  proposedAtIso: string,
  reason?: string,
): Promise<RescheduleProposal> {
  const { data, error } = await supabase.rpc('proponer_reprogramacion', {
    p_trabajo_id: jobId,
    p_fecha: proposedAtIso,
    p_motivo: reason?.trim() || undefined,
  });
  if (error || !data) throw new Error(rpcMessage(error, 'No se pudo proponer la nueva hora.'));
  return mapRescheduleRow(data as unknown as Record<string, unknown>);
}

export async function respondReschedule(
  supabase: AppSupabase,
  proposalId: string,
  accept: boolean,
): Promise<RescheduleProposal> {
  const { data, error } = await supabase.rpc('responder_reprogramacion', {
    p_id: proposalId,
    p_acepta: accept,
  });
  if (error || !data) throw new Error(rpcMessage(error, 'No se pudo responder la propuesta.'));
  return mapRescheduleRow(data as unknown as Record<string, unknown>);
}

export async function withdrawReschedule(
  supabase: AppSupabase,
  proposalId: string,
): Promise<RescheduleProposal> {
  const { data, error } = await supabase.rpc('retirar_reprogramacion', { p_id: proposalId });
  if (error || !data) throw new Error(rpcMessage(error, 'No se pudo retirar la propuesta.'));
  return mapRescheduleRow(data as unknown as Record<string, unknown>);
}
