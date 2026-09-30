/** Arma la vuelta del navegador después de Webpay. Sin Deno, para poder testearla. */

export function readCommitTokens(input: {
  queryTokenWs?: string | null;
  queryTbkToken?: string | null;
  bodyTokenWs?: string | null;
  bodyTbkToken?: string | null;
}): { tokenWs: string; tbkToken: string } {
  const tokenWs = String(input.bodyTokenWs || input.queryTokenWs || "").trim();
  const tbkToken = String(input.bodyTbkToken || input.queryTbkToken || "").trim();
  return { tokenWs, tbkToken };
}

export function webReturnLocation(input: {
  origin: string;
  pago: "ok" | "fail";
  paymentId?: string;
  jobId?: string;
  guest?: boolean;
  alta?: string;
}): string {
  const raw = input.origin.trim();
  const base = raw.endsWith("/") ? raw : `${raw}/`;
  const url = new URL(base);
  url.searchParams.set("pago", input.pago);
  if (input.paymentId) url.searchParams.set("paymentId", input.paymentId);
  if (input.jobId) url.searchParams.set("jobId", input.jobId);
  if (input.guest) url.searchParams.set("invitado", "1");
  if (input.alta) url.searchParams.set("alta", input.alta);
  return url.toString();
}
