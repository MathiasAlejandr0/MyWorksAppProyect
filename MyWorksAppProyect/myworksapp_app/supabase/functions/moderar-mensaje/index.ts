import { jsonResponse } from "../_shared/cors.ts";
import { clasificarMensaje, enmascararParaExterno, parsearJsonModelo } from "../_shared/ia.ts";
import { crearProveedor } from "../_shared/ia_proveedor.ts";
import { allowRateDb } from "../_shared/rate_limit_db.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

Deno.serve({ port: Number(Deno.env.get("PORT") || "8000") }, async (req) => {
  if (req.method === "OPTIONS") return jsonResponse(req, { ok: true });
  if (req.method !== "POST") return jsonResponse(req, { error: "Método no permitido" }, 405);
  const { data: authData } = await userClient(req).auth.getUser();
  const userId = authData.user?.id;
  if (!userId) return jsonResponse(req, { error: "Inicia sesión." }, 401);
  const permitido = await allowRateDb(serviceClient(), `moderar:${userId}`, 60, 3_600_000);
  if (!permitido) return jsonResponse(req, { error: "Demasiadas revisiones." }, 429);

  const body = await req.json().catch(() => null) as { id_mensaje?: string; texto?: string } | null;
  const motivo = clasificarMensaje(String(body?.texto ?? ""));
  if (motivo !== "dudoso") {
    return jsonResponse(req, { motivo, veredicto: null, aviso: "La regla ya marcó o dejó pasar el mensaje. No se borra." });
  }
  const proveedor = crearProveedor({
    IA_PROVEEDOR: Deno.env.get("IA_PROVEEDOR"),
    OLLAMA_URL: Deno.env.get("OLLAMA_URL"),
    GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY"),
    GEMINI_MODEL: Deno.env.get("GEMINI_MODEL"),
  });
  let veredicto: "revisar" | "parece_limpio" = "revisar";
  if (proveedor.nombre !== "mock") {
    const crudo = await proveedor.completar({
      sistema: "Responde JSON {\"veredicto\":\"revisar\"|\"parece_limpio\"}. No copies datos personales.",
      usuario: enmascararParaExterno(String(body?.texto ?? "")),
    }).catch(() => "");
    const parsed = parsearJsonModelo(crudo) as { veredicto?: string } | null;
    if (parsed?.veredicto === "parece_limpio") veredicto = "parece_limpio";
  }
  if (body?.id_mensaje) {
    await serviceClient().rpc("anotar_veredicto_llm", {
      p_mensaje: body.id_mensaje,
      p_veredicto: veredicto,
    });
  }
  return jsonResponse(req, {
    motivo: "dudoso",
    veredicto,
    aviso: "Sugerencia de la IA. El mensaje sigue visible hasta que un administrador decida.",
  });
});
