import type { AppSupabase } from '../client';

export interface GuestCheckoutInput {
  name: string;
  email: string;
  phone: string;
  address: string;
  workerId: string;
  serviceId: string;
  description?: string;
  amountClp: number;
  /** Solo para el return_url de Transbank (commit Edge o allowlist). */
  returnUrl?: string;
}

export interface GuestCheckoutResult {
  jobId: string;
  paymentId: string;
  buyOrder: string;
  redirectUrl: string;
  ambiente?: string;
  mode: 'guest_redirect';
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
      returnUrl: input.returnUrl,
    },
  });

  if (error) {
    throw new Error(error.message || 'No se pudo iniciar el checkout invitado');
  }

  const payload = data as Record<string, unknown> | null;
  if (!payload) {
    throw new Error('Respuesta guest-checkout vacía');
  }

  if (payload.error === 'account_exists') {
    const err = new Error(
      String(
        payload.message ||
          'Ya existe una cuenta con este correo. Inicia sesión.',
      ),
    );
    (err as Error & { code?: string }).code = 'account_exists';
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
  };
}
