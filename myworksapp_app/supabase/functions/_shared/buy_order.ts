/** Orden Oneclick de 26 caracteres. Un rechazo del banco quema la orden; el reintento usa el sufijo siguiente. */
export function freshBuyOrder(paymentId: string, previous: string | null): string {
  const hex = paymentId.replace(/-/g, "").padEnd(23, "0").slice(0, 23);
  const stem = `A${hex}`;
  let next = 0;
  if (previous && previous.length === 26 && previous.startsWith(stem)) {
    const suffix = Number.parseInt(previous.slice(24), 16);
    if (Number.isFinite(suffix)) next = (suffix + 1) & 0xff;
  } else if (previous) {
    next = 1;
  }
  return `${stem}${next.toString(16).padStart(2, "0")}`;
}

export function detailBuyOrder(parent: string): string {
  return `B${parent.slice(1, 26)}`;
}
