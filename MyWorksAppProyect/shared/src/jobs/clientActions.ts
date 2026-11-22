import type { AppSupabase } from '../client';
import { registrarEvento } from '../ia/buscar';
import { edgeFunctionErrorMessage } from '../payments/edgeError';

/**
 * Acciones del cliente en la web con las mismas reglas que la app:
 * cancelar (devolver el retenido con webpay-refund-cancellation y luego
 * transicionar_trabajo) y calificar un trabajo completado (tabla
 * calificaciones; la política RLS exige trabajo completado y sin disputa
 * activa).
 */

/** Igual que la app: el cliente cancela antes de que el profesional acepte. */
export const CLIENT_CANCELLABLE_STATUSES = ['esperando_pago', 'pendiente'] as const;

export function canClientCancel(status: string | null | undefined): boolean {
  return (CLIENT_CANCELLABLE_STATUSES as readonly string[]).includes(status ?? '');
}

export function canClientRate(status: string | null | undefined, alreadyRated: boolean): boolean {
  return status === 'completado' && !alreadyRated;
}

export function validateRating(score: number, comment: string): string | null {
  if (!Number.isInteger(score) || score < 1 || score > 5) return 'Elige de 1 a 5 estrellas.';
  if (comment.trim().length > 500) return 'El comentario puede tener hasta 500 caracteres.';
  return null;
}

function newId(): string {
  return globalThis.crypto.randomUUID();
}

function rpcMessage(message: string | undefined, fallback: string): string {
  const clean = message?.trim();
  if (!clean || /forbidden|permission|jwt|row-level/i.test(clean)) return fallback;
  return clean.charAt(0).toUpperCase() + clean.slice(1);
}

export interface CancelJobInput {
  jobId: string;
  userId: string;
  workerId: string | null;
  reason: string;
}

export async function cancelJobAsClient(supabase: AppSupabase, input: CancelJobInput): Promise<void> {
  const reason = input.reason.trim();
  if (!reason) throw new Error('Cuéntanos por qué cancelas.');

  const refund = await supabase.functions.invoke('webpay-refund-cancellation', {
    body: { jobId: input.jobId },
  });
  if (refund.error) {
    throw new Error(await edgeFunctionErrorMessage(refund.error, 'No se pudo devolver el pago.'));
  }
  const refundBody = refund.data as { error?: string } | null;
  if (refundBody?.error) throw new Error(refundBody.error);

  const { error } = await supabase.rpc('transicionar_trabajo', {
    p_trabajo_id: input.jobId,
    p_nuevo_estado: 'cancelado',
  });
  if (error) throw new Error(rpcMessage(error.message, 'No se pudo cancelar la solicitud.'));

  const now = new Date().toISOString();
  await supabase.from('cancelaciones_trabajo').insert({
    id: newId(),
    id_trabajo: input.jobId,
    cancelado_por: input.userId,
    motivo: reason.slice(0, 500),
    cancelado_en: now,
  });
  await registrarEvento(supabase, { tipo: 'cancelacion', entidadId: input.jobId });
  if (input.workerId) {
    await supabase.from('notificaciones').insert({
      id: newId(),
      id_usuario: input.workerId,
      tipo: 'job_cancelled',
      titulo: 'Trabajo Cancelado',
      cuerpo: `El cliente canceló la solicitud. Motivo: ${reason.slice(0, 200)}`,
      id_relacionado: input.jobId,
      leido: 0,
      creado_en: now,
    });
  }
}

export interface RateJobInput {
  jobId: string;
  userId: string;
  workerId: string;
  score: number;
  comment: string;
}

export async function fetchClientRatingForJob(
  supabase: AppSupabase,
  jobId: string,
  userId: string,
): Promise<{ score: number; comment: string | null } | null> {
  const { data, error } = await supabase
    .from('calificaciones')
    .select('puntaje, comentario')
    .eq('id_trabajo', jobId)
    .eq('id_usuario', userId)
    .eq('direccion', 'cliente_a_trabajador')
    .maybeSingle();
  if (error || !data) return null;
  const row = data as { puntaje: number; comentario: string | null };
  return { score: Number(row.puntaje), comment: row.comentario };
}

export async function rateJobAsClient(supabase: AppSupabase, input: RateJobInput): Promise<void> {
  const invalid = validateRating(input.score, input.comment);
  if (invalid) throw new Error(invalid);
  const { error } = await supabase.from('calificaciones').insert({
    id: newId(),
    id_trabajo: input.jobId,
    id_usuario: input.userId,
    id_calificado: input.workerId,
    direccion: 'cliente_a_trabajador',
    puntaje: input.score,
    comentario: input.comment.trim() || null,
    creado_en: new Date().toISOString(),
  });
  if (!error) {
    await registrarEvento(supabase, { tipo: 'resena', entidadId: input.jobId });
    return;
  }
  if (error.code === '23505') throw new Error('Ya calificaste este trabajo.');
  throw new Error(
    rpcMessage(
      /row-level/i.test(error.message) ? undefined : error.message,
      'Solo puedes calificar un trabajo completado y sin disputa abierta.',
    ),
  );
}
