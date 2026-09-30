export type CheckoutReturn =
  | { kind: 'card' }
  | {
      kind: 'tracked';
      jobId: string | null;
      paymentId: string | null;
      amount: number;
      last4: string | null;
    }
  | {
      kind: 'verify';
      jobId: string | null;
      paymentId: string | null;
      guest: boolean;
      passwordToken: string | null;
    }
  | { kind: 'failed'; message: string }
  | { kind: 'none' };

/** Lee el regreso de Transbank (Webpay del invitado o tarjeta guardada). */
export function parseCheckoutReturn(search: string): CheckoutReturn {
  const raw = search.startsWith('?') ? search.slice(1) : search;
  const params = new URLSearchParams(raw);
  if (params.get('tarjeta')) return { kind: 'card' };

  const pago = params.get('pago');
  const jobId = params.get('jobId');
  if (pago === 'ok' && params.get('tracking') === '1') {
    const amount = Number(params.get('amount') || 0);
    return {
      kind: 'tracked',
      jobId,
      paymentId: params.get('paymentId'),
      amount: Number.isFinite(amount) ? amount : 0,
      last4: params.get('last4'),
    };
  }
  if (pago === 'ok' || pago === 'retorno') {
    return {
      kind: 'verify',
      jobId,
      paymentId: params.get('paymentId'),
      guest: params.get('invitado') === '1',
      passwordToken: params.get('alta'),
    };
  }
  if (pago === 'fail') {
    const motivo = params.get('motivo');
    const message =
      motivo === 'tarjeta' || motivo === 'cancelado'
        ? 'No se guardó la tarjeta. Puedes confirmar el pedido de nuevo.'
        : motivo === 'cobro'
          ? 'La tarjeta quedó guardada, pero el banco no autorizó este cobro. Confirma el pedido otra vez.'
          : 'Pago cancelado. No se realizó ningún cargo.';
    return { kind: 'failed', message };
  }
  return { kind: 'none' };
}
