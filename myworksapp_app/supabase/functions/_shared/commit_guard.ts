export type CommitAssessment =
  | { action: "replay" }
  | { action: "hold" }
  | { action: "reject" }
  | { action: "mismatch"; reason: "monto" | "buy_order" };

/** Un pago ya retenido o liberado no se vuelve a escribir ni a reautorizar. */
export function assessWebpayCommit(input: {
  estado: string;
  responseCode: number | null;
  status: string;
  commitAmount: number | null;
  expectedAmount: number;
  commitBuyOrder: string;
  storedBuyOrder: string;
}): CommitAssessment {
  if (input.estado === "retenido" || input.estado === "liberado") {
    return { action: "replay" };
  }
  const approved = input.responseCode === 0 ||
    input.status.toUpperCase() === "AUTHORIZED";
  if (!approved) return { action: "reject" };

  const amount = input.commitAmount;
  if (
    amount == null ||
    !Number.isFinite(amount) ||
    !Number.isFinite(input.expectedAmount) ||
    Math.round(amount) !== Math.round(input.expectedAmount)
  ) {
    return { action: "mismatch", reason: "monto" };
  }

  const got = input.commitBuyOrder.trim();
  const want = input.storedBuyOrder.trim();
  if (!got || !want || got !== want) {
    return { action: "mismatch", reason: "buy_order" };
  }
  return { action: "hold" };
}
