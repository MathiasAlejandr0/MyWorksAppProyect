import type { AppSupabase } from "../client";
import { fetchWorkersCatalog } from "../repositories/workers.ts";
import type { WorkerWithProfile } from "../types";
import { sanitizarMetadata, type TipoEvento } from "../ia.ts";

export interface BusquedaHibridaInput {
  q: string;
  categoria?: string | null;
  origin?: { latitude: number; longitude: number } | null;
  limit?: number;
}

export async function registrarEvento(
  supabase: AppSupabase,
  input: {
    tipo: TipoEvento;
    entidadId?: string | null;
    categoria?: string | null;
    comuna?: string | null;
    metadata?: Record<string, unknown>;
  },
): Promise<void> {
  try {
    await supabase.rpc("registrar_evento", {
      p_tipo: input.tipo,
      p_entidad_id: input.entidadId ?? null,
      p_categoria: input.categoria ?? null,
      p_comuna: input.comuna ?? null,
      p_metadata: sanitizarMetadata(input.metadata),
    });
  } catch {
    // El evento no puede frenar la pantalla.
  }
}

function mapFila(row: Record<string, unknown>): WorkerWithProfile {
  return {
    userId: String(row.id_usuario),
    profession: String(row.profesion ?? ""),
    description: row.descripcion == null ? null : String(row.descripcion),
    rating: Number(row.calificacion ?? 0),
    isAvailable: 1,
    visitFee: Number(row.tarifa_visita ?? 0),
    serviceCategory: String(row.categoria_servicio ?? ""),
    pricingConfigured: 1,
    workZone: row.zona_trabajo == null ? null : String(row.zona_trabajo),
    verificationStatus: "verificado",
    verificationNote: null,
    baseLatitude: row.latitud_base == null ? null : Number(row.latitud_base),
    baseLongitude: row.longitud_base == null ? null : Number(row.longitud_base),
    serviceRadiusKm: row.radio_servicio_km == null ? null : Number(row.radio_servicio_km),
    baseOrigin: row.origen_base == null ? null : String(row.origen_base),
    completedJobs: Number(row.trabajos_completados ?? 0),
    listingScore: Number(row.puntaje ?? row.score_listado ?? 0),
    urbanRadiusKm: row.radio_urbano_km == null ? null : Number(row.radio_urbano_km),
    outsideMobilizationFeeClp: row.tarifa_fuera_radio_clp == null ? null : Number(row.tarifa_fuera_radio_clp),
    isElite: row.es_elite === true,
    name: String(row.nombre ?? "Profesional"),
    profilePhotoPath: row.ruta_foto_perfil == null ? null : String(row.ruta_foto_perfil),
  };
}

/**
 * Intenta la RPC híbrida. Si no está o falla, usa el catálogo actual.
 * `respaldo` dice cuál de las dos respondió.
 */
export async function buscarProfesionales(
  supabase: AppSupabase,
  input: BusquedaHibridaInput,
): Promise<{ workers: WorkerWithProfile[]; respaldo: boolean; modo: string }> {
  try {
    const rpc = await supabase.rpc("buscar_profesionales_hibrido", {
      p_q: input.q,
      p_lat: input.origin?.latitude ?? null,
      p_lng: input.origin?.longitude ?? null,
      p_categoria: input.categoria ?? null,
      p_limit: input.limit ?? 20,
    });
    if (!rpc.error && Array.isArray(rpc.data)) {
      return {
        workers: (rpc.data as Record<string, unknown>[]).map(mapFila),
        respaldo: false,
        modo: String((rpc.data[0] as { modo?: string } | undefined)?.modo ?? "lexico"),
      };
    }
  } catch {
    // Sigue el catálogo.
  }
  if (!input.categoria) return { workers: [], respaldo: true, modo: "catalogo" };
  const page = await fetchWorkersCatalog(supabase, {
    category: input.categoria,
    origin: input.origin,
    limit: input.limit,
  });
  return { workers: page.workers, respaldo: true, modo: "catalogo" };
}
