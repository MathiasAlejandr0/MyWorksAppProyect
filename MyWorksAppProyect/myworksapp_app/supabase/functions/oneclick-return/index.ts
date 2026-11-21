import { corsHeadersFor } from "../_shared/cors.ts";
import {
  cardLast4,
  chargeInscribedCard,
  expectedJobAmount,
} from "../_shared/oneclick_charge.ts";
import { allowRate, clientIp } from "../_shared/rate_limit.ts";
import { serviceClient } from "../_shared/supabase.ts";
import {
  OneclickInscriptionInactiveError,
  tbkOneclickDeleteInscription,
  tbkOneclickFinish,
} from "../_shared/tbk.ts";

import { allowedWebReturnOrigins } from "../_shared/security.ts";
import { oneclickReturnBase } from "../_shared/oneclick_return_base.ts";

type Dest = { fromApp: boolean; webOrigin: string };

function baseFor(dest: Dest): string {
  return oneclickReturnBase({
    fromApp: dest.fromApp,
    webOrigin: dest.webOrigin,
    allowedOrigins: allowedWebReturnOrigins(),
    configured: Deno.env.get("WEBPAY_WEB_RETURN_URL"),
  });
}

function cardSavedUrl(ok: boolean, dest: Dest): string {
  const url = new URL(baseFor(dest));
  url.searchParams.set("tarjeta", ok ? "ok" : "fail");
  return url.toString();
}

function webHome(
  ok: boolean,
  extra: Record<string, string>,
  dest: Dest,
): string {
  const url = new URL(baseFor(dest));
  url.searchParams.set("pago", ok ? "ok" : "fail");
  if (ok) url.searchParams.set("tracking", "1");
  for (const [key, value] of Object.entries(extra)) {
    if (value) url.searchParams.set(key, value);
  }
  return url.toString();
}

function redirect(location: string): Response {
  return new Response(null, {
    status: 302,
    headers: { Location: location, "Cache-Control": "no-store" },
  });
}

async function readToken(req: Request): Promise<string> {
  const url = new URL(req.url);
  let token = url.searchParams.get("TBK_TOKEN") || "";
  if (req.method === "POST") {
    const ct = req.headers.get("content-type") || "";
    if (ct.includes("application/json")) {
      const body = await req.json().catch(() => ({}));
      token = String(body.TBK_TOKEN || body.token || token);
    } else {
      const form = await req.formData().catch(() => null);
      token = String(form?.get("TBK_TOKEN") || token);
    }
  }
  return token.trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }

  const reqParams = new URL(req.url).searchParams;
  const fromApp = reqParams.get("desde") === "app";
  const dest: Dest = { fromApp, webOrigin: (reqParams.get("o") || "").trim() };

  try {
    if (!allowRate(`oneclick-return:${clientIp(req)}`, 30, 60_000)) {
      return redirect(webHome(false, { motivo: "limite" }, dest));
    }

    const token = await readToken(req);
    if (!token) return redirect(webHome(false, { motivo: "cancelado" }, dest));

    const admin = serviceClient();
    const { data: row } = await admin
      .from("metodos_pago_oneclick")
      .select(
        "id_usuario, username, tbk_user, ultimos4, estado, id_trabajo_pendiente, tbk_user_prev, username_prev, tipo_tarjeta_prev, ultimos4_prev",
      )
      .eq("token_inscripcion", token)
      .maybeSingle();
    if (!row?.id_usuario) {
        return redirect(cardSavedUrl(false, dest));
    }

    const enrollOnly = !row.id_trabajo_pendiente;
    let tbkUser = String(row.tbk_user || "");
    let last4 = String(row.ultimos4 || "");
    if (row.estado !== "activa" || !tbkUser) {
      const finished = await tbkOneclickFinish(token);
      const code = Number(finished.response_code);
      tbkUser = String(finished.tbk_user || "");
      last4 = cardLast4(finished.card_number);
      if (code !== 0 || !tbkUser) {
        if (row.tbk_user_prev) {
          await admin
            .from("metodos_pago_oneclick")
            .update({
              estado: "activa",
              tbk_user: row.tbk_user_prev,
              username: row.username_prev || row.username,
              tipo_tarjeta: row.tipo_tarjeta_prev,
              ultimos4: row.ultimos4_prev,
              token_inscripcion: null,
              url_inscripcion: null,
              ticket_handoff: null,
              tbk_user_prev: null,
              username_prev: null,
              tipo_tarjeta_prev: null,
              ultimos4_prev: null,
              actualizado_en: new Date().toISOString(),
            })
            .eq("id_usuario", row.id_usuario);
        } else {
          await admin
            .from("metodos_pago_oneclick")
            .update({
              estado: "rechazada",
              token_inscripcion: null,
              actualizado_en: new Date().toISOString(),
            })
            .eq("id_usuario", row.id_usuario);
        }
        return redirect(
          enrollOnly
            ? cardSavedUrl(false, dest)
            : webHome(false, { motivo: "tarjeta" }, dest),
        );
      }
      await admin
        .from("metodos_pago_oneclick")
        .update({
          estado: "activa",
          tbk_user: tbkUser,
          tipo_tarjeta: String(finished.card_type || ""),
          ultimos4: last4,
          actualizado_en: new Date().toISOString(),
        })
        .eq("id_usuario", row.id_usuario);
      if (row.tbk_user_prev) {
        try {
          await tbkOneclickDeleteInscription({
            username: String(row.username_prev || row.id_usuario),
            tbkUser: String(row.tbk_user_prev),
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
          .eq("id_usuario", row.id_usuario);
      }
    }

    if (enrollOnly) {
      await admin
        .from("metodos_pago_oneclick")
        .update({
          token_inscripcion: null,
          actualizado_en: new Date().toISOString(),
        })
        .eq("id_usuario", row.id_usuario);
      return redirect(cardSavedUrl(true, dest));
    }

    const jobId = String(row.id_trabajo_pendiente);
    const { data: job } = await admin
      .from("trabajos")
      .select("estado")
      .eq("id", jobId)
      .maybeSingle();
    if (String(job?.estado || "") !== "esperando_pago") {
      await admin
        .from("metodos_pago_oneclick")
        .update({
          token_inscripcion: null,
          id_trabajo_pendiente: null,
          actualizado_en: new Date().toISOString(),
        })
        .eq("id_usuario", row.id_usuario);
      return redirect(cardSavedUrl(true, dest));
    }

    const amount = await expectedJobAmount(admin, jobId);
    const { data: payment, error: payErr } = await admin.rpc(
      "crear_intencion_pago_servicio",
      {
        p_id_usuario: String(row.id_usuario),
        p_id_trabajo: jobId,
        p_monto: amount,
      },
    );
    const paymentRow = Array.isArray(payment) ? payment[0] : payment;
    if (payErr || !paymentRow?.id) {
      return redirect(webHome(false, { motivo: "cobro", jobId }, dest));
    }

    const charged = await chargeInscribedCard(admin, {
      userId: String(row.id_usuario),
      username: String(row.username || row.id_usuario),
      tbkUser,
      jobId,
      amountClp: Number(paymentRow.monto || amount),
      payment: paymentRow,
    });

    await admin
      .from("metodos_pago_oneclick")
      .update({
        token_inscripcion: null,
        id_trabajo_pendiente: null,
        actualizado_en: new Date().toISOString(),
      })
      .eq("id_usuario", row.id_usuario);

    return redirect(
      webHome(true, {
        paymentId: charged.paymentId,
        jobId,
        amount: String(charged.amount),
        last4,
      }, dest),
    );
  } catch (e) {
    console.error("oneclick-return", e instanceof Error ? e.message : "error");
    return redirect(webHome(false, { motivo: "cobro" }, dest));
  }
});
