/** Comisión de plataforma sobre el GMV cobrado o retenido. No es un secreto. */
export const PLATFORM_COMMISSION_RATE = 0.15;

const GMV_STATUSES = new Set(['retenido', 'liberado', 'autorizado']);

export type PeriodPayment = {
  amount: number;
  status: string;
  createdAt: string;
};

export type PeriodJob = {
  status: string;
  updatedAt: string;
};

export type PeriodRating = {
  score: number;
  createdAt: string;
};

export type DailyGmv = { day: string; amount: number };

export type BusinessPeriodSummary = {
  gmv: number;
  commission: number;
  commissionRate: number;
  completedJobs: number;
  paidOrders: number;
  avgTicket: number | null;
  csat: number | null;
  ratingCount: number;
  byPaymentStatus: { status: string; amount: number; count: number }[];
  dailyGmv: DailyGmv[];
};

/**
 * Las columnas creado_en/actualizado_en son texto y a veces vienen sin zona
 * (p. ej. el seed: "2026-09-30T07:58:44.929384" o "2026-09-30 08:14:15+00").
 * La base escribe UTC, así que un valor sin zona se lee como UTC; si no, el
 * navegador lo toma como hora local y en Chile queda 3 h en el futuro.
 */
export function parseDbTimestamp(value: string | null | undefined): number {
  if (!value) return Number.NaN;
  let s = String(value).trim().replace(' ', 'T');
  if (/[+-]\d{2}$/.test(s)) s = `${s}:00`;
  if (/^\d{4}-\d{2}-\d{2}T/.test(s) && !/(Z|[+-]\d{2}:?\d{2})$/i.test(s)) s = `${s}Z`;
  return Date.parse(s);
}

/** Hora de Chile a partir de un timestamp de la base, con o sin zona. */
export function formatDbDateTime(value: string | null | undefined): string {
  const ms = parseDbTimestamp(value);
  if (!Number.isFinite(ms)) return '—';
  return new Date(ms).toLocaleString('es-CL', {
    timeZone: 'America/Santiago',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
}

function inRange(iso: string, fromMs: number, toMs: number): boolean {
  const ms = parseDbTimestamp(iso);
  return Number.isFinite(ms) && ms >= fromMs && ms <= toMs;
}

function dayKey(iso: string): string {
  const ms = parseDbTimestamp(iso);
  if (!Number.isFinite(ms)) return '';
  return new Date(ms).toISOString().slice(0, 10);
}

export function summarizeBusinessPeriod(input: {
  payments: PeriodPayment[];
  jobs: PeriodJob[];
  ratings: PeriodRating[];
  fromIso: string;
  toIso: string;
  commissionRate?: number;
}): BusinessPeriodSummary {
  const fromMs = Date.parse(input.fromIso);
  const toMs = Date.parse(input.toIso);
  const rate = input.commissionRate ?? PLATFORM_COMMISSION_RATE;

  const payments = input.payments.filter((row) =>
    inRange(row.createdAt, fromMs, toMs),
  );
  const gmvRows = payments.filter((row) => GMV_STATUSES.has(row.status));
  const gmv = gmvRows.reduce((sum, row) => sum + (Number(row.amount) || 0), 0);
  const completedJobs = input.jobs.filter(
    (row) => row.status === 'completado' && inRange(row.updatedAt, fromMs, toMs),
  ).length;
  const ratings = input.ratings.filter(
    (row) =>
      Number.isFinite(row.score) && inRange(row.createdAt, fromMs, toMs),
  );
  const csat = ratings.length
    ? ratings.reduce((sum, row) => sum + row.score, 0) / ratings.length
    : null;

  const buckets = new Map<string, { amount: number; count: number }>();
  for (const row of payments) {
    const bucket = buckets.get(row.status) ?? { amount: 0, count: 0 };
    bucket.amount += Number(row.amount) || 0;
    bucket.count += 1;
    buckets.set(row.status, bucket);
  }

  const days = new Map<string, number>();
  for (const row of gmvRows) {
    const key = dayKey(row.createdAt);
    if (!key) continue;
    days.set(key, (days.get(key) ?? 0) + (Number(row.amount) || 0));
  }

  return {
    gmv,
    commission: Math.round(gmv * rate),
    commissionRate: rate,
    completedJobs,
    paidOrders: gmvRows.length,
    avgTicket: gmvRows.length ? Math.round(gmv / gmvRows.length) : null,
    csat,
    ratingCount: ratings.length,
    byPaymentStatus: [...buckets.entries()]
      .map(([status, bucket]) => ({ status, ...bucket }))
      .sort((a, b) => b.amount - a.amount),
    dailyGmv: [...days.entries()]
      .map(([day, amount]) => ({ day, amount }))
      .sort((a, b) => a.day.localeCompare(b.day)),
  };
}

export function periodRange(preset: '24h' | '7d' | '30d' | '90d', now = new Date()): {
  fromIso: string;
  toIso: string;
} {
  const to = now.getTime();
  const hours = preset === '24h' ? 24 : preset === '7d' ? 24 * 7 : preset === '30d' ? 24 * 30 : 24 * 90;
  return {
    fromIso: new Date(to - hours * 60 * 60 * 1000).toISOString(),
    toIso: now.toISOString(),
  };
}
