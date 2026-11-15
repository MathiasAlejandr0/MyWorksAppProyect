/** Ventana para reintentar la confirmación del trabajo tras un Webpay capturado. */
export const UNCONFIRMED_WINDOW_MS = 30 * 60 * 1000;

export const PAYMENT_AWAITING_JOB = "pagado_por_confirmar";
export const PAYMENT_AUTO_REFUNDED = "reembolsado_auto";

export type ReconcileDecision =
  | { action: "confirm" }
  | { action: "mark_held" }
  | { action: "refund" }
  | { action: "drop" }
  | { action: "wait" }
  | { action: "ignore" };

/**
 * No vuelve a cobrar. `confirm` solo abre el trabajo.
 * `refund` exige que Transbank siga autorizando el cobro.
 * `mark_held` cierra el pago si el trabajo ya salió de esperando_pago.
 */
export function decideReconciliation(input: {
  paymentStatus: string;
  jobStatus: string;
  capturedAtMs: number;
  nowMs: number;
  transbankAuthorized: boolean;
  windowMs?: number;
}): ReconcileDecision {
  if (input.paymentStatus !== PAYMENT_AWAITING_JOB) {
    return { action: "ignore" };
  }
  const windowMs = input.windowMs ?? UNCONFIRMED_WINDOW_MS;
  const expired = input.nowMs - input.capturedAtMs >= windowMs;
  if (input.jobStatus !== "esperando_pago") {
    return { action: "mark_held" };
  }
  if (!input.transbankAuthorized) {
    return expired ? { action: "drop" } : { action: "wait" };
  }
  if (expired) return { action: "refund" };
  return { action: "confirm" };
}
