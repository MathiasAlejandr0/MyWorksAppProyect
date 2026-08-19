import type { SupabaseClient } from '@supabase/supabase-js';
import type { ServiceRow } from '../types';

export async function fetchServiceByCategory(
  supabase: SupabaseClient,
  category: string,
): Promise<ServiceRow | null> {
  const { data, error } = await supabase
    .from('services')
    .select('id, name, description, category, isActive, pricingModel')
    .eq('category', category)
    .eq('isActive', 1)
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return (data as ServiceRow | null) ?? null;
}

export async function fetchActiveServices(supabase: SupabaseClient): Promise<ServiceRow[]> {
  const { data, error } = await supabase
    .from('services')
    .select('id, name, description, category, isActive, pricingModel')
    .eq('isActive', 1)
    .order('name', { ascending: true });

  if (error) throw error;
  return (data ?? []) as ServiceRow[];
}
