import type { AppSupabase } from '../client';
import { edgeFunctionErrorMessage } from './edgeError';

export type OneclickCharged = {
  charged: true;
  paymentId: string;
  jobId: string;
  amount: number;
  last4: string;
  cardType: string;
};

export type OneclickNeedsCard = {
  charged: false;
  needsCard: true;
  /** `tarjeta_inactiva`: Transbank dio de baja la tarjeta guardada y hay que inscribir otra. */
  reason?: string;
};

export type SavedCardStatus = {
  enrolled: boolean;
  last4: string;
  cardType: string;
};

/** Invitado y sesión sin tarjeta van a Webpay Plus. Con tarjeta inscrita se cobra Oneclick. */
export function checkoutLane(input: {
  signedIn: boolean;
  cardEnrolled: boolean;
}): 'webpay' | 'charge' {
  if (input.signedIn && input.cardEnrolled) return 'charge';
  return 'webpay';
}

export type OneclickChargeResult = OneclickCharged | OneclickNeedsCard;

const TRANSBANK_HOSTS = new Set([
  'webpay3gint.transbank.cl',
  'webpay3g.transbank.cl',
]);

export function formatClpAmount(amount: number): string {
  const n = Math.max(0, Math.round(Number.isFinite(amount) ? amount : 0));
  return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

export function orderConfirmedMessage(input: {
  amountClp: number;
  last4?: string | null;
  workerName?: string | null;
}): string {
  const money = formatClpAmount(input.amountClp);
  const last4 = String(input.last4 || '').replace(/\D/g, '').slice(-4);
  const card = last4 ? ` de tu tarjeta •••• ${last4}` : ' de tu tarjeta';
  const who = input.workerName?.trim()
    ? `${input.workerName.trim()} ya puede aceptar el pedido.`
    : 'El profesional ya puede aceptar el pedido.';
  return `Pedido confirmado. Se descontará $${money}${card}. ${who}`;
}

export function assertTransbankUrl(url: string): void {
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' || !TRANSBANK_HOSTS.has(parsed.hostname)) {
    throw new Error('URL de pago inválida');
  }
}

export function parseOneclickCharge(payload: unknown): OneclickChargeResult {
  const data = payload as Record<string, unknown> | null;
  if (!data || data.error) {
    throw new Error(String(data?.error || 'Respuesta de pago inválida'));
  }
  if (data.charged === true) {
    return {
      charged: true,
      paymentId: String(data.paymentId || ''),
      jobId: String(data.jobId || ''),
      amount: Number(data.amount || 0),
      last4: String(data.last4 || '').replace(/\D/g, '').slice(-4),
      cardType: String(data.cardType || ''),
    };
  }
  if (data.needsCard === true) {
    return {
      charged: false,
      needsCard: true,
      ...(typeof data.reason === 'string' && data.reason ? { reason: data.reason } : {}),
    };
  }
  throw new Error('Respuesta de pago inválida');
}

async function errorMessage(error: { message?: string; context?: Response }): Promise<string> {
  return edgeFunctionErrorMessage(error, 'No se pudo cobrar la tarjeta');
}

/** Cobra la tarjeta inscrita. Si no hay tarjeta, needsCard y la web abre Webpay Plus. */
export async function chargeSavedCard(
  supabase: AppSupabase,
  input: { jobId: string; amountClp: number; changeOrderId?: string },
): Promise<OneclickChargeResult> {
  const { data, error } = await supabase.functions.invoke('oneclick-charge', {
    body: {
      jobId: input.jobId,
      amountClp: input.amountClp,
      changeOrderId: input.changeOrderId,
    },
  });
  if (error) {
    throw new Error(await errorMessage(error));
  }
  return parseOneclickCharge(data);
}

export function parseSavedCardStatus(payload: unknown): SavedCardStatus {
  const data = payload as Record<string, unknown> | null;
  if (!data || data.error) {
    throw new Error(String(data?.error || 'Respuesta de tarjeta inválida'));
  }
  return {
    enrolled: data.enrolled === true,
    last4: String(data.last4 || '').replace(/\D/g, '').slice(-4),
    cardType: String(data.cardType || ''),
  };
}

/** Tarjeta guardada del cliente (últimos 4 y tipo). Si Transbank ya la dejó lista, la confirma. */
export async function getSavedCard(supabase: AppSupabase): Promise<SavedCardStatus> {
  const { data, error } = await supabase.functions.invoke('oneclick-charge', {
    body: { action: 'status' },
  });
  if (error) throw new Error(await errorMessage(error));
  return parseSavedCardStatus(data);
}

/**
 * Prepara la inscripción de la tarjeta. Con `jobId`, al volver de Transbank el servidor
 * cobra ese pedido con la tarjeta recién guardada. Devuelve la URL que hay que abrir.
 */
export async function startCardEnrollment(
  supabase: AppSupabase,
  input: { jobId?: string } = {},
): Promise<{ handoffUrl: string }> {
  const { data, error } = await supabase.functions.invoke('oneclick-charge', {
    body: { action: 'enroll', ...(input.jobId ? { jobId: input.jobId } : {}) },
  });
  if (error) throw new Error(await errorMessage(error));
  const payload = data as Record<string, unknown> | null;
  if (!payload || payload.error) {
    throw new Error(String(payload?.error || 'No se pudo preparar la tarjeta'));
  }
  const handoffUrl = String(payload.handoffUrl || '');
  if (!handoffUrl.startsWith('https://')) {
    throw new Error('Esa tarjeta ya está guardada.');
  }
  return { handoffUrl };
}

/** Quita la tarjeta guardada para poder inscribir otra. */
export async function removeSavedCard(supabase: AppSupabase): Promise<void> {
  const { data, error } = await supabase.functions.invoke('oneclick-charge', {
    body: { action: 'remove' },
  });
  if (error) throw new Error(await errorMessage(error));
  const payload = data as Record<string, unknown> | null;
  if (payload?.error) throw new Error(String(payload.error));
}
