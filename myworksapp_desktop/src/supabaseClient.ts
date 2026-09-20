import { createClient } from '@supabase/supabase-js';
import type { Database } from '@myworksapp/shared';

const SUPABASE_URL =
  (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.trim() ||
  'https://example.supabase.co';
const SUPABASE_ANON_KEY =
  (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)?.trim() ||
  'public-anon-placeholder';

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    detectSessionInUrl: true,
    flowType: 'pkce',
  },
});

export const supabaseConfigStatus = {
  urlConfigured: Boolean(
    (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.trim(),
  ),
  anonKeyConfigured: Boolean(
    (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)?.trim(),
  ),
};
