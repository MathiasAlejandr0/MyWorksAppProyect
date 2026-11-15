import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { chargeInscribedCard } from "../_shared/oneclick_charge.ts";
import {
  allowRate,
  clientIp,
  rateLimitExceededMessage,
} from "../_shared/rate_limit.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";
import { assertTransbankAction } from "../_shared/transbank_form.ts";
import { tbkOneclickStart } from "../_shared/tbk.ts";

async function cardSetup(req: Request, userId: string, email: string, action: string) {
  const admin = serviceClient();
  const { data: card, error: cardErr } = await admin
    .from("metodos_pago_oneclick")
    .select("ultimos4, tipo_tarjeta, estado, tbk_user")
    .eq("id_usuario", userId)
    .maybeSingle();
  if (cardErr) {
    return jsonResponse(req, { error: "No se pudo leer la tarjeta guardada." }, 500);
  }
  const enrolled = card?.estado === "activa" && Boolean(card.tbk_user);
  if (action === "status" || enrolled) {
    return jsonResponse(req, {
      enrolled,
      last4: card?.ultimos4 || "",
      cardType: card?.tipo_tarjeta || "",
    });
  }

  const mail = email.trim();
  if (!mail) {
    return jsonResponse(
      req,
      { error: "Tu cuenta necesita un correo para guardar la tarjeta." },
      400,
    );
  }
  const base = Deno.env.get("SUPABASE_URL") || "";
  if (!base.startsWith("https://")) {
    return jsonResponse(req, { error: "No se pudo preparar la inscripción de la tarjeta." }, 500);
  }
  const started = await tbkOneclickStart({
    username: userId,
    email: mail,
    responseUrl: `${base}/functions/v1/oneclick-return`,
  });
  assertTransbankAction(started.url);
  const ticket = crypto.randomUUID();
  const { error: saveErr } = await admin.from("metodos_pago_oneclick").upsert(
    {
      id_usuario: userId,
      username: userId,
      estado: "pendiente",
      token_inscripcion: started.token,
      url_inscripcion: started.url,
      ticket_handoff: ticket,
      id_trabajo_pendiente: null,
      tbk_user: null,
      actualizado_en: new Date().toISOString(),
    },
    { onConflict: "id_usuario" },
  );
  if (saveErr) {
    return jsonResponse(req, { error: "No se pudo preparar la inscripción de la tarjeta." }, 500);
  }
  return jsonResponse(req, {
    enrolled: false,
    needsCard: true,
    handoffUrl: `${base}/functions/v1/oneclick-handoff?t=${encodeURIComponent(ticket)}`,
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  try {
    if (isKillSwitchOn("MWA_READ_ONLY") || isKillSwitchOn("MWA_KILL_WEBPAY")) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }

    const ip = clientIp(req);
    if (!allowRate(`oneclick:ip:${ip}`, 20, 60_000)) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }

    const userSb = userClient(req);
    const {
      data: { user },
      error: authErr,
    } = await userSb.auth.getUser();
    if (authErr || !user) {
      return jsonResponse(req, { error: "No autenticado" }, 401);
    }
    if (!allowRate(`oneclick:user:${user.id}`, 8, 60_000)) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }

    const body = await req.json();
    const action = String(body.action || "");
    if (action === "status" || action === "enroll") {
      return await cardSetup(req, user.id, String(user.email || ""), action);
    }

    const jobId = String(body.jobId || "");
    const amountClp = Number(body.amountClp);
    if (!jobId || !Number.isFinite(amountClp) || amountClp <= 0) {
      return jsonResponse(req, { error: "jobId y amountClp requeridos" }, 400);
    }

    const admin = serviceClient();
    const { data: job } = await admin
      .from("trabajos")
      .select("id_usuario, estado")
      .eq("id", jobId)
      .maybeSingle();
    if (!job || String(job.id_usuario) !== user.id) {
      return jsonResponse(req, { error: "No puedes pagar este trabajo." }, 403);
    }

    const { data: held } = await admin
      .from("pagos")
      .select("id, monto, estado")
      .eq("id_trabajo", jobId)
      .eq("tipo_pago", "principal")
      .in("estado", ["retenido", "autorizado", "liberado"])
      .limit(1)
      .maybeSingle();
    if (held?.id) {
      const { data: saved } = await admin
        .from("metodos_pago_oneclick")
        .select("ultimos4, tipo_tarjeta")
        .eq("id_usuario", user.id)
        .maybeSingle();
      return jsonResponse(req, {
        charged: true,
        paymentId: held.id,
        jobId,
        amount: Number(held.monto || amountClp),
        last4: saved?.ultimos4 || "",
        cardType: saved?.tipo_tarjeta || "",
      });
    }

    if (String(job.estado || "") !== "esperando_pago") {
      return jsonResponse(
        req,
        { error: "Este pedido ya no está pendiente de pago." },
        409,
      );
    }

    const { data: card, error: cardErr } = await admin
      .from("metodos_pago_oneclick")
      .select("username, tbk_user, ultimos4, tipo_tarjeta, estado")
      .eq("id_usuario", user.id)
      .maybeSingle();
    if (cardErr) {
      return jsonResponse(
        req,
        { error: "No se pudo leer la tarjeta guardada." },
        500,
      );
    }

    if (card?.estado === "activa" && card.tbk_user) {
      const { data: payment, error: payErr } = await userSb.rpc(
        "crear_intencion_pago",
        {
          p_id_trabajo: jobId,
          p_monto: amountClp,
          p_buy_order: null,
        },
      );
      const paymentRow = Array.isArray(payment) ? payment[0] : payment;
      if (payErr || !paymentRow?.id) {
        return jsonResponse(
          req,
          { error: publicErrorMessage(payErr, "No se pudo crear la intención de pago") },
          400,
        );
      }

      const charged = await chargeInscribedCard(admin, {
        userId: user.id,
        username: String(card.username || user.id),
        tbkUser: String(card.tbk_user),
        jobId,
        amountClp: Number(paymentRow.monto || amountClp),
        payment: paymentRow,
      });

      return jsonResponse(req, {
        charged: true,
        paymentId: charged.paymentId,
        jobId,
        amount: charged.amount,
        last4: card.ultimos4 || "",
        cardType: card.tipo_tarjeta || "",
      });
    }

    return jsonResponse(req, {
      charged: false,
      needsCard: true,
    });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
