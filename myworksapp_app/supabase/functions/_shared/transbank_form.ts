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

/** Transbank acepta el token por GET. El HTML auto-POST lo sirve *.supabase.co como text/plain. */
export function transbankRedirectUrl(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): string {
  const url = new URL(assertTransbankAction(input.action));
  url.searchParams.set(input.fieldName, input.token);
  return url.toString();
}

export function transbankRedirectResponse(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): Response {
  return new Response(null, {
    status: 303,
    headers: {
      Location: transbankRedirectUrl(input),
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}
