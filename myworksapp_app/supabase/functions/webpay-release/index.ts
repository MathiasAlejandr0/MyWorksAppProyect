import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Liberación de escrow de negocio + registro de liquidación.
 * Hoy: proveedor `manual` (admin confirma transferencia bancaria fuera de la app).
 * Futuro: mismo endpoint podrá orquestar khipu/fintoc cuando exista empresa.
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
    const transferRef = String(body.transferRef || body.referencia || "").trim();
    const notes = String(body.notes || "").trim().slice(0, 500);
    const confirmExternal = body.confirmExternal === true;
    const providerRaw = String(body.provider || "manual").toLowerCase();
    const provider =
      providerRaw === "khipu" || providerRaw === "fintoc" ? providerRaw : "manual";

    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }
    if (!confirmExternal) {
      return jsonResponse(
        req,
        {
          error:
            "Debes confirmar confirmExternal=true (transferencia hecha fuera de la app o via PSP).",
        },
        400,
      );
    }
    if (provider === "manual" && transferRef.length < 4) {
      return jsonResponse(
        req,
        { error: "referencia_transferencia requerida (mín. 4 caracteres)" },
        400,
      );
    }
    if (provider !== "manual") {
      return jsonResponse(
        req,
        {
          error: `Proveedor ${provider} aún no conectado. Usa provider=manual hasta existir empresa + API keys.`,
          code: "provider_not_ready",
        },
        501,
      );
    }

    const admin = serviceClient();
    const { data: payment } = await admin
      .from("pagos")
      .select("id, estado, id_trabajo, monto")
      .eq("id", paymentId)
      .maybeSingle();

    if (!payment) {
      return jsonResponse(req, { error: "Pago no encontrado" }, 404);
    }
    if (!["autorizado", "retenido"].includes(payment.estado)) {
      return jsonResponse(req, { error: "Pago no liberable" }, 409);
    }

    const { data: existingLiq } = await admin
      .from("liquidaciones")
      .select("id")
      .eq("id_pago", paymentId)
      .maybeSingle();
    if (existingLiq) {
      return jsonResponse(req, { error: "Pago ya liquidado" }, 409);
    }

    const { data: job } = await admin
      .from("trabajos")
      .select("id, id_trabajador")
      .eq("id", payment.id_trabajo)
      .maybeSingle();

    const { data: updated, error } = await admin
      .from("pagos")
      .update({
        estado: "liberado",
        liberado_en: new Date().toISOString(),
        actualizado_en: new Date().toISOString(),
      })
      .eq("id", paymentId)
      .select()
      .single();

    if (error) return jsonResponse(req, { error: error.message }, 500);

    await admin
      .from("trabajos")
      .update({
        estado_pago: "liberado",
        actualizado_en: new Date().toISOString(),
      })
      .eq("id", payment.id_trabajo);

    const { data: liquidacion, error: liqErr } = await admin
      .from("liquidaciones")
      .insert({
        id: crypto.randomUUID(),
        id_pago: paymentId,
        id_trabajo: payment.id_trabajo,
        id_trabajador: job?.id_trabajador ?? null,
        monto_clp: payment.monto,
        proveedor: provider,
        referencia_transferencia: transferRef,
        notas: notes || null,
        id_operador: user.id,
        creado_en: new Date().toISOString(),
      })
      .select()
      .single();

    if (liqErr) {
      return jsonResponse(
        req,
        {
          error: liqErr.message,
          payment: updated,
          warning: "Pago liberado pero falló el registro de liquidación",
        },
        500,
      );
    }

    return jsonResponse(req, {
      payment: updated,
      liquidacion,
      note:
        "Escrow liberado. Liquidación manual registrada — confirma que la transferencia bancaria ya se ejecutó.",
    });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
