import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { openJobAfterHold } from "../_shared/open_job_after_hold.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkCommit } from "../_shared/tbk.ts";
import { webPostMessageOrigins } from "../_shared/security.ts";

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

    const admin = serviceClient();
    const { data: payment } = await admin
      .from("pagos")
      .select("id, id_trabajo, monto, estado, metodo_pago")
      .eq("token_tbk", token)
      .maybeSingle();

    if (!payment) {
      return jsonResponse(req, { error: "Pago no encontrado" }, 404);
    }
    if (payment.metodo_pago === "oneclick") {
      return jsonResponse(req, { error: "Este pago no es Webpay" }, 409);
    }

    const wantsJson = (req.headers.get("content-type") || "").includes(
      "application/json",
    );

    const alreadyHeld = payment.estado === "retenido" ||
      payment.estado === "liberado";
    let commit: Record<string, unknown> = {};
    if (!alreadyHeld) {
      commit = await tbkCommit(token);
    }
    const responseCode = Number(commit.response_code ?? (alreadyHeld ? 0 : -1));
    const status = String(commit.status || (alreadyHeld ? "AUTHORIZED" : ""));
    const buyOrder = String(commit.buy_order || "");
    const approved = alreadyHeld ||
      responseCode === 0 || status.toUpperCase() === "AUTHORIZED";

    if (payment.estado !== "liberado") {
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
    }

    let passwordSetupUrl = "";
    if (approved && payment.estado !== "liberado") {
      await openJobAfterHold(admin, payment.id_trabajo);

      const { data: job } = await admin
        .from("trabajos")
        .select("id_usuario")
        .eq("id", payment.id_trabajo)
        .maybeSingle();
      const ownerId = job?.id_usuario ? String(job.id_usuario) : "";
      if (ownerId) {
        const { data: owner } = await admin.auth.admin.getUserById(ownerId);
        const meta = owner.user?.user_metadata ?? {};
        const guest = meta.guest_checkout === true || meta.guest_checkout === "true";
        const email = owner.user?.email ?? "";
        if (guest && email) {
          await admin.auth.admin.updateUserById(ownerId, { email_confirm: true });
          const link = await admin.auth.admin.generateLink({
            type: "recovery",
            email,
          });
          passwordSetupUrl = link.data?.properties?.action_link ?? "";
        }
      }
    }

    if (wantsJson) {
      return jsonResponse(req, {
        approved,
        ok: approved,
        paymentStatus: approved ? "ESCROW" : "REJECTED",
        paymentId: payment.id,
        jobId: payment.id_trabajo,
      });
    }

    const passwordHref = passwordSetupUrl
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");

    const webBase =
      Deno.env.get("WEBPAY_WEB_RETURN_URL") || "http://localhost:5173/";
    const webUrl = new URL(webBase);
    webUrl.searchParams.set("pago", approved ? "ok" : "fail");
    webUrl.searchParams.set("paymentId", payment.id);
    webUrl.searchParams.set("jobId", payment.id_trabajo);
    const webReturn = webUrl.toString();

    const appReturn =
      Deno.env.get("WEBPAY_APP_RETURN_URL") || "myworksapp://pago/retorno";

    const payload = JSON.stringify({
      type: "mwa-webpay",
      ok: approved,
      paymentId: payment.id,
      jobId: payment.id_trabajo,
    });

    const origins = webPostMessageOrigins();
    const originsJs = JSON.stringify(origins);

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
${passwordHref ? `<p><a href="${passwordHref}">Crea tu contraseña para entrar después</a></p>` : ""}
<p><a id="web" href="${webReturn}">Volver a la web</a> · <a id="app" href="${appReturn}?ok=${approved ? "1" : "0"}&paymentId=${payment.id}&jobId=${payment.id_trabajo}">Abrir app</a></p>
<script>
(function(){
  var msg = ${payload};
  var origins = ${originsJs};
  function post(target) {
    if (!target) return;
    if (!origins.length) {
      try { target.postMessage(msg, "*"); } catch (e) {}
      return;
    }
    for (var i = 0; i < origins.length; i++) {
      try { target.postMessage(msg, origins[i]); } catch (e) {}
    }
  }
  try {
    if (window.opener && !window.opener.closed) {
      post(window.opener);
      setTimeout(function(){ window.close(); }, 400);
      return;
    }
  } catch (e) {}
  try {
    if (window.parent && window.parent !== window) {
      post(window.parent);
      return;
    }
  } catch (e) {}
  if (${passwordHref ? "false" : "true"}) {
    setTimeout(function(){ location.replace(${JSON.stringify(webReturn)}); }, 1200);
  }
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
