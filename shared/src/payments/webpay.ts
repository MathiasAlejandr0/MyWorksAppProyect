import type { AppSupabase } from '../client';

export type PaymentsMode = 'integration' | 'production' | 'off';

/** Cómo presentar Webpay en el cliente. */
export type WebpayPresentMode = 'embed' | 'redirect';

export function getPaymentsMode(
  envValue?: string | null,
): PaymentsMode {
  const v = (envValue || 'integration').trim().toLowerCase();
  if (v === 'production' || v === 'off') return v;
  return 'integration';
}

export interface WebpayCreateResult {
  paymentId: string;
  buyOrder: string;
  redirectUrl: string;
  token?: string;
  ambiente?: string;
  /** embed = usuario autenticado (modal/WebView); redirect = invitado web. */
  presentMode?: WebpayPresentMode;
}

/**
 * Inicia sesión Webpay vía Edge Function `webpay-create`.
 * Requiere JWT de usuario en el cliente Supabase.
 *
 * Usuarios autenticados: presentMode=embed (no hacer window.location.assign).
 * Invitados web: usar createGuestWebpayCheckout (redirect completo).
 */
export async function createWebpaySession(
  supabase: AppSupabase,
  input: {
    jobId: string;
    amountClp: number;
    returnUrl?: string;
    presentMode?: WebpayPresentMode;
  },
): Promise<WebpayCreateResult> {
  const presentMode = input.presentMode ?? 'embed';
  const { data, error } = await supabase.functions.invoke('webpay-create', {
    body: {
      jobId: input.jobId,
      amountClp: input.amountClp,
      returnUrl: input.returnUrl,
      presentMode,
    },
  });

  if (error) {
    throw new Error(error.message || 'No se pudo iniciar Webpay');
  }

  const payload = data as Record<string, unknown> | null;
  if (!payload || payload.error) {
    throw new Error(String(payload?.error || 'Respuesta Webpay inválida'));
  }

  const redirectUrl = String(payload.redirectUrl || '');
  if (!redirectUrl) {
    throw new Error('Webpay no devolvió redirectUrl');
  }

  return {
    paymentId: String(payload.paymentId || ''),
    buyOrder: String(payload.buyOrder || ''),
    redirectUrl,
    token: payload.token ? String(payload.token) : undefined,
    ambiente: payload.ambiente ? String(payload.ambiente) : undefined,
    presentMode,
  };
}

export async function fetchPaymentStatus(
  supabase: AppSupabase,
  paymentId: string,
  jobId?: string,
): Promise<{ id: string; estado: string; id_trabajo?: string } | null> {
  const { data, error } = await supabase.functions.invoke('webpay-status', {
    body: { paymentId, jobId },
  });
  if (error) throw new Error(error.message || 'No se pudo consultar el pago');
  const payload = data as { payment?: Record<string, unknown>; error?: string } | null;
  if (!payload || payload.error || !payload.payment) return null;
  return {
    id: String(payload.payment.id),
    estado: String(payload.payment.estado),
    id_trabajo: payload.payment.id_trabajo
      ? String(payload.payment.id_trabajo)
      : undefined,
  };
}
