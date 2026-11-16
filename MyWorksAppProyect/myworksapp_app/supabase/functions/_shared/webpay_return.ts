/** La APK no puede abrir `myworksapp://`. El WebView sí sigue un https con `pago=ok`. */
export const APP_WEBVIEW_RETURN_ORIGIN = "https://myworksapp-cl.vercel.app/";

/**
 * Si la vuelta es un esquema de la app, la reescribe al sitio https conservando
 * la query (`pago`, `tarjeta`, `paymentId`, `jobId`). Un http(s) no se toca.
 */
export function bridgeCustomSchemeReturn(
  location: string,
  httpsOrigin: string,
): string {
  const url = new URL(location);
  if (url.protocol === "http:" || url.protocol === "https:") return location;
  const origin = httpsOrigin.trim();
  const bridge = new URL(origin.endsWith("/") ? origin : `${origin}/`);
  if (bridge.protocol !== "https:") return location;
  url.searchParams.forEach((value, key) => {
    bridge.searchParams.set(key, value);
  });
  return bridge.toString();
}

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
