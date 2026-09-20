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
    direccion: input.address ?? 'Solicitud desde web',
    latitud: input.latitude ?? null,
    longitud: input.longitude ?? null,
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
