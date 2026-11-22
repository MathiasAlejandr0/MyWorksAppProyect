import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@myworksapp/shared';
import { clienteCaptura } from './captura/cliente';
import { capturaActiva } from './features/premium/captura';

const SUPABASE_URL =
  (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.trim() ||
  'https://example.supabase.co';
const SUPABASE_ANON_KEY =
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)?.trim() ||
  'public-anon-placeholder';

const real = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
  },
});

export const supabase = (capturaActiva() ? clienteCaptura() : real) as SupabaseClient<Database>;

export const supabaseConfigStatus = {
  urlConfigured: Boolean(
    (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.trim(),
  ),
  anonKeyConfigured: Boolean(
    (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)?.trim(),
  ),
};
