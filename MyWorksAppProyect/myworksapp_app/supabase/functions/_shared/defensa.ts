import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const CLAVES_PAGO = ["defensa_bloqueo", "defensa_solo_lectura", "defensa_pausar_pagos"];
const CLAVES_REGISTRO = ["defensa_bloqueo", "defensa_pausar_registros"];

async function algunaActiva(admin: SupabaseClient, claves: string[]): Promise<boolean> {
  const { data, error } = await admin.from("app_config").select("clave, valor").in("clave", claves);
  if (error || !data) return false;
  return data.some((row) => row.valor === "1");
}

/** Pagos, liberaciones y reembolsos. Si la migración aún no está, no corta el cobro. */
export function pagosPausados(admin: SupabaseClient): Promise<boolean> {
  return algunaActiva(admin, CLAVES_PAGO);
}

/** Altas de cuentas. */
export function registrosPausados(admin: SupabaseClient): Promise<boolean> {
  return algunaActiva(admin, CLAVES_REGISTRO);
}

/** La IP la manda el borde. El cliente no puede leer la tabla. */
export async function ipBloqueada(admin: SupabaseClient, ip: string): Promise<boolean> {
  const limpia = ip.trim();
  if (!limpia || limpia === "unknown") return false;
  const { data, error } = await admin
    .from("bloqueos_ip")
    .select("id")
    .eq("ip", limpia)
    .eq("activo", true)
    .limit(1);
  if (error || !data) return false;
  return data.length > 0;
}
