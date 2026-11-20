import type { AppSupabase } from '../client';

/** Entero que acepta el cobro. Sale de `resumen_cobro_trabajo`. */
export interface JobChargePreview {
  totalClp: number;
  serviceClp: number;
  transportClp: number;
  feeClp: number;
  payoutClp: number;
}

export const chargePreviewBlockedMessage =
  'No pudimos calcular el total. Reintenta antes de pagar.';

/** El botón de pagar solo aparece con el total del servidor. */
export function payableTotalClp(serverTotalClp: number | null | undefined): number | null {
  if (serverTotalClp == null || !Number.isFinite(serverTotalClp)) return null;
  const total = Math.round(serverTotalClp);
  return total > 0 ? total : null;
}

function asInt(value: unknown): number | null {
  const n = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.round(n);
}

export function parseJobChargePreview(row: Record<string, unknown> | null): JobChargePreview | null {
  if (!row) return null;
  const totalClp = asInt(row.total_clp);
  const serviceClp = asInt(row.tarifa_clp);
  const transportClp = asInt(row.traslado_clp);
  const feeClp = asInt(row.comision_clp);
  const payoutClp = asInt(row.neto_clp);
  if (
    totalClp == null || totalClp <= 0 ||
    serviceClp == null || transportClp == null ||
    feeClp == null || payoutClp == null
  ) {
    return null;
  }
  return { totalClp, serviceClp, transportClp, feeClp, payoutClp };
}

function firstRow(data: unknown): Record<string, unknown> | null {
  if (Array.isArray(data)) {
    const row = data[0];
    return row && typeof row === 'object' ? row as Record<string, unknown> : null;
  }
  if (data && typeof data === 'object') return data as Record<string, unknown>;
  return null;
}

export async function fetchJobChargePreview(
  supabase: AppSupabase,
  jobId: string,
): Promise<JobChargePreview | null> {
  const id = jobId.trim();
  if (!id) return null;
  const { data, error } = await supabase.rpc('resumen_cobro_trabajo', {
    p_id_trabajo: id,
  });
  if (error) return null;
  return parseJobChargePreview(firstRow(data));
}
