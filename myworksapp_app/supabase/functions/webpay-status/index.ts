import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }

  try {
    const userSb = userClient(req);
    const {
      data: { user },
    } = await userSb.auth.getUser();
    if (!user) return jsonResponse(req, { error: "No autenticado" }, 401);

    let paymentId = "";
    const url = new URL(req.url);
    paymentId = url.searchParams.get("paymentId") || "";

    if (req.method === "POST") {
      try {
        const body = await req.json();
        paymentId = String(body.paymentId || paymentId);
      } catch {
        // ignore
      }
    }

    if (!paymentId) {
      return jsonResponse(req, { error: "paymentId requerido" }, 400);
    }

    const { data, error } = await userSb
      .from("pagos")
      .select("id, estado, monto, buy_order, ambiente, id_trabajo")
      .eq("id", paymentId)
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
