import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    '[MyWorks Desktop] Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. Configúralas en .env — no hay claves embebidas.',
  );
}

export const supabase = createClient(
  SUPABASE_URL || 'https://placeholder.supabase.co',
  SUPABASE_ANON_KEY || 'missing-anon-key',
);

export const supabaseConfigStatus = {
  urlConfigured: Boolean(SUPABASE_URL),
  anonKeyConfigured: Boolean(SUPABASE_ANON_KEY),
};
