import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Liberación de escrow + liquidación atómica (RPC liberar_escrow_manual).
 * Hoy: proveedor `manual`. Futuro: khipu/fintoc.
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
    const { data: rpcResult, error: rpcErr } = await admin.rpc(
      "liberar_escrow_manual",
      {
        p_id_pago: paymentId,
        p_id_operador: user.id,
        p_referencia: transferRef,
        p_notas: notes || null,
        p_proveedor: provider,
      },
    );

    if (rpcErr) {
      const msg = rpcErr.message || "Error al liberar";
      const status = /no encontrado|no liberable|ya liquidado|requeridos|inválido/i
        .test(msg)
        ? 409
        : 500;
      return jsonResponse(req, { error: msg }, status);
    }

    const { data: payment } = await admin
      .from("pagos")
      .select(
        "id, id_trabajo, monto, moneda, estado, metodo_pago, id_transaccion, autorizado_en, liberado_en, reembolsado_en, creado_en, actualizado_en",
      )
      .eq("id", paymentId)
      .maybeSingle();

    const { data: liquidacion } = await admin
      .from("liquidaciones")
      .select("*")
      .eq("id_pago", paymentId)
      .maybeSingle();

    return jsonResponse(req, {
      payment,
      liquidacion,
      result: rpcResult,
      note:
        "Escrow liberado y liquidación registrada en una sola transacción.",
    });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
