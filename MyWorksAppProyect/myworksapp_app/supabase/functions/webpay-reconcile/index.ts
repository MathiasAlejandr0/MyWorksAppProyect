import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import {
  decideReconciliation,
  PAYMENT_AWAITING_JOB,
  UNCONFIRMED_WINDOW_MS,
} from "../_shared/reconcile_hold.ts";
import { reconcileAuthorized } from "../_shared/reconcile_auth.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tbkRefund, tbkStatusAuthorized, tbkTransactionStatus } from "../_shared/tbk.ts";

async function authorized(req: Request): Promise<boolean> {
  return await reconcileAuthorized({
    header: req.headers.get("x-reconcile-secret") || "",
    bearer: (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, ""),
    envSecret: Deno.env.get("RECONCILE_CRON_SECRET") || "",
    serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "",
    vaultCheck: async (secret) => {
      const { data, error } = await serviceClient().rpc("reconcile_secret_valido", {
        p_secret: secret,
      });
      if (error) {
        console.error("validar secreto cron", error.code ?? "rpc");
        return false;
      }
      return data === true;
    },
  });
}

function capturedAtMs(value: string | null | undefined): number {
  const parsed = Date.parse(String(value || ""));
  return Number.isFinite(parsed) ? parsed : Date.now();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (!(await authorized(req))) {
    return jsonResponse(req, { error: "No autorizado" }, 401);
  }

  const admin = serviceClient();
  const { data: rows, error } = await admin
    .from("pagos")
    .select("id, id_trabajo, monto, token_tbk, estado, autorizado_en, reembolso_solicitado_en")
    .eq("estado", PAYMENT_AWAITING_JOB)
    .limit(40);
  if (error) {
    console.error("listar por confirmar", error.message);
    return jsonResponse(req, { error: "No se pudieron leer los cobros" }, 500);
  }

  const summary = { confirmed: 0, refunded: 0, waiting: 0, dropped: 0 };
  for (const row of rows ?? []) {
    const { data: job } = await admin
      .from("trabajos")
      .select("estado")
      .eq("id", row.id_trabajo)
      .maybeSingle();
    let authorizedCapture = false;
    if (row.token_tbk) {
      try {
        authorizedCapture = tbkStatusAuthorized(
          await tbkTransactionStatus(String(row.token_tbk)),
        );
      } catch (statusError) {
        console.error(
          "estado tbk",
          statusError instanceof Error ? statusError.message : statusError,
        );
        summary.waiting += 1;
        continue;
      }
    }
    const decision = decideReconciliation({
      paymentStatus: String(row.estado),
      jobStatus: String(job?.estado || ""),
      capturedAtMs: capturedAtMs(row.autorizado_en),
      nowMs: Date.now(),
      transbankAuthorized: authorizedCapture,
      windowMs: UNCONFIRMED_WINDOW_MS,
    });

    if (decision.action === "confirm" || decision.action === "mark_held") {
      const { error: confirmError } = await admin.rpc(
        "confirmar_trabajo_tras_captura",
        { p_id_pago: row.id },
      );
      if (confirmError) {
        console.error("confirmar", confirmError.message);
        summary.waiting += 1;
      } else {
        summary.confirmed += 1;
      }
      continue;
    }

    if (decision.action === "refund") {
      if (!row.reembolso_solicitado_en) {
        const claimed = await admin
          .from("pagos")
          .update({ reembolso_solicitado_en: new Date().toISOString() })
          .eq("id", row.id)
          .eq("estado", PAYMENT_AWAITING_JOB)
          .is("reembolso_solicitado_en", null)
          .select("id");
        if (!claimed.data?.length) {
          summary.waiting += 1;
          continue;
        }
        try {
          await tbkRefund(String(row.token_tbk), Number(row.monto));
        } catch (refundError) {
          console.error(
            "reembolso",
            refundError instanceof Error ? refundError.message : refundError,
          );
          summary.waiting += 1;
          continue;
        }
      }
      const { error: markError } = await admin.rpc("marcar_reembolso_automatico", {
        p_id_pago: row.id,
        p_modo: "reembolso",
      });
      if (markError) {
        console.error("marcar reembolso", markError.message);
        summary.waiting += 1;
      } else {
        summary.refunded += 1;
      }
      continue;
    }

    if (decision.action === "drop") {
      const { error: dropError } = await admin.rpc("marcar_reembolso_automatico", {
        p_id_pago: row.id,
        p_modo: "sin_captura",
      });
      if (dropError) summary.waiting += 1;
      else summary.dropped += 1;
      continue;
    }

    summary.waiting += 1;
  }

  return jsonResponse(req, summary);
});
