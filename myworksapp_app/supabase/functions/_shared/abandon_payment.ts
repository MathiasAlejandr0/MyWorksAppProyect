export type AbandonedCheckout = {
  pago: "anulado" | "fallido";
  job: "cancelado";
  reason: "abort" | "reject" | "mismatch";
};

const SETTLED = new Set(["retenido", "liberado", "autorizado"]);

/**
 * Un cobro ya en garantía no se anula.
 * Cancelar en Webpay (TBK_TOKEN, sin token_ws) deja el pago anulado.
 * Un rechazo o un monto distinto lo deja fallido. El pedido pasa a cancelado.
 */
export function abandonedCheckoutUpdate(input: {
  estado: string;
  tokenWs: string;
  tbkToken: string;
  decision?: "reject" | "mismatch" | "hold" | "replay";
}): AbandonedCheckout | null {
  if (SETTLED.has(input.estado) || input.estado !== "pendiente") return null;
  const tokenWs = input.tokenWs.trim();
  const tbkToken = input.tbkToken.trim();
  if (!tokenWs && tbkToken) {
    return { pago: "anulado", job: "cancelado", reason: "abort" };
  }
  if (input.decision === "reject" || input.decision === "mismatch") {
    return { pago: "fallido", job: "cancelado", reason: input.decision };
  }
  return null;
}
