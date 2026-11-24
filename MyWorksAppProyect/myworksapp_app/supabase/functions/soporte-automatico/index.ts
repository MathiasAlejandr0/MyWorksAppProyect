import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { scheduleRefundEmail } from "../_shared/payment_mail.ts";
import { reconcileAuthorized } from "../_shared/reconcile_auth.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { pagosPausados } from "../_shared/defensa.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";

type Admin = ReturnType<typeof serviceClient>;

/**
 * Cierra lo que las reglas ya dejaron listo y devuelve a la tarjeta
 * los reembolsos pendientes. El cron la llama con el secreto de Vault
 * (header x-soporte-secret). También acepta la service role.
 * Un mismo pago no se devuelve dos veces.
 */
async function authorized(req: Request): Promise<boolean> {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  return await reconcileAuthorized({
    header: req.headers.get("x-soporte-secret") || "",
    bearer: (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, ""),
    envSecret: Deno.env.get("SOPORTE_CRON_SECRET") || "",
    serviceKey,
    vaultCheck: async (secret) => {
      const { data, error } = await serviceClient().rpc("soporte_secret_valido", {
        p_secret: secret,
      });
      if (error) return false;
      return data === true;
    },
  });
}

async function refundOne(
  admin: Admin,
  disputeId: string,
  paymentId: string,
  resolution: string,
): Promise<{ disputa_id: string; status: string }> {
  const { data: previo } = await admin
    .from("reembolsos_automaticos")
    .select("estado")
    .eq("id_disputa", disputeId)
    .maybeSingle();
  if (previo?.estado === "ejecutado") {
    return { disputa_id: disputeId, status: "already" };
  }
  try {
    const refund = await refundHeldPaymentOnce(admin, paymentId);
    if (refund.status === "refunded" || refund.status === "already") {
      scheduleRefundEmail(admin, paymentId);
    }
    const { error: closeError } = await admin.rpc("aplicar_cierre_disputa", {
      p_disputa_id: disputeId,
      p_operador: "sistema",
      p_decision: "reembolsar",
      p_resolucion: resolution || "Devolución automática",
    });
    if (closeError && !/already|resuelta/i.test(closeError.message)) {
      throw new Error(closeError.message);
    }
    await admin.rpc("marcar_reembolso_automatico", {
      p_disputa: disputeId,
      p_pago: paymentId,
      p_estado: "ejecutado",
      p_error: null,
    });
    return { disputa_id: disputeId, status: refund.status };
  } catch (err) {
    const message = err instanceof Error ? err.message : "No se pudo devolver";
    await admin.rpc("marcar_reembolso_automatico", {
      p_disputa: disputeId,
      p_pago: paymentId,
      p_estado: "fallido",
      p_error: message,
    });
    throw err;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  if (!(await authorized(req))) {
    return jsonResponse(req, { error: "No autorizado" }, 401);
  }
  if (isKillSwitchOn("MWA_READ_ONLY") || isKillSwitchOn("MWA_KILL_WEBPAY")) {
    return jsonResponse(req, killSwitchResponse(), 503);
  }

  try {
    const admin = serviceClient();
    if (await pagosPausados(admin)) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }
    const body = await req.json().catch(() => ({})) as {
      disputa_id?: string;
      pago_id?: string;
      resolucion?: string;
    };
    if (body.disputa_id && body.pago_id) {
      const one = await refundOne(
        admin,
        String(body.disputa_id),
        String(body.pago_id),
        String(body.resolucion || "Devolución automática"),
      );
      return jsonResponse(req, { reembolsados: [one.disputa_id], estado: one.status, fallos: [] });
    }

    const { data, error } = await admin.rpc("resolver_soporte_automatico");
    if (error) {
      return jsonResponse(req, { error: publicErrorMessage(error, "No se pudo resolver el soporte") }, 409);
    }

    const payload = (data ?? {}) as {
      liberados?: number;
      acuerdos?: number;
      reembolsos?: { disputa_id?: string; pago_id?: string; resolucion?: string }[];
    };
    const refunds = Array.isArray(payload.reembolsos) ? payload.reembolsos : [];
    const refunded: string[] = [];
    const failed: { disputa_id: string; error: string }[] = [];

    for (const item of refunds) {
      const disputeId = String(item.disputa_id || "");
      const paymentId = String(item.pago_id || "");
      if (!disputeId || !paymentId) continue;
      try {
        await refundOne(
          admin,
          disputeId,
          paymentId,
          String(item.resolucion || "Devolución automática"),
        );
        refunded.push(disputeId);
      } catch (err) {
        failed.push({
          disputa_id: disputeId,
          error: err instanceof Error ? err.message : "No se pudo devolver",
        });
      }
    }

    return jsonResponse(req, {
      liberados: payload.liberados ?? 0,
      acuerdos: payload.acuerdos ?? 0,
      reembolsados: refunded,
      fallos: failed,
    });
  } catch (err) {
    return jsonResponse(req, { error: publicErrorMessage(err) }, 500);
  }
});
