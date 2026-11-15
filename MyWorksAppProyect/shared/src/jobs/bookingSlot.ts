export const CHILE_TIME_ZONE = 'America/Santiago';

export interface WorkerHourSlot {
  dia: number;
  hora: string;
}

export const workerHourDuplicateMessage =
  'Esa hora ya está en tu agenda para ese día. Elige otra distinta.';

export const workerSlotTakenMessage =
  'Ese horario ya está reservado con este profesional. Elige otra hora.';

export const workerSlotUnpublishedMessage =
  'Esa hora no está publicada por el profesional. Elige un horario de su agenda.';

export const tooManyPendingPaymentsMessage =
  'Tienes pedidos sin pagar en curso. Completa o espera a que venza uno para reservar otra hora.';

export function normalizeHourLabel(raw: string): string | null {
  const match = raw.trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return null;
  return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
}

export function parseWorkerHours(raw: unknown): WorkerHourSlot[] {
  if (!Array.isArray(raw)) return [];
  const slots: WorkerHourSlot[] = [];
  for (const item of raw) {
    if (!item || typeof item !== 'object') continue;
    const row = item as { dia?: unknown; hora?: unknown };
    const dia = Number(row.dia);
    const hora = typeof row.hora === 'string' ? normalizeHourLabel(row.hora) : null;
    if (!Number.isInteger(dia) || dia < 1 || dia > 7 || !hora) continue;
    slots.push({ dia, hora });
  }
  return uniqueWorkerHours(slots);
}

export function uniqueWorkerHours(slots: WorkerHourSlot[]): WorkerHourSlot[] {
  const seen = new Set<string>();
  const unique: WorkerHourSlot[] = [];
  for (const slot of slots) {
    const hora = normalizeHourLabel(slot.hora);
    if (!hora || slot.dia < 1 || slot.dia > 7) continue;
    const key = `${slot.dia}|${hora}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push({ dia: slot.dia, hora });
  }
  return unique.sort((a, b) => a.dia - b.dia || a.hora.localeCompare(b.hora));
}

export function addWorkerHour(
  slots: WorkerHourSlot[],
  next: WorkerHourSlot,
): { slots: WorkerHourSlot[]; error?: string } {
  const hora = normalizeHourLabel(next.hora);
  if (!hora || next.dia < 1 || next.dia > 7) {
    return { slots, error: 'Indica un día y una hora válidos.' };
  }
  if (slots.some((item) => item.dia === next.dia && item.hora === hora)) {
    return { slots, error: workerHourDuplicateMessage };
  }
  return { slots: uniqueWorkerHours([...slots, { dia: next.dia, hora }]) };
}

export function uniqueIsoSlots(isos: string[]): string[] {
  const seen = new Set<string>();
  const unique: string[] = [];
  for (const iso of isos) {
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) continue;
    const key = date.toISOString().slice(0, 16);
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(date.toISOString());
  }
  return unique.sort();
}

export function formatBookingSlotLabel(
  iso: string,
  timeZone = CHILE_TIME_ZONE,
): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return iso;
  const formatted = new Intl.DateTimeFormat('es-CL', {
    timeZone,
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date);
  return formatted.replace(',', ' |');
}

export function bookingSlotError(err: unknown): string | null {
  const raw =
    err instanceof Error
      ? err.message
      : typeof err === 'object' && err && 'message' in err
        ? String((err as { message: unknown }).message)
        : String(err ?? '');
  if (/ya esta reservado|ya está reservado|duplicate key|23505/i.test(raw)) {
    return workerSlotTakenMessage;
  }
  if (
    /no esta publicada|no está publicada|ya no esta disponible|elige un horario publicado/i.test(
      raw,
    )
  ) {
    return workerSlotUnpublishedMessage;
  }
  if (/demasiados pedidos esperando pago/i.test(raw)) {
    return tooManyPendingPaymentsMessage;
  }
  return null;
}
