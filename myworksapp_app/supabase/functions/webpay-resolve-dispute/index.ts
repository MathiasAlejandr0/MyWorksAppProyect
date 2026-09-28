import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
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

    const { data: profile } = await userSb
      .from("perfiles")
      .select("rol")
      .eq("id", user.id)
      .maybeSingle();
    if (profile?.rol !== "administrador") {
      return jsonResponse(req, { error: "Solo atención al cliente" }, 403);
    }

    const body = await req.json();
    const disputeId = String(body.disputeId || "").trim();
    const decision = String(body.decision || "").trim();
    const resolution = String(body.resolution || "").trim().slice(0, 500);
    if (!disputeId) {
      return jsonResponse(req, { error: "disputeId requerido" }, 400);
    }
    if (decision !== "liberar" && decision !== "reembolsar") {
      return jsonResponse(req, { error: "decision debe ser liberar o reembolsar" }, 400);
    }
    if (resolution.length < 4) {
      return jsonResponse(req, { error: "Escribe la resolución (mín. 4 caracteres)" }, 400);
    }

    const admin = serviceClient();
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

    if (decision === "reembolsar") {
      const { data: payment, error: payErr } = await admin
        .from("pagos")
        .select("id, monto, token_tbk, estado")
        .eq("id_trabajo", dispute.id_trabajo)
        .eq("tipo_pago", "principal")
        .order("creado_en", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (payErr || !payment) {
        return jsonResponse(req, { error: "No hay pago para devolver" }, 409);
      }
      if (payment.estado === "liberado") {
        return jsonResponse(
          req,
          { error: "El pago ya fue liberado al profesional" },
          409,
        );
      }
      if (payment.estado !== "reembolsado") {
        await refundHeldPaymentOnce(admin, payment.id);
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

    return jsonResponse(req, { result: rpcResult, decision });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
