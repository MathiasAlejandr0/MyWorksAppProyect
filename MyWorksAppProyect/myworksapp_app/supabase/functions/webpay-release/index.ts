import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { ipBloqueada, pagosPausados } from "../_shared/defensa.ts";
import { killSwitchResponse } from "../_shared/kill_switch.ts";
import { clientIp } from "../_shared/rate_limit.ts";
import { scheduleReleasedEmail } from "../_shared/payment_mail.ts";
import { jobHasOpenDispute } from "../_shared/dispute_guard.ts";
import { motivoValido, registrarAuditoria, requestClientMeta, requireAdmin } from "../_shared/require_admin.ts";
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

    const adminGate = await requireAdmin(userSb);
    if (!adminGate.ok) {
      return jsonResponse(req, { error: adminGate.error }, adminGate.status);
    }

    const body = await req.json();
    const paymentId = String(body.paymentId || "");
    const transferRef = String(body.transferRef || body.referencia || "").trim();
    const motivo = motivoValido(body.motivo || body.notes);
    const notes = (motivo ?? "").slice(0, 500);
    const confirmExternal = body.confirmExternal === true;
    const providerRaw = String(body.provider || "manual").toLowerCase();
    const provider =
      providerRaw === "khipu" || providerRaw === "fintoc" ? providerRaw : "manual";

    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }
    if (!motivo) {
      return jsonResponse(req, { error: "El motivo debe tener entre 10 y 2000 caracteres" }, 400);
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
    if (await pagosPausados(admin) || await ipBloqueada(admin, clientIp(req))) {
      return jsonResponse(req, killSwitchResponse(), 503);
    }
    const { data: paymentRow } = await admin
      .from("pagos")
      .select("id_trabajo")
      .eq("id", paymentId)
      .maybeSingle();
    if (paymentRow?.id_trabajo && await jobHasOpenDispute(admin, paymentRow.id_trabajo)) {
      return jsonResponse(
        req,
        {
          error:
            "Hay una disputa abierta. Resuélvela en atención al cliente para liberar o devolver el pago.",
        },
        409,
      );
    }

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
      const msg = rpcErr.message || "";
      console.error("liberar_escrow_manual", msg.slice(0, 200));
      const status = /no encontrado|no liberable|ya liquidado|requeridos|inválido/i.test(msg)
        ? 409
        : 500;
      return jsonResponse(req, { error: "No se pudo liberar el pago" }, status);
    }
    scheduleReleasedEmail(admin, paymentId);

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

    const meta = requestClientMeta(req);
    const audited = await registrarAuditoria(admin, {
      p_accion: "liquidar",
      p_entidad: "pagos",
      p_id_entidad: paymentId,
      p_antes: { estado: "retenido" },
      p_despues: { estado: "liberado", referencia: transferRef },
      p_motivo: motivo,
      p_ip: meta.ip,
      p_user_agent: meta.userAgent,
      p_id_actor: user.id,
      p_rol_actor: "administrador",
    });

    return jsonResponse(req, {
      payment,
      liquidacion,
      result: rpcResult,
      auditoria: audited,
      note:
        "Escrow liberado y liquidación registrada en una sola transacción.",
    });
  } catch (e) {
    console.error("webpay-release", e instanceof Error ? e.message : "error");
    return jsonResponse(req, { error: "No se pudo liberar el pago" }, 500);
  }
});
