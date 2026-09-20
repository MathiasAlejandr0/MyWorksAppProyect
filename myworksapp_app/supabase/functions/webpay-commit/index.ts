import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkCommit } from "../_shared/tbk.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }

  try {
    let token = "";
    const reqUrl = new URL(req.url);
    token = reqUrl.searchParams.get("token_ws") || "";

    if (req.method === "POST") {
      const ct = req.headers.get("content-type") || "";
      if (ct.includes("application/json")) {
        const body = await req.json();
        token = String(body.token_ws || body.token || token);
      } else {
        const form = await req.formData();
        token = String(form.get("token_ws") || token);
      }
    }

    if (!token) {
      return jsonResponse(req, { error: "token_ws ausente" }, 400);
    }

    const commit = await tbkCommit(token);
    const responseCode = Number(commit.response_code ?? -1);
    const status = String(commit.status || "");
    const buyOrder = String(commit.buy_order || "");
    const approved =
      responseCode === 0 || status.toUpperCase() === "AUTHORIZED";

    const admin = serviceClient();
    let { data: payment } = await admin
      .from("pagos")
      .select("id, id_trabajo, monto")
      .eq("token_tbk", token)
      .maybeSingle();

    if (!payment && buyOrder) {
      const fb = await admin
        .from("pagos")
        .select("id, id_trabajo, monto")
        .eq("buy_order", buyOrder)
        .maybeSingle();
      payment = fb.data;
    }

    if (!payment) {
      return jsonResponse(req, { error: "Pago no encontrado", commit }, 404);
    }

    // Webpay Plus commit = captura en comercio. Escrow de negocio = retenido.
    await admin
      .from("pagos")
      .update({
        estado: approved ? "retenido" : "pendiente",
        autorizado_en: approved ? new Date().toISOString() : null,
        id_transaccion: String(
          commit.authorization_code || buyOrder || token,
        ),
        actualizado_en: new Date().toISOString(),
      })
      .eq("id", payment.id);

    if (approved) {
      await admin
        .from("trabajos")
        .update({
          estado_pago: "retenido",
          actualizado_en: new Date().toISOString(),
        })
        .eq("id", payment.id_trabajo);
    }

    const webReturn =
      Deno.env.get("WEBPAY_WEB_RETURN_URL") ||
      (approved
        ? "http://localhost:5173/?pago=ok"
        : "http://localhost:5173/?pago=fail");
    const appReturn =
      Deno.env.get("WEBPAY_APP_RETURN_URL") || "myworksapp://pago/retorno";

    const payload = JSON.stringify({
      type: "mwa-webpay",
      ok: approved,
      paymentId: payment.id,
      jobId: payment.id_trabajo,
    });

    // Embed (iframe/popup/WebView): avisa al opener/parent y cierra.
    // Redirect invitado: meta-refresh a la web.
    const html = `<!DOCTYPE html>
<html lang="es"><head>
<meta charset="utf-8"/>
<title>Pago Webpay</title>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
  body{font-family:system-ui,sans-serif;background:#0b1220;color:#f8fafc;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0;padding:24px;text-align:center}
  a{color:#FF5E03}
</style>
</head><body>
<h1>${approved ? "Pago autorizado y retenido" : "Pago no autorizado"}</h1>
<p>Puedes volver a My Works App.</p>
<p><a id="web" href="${webReturn}">Volver a la web</a> · <a id="app" href="${appReturn}?ok=${approved ? "1" : "0"}&paymentId=${payment.id}">Abrir app</a></p>
<script>
(function(){
  var msg = ${payload};
  try {
    if (window.opener && !window.opener.closed) {
      window.opener.postMessage(msg, "*");
      setTimeout(function(){ window.close(); }, 400);
      return;
    }
  } catch (e) {}
  try {
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(msg, "*");
      return;
    }
  } catch (e) {}
  // Flujo invitado / navegación completa
  setTimeout(function(){ location.replace(${JSON.stringify(webReturn)}); }, 1200);
})();
</script>
</body></html>`;

    return new Response(html, {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        ...corsHeadersFor(req),
        "Cache-Control": "no-store",
      },
    });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
