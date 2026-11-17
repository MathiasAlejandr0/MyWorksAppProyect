const TRANSBANK_HOSTS = new Set([
  "webpay3gint.transbank.cl",
  "webpay3g.transbank.cl",
]);

/** Solo el host de Transbank, https. */
export function assertTransbankAction(url: string): string {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:" || !TRANSBANK_HOSTS.has(parsed.hostname)) {
    throw new Error("URL de pago inválida");
  }
  return parsed.toString();
}

/** Query GET con el token, para el fallback sin JavaScript. */
export function transbankRedirectUrl(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): string {
  const url = new URL(assertTransbankAction(input.action));
  url.searchParams.set(input.fieldName, input.token);
  return url.toString();
}

/** Página estática (Vercel) que hace el POST. *.supabase.co sirve HTML como text/plain. */
export const TRANSBANK_BRIDGE_ORIGIN = "https://myworksapp-cl.vercel.app";

/**
 * Dirección de la página puente. Lleva acción, campo y token en el fragmento (#),
 * que el navegador no envía al servidor ni a los logs.
 */
export function transbankBridgeUrl(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
  bridgeOrigin?: string;
}): string {
  if (input.fieldName !== "token_ws" && input.fieldName !== "TBK_TOKEN") {
    throw new Error("campo de token inválido");
  }
  const frag = new URLSearchParams({
    a: assertTransbankAction(input.action),
    f: input.fieldName,
    t: input.token,
  });
  const origin = (input.bridgeOrigin || TRANSBANK_BRIDGE_ORIGIN).replace(/\/+$/, "");
  return `${origin}/tbk-post.html#${frag.toString()}`;
}

/**
 * Transbank recibe el token por POST: con solo el GET, la tarjeta de prueba muestra
 * el formulario y el botón de continuar no confirma el cobro. Como la puerta de
 * Supabase no sirve HTML, se redirige a la página puente que envía el formulario.
 */
export function transbankRedirectResponse(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): Response {
  return new Response(null, {
    status: 303,
    headers: {
      Location: transbankBridgeUrl(input),
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}
