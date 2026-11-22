import { jsonResponse } from "../_shared/cors.ts";
import { enmascararParaExterno, redactarPerfil, resumirResenas } from "../_shared/ia.ts";
import { crearProveedor, sugerenciaConProveedor } from "../_shared/ia_proveedor.ts";
import { allowRateDb } from "../_shared/rate_limit_db.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return jsonResponse(req, { ok: true });
  if (req.method !== "POST") return jsonResponse(req, { error: "Método no permitido" }, 405);
  const usuario = userClient(req);
  const { data: authData } = await usuario.auth.getUser();
  const userId = authData.user?.id;
  if (!userId) return jsonResponse(req, { error: "Inicia sesión para usar la sugerencia." }, 401);

  const { data: consentimiento } = await usuario.rpc("ia_tiene_consentimiento");
  if (consentimiento !== true) {
    return jsonResponse(req, { error: "Falta el consentimiento para usar IA con tus datos." }, 403);
  }
  const permitido = await allowRateDb(serviceClient(), `asistente:${userId}`, 20, 3_600_000);
  if (!permitido) return jsonResponse(req, { error: "Llegaste al límite de sugerencias de esta hora." }, 429);

  const body = await req.json().catch(() => null) as {
    modo?: string;
    texto?: string;
    comentarios?: string[];
    profesional_id?: string;
  } | null;
  const modo = body?.modo ?? "solicitud";
  const proveedor = crearProveedor({
    IA_PROVEEDOR: Deno.env.get("IA_PROVEEDOR"),
    OLLAMA_URL: Deno.env.get("OLLAMA_URL"),
    OLLAMA_MODEL: Deno.env.get("OLLAMA_MODEL"),
    GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY"),
    GEMINI_MODEL: Deno.env.get("GEMINI_MODEL"),
  });
  const aviso = "Sugerencia de la IA. Un humano confirma; esto no reserva ni aprueba nada.";

  if (modo === "solicitud") {
    const texto = enmascararParaExterno(String(body?.texto ?? ""));
    const sugerencia = await sugerenciaConProveedor(proveedor, texto);
    if (!sugerencia) return jsonResponse(req, { error: "La salida no pasó el esquema." }, 422);
    return jsonResponse(req, { ...sugerencia, proveedor: proveedor.nombre, aviso });
  }

  if (modo === "perfil") {
    const texto = redactarPerfil(enmascararParaExterno(String(body?.texto ?? "")));
    if (!texto) return jsonResponse(req, { error: "Escribe un poco más sobre tu oficio." }, 400);
    const { error } = await serviceClient().rpc("guardar_sugerencia_perfil", {
      p_usuario: userId,
      p_texto: texto,
    });
    if (error) return jsonResponse(req, { error: "No se guardó la sugerencia." }, 500);
    return jsonResponse(req, { texto, proveedor: proveedor.nombre, aviso });
  }

  if (modo === "resumen") {
    const profesional = body?.profesional_id || userId;
    const comentarios = (body?.comentarios ?? []).map((item) => enmascararParaExterno(String(item)));
    const resumen = resumirResenas(comentarios);
    if (!resumen) return jsonResponse(req, { error: "No hay reseñas para resumir." }, 400);
    const { error } = await serviceClient().rpc("guardar_resumen_resenas", {
      p_profesional: profesional,
      p_resumen: resumen,
      p_n: comentarios.length,
      p_origen: proveedor.nombre,
    });
    if (error) return jsonResponse(req, { error: "No se guardó el resumen." }, 500);
    return jsonResponse(req, { resumen, proveedor: proveedor.nombre, aviso });
  }

  return jsonResponse(req, { error: "Modo no permitido" }, 400);
});
