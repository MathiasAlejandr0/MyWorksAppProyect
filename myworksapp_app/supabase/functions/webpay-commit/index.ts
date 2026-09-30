import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
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
        .select("id, id_trabajo, origen_retorno")
        .eq("token_tbk", tbkToken)
        .maybeSingle();
      if (wantsJson) {
        return jsonResponse(req, {
          approved: false,
          ok: false,
          paymentStatus: "REJECTED",
          paymentId: abandoned?.id ?? null,
          jobId: abandoned?.id_trabajo ?? null,
        });
      }
      return browserRedirect(
        webReturnLocation({
          origin: returnOrigin(abandoned?.origen_retorno),
          pago: "fail",
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
      .select("id, id_trabajo, monto, estado, metodo_pago, origen_retorno")
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
            commit.authorization_code || buyOrder || tokenWs,
          ),
          actualizado_en: new Date().toISOString(),
        })
        .eq("id", payment.id);
    }

    let guest = false;
    let alta = "";
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
        guest = meta.guest_checkout === true || meta.guest_checkout === "true";
        if (guest) {
          await admin.auth.admin.updateUserById(ownerId, { email_confirm: true });
          try {
            alta = await signGuestPasswordTicket(ownerId);
          } catch (e) {
            console.error("alta invitado", e instanceof Error ? e.message : e);
          }
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
