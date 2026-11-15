import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";

/**
 * Cierra lo que las reglas ya dejaron listo y devuelve a la tarjeta
 * los reembolsos pendientes. La invoca un cron con la service role.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  const auth = req.headers.get("Authorization") || "";
  if (!serviceKey || auth !== `Bearer ${serviceKey}`) {
    return jsonResponse(req, { error: "No autorizado" }, 401);
  }
  if (isKillSwitchOn("MWA_READ_ONLY") || isKillSwitchOn("MWA_KILL_WEBPAY")) {
    return jsonResponse(req, killSwitchResponse(), 503);
  }

  try {
    const admin = serviceClient();
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
        await refundHeldPaymentOnce(admin, paymentId);
        const { error: closeError } = await admin.rpc("aplicar_cierre_disputa", {
          p_disputa_id: disputeId,
          p_operador: "sistema",
          p_decision: "reembolsar",
          p_resolucion: String(item.resolucion || "Devolución automática"),
        });
        if (closeError) throw new Error(closeError.message);
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
