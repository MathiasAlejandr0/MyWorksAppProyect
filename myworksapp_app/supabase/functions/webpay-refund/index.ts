import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";
import { tbkRefund } from "../_shared/tbk.ts";

/**
 * Reembolso Transbank + estado reembolsado.
 * Solo admin (JWT + is_admin vía RPC o perfil).
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
      .select("id, monto, token_tbk, estado")
      .eq("id", paymentId)
      .maybeSingle();
    if (error || !payment) {
      return jsonResponse(req, { error: "Pago no encontrado" }, 404);
    }
    if (!payment.token_tbk) {
      return jsonResponse(req, { error: "Pago sin token Transbank" }, 400);
    }
    if (!["autorizado", "retenido", "pendiente"].includes(payment.estado)) {
      return jsonResponse(req, { error: "Estado no reembolsable" }, 409);
    }

    const refund = await tbkRefund(payment.token_tbk, Number(payment.monto));

    const { data: updated, error: upErr } = await admin
      .from("pagos")
      .update({
        estado: "reembolsado",
        reembolsado_en: new Date().toISOString(),
        actualizado_en: new Date().toISOString(),
      })
      .eq("id", paymentId)
      .select()
      .single();

    if (upErr) {
      return jsonResponse(req, { error: upErr.message, refund }, 500);
    }

    return jsonResponse(req, { payment: updated, refund });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
