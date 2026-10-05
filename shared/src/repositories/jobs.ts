import type { AppSupabase } from '../client';
import type { JobRow } from '../types';

export interface CreateJobInput {
  userId: string;
  workerId: string;
  serviceId: string;
  description: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  /** ISO del horario elegido en la barra (próximo viernes 10, 14 o 18). */
  scheduledAt?: string;
  /** Alineado a PricingModes Flutter — default precio_fijo (visita). */
  pricingMode?: 'precio_fijo' | 'bloque_horas' | 'cotizacion_abierta' | 'legado';
}

export async function createPendingJob(
  supabase: AppSupabase,
  input: CreateJobInput,
): Promise<JobRow> {
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
  if (error) throw error;

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
