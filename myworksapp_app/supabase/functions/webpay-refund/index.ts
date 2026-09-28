import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { publicErrorMessage } from "../_shared/safe_error.ts";
import { refundHeldPaymentOnce } from "../_shared/refund_once.ts";
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

    const { data: profile } = await userSb
      .from("perfiles")
      .select("rol")
      .eq("id", user.id)
      .maybeSingle();
    if (profile?.rol !== "administrador") {
      return jsonResponse(req, { error: "Solo administrador" }, 403);
    }

    const body = await req.json();
    const paymentId = String(body.paymentId || "");
    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }

    const admin = serviceClient();
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
    return jsonResponse(req, { payment: result.payment, status: result.status });
  } catch (e) {
    return jsonResponse(req, { error: publicErrorMessage(e) }, 500);
  }
});
