import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { isKillSwitchOn, killSwitchResponse } from "../_shared/kill_switch.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { scheduleRefundEmail } from "../_shared/payment_mail.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
import { requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";
import { ipBloqueada, pagosPausados } from "../_shared/defensa.ts";
import { clientIp } from "../_shared/rate_limit.ts";

const OPEN_DISPUTE = [
  "abierta",
  "en_revision",
  "requiere_humano",
  "reembolso_pendiente",
];

const REFUNDABLE_TYPES = ["principal", "orden_cambio", "horas_extra"];

/**
 * Devuelve principal, orden de cambio y horas extra antes de cancelar.
 * No cierra el trabajo: eso lo hace la transición.
 * Con disputa abierta solo el cliente que la abrió (o un admin) puede devolver.
 * En una entrega en revisión, sin disputa, solo el cliente o un admin.
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
    if (await pagosPausados(admin) || await ipBloqueada(admin, clientIp(req))) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }
    const adminGate = await requireAdmin(userSb);
    const isAdmin = adminGate.ok;

    const { data: job, error: jobErr } = await admin
      .from("trabajos")
      .select("id, estado, id_usuario, id_trabajador")
      .eq("id", jobId)
      .maybeSingle();
    if (jobErr || !job) return jsonResponse(req, { error: "Trabajo no encontrado" }, 404);
    const isClient = job.id_usuario === user.id;
    const party = isClient || job.id_trabajador === user.id;
    if (!isAdmin && !party) {
      return jsonResponse(req, { error: "No puedes devolver este pago" }, 403);
    }

    const { data: disputes, error: disputeErr } = await admin
      .from("disputas")
      .select("abierta_por")
      .eq("id_trabajo", jobId)
      .in("estado", OPEN_DISPUTE);
    if (disputeErr) {
      return jsonResponse(req, { error: "No se pudo revisar la disputa" }, 500);
    }
    const openDisputes = disputes ?? [];
    if (openDisputes.length > 0 && !isAdmin) {
      const openedByClient = openDisputes.every((row) => row.abierta_por === job.id_usuario);
      if (!isClient || !openedByClient) {
        return jsonResponse(
          req,
          { error: "Hay una disputa abierta. Solo el cliente que la abrió puede cancelar la solicitud." },
          409,
        );
      }
    }

    if (job.estado === "esperando_aprobacion_cliente" && !isClient && !isAdmin) {
      return jsonResponse(
        req,
        { error: "Si no estás conforme, abre una disputa. El pago sigue retenido." },
        409,
      );
    }
    if (["completado", "cancelado", "expirado", "no_asistio"].includes(job.estado)) {
      return jsonResponse(req, { error: "El trabajo ya está cerrado" }, 409);
    }

    const { data: payments, error: payErr } = await admin
      .from("pagos")
      .select("id, estado")
      .eq("id_trabajo", jobId)
      .in("tipo_pago", REFUNDABLE_TYPES)
      .in("estado", ["autorizado", "retenido", "reembolsado"])
      .order("creado_en", { ascending: true });
    if (payErr) {
      return jsonResponse(req, { error: "No se pudieron leer los cobros" }, 500);
    }
    const rows = payments ?? [];
    if (rows.length === 0) return jsonResponse(req, { skipped: true });

    const pending = rows.filter((row) => row.estado === "autorizado" || row.estado === "retenido");
    if (pending.length === 0) return jsonResponse(req, { status: "already" });

    let refunded = 0;
    for (const row of pending) {
      const result = await refundHeldPaymentOnce(admin, row.id);
      if (result.status === "refunded") {
        refunded += 1;
        scheduleRefundEmail(admin, String(row.id));
      }
    }
    return jsonResponse(req, { status: refunded > 0 ? "refunded" : "already" });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
