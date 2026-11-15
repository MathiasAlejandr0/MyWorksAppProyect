import type { AppSupabase } from '../client';
import { bookingSlotError, workerSlotUnpublishedMessage } from '../jobs/bookingSlot';
import { decodeBytea, isWebpBytes, webpBytesToDataUrl } from '../media/bytea';
import type { JobRow } from '../types';

export interface CreateJobInput {
  userId: string;
  workerId: string;
  serviceId: string;
  description: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  /** ISO del horario libre que eligió el cliente. */
  scheduledAt?: string;
  /** Alineado a PricingModes Flutter — default precio_fijo (visita). */
  pricingMode?: 'precio_fijo' | 'bloque_horas' | 'cotizacion_abierta' | 'legado';
}

export async function createPendingJob(
  supabase: AppSupabase,
  input: CreateJobInput,
): Promise<JobRow> {
  if (!input.scheduledAt) {
    throw new Error(workerSlotUnpublishedMessage);
  }
  const now = new Date().toISOString();
  const modalidad = input.pricingMode ?? 'precio_fijo';
  const payload = {
    id: crypto.randomUUID(),
    id_usuario: input.userId,
    id_trabajador: input.workerId,
    id_servicio: input.serviceId,
    estado: 'esperando_pago',
    descripcion: input.description,
    direccion: input.address ?? 'Dirección por confirmar',
    latitud: input.latitude ?? null,
    longitud: input.longitude ?? null,
    fecha_programada: input.scheduledAt ?? null,
    modalidad_cobro: modalidad,
    estado_pago: 'pendiente',
    creado_en: now,
    actualizado_en: now,
  };

  const { data, error } = await supabase.from('trabajos').insert(payload).select().single();
  if (error) {
    throw new Error(bookingSlotError(error) ?? error.message);
  }

  return {
    id: data.id as string,
    userId: data.id_usuario as string,
    workerId: data.id_trabajador as string | null,
    serviceId: data.id_servicio as string | null,
    status: data.estado as string,
    address: data.direccion as string | null,
    description: data.descripcion as string | null,
    createdAt: data.creado_en as string,
  };
}

export interface JobTrackingSnapshot {
  id: string;
  status: string;
  paymentStatus: string | null;
  address: string | null;
  description: string | null;
  latitude: number | null;
  longitude: number | null;
  workerId: string | null;
  userId: string;
}

export async function fetchJobTrackingSnapshot(
  supabase: AppSupabase,
  jobId: string,
): Promise<JobTrackingSnapshot | null> {
  const { data, error } = await supabase
    .from('trabajos')
    .select(
      'id, estado, estado_pago, direccion, descripcion, latitud, longitud, id_trabajador, id_usuario',
    )
    .eq('id', jobId)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  const row = data as Record<string, unknown>;
  return {
    id: String(row.id),
    status: String(row.estado ?? ''),
    paymentStatus: row.estado_pago ? String(row.estado_pago) : null,
    address: row.direccion ? String(row.direccion) : null,
    description: row.descripcion ? String(row.descripcion) : null,
    latitude: row.latitud == null ? null : Number(row.latitud),
    longitude: row.longitud == null ? null : Number(row.longitud),
    workerId: row.id_trabajador ? String(row.id_trabajador) : null,
    userId: String(row.id_usuario),
  };
}

export async function fetchUserJobs(
  supabase: AppSupabase,
  userId: string,
): Promise<JobRow[]> {
  const { data, error } = await supabase
    .from('trabajos')
    .select('id, id_usuario, id_trabajador, id_servicio, estado, direccion, descripcion, creado_en')
    .eq('id_usuario', userId)
    .order('creado_en', { ascending: false });

  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[]).map((row) => ({
    id: row.id as string,
    userId: row.id_usuario as string,
    workerId: row.id_trabajador as string | null,
    serviceId: row.id_servicio as string | null,
    status: row.estado as string,
    address: row.direccion as string | null,
    description: row.descripcion as string | null,
    createdAt: row.creado_en as string,
  }));
}

/** Tras un pago retenido, el profesional puede aceptar. Si ya está pendiente, no falla. */
export async function openJobForWorker(
  supabase: AppSupabase,
  jobId: string,
): Promise<void> {
  const { error } = await supabase.rpc('transicionar_trabajo', {
    p_trabajo_id: jobId,
    p_nuevo_estado: 'pendiente',
  });
  if (!error) return;
  const message = error.message || '';
  if (/transicion no permitida/i.test(message)) return;
  throw new Error(message);
}

/** El cliente recibe conforme. El RPC libera el pago retenido y completa el trabajo. */
export async function closeJobOnClientApproval(
  supabase: AppSupabase,
  jobId: string,
): Promise<void> {
  const { error } = await supabase.rpc('cerrar_trabajo_conforme', {
    p_trabajo_id: jobId,
  });
  if (error) throw new Error(error.message || 'No se pudo recibir conforme');
}

export interface JobEvidencePhoto {
  id: string;
  mediaType: string;
  src: string | null;
}

function mapEvidenceRow(row: Record<string, unknown>): JobEvidencePhoto {
  const bytes = decodeBytea(row.imagen_webp);
  const src = bytes && isWebpBytes(bytes) ? webpBytesToDataUrl(bytes) : null;
  return {
    id: String(row.id),
    mediaType: String(row.tipo_medio ?? 'foto'),
    src,
  };
}

/** True si el índice (ids en orden) ya está pintado con bytes. */
export function evidenceIndexMatches(
  indexIds: string[],
  current: JobEvidencePhoto[],
): boolean {
  if (indexIds.length !== current.length) return false;
  return indexIds.every((id, i) => current[i]?.id === id && Boolean(current[i]?.src));
}

export function missingEvidenceIds(
  indexIds: string[],
  current: JobEvidencePhoto[],
): string[] {
  const have = new Set(current.filter((photo) => photo.src).map((photo) => photo.id));
  return indexIds.filter((id) => !have.has(id));
}

export function reconcileEvidencePhotos(
  index: Array<{ id: string; mediaType: string }>,
  current: JobEvidencePhoto[],
  fetched: JobEvidencePhoto[],
): JobEvidencePhoto[] {
  const known = new Map<string, JobEvidencePhoto>();
  for (const photo of current) known.set(photo.id, photo);
  for (const photo of fetched) known.set(photo.id, photo);
  return index.map((row) => known.get(row.id) ?? {
    id: row.id,
    mediaType: row.mediaType,
    src: null,
  });
}

/** Fotos de evidencia en WebP (columna imagen_webp) listas para pintar. */
export async function fetchJobEvidencePhotos(
  supabase: AppSupabase,
  jobId: string,
): Promise<JobEvidencePhoto[]> {
  const { data, error } = await supabase
    .from('fotos_trabajo')
    .select('id, tipo_medio, imagen_webp')
    .eq('id_trabajo', jobId)
    .order('creado_en', { ascending: false });
  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[]).map(mapEvidenceRow);
}

/**
 * En el poll del seguimiento solo pide ids. Si no hay fotos nuevas, no baja
 * otra vez el bytea WebP.
 */
export async function syncJobEvidencePhotos(
  supabase: AppSupabase,
  jobId: string,
  current: JobEvidencePhoto[],
): Promise<JobEvidencePhoto[]> {
  const { data, error } = await supabase
    .from('fotos_trabajo')
    .select('id, tipo_medio')
    .eq('id_trabajo', jobId)
    .order('creado_en', { ascending: false });
  if (error) throw error;
  const index = ((data ?? []) as Record<string, unknown>[]).map((row) => ({
    id: String(row.id),
    mediaType: String(row.tipo_medio ?? 'foto'),
  }));
  const indexIds = index.map((row) => row.id);
  if (evidenceIndexMatches(indexIds, current)) return current;

  const missingIds = missingEvidenceIds(indexIds, current);
  let fetched: JobEvidencePhoto[] = [];
  if (missingIds.length > 0) {
    const { data: rows, error: fetchError } = await supabase
      .from('fotos_trabajo')
      .select('id, tipo_medio, imagen_webp')
      .in('id', missingIds);
    if (fetchError) throw fetchError;
    fetched = ((rows ?? []) as Record<string, unknown>[]).map(mapEvidenceRow);
  }
  return reconcileEvidencePhotos(index, current, fetched);
}
