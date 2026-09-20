import type { AppSupabase } from '../client';
import type { WebWorkerCard, WorkerWithProfile } from '../types';

const DEFAULT_AVATAR =
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200';

type WorkerQueryRow = {
  id_usuario: string;
  profesion: string;
  descripcion?: string | null;
  calificacion?: number | null;
  disponible?: number | null;
  tarifa_visita?: number | null;
  categoria_servicio: string;
  precios_configurados?: number | null;
  zona_trabajo?: string | null;
  perfiles?:
    | { nombre?: string; correo?: string; ruta_foto_perfil?: string | null }
    | { nombre?: string; correo?: string; ruta_foto_perfil?: string | null }[]
    | null;
};

function mapWorkerRow(row: WorkerQueryRow): WorkerWithProfile {
  const profile = row.perfiles;
  const profileRow = Array.isArray(profile) ? profile[0] : profile;

  return {
    userId: row.id_usuario,
    profession: row.profesion,
    description: row.descripcion,
    rating: Number(row.calificacion ?? 0),
    isAvailable: Number(row.disponible ?? 0),
    visitFee: Number(row.tarifa_visita ?? 0),
    serviceCategory: row.categoria_servicio,
    pricingConfigured: Number(row.precios_configurados ?? 0),
    workZone: row.zona_trabajo,
    name: profileRow?.nombre ?? 'Profesional',
    email: profileRow?.correo,
    profilePhotoPath: profileRow?.ruta_foto_perfil,
  };
}

export async function fetchWorkersByCategory(
  supabase: AppSupabase,
  category: string,
): Promise<WorkerWithProfile[]> {
  const { data, error } = await supabase
    .from('trabajadores')
    .select(
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo, perfiles!trabajadores_id_usuario_fkey(nombre, correo, ruta_foto_perfil)',
    )
    .eq('categoria_servicio', category)
    .eq('disponible', 1)
    .eq('precios_configurados', 1)
    .order('calificacion', { ascending: false });

  if (error) throw error;
  return ((data ?? []) as WorkerQueryRow[]).map(mapWorkerRow);
}

export async function fetchWorkersForAdmin(
  supabase: AppSupabase,
): Promise<WorkerWithProfile[]> {
  const { data, error } = await supabase
    .from('trabajadores')
    .select(
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo, perfiles!trabajadores_id_usuario_fkey(nombre, correo, ruta_foto_perfil)',
    )
    .order('calificacion', { ascending: false });

  if (error) throw error;
  return ((data ?? []) as WorkerQueryRow[]).map(mapWorkerRow);
}

export function toWebWorkerCard(worker: WorkerWithProfile, jobsDone = 0): WebWorkerCard {
  return {
    id: worker.userId,
    name: worker.name,
    profession: worker.profession,
    category: worker.serviceCategory,
    rating: worker.rating,
    jobsDone,
    photoUrl: worker.profilePhotoPath || DEFAULT_AVATAR,
    pricePerVisit: worker.visitFee,
  };
}
