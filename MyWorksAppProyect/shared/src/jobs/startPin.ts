import type { AppSupabase } from '../client';

/** Estados en los que el cliente le muestra el PIN al profesional. */
export const START_PIN_VISIBLE_STATUSES = ['aceptado', 'en_camino'] as const;

export function clientShouldShowStartPin(status: string | null | undefined): boolean {
  return START_PIN_VISIBLE_STATUSES.includes(
    status as (typeof START_PIN_VISIBLE_STATUSES)[number],
  );
}

export function normalizeStartPin(pin: string): string {
  const clean = pin.trim();
  if (!/^\d{4}$/.test(clean)) {
    throw new Error('Ingresa el PIN de 4 dígitos que te muestra el cliente.');
  }
  return clean;
}

type PinAttempt = { ok?: boolean; mensaje?: string };

/**
 * Inicia el trabajo. Web y escritorio deben usar esto: el estado en_curso
 * no se escribe con un update directo.
 */
export async function startJobWithPin(
  supabase: AppSupabase,
  jobId: string,
  pin: string,
): Promise<void> {
  const clean = normalizeStartPin(pin);
  const attempt = await supabase.rpc('intentar_pin_inicio', {
    p_trabajo_id: jobId,
    p_pin: clean,
  });
  if (attempt.error) {
    throw new Error(attempt.error.message || 'No se pudo comprobar el PIN');
  }
  const body = attempt.data as PinAttempt | null;
  if (!body || body.ok !== true) {
    throw new Error(body?.mensaje || 'PIN incorrecto.');
  }
  const { error } = await supabase.rpc('transicionar_trabajo', {
    p_trabajo_id: jobId,
    p_nuevo_estado: 'en_curso',
    p_pin: clean,
  });
  if (error) {
    throw new Error(error.message || 'No se pudo iniciar el trabajo');
  }
}

export async function fetchClientStartPin(
  supabase: AppSupabase,
  jobId: string,
): Promise<string | null> {
  const { data, error } = await supabase.rpc('obtener_pin_inicio', {
    p_trabajo_id: jobId,
  });
  if (error) return null;
  const pin = typeof data === 'string' ? data.trim() : '';
  return /^\d{4}$/.test(pin) ? pin : null;
}
