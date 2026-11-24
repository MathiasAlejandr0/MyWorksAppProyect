import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { ipBloqueada, pagosPausados } from "../_shared/defensa.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { clientIp } from "../_shared/rate_limit.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { scheduleRefundEmail } from "../_shared/payment_mail.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { motivoValido, registrarAuditoria, requestClientMeta, requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Cierra una disputa y, en ese momento, libera el pago al profesional
 * o lo devuelve a la tarjeta del cliente.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }
  if (isKillSwitchOn("MWA_READ_ONLY") || isKillSwitchOn("MWA_KILL_WEBPAY")) {
    return jsonResponse(req, killSwitchResponse(), 503);
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
    const disputeId = String(body.disputeId || "").trim();
    const decision = String(body.decision || "").trim();
    const resolution = motivoValido(body.resolution || body.motivo) ?? "";
    if (!disputeId) {
      return jsonResponse(req, { error: "disputeId requerido" }, 400);
    }
    if (decision !== "liberar" && decision !== "reembolsar") {
      return jsonResponse(req, { error: "decision debe ser liberar o reembolsar" }, 400);
    }
    if (!resolution) {
      return jsonResponse(req, { error: "El motivo debe tener entre 10 y 2000 caracteres" }, 400);
    }

    const admin = serviceClient();
    if (await pagosPausados(admin) || await ipBloqueada(admin, clientIp(req))) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }
    const { data: dispute, error: disputeErr } = await admin
      .from("disputas")
      .select("id, id_trabajo, estado")
      .eq("id", disputeId)
      .maybeSingle();
    if (disputeErr || !dispute) {
      return jsonResponse(req, { error: "Disputa no encontrada" }, 404);
    }
    if (dispute.estado === "resuelta") {
      return jsonResponse(req, { already: true, decision });
    }
    if (!(await jobHasOpenDispute(admin, dispute.id_trabajo))) {
      return jsonResponse(req, { error: "La disputa no está abierta" }, 409);
    }

    const refundedPaymentIds: string[] = [];
    if (decision === "reembolsar") {
      const { data: payments, error: payErr } = await admin
        .from("pagos")
        .select("id, estado")
        .eq("id_trabajo", dispute.id_trabajo)
        .in("tipo_pago", ["principal", "orden_cambio", "horas_extra"])
        .order("creado_en", { ascending: true });
      if (payErr) {
        return jsonResponse(req, { error: "No se pudieron leer los cobros" }, 500);
      }
      const rows = payments ?? [];
      if (rows.length === 0) {
        return jsonResponse(req, { error: "No hay pago para devolver" }, 409);
      }
      if (rows.some((row) => row.estado === "liberado")) {
        return jsonResponse(
          req,
          { error: "El pago ya fue liberado al profesional" },
          409,
        );
      }
      for (const row of rows) {
        if (row.estado === "retenido" || row.estado === "autorizado" || row.estado === "pendiente") {
          await refundHeldPaymentOnce(admin, row.id);
          refundedPaymentIds.push(String(row.id));
        }
      }
    }

    const { data: rpcResult, error: rpcErr } = await admin.rpc(
      "aplicar_cierre_disputa",
      {
        p_disputa_id: disputeId,
        p_operador: user.id,
        p_decision: decision,
        p_resolucion: resolution,
      },
    );
    if (rpcErr) {
      return jsonResponse(req, { error: publicErrorMessage(rpcErr, "No se pudo cerrar la disputa") }, 409);
    }
    if (decision === "reembolsar") {
      for (const paymentId of refundedPaymentIds) scheduleRefundEmail(admin, paymentId);
    }

    const meta = requestClientMeta(req);
    const audited = await registrarAuditoria(admin, {
      p_accion: decision === "reembolsar" ? "devolver_pago" : "liberar_pago",
      p_entidad: "disputas",
      p_id_entidad: disputeId,
      p_antes: { estado: dispute.estado },
      p_despues: { decision },
      p_motivo: resolution,
      p_ip: meta.ip,
      p_user_agent: meta.userAgent,
      p_id_actor: user.id,
      p_rol_actor: "administrador",
    });
    return jsonResponse(req, { result: rpcResult, decision, auditoria: audited });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
