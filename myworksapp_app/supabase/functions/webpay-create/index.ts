import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { resolveReturnUrl, signHandoffTicket } from "../_shared/security.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";
import { tbkConfig, tbkCreateTransaction } from "../_shared/tbk.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  try {
    const userSb = userClient(req);
    const {
      data: { user },
      error: authErr,
    } = await userSb.auth.getUser();
    if (authErr || !user) {
      return jsonResponse(req, { error: "No autenticado" }, 401);
    }

    const body = await req.json();
    const jobId = String(body.jobId || "");
    const amountClp = Number(body.amountClp);
    if (!jobId || !Number.isFinite(amountClp) || amountClp <= 0) {
      return jsonResponse(req, { error: "jobId y amountClp requeridos" }, 400);
    }

    const { data: payment, error: payErr } = await userSb.rpc(
      "crear_intencion_pago",
      {
        p_id_trabajo: jobId,
        p_monto: amountClp,
        p_buy_order: null,
      },
    );
    if (payErr) {
      return jsonResponse(req, { error: payErr.message }, 400);
    }

    const paymentId = payment.id as string;
    const buyOrder = `MWA${paymentId.replace(/-/g, "").slice(0, 20)}`;
    const returnUrl = resolveReturnUrl(
      typeof body.returnUrl === "string" ? body.returnUrl : undefined,
    );

    const { env } = tbkConfig();
    const { token, url } = await tbkCreateTransaction({
      buyOrder,
      sessionId: user.id,
      amount: amountClp,
      returnUrl,
    });

    const admin = serviceClient();
    await admin
      .from("pagos")
      .update({
        buy_order: buyOrder,
        token_tbk: token,
        url_tbk: url,
        ambiente: env,
        id_transaccion: buyOrder,
        actualizado_en: new Date().toISOString(),
      })
      .eq("id", paymentId);

    const ticket = await signHandoffTicket(paymentId);
    const handoff = `${Deno.env.get("SUPABASE_URL")}/functions/v1/webpay-handoff?t=${encodeURIComponent(ticket)}`;

    // No devolver token_ws al cliente — solo URL firmada de handoff.
    // presentMode informativo para el cliente (embed vs redirect).
    const presentMode =
      typeof body.presentMode === "string" && body.presentMode === "redirect"
        ? "redirect"
        : "embed";

    return jsonResponse(req, {
      paymentId,
      buyOrder,
      redirectUrl: handoff,
      ambiente: env,
      presentMode,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const status = msg.includes("WEBPAY_HANDOFF_SECRET") ? 503 : 500;
    return jsonResponse(req, { error: msg }, status);
  }
});
