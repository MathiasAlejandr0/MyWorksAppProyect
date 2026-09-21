import type { AppSupabase } from '../client';
import {
  CATALOG_PAGE_SIZE,
  type CatalogCursor,
} from '../catalog';
import type { WebWorkerCard, WorkerWithProfile } from '../types';

const DEFAULT_AVATAR =
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&q=70';

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
  nombre?: string | null;
  ruta_foto_perfil?: string | null;
  perfiles?:
    | { nombre?: string; ruta_foto_perfil?: string | null }
    | { nombre?: string; ruta_foto_perfil?: string | null }[]
    | null;
};

export type WorkersCatalogPage = {
  workers: WorkerWithProfile[];
  nextCursor: CatalogCursor | null;
};

function listPhotoUrl(url?: string | null): string {
  if (!url) return DEFAULT_AVATAR;
  if (url.includes('images.unsplash.com')) {
    return url
      .replace(/([?&])w=\d+/g, '$1w=200')
      .replace(/([?&])h=\d+/g, '$1h=200');
  }
  return url;
}

function mapWorkerRow(row: WorkerQueryRow): WorkerWithProfile {
  const profile = row.perfiles;
  const profileRow = Array.isArray(profile) ? profile[0] : profile;

  return {
    userId: row.id_usuario,
    profession: row.profesion,
    description: row.descripcion,
    rating: Number(row.calificacion ?? 0),
    isAvailable: Number(row.disponible ?? 1),
    visitFee: Number(row.tarifa_visita ?? 0),
    serviceCategory: row.categoria_servicio,
    pricingConfigured: Number(row.precios_configurados ?? 1),
    workZone: row.zona_trabajo,
    name: row.nombre ?? profileRow?.nombre ?? 'Profesional',
    profilePhotoPath: row.ruta_foto_perfil ?? profileRow?.ruta_foto_perfil,
  };
}

function pageFromRows(
  rows: WorkerQueryRow[],
  limit: number,
): WorkersCatalogPage {
  const workers = rows.map(mapWorkerRow);
  if (workers.length < limit) {
    return { workers, nextCursor: null };
  }
  const last = workers[workers.length - 1];
  return {
    workers,
    nextCursor: { rating: last.rating, id: last.userId },
  };
}

export async function fetchWorkersCatalog(
  supabase: AppSupabase,
  opts: {
    category: string;
    zone?: string;
    cursor?: CatalogCursor | null;
    limit?: number;
  },
): Promise<WorkersCatalogPage> {
  const limit = Math.min(
    Math.max(opts.limit ?? CATALOG_PAGE_SIZE, 1),
    40,
  );

  const rpc = await supabase.rpc('listar_profesionales_catalogo', {
    p_categoria: opts.category,
    p_zona: opts.zone ?? null,
    p_cursor_calificacion: opts.cursor?.rating ?? null,
    p_cursor_id: opts.cursor?.id ?? null,
    p_limit: limit,
  });

  if (!rpc.error && Array.isArray(rpc.data)) {
    return pageFromRows(rpc.data as WorkerQueryRow[], limit);
  }

  let query = supabase
    .from('trabajadores')
    .select(
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo',
    )
    .eq('categoria_servicio', opts.category)
    .eq('disponible', 1)
    .eq('precios_configurados', 1)
    .order('calificacion', { ascending: false })
    .order('id_usuario', { ascending: true })
    .limit(limit);

  if (opts.cursor) {
    query = query.or(
      `calificacion.lt.${opts.cursor.rating},and(calificacion.eq.${opts.cursor.rating},id_usuario.gt.${opts.cursor.id})`,
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  return pageFromRows((data ?? []) as WorkerQueryRow[], limit);
}

/** Primera página del catálogo (compat). No incluye correo. */
export async function fetchWorkersByCategory(
  supabase: AppSupabase,
  category: string,
): Promise<WorkerWithProfile[]> {
  const page = await fetchWorkersCatalog(supabase, { category });
  return page.workers;
}

export async function fetchWorkersForAdmin(
  supabase: AppSupabase,
): Promise<WorkerWithProfile[]> {
  const { data, error } = await supabase
    .from('trabajadores')
    .select(
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo, perfiles!trabajadores_id_usuario_fkey(nombre, ruta_foto_perfil)',
    )
    .order('calificacion', { ascending: false })
    .limit(200);

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
    photoUrl: listPhotoUrl(worker.profilePhotoPath),
    pricePerVisit: worker.visitFee,
  };
}
