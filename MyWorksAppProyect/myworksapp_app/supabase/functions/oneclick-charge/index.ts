import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { schedulePaymentReceivedEmail } from "../_shared/payment_mail.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { chargeInscribedCard } from "../_shared/oneclick_charge.ts";
import { clientIp, rateLimitExceededMessage } from "../_shared/rate_limit.ts";
import { allowRateDb } from "../_shared/rate_limit_db.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { resolveCallerReturnOrigin } from "../_shared/security.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";
import { assertTransbankAction } from "../_shared/transbank_form.ts";
import {
  activatePendingInscription,
  isEnrolled,
} from "../_shared/oneclick_inscription.ts";
import {
  OneclickInscriptionInactiveError,
  tbkOneclickDeleteInscription,
  tbkOneclickStart,
} from "../_shared/tbk.ts";

const CARD_COLUMNS =
  "ultimos4, tipo_tarjeta, estado, tbk_user, token_inscripcion, username";

/** Un pedido solo se deja pendiente de la inscripción si es del cliente y espera pago. */
async function pendingJobFor(
  admin: ReturnType<typeof serviceClient>,
  userId: string,
  jobId: string,
): Promise<string | null> {
  if (!jobId) return null;
  const { data: job } = await admin
    .from("trabajos")
    .select("id_usuario, estado")
    .eq("id", jobId)
    .maybeSingle();
  if (!job || String(job.id_usuario) !== userId) return null;
  return String(job.estado || "") === "esperando_pago" ? jobId : null;
}

async function cardSetup(
  req: Request,
  userId: string,
  email: string,
  action: string,
  fromApp: boolean,
  jobId: string,
) {
  const admin = serviceClient();
  const { data: stored, error: cardErr } = await admin
    .from("metodos_pago_oneclick")
    .select(CARD_COLUMNS)
    .eq("id_usuario", userId)
    .maybeSingle();
  if (cardErr) {
    return jsonResponse(req, { error: "No se pudo leer la tarjeta guardada." }, 500);
  }
  const card = await activatePendingInscription(admin, userId, stored);
  const enrolled = isEnrolled(card);
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
  // La web vuelve al mismo sitio desde el que inscribió la tarjeta.
  const webOrigin = fromApp ? null : resolveCallerReturnOrigin(req);
  const started = await tbkOneclickStart({
    username: userId,
    email: mail,
    responseUrl: fromApp
      ? `${base}/functions/v1/oneclick-return?desde=app`
      : webOrigin
        ? `${base}/functions/v1/oneclick-return?o=${encodeURIComponent(webOrigin)}`
        : `${base}/functions/v1/oneclick-return`,
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
      id_trabajo_pendiente: await pendingJobFor(admin, userId, jobId),
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

/** El cliente quita su tarjeta para inscribir otra. Los pedidos ya cobrados no cambian. */
async function removeCard(req: Request, userId: string) {
  const admin = serviceClient();
  const { data: card, error } = await admin
    .from("metodos_pago_oneclick")
    .select("tbk_user, username")
    .eq("id_usuario", userId)
    .maybeSingle();
  if (error) {
    return jsonResponse(req, { error: "No se pudo leer la tarjeta guardada." }, 500);
  }
  if (card?.tbk_user) {
    await tbkOneclickDeleteInscription({
      username: String(card.username || userId),
      tbkUser: String(card.tbk_user),
    });
  }
  const { error: delErr } = await admin
    .from("metodos_pago_oneclick")
    .delete()
    .eq("id_usuario", userId);
  if (delErr) {
    return jsonResponse(req, { error: "No se pudo quitar la tarjeta." }, 500);
  }
  return jsonResponse(req, { enrolled: false, removed: true, last4: "", cardType: "" });
}

/** Transbank ya no reconoce la tarjeta: se marca para que el cliente inscriba otra. */
async function markCardInactive(userId: string) {
  await serviceClient()
    .from("metodos_pago_oneclick")
    .update({
      estado: "rechazada",
      tbk_user: null,
      token_inscripcion: null,
      actualizado_en: new Date().toISOString(),
    })
    .eq("id_usuario", userId);
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

    const body = await req.json().catch(() => ({}));
    const action = String(body.action || "");
    // La app consulta "status" cada 2 s mientras el cliente inscribe la tarjeta.
    // Con el tope de cobro (8 por minuto) el cobro que sigue a la inscripción
    // salía rechazado con "Demasiados intentos". La consulta tiene su propio tope.
    const polling = action === "status";

    const ip = clientIp(req);
    const admin = serviceClient();
    if (!(await allowRateDb(admin, `oneclick${polling ? ":status" : ""}:ip:${ip}`, polling ? 240 : 20, 60_000))) {
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
    if (!(await allowRateDb(admin, `oneclick${polling ? ":status" : ""}:user:${user.id}`, polling ? 120 : 8, 60_000))) {
      return jsonResponse(req, { error: rateLimitExceededMessage() }, 429);
    }

    if (action === "status" || action === "enroll") {
      return await cardSetup(
        req,
        user.id,
        String(user.email || ""),
        action,
        body.client === "app",
        String(body.jobId || ""),
      );
    }
    if (action === "remove") {
      return await removeCard(req, user.id);
    }

    const jobId = String(body.jobId || "");
    const amountClp = Number(body.amountClp);
    if (!jobId || !Number.isFinite(amountClp) || amountClp <= 0) {
      return jsonResponse(req, { error: "jobId y amountClp requeridos" }, 400);
    }

    const { data: job } = await admin
      .from("trabajos")
      .select("id_usuario, estado")
      .eq("id", jobId)
      .maybeSingle();
    if (!job || String(job.id_usuario) !== user.id) {
      return jsonResponse(req, { error: "No puedes pagar este trabajo." }, 403);
    }

    const changeOrderId = String(body.changeOrderId || "").trim();
    if (changeOrderId) {
      if (String(job.estado || "") !== "pausado_orden_cambio") {
        return jsonResponse(req, { error: "Este pedido no tiene un cobro adicional pendiente." }, 409);
      }
      const { data: storedCard, error: cardErr } = await admin
        .from("metodos_pago_oneclick")
        .select(CARD_COLUMNS)
        .eq("id_usuario", user.id)
        .maybeSingle();
      if (cardErr) {
        return jsonResponse(req, { error: "No se pudo leer la tarjeta guardada." }, 500);
      }
      const card = await activatePendingInscription(admin, user.id, storedCard);
      if (!isEnrolled(card) || !card) {
        return jsonResponse(req, { charged: false, needsCard: true });
      }
      const { data: payment, error: payErr } = await userSb.rpc(
        "crear_intencion_pago_orden_cambio",
        {
          p_id_trabajo: jobId,
          p_id_orden_cambio: changeOrderId,
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
      schedulePaymentReceivedEmail(admin, String(charged.paymentId));
      return jsonResponse(req, {
        charged: true,
        paymentId: charged.paymentId,
        jobId,
        amount: charged.amount,
        last4: card.ultimos4 || "",
        cardType: card.tipo_tarjeta || "",
      });
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

    const { data: storedCard, error: cardErr } = await admin
      .from("metodos_pago_oneclick")
      .select(CARD_COLUMNS)
      .eq("id_usuario", user.id)
      .maybeSingle();
    if (cardErr) {
      return jsonResponse(
        req,
        { error: "No se pudo leer la tarjeta guardada." },
        500,
      );
    }
    const card = await activatePendingInscription(admin, user.id, storedCard);

    if (isEnrolled(card) && card) {
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

      let charged: Awaited<ReturnType<typeof chargeInscribedCard>>;
      try {
        charged = await chargeInscribedCard(admin, {
          userId: user.id,
          username: String(card.username || user.id),
          tbkUser: String(card.tbk_user),
          jobId,
          amountClp: Number(paymentRow.monto || amountClp),
          payment: paymentRow,
        });
      } catch (e) {
        if (e instanceof OneclickInscriptionInactiveError) {
          await markCardInactive(user.id);
          return jsonResponse(req, {
            charged: false,
            needsCard: true,
            reason: "tarjeta_inactiva",
          });
        }
        throw e;
      }

      schedulePaymentReceivedEmail(admin, String(charged.paymentId));
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
