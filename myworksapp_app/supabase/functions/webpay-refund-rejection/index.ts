import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * El profesional rechaza un trabajo pendiente que ya tiene el pago retenido.
 * Devuelve el monto a la tarjeta y cancela el trabajo.
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

    const body = await req.json();
    const jobId = String(body.jobId || "").trim();
    if (!jobId) return jsonResponse(req, { error: "jobId requerido" }, 400);

    const admin = serviceClient();
    const { data: job, error: jobErr } = await admin
      .from("trabajos")
      .select("id, estado, id_trabajador, metadatos_servicio")
      .eq("id", jobId)
      .maybeSingle();
    if (jobErr || !job) return jsonResponse(req, { error: "Trabajo no encontrado" }, 404);
    if (job.id_trabajador !== user.id) {
      return jsonResponse(req, { error: "Solo el profesional asignado puede rechazar" }, 403);
    }
    if (job.estado !== "pendiente") {
      return jsonResponse(req, { error: "Solo se rechazan trabajos pendientes" }, 409);
    }
    if (await jobHasOpenDispute(admin, jobId)) {
      return jsonResponse(
        req,
        { error: "Hay una disputa abierta; el pago sigue retenido" },
        409,
      );
    }

    const { data: payment, error: payErr } = await admin
      .from("pagos")
      .select("id, monto, token_tbk, estado")
      .eq("id_trabajo", jobId)
      .eq("tipo_pago", "principal")
      .order("creado_en", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (payErr || !payment) {
      return jsonResponse(req, { error: "No hay pago en garantía" }, 409);
    }
    if (payment.estado !== "reembolsado") {
      if (!["autorizado", "retenido"].includes(payment.estado)) {
        return jsonResponse(req, { error: "El pago no está retenido" }, 409);
      }
      await refundHeldPaymentOnce(admin, payment.id);
    }

    const now = new Date().toISOString();
    const incoming = body.metadata && typeof body.metadata === "object"
      ? body.metadata
      : {};
    let previous: Record<string, unknown> = {};
    if (typeof job.metadatos_servicio === "string" && job.metadatos_servicio) {
      try {
        const parsed = JSON.parse(job.metadatos_servicio);
        if (parsed && typeof parsed === "object") previous = parsed;
      } catch {
        previous = {};
      }
    } else if (job.metadatos_servicio && typeof job.metadatos_servicio === "object") {
      previous = job.metadatos_servicio;
    }
    const { data: cancelled, error: jobUpErr } = await admin
      .from("trabajos")
      .update({
        estado: "cancelado",
        estado_pago: "reembolsado",
        metadatos_servicio: JSON.stringify({ ...previous, ...incoming }),
        actualizado_en: now,
      })
      .eq("id", jobId)
      .eq("estado", "pendiente")
      .select("id");
    if (jobUpErr || !cancelled || cancelled.length === 0) {
      return jsonResponse(
        req,
        { error: "El cobro volvió a la tarjeta, pero el trabajo no quedó cancelado" },
        500,
      );
    }

    return jsonResponse(req, { refunded: true, jobId });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
