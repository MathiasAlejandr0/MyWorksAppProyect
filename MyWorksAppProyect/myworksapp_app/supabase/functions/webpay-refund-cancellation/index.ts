import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * El cliente, el profesional o un administrador devuelve la garantía
 * antes de cancelar. No cierra el trabajo: eso lo hace la transición.
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
    const { data: profile } = await userSb
      .from("perfiles")
      .select("rol")
      .eq("id", user.id)
      .maybeSingle();
    const isAdmin = profile?.rol === "administrador";

    const { data: job, error: jobErr } = await admin
      .from("trabajos")
      .select("id, estado, id_usuario, id_trabajador")
      .eq("id", jobId)
      .maybeSingle();
    if (jobErr || !job) return jsonResponse(req, { error: "Trabajo no encontrado" }, 404);
    const party = job.id_usuario === user.id || job.id_trabajador === user.id;
    if (!isAdmin && !party) {
      return jsonResponse(req, { error: "No puedes devolver este pago" }, 403);
    }
    if (job.estado === "esperando_aprobacion_cliente") {
      return jsonResponse(
        req,
        { error: "Si no estás conforme, abre una disputa. El pago sigue retenido." },
        409,
      );
    }
    if (["completado", "cancelado", "expirado", "no_asistio"].includes(job.estado)) {
      return jsonResponse(req, { error: "El trabajo ya está cerrado" }, 409);
    }
    if (await jobHasOpenDispute(admin, jobId)) {
      return jsonResponse(
        req,
        { error: "Hay una disputa abierta. Resuélvela para liberar o devolver el pago." },
        409,
      );
    }

    const { data: payment, error: payErr } = await admin
      .from("pagos")
      .select("id, estado")
      .eq("id_trabajo", jobId)
      .eq("tipo_pago", "principal")
      .order("creado_en", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (payErr || !payment) {
      return jsonResponse(req, { skipped: true });
    }
    if (!["autorizado", "retenido", "reembolsado"].includes(payment.estado)) {
      return jsonResponse(req, { skipped: true });
    }

    const result = await refundHeldPaymentOnce(admin, payment.id);
    return jsonResponse(req, result);
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
