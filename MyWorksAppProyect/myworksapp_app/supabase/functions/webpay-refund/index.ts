import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { ipBloqueada, pagosPausados } from "../_shared/defensa.ts";
import { killSwitchResponse } from "../_shared/kill_switch.ts";
import { clientIp } from "../_shared/rate_limit.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { scheduleRefundEmail } from "../_shared/payment_mail.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { motivoValido, registrarAuditoria, requestClientMeta, requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Reembolso Transbank + estado reembolsado en pago y trabajo.
 * Solo admin.
 */
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
    } = await userSb.auth.getUser();
    if (!user) return jsonResponse(req, { error: "No autenticado" }, 401);

    const adminGate = await requireAdmin(userSb);
    if (!adminGate.ok) {
      return jsonResponse(req, { error: adminGate.error }, adminGate.status);
    }

    const body = await req.json();
    const paymentId = String(body.paymentId || "");
    const motivo = motivoValido(body.motivo);
    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }
    if (!motivo) {
      return jsonResponse(req, { error: "El motivo debe tener entre 10 y 2000 caracteres" }, 400);
    }

    const admin = serviceClient();
    if (await pagosPausados(admin) || await ipBloqueada(admin, clientIp(req))) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }
    const { data: payment, error } = await admin
      .from("pagos")
      .select("id, monto, token_tbk, estado, id_trabajo")
      .eq("id", paymentId)
      .maybeSingle();
    if (error || !payment) {
      return jsonResponse(req, { error: "Pago no encontrado" }, 404);
    }
    if (payment.estado === "reembolsado") {
      return jsonResponse(req, { already: true, payment });
    }
    if (!["autorizado", "retenido", "pendiente"].includes(payment.estado)) {
      return jsonResponse(req, { error: "Estado no reembolsable" }, 409);
    }
    if (payment.id_trabajo && await jobHasOpenDispute(admin, payment.id_trabajo)) {
      return jsonResponse(
        req,
        {
          error:
            "Hay una disputa abierta. Resuélvela en atención al cliente para liberar o devolver el pago.",
        },
        409,
      );
    }

    const result = await refundHeldPaymentOnce(admin, paymentId);
    if (result.status === "refunded") scheduleRefundEmail(admin, paymentId);
    const meta = requestClientMeta(req);
    const audited = await registrarAuditoria(admin, {
      p_accion: "devolver_pago",
      p_entidad: "pagos",
      p_id_entidad: paymentId,
      p_antes: { estado: payment.estado },
      p_despues: { estado: "reembolsado" },
      p_motivo: motivo,
      p_ip: meta.ip,
      p_user_agent: meta.userAgent,
      p_id_actor: user.id,
      p_rol_actor: "administrador",
    });
    return jsonResponse(req, { payment: result.payment, status: result.status, auditoria: audited });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
