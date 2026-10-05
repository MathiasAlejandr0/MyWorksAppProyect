import { abandonedCheckoutUpdate } from "../_shared/abandon_payment.ts";
import { assessWebpayCommit } from "../_shared/commit_guard.ts";
import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import {
  paymentHoldTransitioned,
  shouldIssueGuestPasswordTicket,
} from "../_shared/guest_ticket.ts";
import { openJobAfterHold } from "../_shared/open_job_after_hold.ts";
import {
  fallbackWebReturnOrigin,
  signGuestPasswordTicket,
} from "../_shared/security.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkCommit } from "../_shared/tbk.ts";
import { readCommitTokens, webReturnLocation } from "../_shared/webpay_return.ts";

function browserRedirect(location: string): Response {
  return new Response(null, {
    status: 303,
    headers: {
      Location: location,
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}

function returnOrigin(stored: string | null | undefined): string {
  const value = (stored || "").trim();
  if (value) return value;
  return fallbackWebReturnOrigin();
}

type AdminClient = ReturnType<typeof serviceClient>;

async function voidPendingCheckout(
  admin: AdminClient,
  paymentId: string,
  jobId: string,
  pagoEstado: "anulado" | "fallido",
): Promise<void> {
  const paymentUpdate = await admin
    .from("pagos")
    .update({
      estado: pagoEstado,
      actualizado_en: new Date().toISOString(),
    })
    .eq("id", paymentId)
    .eq("estado", "pendiente");
  if (paymentUpdate.error) {
    console.error("anular pago", paymentUpdate.error.message);
    return;
  }
  const held = await admin
    .from("pagos")
    .select("id")
    .eq("id_trabajo", jobId)
    .in("estado", ["retenido", "liberado", "autorizado"])
    .limit(1);
  if (held.data && held.data.length > 0) return;
  const jobUpdate = await admin
    .from("trabajos")
    .update({
      estado: "cancelado",
      actualizado_en: new Date().toISOString(),
    })
    .eq("id", jobId)
    .eq("estado", "esperando_pago");
  if (jobUpdate.error) {
    console.error("cancelar trabajo", jobUpdate.error.message);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }

  const wantsJson = (req.headers.get("content-type") || "").includes(
    "application/json",
  );

  try {
    const reqUrl = new URL(req.url);
    let bodyTokenWs = "";
    let bodyTbkToken = "";
    if (req.method === "POST") {
      const ct = req.headers.get("content-type") || "";
      if (ct.includes("application/json")) {
        const body = await req.json();
        bodyTokenWs = String(body.token_ws || body.token || "");
        bodyTbkToken = String(body.TBK_TOKEN || "");
      } else {
        const form = await req.formData();
        bodyTokenWs = String(form.get("token_ws") || "");
        bodyTbkToken = String(form.get("TBK_TOKEN") || "");
      }
    }

    const { tokenWs, tbkToken } = readCommitTokens({
      queryTokenWs: reqUrl.searchParams.get("token_ws"),
      queryTbkToken: reqUrl.searchParams.get("TBK_TOKEN"),
      bodyTokenWs,
      bodyTbkToken,
    });

    const admin = serviceClient();

    if (!tokenWs && tbkToken) {
      const { data: abandoned } = await admin
        .from("pagos")
        .select("id, id_trabajo, origen_retorno, estado")
        .eq("token_tbk", tbkToken)
        .maybeSingle();
      const plan = abandoned
        ? abandonedCheckoutUpdate({
          estado: String(abandoned.estado || ""),
          tokenWs: "",
          tbkToken,
        })
        : null;
      if (plan && abandoned?.id && abandoned.id_trabajo) {
        await voidPendingCheckout(
          admin,
          String(abandoned.id),
          String(abandoned.id_trabajo),
          plan.pago,
        );
      }
      const settled = abandoned?.estado === "retenido" ||
        abandoned?.estado === "liberado";
      if (wantsJson) {
        return jsonResponse(req, {
          approved: settled,
          ok: settled,
          paymentStatus: settled ? "ESCROW" : "REJECTED",
          paymentId: abandoned?.id ?? null,
          jobId: abandoned?.id_trabajo ?? null,
        });
      }
      return browserRedirect(
        webReturnLocation({
          origin: returnOrigin(abandoned?.origen_retorno),
          pago: settled ? "ok" : "fail",
          paymentId: abandoned?.id ? String(abandoned.id) : undefined,
          jobId: abandoned?.id_trabajo ? String(abandoned.id_trabajo) : undefined,
        }),
      );
    }

    if (!tokenWs) {
      if (wantsJson) {
        return jsonResponse(req, { error: "token_ws ausente" }, 400);
      }
      return browserRedirect(
        webReturnLocation({
          origin: fallbackWebReturnOrigin(),
          pago: "fail",
        }),
      );
    }

    const { data: payment } = await admin
      .from("pagos")
      .select("id, id_trabajo, monto, estado, metodo_pago, origen_retorno, buy_order")
      .eq("token_tbk", tokenWs)
      .maybeSingle();

    if (!payment) {
      return jsonResponse(req, { error: "Pago no encontrado" }, 404);
    }
    if (payment.metodo_pago === "oneclick") {
      return jsonResponse(req, { error: "Este pago no es Webpay" }, 409);
    }

    const alreadyHeld = payment.estado === "retenido" ||
      payment.estado === "liberado";
    let commit: Record<string, unknown> = {};
    if (!alreadyHeld) {
      commit = await tbkCommit(tokenWs);
    }
    const responseCode = alreadyHeld
      ? 0
      : Number(commit.response_code ?? -1);
    const status = String(commit.status || (alreadyHeld ? "AUTHORIZED" : ""));
    const decision = assessWebpayCommit({
      estado: String(payment.estado || ""),
      responseCode: Number.isFinite(responseCode) ? responseCode : null,
      status,
      commitAmount: alreadyHeld ? Number(payment.monto) : Number(commit.amount),
      expectedAmount: Number(payment.monto),
      commitBuyOrder: alreadyHeld
        ? String(payment.buy_order || "")
        : String(commit.buy_order || ""),
      storedBuyOrder: String(payment.buy_order || ""),
    });
    const approved = decision.action === "hold" || decision.action === "replay";
    const voidPlan = abandonedCheckoutUpdate({
      estado: String(payment.estado || ""),
      tokenWs,
      tbkToken,
      decision: decision.action === "reject" || decision.action === "mismatch"
        ? decision.action
        : undefined,
    });
    if (voidPlan) {
      await voidPendingCheckout(
        admin,
        String(payment.id),
        String(payment.id_trabajo),
        voidPlan.pago,
      );
    }

    let transitioned = false;
    if (decision.action === "hold") {
      const jti = crypto.randomUUID().replace(/-/g, "");
      const held = await admin
        .from("pagos")
        .update({
          estado: "retenido",
          autorizado_en: new Date().toISOString(),
          id_transaccion: String(commit.authorization_code || commit.buy_order || ""),
          alta_jti: jti,
          actualizado_en: new Date().toISOString(),
        })
        .eq("id", payment.id)
        .eq("estado", "pendiente")
        .select("id");
      transitioned = paymentHoldTransitioned(held);
    }

    let guest = false;
    let alta = "";
    if (decision.action === "hold") {
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
        guest = meta.guest_checkout === true || meta.guest_checkout === "true";
        if (shouldIssueGuestPasswordTicket({
          alreadyHeld: !transitioned,
          approved: true,
          guest,
        })) {
          const { data: stamped } = await admin
            .from("pagos")
            .select("alta_jti")
            .eq("id", payment.id)
            .maybeSingle();
          const jti = stamped?.alta_jti ? String(stamped.alta_jti) : "";
          if (jti) {
            try {
              alta = await signGuestPasswordTicket(ownerId, jti);
            } catch (e) {
              console.error("alta invitado", e instanceof Error ? e.message : e);
            }
          }
        }
      }
    }

    if (decision.action === "replay") {
      await openJobAfterHold(admin, payment.id_trabajo);
    }

    if (decision.action === "mismatch") {
      const message = decision.reason === "monto"
        ? "El monto autorizado no coincide con el cobro"
        : "La orden de compra no coincide";
      if (wantsJson) return jsonResponse(req, { error: message, approved: false }, 409);
      return browserRedirect(
        webReturnLocation({
          origin: returnOrigin(payment.origen_retorno),
          pago: "fail",
          paymentId: String(payment.id),
          jobId: String(payment.id_trabajo),
        }),
      );
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

    return browserRedirect(
      webReturnLocation({
        origin: returnOrigin(payment.origen_retorno),
        pago: approved ? "ok" : "fail",
        paymentId: String(payment.id),
        jobId: String(payment.id_trabajo),
        guest: guest && approved,
        alta: guest && approved ? alta : undefined,
      }),
    );
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
