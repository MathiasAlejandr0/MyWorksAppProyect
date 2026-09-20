import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Estado de pago sin exponer token_tbk/url_tbk.
 * - Autenticado: dueño del trabajo / admin vía RLS.
 * - Invitado: solo si paymentId + jobId coinciden (retorno Webpay).
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }

  try {
    let paymentId = "";
    let jobId = "";
    const url = new URL(req.url);
    paymentId = url.searchParams.get("paymentId") || "";
    jobId = url.searchParams.get("jobId") || "";

    if (req.method === "POST") {
      try {
        const body = await req.json();
        paymentId = String(body.paymentId || paymentId);
        jobId = String(body.jobId || jobId);
      } catch {
        // ignore
      }
    }

    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }

    const userSb = userClient(req);
    const {
      data: { user },
    } = await userSb.auth.getUser();

    if (user) {
      const { data, error } = await userSb
        .from("pagos")
        .select("id, estado, monto, buy_order, ambiente, id_trabajo")
        .eq("id", paymentId)
        .maybeSingle();

      if (error) return jsonResponse(req, { error: error.message }, 400);
      if (!data) return jsonResponse(req, { error: "No encontrado" }, 404);
      return jsonResponse(req, { payment: data });
    }

    // Invitado: exige jobId y match exacto (service role, columnas públicas).
    if (!jobId) {
      return jsonResponse(req, { error: "No autenticado" }, 401);
    }

    const admin = serviceClient();
    const { data, error } = await admin
      .from("pagos")
      .select("id, estado, monto, buy_order, ambiente, id_trabajo")
      .eq("id", paymentId)
      .eq("id_trabajo", jobId)
      .maybeSingle();

    if (error) return jsonResponse(req, { error: error.message }, 400);
    if (!data) return jsonResponse(req, { error: "No encontrado" }, 404);

    return jsonResponse(req, { payment: data });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : String(e) },
      500,
    );
  }
});
