import type { AppSupabase } from '../client';
import {
  CATALOG_PAGE_SIZE,
  type CatalogCursor,
} from '../catalog';
import { uniqueIsoSlots } from '../jobs/bookingSlot';
import type { WebWorkerCard, WorkerWithProfile } from '../types';
import { initialsAvatarDataUrl } from '../avatar';

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
  estado_verificacion?: string | null;
  nota_verificacion?: string | null;
  latitud_base?: number | null;
  longitud_base?: number | null;
  radio_servicio_km?: number | null;
  origen_base?: string | null;
  trabajos_completados?: number | null;
  score_listado?: number | null;
  radio_urbano_km?: number | null;
  tarifa_fuera_radio_clp?: number | null;
  es_elite?: boolean | null;
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

function listPhotoUrl(url: string | null | undefined, name: string, seed: string): string {
  if (!url) return initialsAvatarDataUrl(name, seed);
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
    verificationStatus: row.estado_verificacion ?? null,
    verificationNote: row.nota_verificacion ?? null,
    baseLatitude: row.latitud_base == null ? null : Number(row.latitud_base),
    baseLongitude: row.longitud_base == null ? null : Number(row.longitud_base),
    serviceRadiusKm:
      row.radio_servicio_km == null ? null : Number(row.radio_servicio_km),
    baseOrigin: row.origen_base ?? null,
    name: row.nombre ?? profileRow?.nombre ?? 'Profesional',
    profilePhotoPath: row.ruta_foto_perfil ?? profileRow?.ruta_foto_perfil,
    completedJobs: Number(row.trabajos_completados ?? 0),
    listingScore: row.score_listado == null ? null : Number(row.score_listado),
    urbanRadiusKm: row.radio_urbano_km == null ? null : Number(row.radio_urbano_km),
    outsideMobilizationFeeClp:
      row.tarifa_fuera_radio_clp == null ? null : Number(row.tarifa_fuera_radio_clp),
    isElite: row.es_elite === true,
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
    nextCursor: { rating: last.listingScore ?? last.rating, id: last.userId },
  };
}


type PublicStatsRow = {
  id_usuario: string;
  calificacion?: number | null;
  n_calificaciones?: number | null;
  trabajos_completados?: number | null;
  es_elite?: boolean | null;
};

/** Superpone la nota y el recuento reales si la RPC canónica está desplegada. */
async function overlayPublicStats(
  supabase: AppSupabase,
  workers: WorkerWithProfile[],
): Promise<WorkerWithProfile[]> {
  if (workers.length === 0) return workers;
  const rpc = await supabase.rpc('stats_profesionales', {
    p_ids: workers.map((w) => w.userId),
  });
  if (rpc.error || !Array.isArray(rpc.data)) return workers;
  const byId = new Map<string, PublicStatsRow>();
  for (const raw of rpc.data as PublicStatsRow[]) {
    if (raw.id_usuario) byId.set(raw.id_usuario, raw);
  }
  if (byId.size === 0) return workers;
  return workers.map((worker) => applyPublicStatsRow(worker, byId.get(worker.userId)));
}

export function applyPublicStatsRow(
  worker: WorkerWithProfile,
  stats: PublicStatsRow | undefined,
): WorkerWithProfile {
  if (!stats) return worker;
  const count = Number(stats.n_calificaciones ?? 0);
  const raw = stats.calificacion == null ? 0 : Number(stats.calificacion);
  return {
    ...worker,
    rating: count <= 0 ? 0 : raw,
    completedJobs: Number(stats.trabajos_completados ?? 0),
    isElite: stats.es_elite === true,
  };
}

export async function fetchWorkerPublicStats(
  supabase: AppSupabase,
  userId: string,
): Promise<{ rating: number; completedJobs: number; isElite: boolean; ratingCount: number } | null> {
  const rpc = await supabase.rpc('stats_profesional', { p_id: userId });
  if (rpc.error || !Array.isArray(rpc.data) || rpc.data.length === 0) return null;
  const row = rpc.data[0] as PublicStatsRow;
  const count = Number(row.n_calificaciones ?? 0);
  const raw = row.calificacion == null ? 0 : Number(row.calificacion);
  return {
    rating: count <= 0 ? 0 : raw,
    completedJobs: Number(row.trabajos_completados ?? 0),
    isElite: row.es_elite === true,
    ratingCount: count,
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
    const page = pageFromRows(rpc.data as WorkerQueryRow[], limit);
    return { ...page, workers: await overlayPublicStats(supabase, page.workers) };
  }

  let query = supabase
    .from('trabajadores')
    .select(
      'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo, radio_servicio_km, origen_base, trabajos_completados, score_listado, radio_urbano_km, tarifa_fuera_radio_clp, es_elite',
    )
    .eq('categoria_servicio', opts.category)
    .eq('disponible', 1)
    .eq('precios_configurados', 1)
    .eq('estado_verificacion', 'verificado')
    .order('score_listado', { ascending: false })
    .order('id_usuario', { ascending: true })
    .limit(limit);

  if (opts.cursor) {
    query = query.or(
      `calificacion.lt.${opts.cursor.rating},and(calificacion.eq.${opts.cursor.rating},id_usuario.gt.${opts.cursor.id})`,
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  const page = pageFromRows((data ?? []) as WorkerQueryRow[], limit);
  return { ...page, workers: await overlayPublicStats(supabase, page.workers) };
}

/** Oficios con al menos un profesional disponible y con precio. Null si la RPC no está. */
export async function fetchCategoriesWithPros(
  supabase: AppSupabase,
): Promise<string[] | null> {
  const rpc = await supabase.rpc('categorias_con_disponibles');
  if (rpc.error || !Array.isArray(rpc.data)) return null;
  const ids = (rpc.data as unknown[])
    .map((row: unknown) => {
      if (typeof row === 'string') return row.trim();
      if (row && typeof row === 'object' && 'categoria' in row) {
        return String((row as { categoria: unknown }).categoria).trim();
      }
      return '';
    })
    .filter((id: string) => id.length > 0);
  return ids;
}

/** Primera página del catálogo (compat). No incluye correo. */
export async function fetchWorkersByCategory(
  supabase: AppSupabase,
  category: string,
): Promise<WorkerWithProfile[]> {
  const page = await fetchWorkersCatalog(supabase, { category });
  return page.workers;
}

const ADMIN_WORKER_COLUMNS =
  'id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita, categoria_servicio, precios_configurados, zona_trabajo, perfiles!trabajadores_id_usuario_fkey(nombre, ruta_foto_perfil)';

export async function fetchWorkersForAdmin(
  supabase: AppSupabase,
): Promise<WorkerWithProfile[]> {
  const withVerification = await supabase
    .from('trabajadores')
    .select(`${ADMIN_WORKER_COLUMNS}, estado_verificacion`)
    .order('calificacion', { ascending: false })
    .limit(200);

  if (!withVerification.error) {
    const notes = await supabase.rpc('fichas_sensibles_admin');
    const byId = new Map<string, WorkerQueryRow>();
    if (!notes.error && Array.isArray(notes.data)) {
      for (const raw of notes.data as WorkerQueryRow[]) {
        if (raw.id_usuario) byId.set(raw.id_usuario, raw);
      }
    }
    const mapped = ((withVerification.data ?? []) as WorkerQueryRow[]).map((row) => {
      const extra = byId.get(row.id_usuario);
      return mapWorkerRow(extra ? { ...row, ...extra } : row);
    });
    return overlayPublicStats(supabase, mapped);
  }

  const fallback = await supabase
    .from('trabajadores')
    .select(ADMIN_WORKER_COLUMNS)
    .order('calificacion', { ascending: false })
    .limit(200);
  if (fallback.error) throw fallback.error;
  return overlayPublicStats(
    supabase,
    ((fallback.data ?? []) as WorkerQueryRow[]).map(mapWorkerRow),
  );
}

export async function setWorkerVerification(
  supabase: AppSupabase,
  userId: string,
  status: 'pendiente' | 'en_revision' | 'verificado' | 'rechazado',
  note?: string | null,
): Promise<void> {
  const { error } = await supabase.rpc('fijar_verificacion_profesional', {
    p_id_usuario: userId,
    p_estado: status,
    p_nota: note ?? null,
  });
  if (error) throw error;
}

export async function fetchWorkerFreeSlots(
  supabase: AppSupabase,
  workerId: string,
  days = 14,
): Promise<string[]> {
  const { data, error } = await supabase.rpc('horarios_libres_profesional', {
    p_id_trabajador: workerId,
    p_dias: days,
  });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  const isos = rows
    .map((row) => {
      if (typeof row === 'string') return row;
      if (row && typeof row === 'object' && 'inicio' in row) {
        return String((row as { inicio: unknown }).inicio);
      }
      return '';
    })
    .filter((iso) => iso.length > 0);
  return uniqueIsoSlots(isos);
}

export function toWebWorkerCard(worker: WorkerWithProfile, jobsDone = 0): WebWorkerCard {
  return {
    id: worker.userId,
    name: worker.name,
    profession: worker.profession,
    category: worker.serviceCategory,
    rating: worker.rating,
    jobsDone: jobsDone || worker.completedJobs || 0,
    photoUrl: listPhotoUrl(worker.profilePhotoPath, worker.name, worker.userId),
    pricePerVisit: worker.visitFee,
    latitude: worker.baseLatitude ?? null,
    longitude: worker.baseLongitude ?? null,
    serviceRadiusKm: worker.serviceRadiusKm ?? null,
    urbanRadiusKm: worker.urbanRadiusKm ?? null,
    outsideMobilizationFeeClp: worker.outsideMobilizationFeeClp ?? null,
    isElite: worker.isElite === true
      || (worker.rating >= 4.7 && (jobsDone || worker.completedJobs || 0) >= 5),
  };
}
