import type { SupabaseClient } from '@supabase/supabase-js';

/**
 * Operaciones que usa el dominio.
 * Es estructural a propósito: la web, el escritorio y shared pueden
 * resolver copias distintas de @supabase/supabase-js.
 */
export type AppSupabase = Pick<SupabaseClient, 'auth' | 'from' | 'rpc'>;
