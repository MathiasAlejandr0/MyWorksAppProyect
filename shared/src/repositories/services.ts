import type { AppSupabase } from '../client';
import type { Tables } from '../database.types';
import type { ServiceRow } from '../types';

type ServiceDbRow = Tables<'servicios'>;

function mapService(row: ServiceDbRow): ServiceRow {
  return {
    id: row.id,
    name: row.nombre,
    description: row.descripcion,
    category: row.categoria,
    isActive: Number(row.activo ?? 0),
    pricingModel: row.modelo_precio,
  };
}

export async function fetchServiceByCategory(
  supabase: AppSupabase,
  category: string,
): Promise<ServiceRow | null> {
  const { data, error } = await supabase
    .from('servicios')
    .select('id, nombre, descripcion, categoria, activo, modelo_precio')
    .eq('categoria', category)
    .eq('activo', 1)
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data ? mapService(data as ServiceDbRow) : null;
}

export async function fetchActiveServices(supabase: AppSupabase): Promise<ServiceRow[]> {
  const { data, error } = await supabase
    .from('servicios')
    .select('id, nombre, descripcion, categoria, activo, modelo_precio')
    .eq('activo', 1)
    .order('nombre', { ascending: true });

  if (error) throw error;
  return ((data ?? []) as ServiceDbRow[]).map(mapService);
}
