export function asNum(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function asRows(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === 'object');
}

export function asText(value: unknown, fallback = '—'): string {
  if (value == null || value === '') return fallback;
  return String(value);
}
