import type { AppSupabase } from '../client';
import {
  PLATFORM_COMMISSION_RATE,
  summarizeBusinessPeriod,
  type BusinessPeriodSummary,
  type PeriodJob,
  type PeriodPayment,
  type PeriodRating,
} from './period';

export async function fetchBusinessPeriod(
  supabase: AppSupabase,
  fromIso: string,
  toIso: string,
): Promise<BusinessPeriodSummary> {
  const [payments, jobs, ratings] = await Promise.all([
    supabase
      .from('pagos')
      .select('monto, estado, creado_en')
      .gte('creado_en', fromIso)
      .lte('creado_en', toIso)
      .limit(2000),
    supabase
      .from('trabajos')
      .select('estado, actualizado_en')
      .eq('estado', 'completado')
      .gte('actualizado_en', fromIso)
      .lte('actualizado_en', toIso)
      .limit(2000),
    supabase
      .from('calificaciones')
      .select('puntaje, creado_en')
      .gte('creado_en', fromIso)
      .lte('creado_en', toIso)
      .limit(2000),
  ]);
  if (payments.error) throw payments.error;
  if (jobs.error) throw jobs.error;
  if (ratings.error) throw ratings.error;

  return summarizeBusinessPeriod({
    fromIso,
    toIso,
    commissionRate: PLATFORM_COMMISSION_RATE,
    payments: ((payments.data ?? []) as { monto: number; estado: string; creado_en: string }[]).map(
      (row): PeriodPayment => ({
        amount: Number(row.monto) || 0,
        status: row.estado,
        createdAt: row.creado_en,
      }),
    ),
    jobs: ((jobs.data ?? []) as { estado: string; actualizado_en: string }[]).map(
      (row): PeriodJob => ({
        status: row.estado,
        updatedAt: row.actualizado_en,
      }),
    ),
    ratings: ((ratings.data ?? []) as { puntaje: number; creado_en: string }[]).map(
      (row): PeriodRating => ({
        score: Number(row.puntaje) || 0,
        createdAt: row.creado_en,
      }),
    ),
  });
}
