import type { SupabaseClient } from '@supabase/supabase-js';
import type { ServiceRow } from '../types';

function mapService(row: Record<string, unknown>): ServiceRow {
  return {
    id: row.id as string,
    name: row.nombre as string,
    description: row.descripcion as string | null,
    category: row.categoria as string,
    isActive: Number(row.activo ?? 0),
    pricingModel: row.modelo_precio as string | null,
  };
}

export async function fetchServiceByCategory(
  supabase: SupabaseClient,
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
  return data ? mapService(data as Record<string, unknown>) : null;
}

export async function fetchActiveServices(supabase: SupabaseClient): Promise<ServiceRow[]> {
  const { data, error } = await supabase
    .from('servicios')
    .select('id, nombre, descripcion, categoria, activo, modelo_precio')
    .eq('activo', 1)
    .order('nombre', { ascending: true });

  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[]).map(mapService);
}
