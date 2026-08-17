import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://wxqrfcqifkfgawrnqmnj.supabase.co';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_WN_cTANRJ4nCuPw_6HWd7w_iDJjRA8O';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
