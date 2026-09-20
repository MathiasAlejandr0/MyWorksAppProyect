import type { AppSupabase } from '../client';
import type { AdminMetrics } from '../types';

function asInt(value: unknown, fallback = 0): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

/**
 * Mapea el JSON de `admin_metricas_resumen` (claves ES o camelCase legacy).
 */
export function mapMetricsPayload(data: unknown): AdminMetrics {
  const row = (data ?? {}) as Record<string, unknown>;
  return {
    usersCount: asInt(row.usuarios ?? row.usersCount),
    workersCount: asInt(row.trabajadores ?? row.workersCount),
    jobsCount: asInt(row.trabajos ?? row.jobsCount),
    openDisputesCount: asInt(row.disputas_abiertas ?? row.openDisputesCount),
    underReviewDisputesCount: asInt(
      row.disputas_en_revision ?? row.underReviewDisputesCount,
    ),
    pendingReportsCount: asInt(row.reportes_pendientes ?? row.pendingReportsCount),
    activeJobsCount: asInt(row.trabajos_activos ?? row.activeJobsCount),
    newErrorsCount: asInt(row.errores_nuevos ?? row.newErrorsCount),
    unresolvedAbuseCount: asInt(row.abusos_abiertos ?? row.unresolvedAbuseCount),
    failedSyncCount: asInt(row.sync_fallidos ?? row.failedSyncCount),
  };
}

/**
 * Métricas admin vía RPC `admin_metricas_resumen` (is_admin + SECURITY DEFINER).
 * Requiere migración `20260914000005_rls_politicas_negocio.sql`.
 */
export async function fetchAdminMetrics(
  supabase: AppSupabase,
): Promise<AdminMetrics> {
  const { data, error } = await supabase.rpc('admin_metricas_resumen');
  if (error) throw error;
  return mapMetricsPayload(data);
}
