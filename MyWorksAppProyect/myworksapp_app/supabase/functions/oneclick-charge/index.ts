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
  "ultimos4, tipo_tarjeta, estado, tbk_user, token_inscripcion, username, url_inscripcion, ticket_handoff, tbk_user_prev, username_prev, tipo_tarjeta_prev, ultimos4_prev";

type CardRow = {
  ultimos4?: string | null;
  tipo_tarjeta?: string | null;
  estado?: string | null;
  tbk_user?: string | null;
  token_inscripcion?: string | null;
  username?: string | null;
  url_inscripcion?: string | null;
  ticket_handoff?: string | null;
  tbk_user_prev?: string | null;
  username_prev?: string | null;
  tipo_tarjeta_prev?: string | null;
  ultimos4_prev?: string | null;
};

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

function previousCardFields(card: CardRow | null | undefined) {
  if (!card) return {};
  if (card.tbk_user_prev) {
    return {
      tbk_user_prev: card.tbk_user_prev,
      username_prev: card.username_prev || card.username,
      tipo_tarjeta_prev: card.tipo_tarjeta_prev,
      ultimos4_prev: card.ultimos4_prev,
    };
  }
  if (!isEnrolled(card)) return {};
  return {
    tbk_user_prev: card.tbk_user,
    username_prev: card.username,
    tipo_tarjeta_prev: card.tipo_tarjeta,
    ultimos4_prev: card.ultimos4,
  };
}

async function retirePreviousInscription(
  admin: ReturnType<typeof serviceClient>,
  userId: string,
  card: CardRow,
) {
  if (!card.tbk_user_prev) return;
  try {
    await tbkOneclickDeleteInscription({
      username: String(card.username_prev || userId),
      tbkUser: String(card.tbk_user_prev),
    });
  } catch (e) {
    if (!(e instanceof OneclickInscriptionInactiveError)) throw e;
  }
  await admin
    .from("metodos_pago_oneclick")
    .update({
      tbk_user_prev: null,
      username_prev: null,
      tipo_tarjeta_prev: null,
      ultimos4_prev: null,
      actualizado_en: new Date().toISOString(),
    })
    .eq("id_usuario", userId);
}

async function restorePreviousCard(
  admin: ReturnType<typeof serviceClient>,
  userId: string,
): Promise<CardRow | null> {
  const { data, error } = await admin
    .from("metodos_pago_oneclick")
    .select(CARD_COLUMNS)
    .eq("id_usuario", userId)
    .maybeSingle();
  if (error) throw new Error("No se pudo leer la tarjeta guardada.");
  const card = data as CardRow | null;
  if (!card?.tbk_user_prev) return card;
  if (card.estado === "activa" && card.tbk_user) {
    await retirePreviousInscription(admin, userId, card);
    return { ...card, tbk_user_prev: null };
  }
  const restored = {
    estado: "activa",
    tbk_user: card.tbk_user_prev,
    username: card.username_prev || card.username || userId,
    tipo_tarjeta: card.tipo_tarjeta_prev,
    ultimos4: card.ultimos4_prev,
    token_inscripcion: null,
    url_inscripcion: null,
    ticket_handoff: null,
    tbk_user_prev: null,
    username_prev: null,
    tipo_tarjeta_prev: null,
    ultimos4_prev: null,
    actualizado_en: new Date().toISOString(),
  };
  const { error: upErr } = await admin
    .from("metodos_pago_oneclick")
    .update(restored)
    .eq("id_usuario", userId);
  if (upErr) throw new Error("No se pudo recuperar la tarjeta anterior.");
  return { ...card, ...restored };
}

async function cardSetup(
  req: Request,
  userId: string,
  email: string,
  action: string,
  fromApp: boolean,
  jobId: string,
  options: { replace?: boolean; recover?: boolean } = {},
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
  let card = await activatePendingInscription(admin, userId, stored) as CardRow | null;
  if (options.recover && card?.tbk_user_prev && !isEnrolled(card)) {
    try {
      card = await restorePreviousCard(admin, userId);
    } catch (e) {
      return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
    }
  }
  if (card?.tbk_user_prev && isEnrolled(card)) {
    try {
      await retirePreviousInscription(admin, userId, card);
    } catch (e) {
      return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
    }
    card = { ...card, tbk_user_prev: null };
  }
  const enrolled = isEnrolled(card);
  if (action === "status" || (enrolled && !options.replace)) {
    return jsonResponse(req, {
      enrolled,
      last4: card?.ultimos4 || "",
      cardType: card?.tipo_tarjeta || "",
    });
  }
  const kept = options.replace ? previousCardFields(card) : {};

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
      tipo_tarjeta: options.replace ? null : undefined,
      ultimos4: options.replace ? null : undefined,
      actualizado_en: new Date().toISOString(),
      ...kept,
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
    .select("tbk_user, username, tbk_user_prev, username_prev")
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
  if (card?.tbk_user_prev && card.tbk_user_prev !== card.tbk_user) {
    try {
      await tbkOneclickDeleteInscription({
        username: String(card.username_prev || userId),
        tbkUser: String(card.tbk_user_prev),
      });
    } catch (e) {
      if (!(e instanceof OneclickInscriptionInactiveError)) throw e;
    }
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

    if (action === "status" || action === "enroll" || action === "replace") {
      return await cardSetup(
        req,
        user.id,
        String(user.email || ""),
        action === "replace" ? "enroll" : action,
        body.client === "app",
        String(body.jobId || ""),
        {
          replace: action === "replace",
          recover: action === "status" && body.recover === true,
        },
      );
    }
    if (action === "restore") {
      try {
        const card = await restorePreviousCard(serviceClient(), user.id);
        return jsonResponse(req, {
          enrolled: isEnrolled(card),
          last4: card?.ultimos4 || "",
          cardType: card?.tipo_tarjeta || "",
        });
      } catch (e) {
        return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
      }
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
        payment: {
          ...paymentRow,
          id_orden_cambio: paymentRow.id_orden_cambio || changeOrderId,
        },
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
