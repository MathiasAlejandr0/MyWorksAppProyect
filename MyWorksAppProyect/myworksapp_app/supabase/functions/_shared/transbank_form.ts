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

/** Arma la query por si hace falta abrir Transbank sin el formulario. */
export function transbankRedirectUrl(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): string {
  const url = new URL(assertTransbankAction(input.action));
  url.searchParams.set(input.fieldName, input.token);
  return url.toString();
}

function escapeAttr(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;");
}

/**
 * Formulario que hace POST del token. Con solo el GET, la tarjeta de prueba
 * muestra el formulario y el botón de continuar no confirma el cobro.
 * El content-type va explícito: sin él, la puerta de Supabase entrega text/plain
 * y el WebView muestra el código en vez de enviarlo.
 */
export function transbankAutoPostHtml(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): string {
  if (input.fieldName !== "token_ws" && input.fieldName !== "TBK_TOKEN") {
    throw new Error("campo de token inválido");
  }
  const action = escapeAttr(assertTransbankAction(input.action));
  const token = escapeAttr(input.token);
  return `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Transbank</title>
</head>
<body>
  <p>Conectando con Transbank…</p>
  <form id="tbk" method="post" action="${action}">
    <input type="hidden" name="${input.fieldName}" value="${token}">
    <button type="submit">Continuar a Transbank</button>
  </form>
  <script>document.getElementById("tbk").submit();</script>
</body>
</html>`;
}

export function transbankRedirectResponse(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
}): Response {
  return new Response(transbankAutoPostHtml(input), {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
