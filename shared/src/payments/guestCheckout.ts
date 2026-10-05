import type { AppSupabase } from '../client';
import { edgeFunctionErrorMessage } from './edgeError';

export interface GuestCheckoutInput {
  name: string;
  email: string;
  phone: string;
  address: string;
  workerId: string;
  serviceId: string;
  description?: string;
  amountClp: number;
  /** ISO del horario elegido en la barra. */
  scheduledAt?: string;
  /** Solo para el return_url de Transbank (commit Edge o allowlist). */
  returnUrl?: string;
  turnstileToken?: string;
}

export interface GuestCheckoutResult {
  jobId: string;
  paymentId: string;
  buyOrder: string;
  redirectUrl: string;
  ambiente?: string;
  mode: 'guest_redirect';
  /** Nonce del navegador. Se guarda en sessionStorage; no va en la URL. */
  nonce?: string;
}

/**
 * Checkout web sin sesión: crea cuenta + trabajo + intención Webpay.
 * El cliente DEBE redirigir (window.location) — no embeber.
 */
export async function createGuestWebpayCheckout(
  supabase: AppSupabase,
  input: GuestCheckoutInput,
): Promise<GuestCheckoutResult> {
  const { data, error } = await supabase.functions.invoke('guest-checkout', {
    body: {
      name: input.name,
      email: input.email,
      phone: input.phone,
      address: input.address,
      workerId: input.workerId,
      serviceId: input.serviceId,
      description: input.description,
      amountClp: input.amountClp,
      scheduledAt: input.scheduledAt,
      returnUrl: input.returnUrl,
      turnstileToken: input.turnstileToken,
    },
  });

  if (error) {
    throw new Error(
      await edgeFunctionErrorMessage(error, 'No se pudo iniciar el checkout invitado'),
    );
  }

  const payload = data as Record<string, unknown> | null;
  if (!payload) {
    throw new Error('Respuesta guest-checkout vacía');
  }

  if (payload.needsLogin === true) {
    const err = new Error(
      'No se abrió el pago. Si ya estás registrado, entra con tu cuenta.',
    );
    (err as Error & { code?: string }).code = 'sign_in';
    throw err;
  }

  if (payload.error) {
    throw new Error(String(payload.error));
  }

  const redirectUrl = String(payload.redirectUrl || '');
  if (!redirectUrl) {
    throw new Error('guest-checkout no devolvió redirectUrl');
  }

  return {
    jobId: String(payload.jobId || ''),
    paymentId: String(payload.paymentId || ''),
    buyOrder: String(payload.buyOrder || ''),
    redirectUrl,
    ambiente: payload.ambiente ? String(payload.ambiente) : undefined,
    mode: 'guest_redirect',
    nonce: payload.nonce ? String(payload.nonce) : undefined,
  };
}
