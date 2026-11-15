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
    return { charged: false, needsCard: true };
  }
  throw new Error('Respuesta de pago inválida');
}

async function errorMessage(error: { message?: string; context?: Response }): Promise<string> {
  return edgeFunctionErrorMessage(error, 'No se pudo cobrar la tarjeta');
}

/** Cobra la tarjeta inscrita. Si no hay tarjeta, needsCard y la web abre Webpay Plus. */
export async function chargeSavedCard(
  supabase: AppSupabase,
  input: { jobId: string; amountClp: number },
): Promise<OneclickChargeResult> {
  const { data, error } = await supabase.functions.invoke('oneclick-charge', {
    body: { jobId: input.jobId, amountClp: input.amountClp },
  });
  if (error) {
    throw new Error(await errorMessage(error));
  }
  return parseOneclickCharge(data);
}
