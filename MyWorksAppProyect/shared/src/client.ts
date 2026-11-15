import type { Database } from './database.types';

/**
 * Cliente mínimo estructural.
 * `any` a propósito: web/desktop tipan con `createClient<Database>` localmente;
 * shared no puede Pick<SupabaseClient> por copias distintas del SDK y por
 * contravarianza de `rpc` (string vs union de RPCs).
 */
export type AppSupabase = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  auth: any;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  from: any;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  rpc: any;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  functions: any;
};

export type { Database };
