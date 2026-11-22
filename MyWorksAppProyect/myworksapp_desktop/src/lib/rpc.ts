import type { PostgrestError } from '@supabase/supabase-js';
import { supabase } from '../supabaseClient';

type RpcClient = {
  rpc: (
    name: string,
    args?: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: PostgrestError | null }>;
};

/** Llama un RPC nuevo sin ampliar el archivo generado de tipos. */
export async function callRpc<T>(name: string, args?: Record<string, unknown>): Promise<T> {
  const client = supabase as unknown as RpcClient;
  const { data, error } = await client.rpc(name, args);
  if (error) throw error;
  return data as T;
}
