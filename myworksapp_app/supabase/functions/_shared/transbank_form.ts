const TRANSBANK_HOSTS = new Set([
  "webpay3gint.transbank.cl",
  "webpay3g.transbank.cl",
]);

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Solo el host de Transbank, https. */
export function assertTransbankAction(url: string): string {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:" || !TRANSBANK_HOSTS.has(parsed.hostname)) {
    throw new Error("URL de pago inválida");
  }
  return parsed.toString();
}

/**
 * Página que hace POST del token a Transbank.
 * La usan el handoff de Webpay (invitado) y el de inscripción Oneclick (app).
 */
export function transbankAutoPostHtml(input: {
  action: string;
  fieldName: "token_ws" | "TBK_TOKEN";
  token: string;
  title: string;
  message: string;
}): string {
  const action = escapeHtml(assertTransbankAction(input.action));
  const token = escapeHtml(input.token);
  const title = escapeHtml(input.title);
  const message = escapeHtml(input.message);
  return `<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"/><title>${title}</title></head>
<body onload="document.getElementById('tbk').submit()">
<p>${message}</p>
<form id="tbk" method="POST" action="${action}">
  <input type="hidden" name="${input.fieldName}" value="${token}" />
  <button type="submit">Continuar</button>
</form>
<script>document.getElementById('tbk').submit();</script>
</body></html>`;
}

export function transbankFormResponse(html: string): Response {
  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Content-Disposition": "inline",
      "Content-Security-Policy":
        "default-src 'none'; script-src 'unsafe-inline'; form-action https://webpay3gint.transbank.cl https://webpay3g.transbank.cl; style-src 'unsafe-inline'",
    },
  });
}
