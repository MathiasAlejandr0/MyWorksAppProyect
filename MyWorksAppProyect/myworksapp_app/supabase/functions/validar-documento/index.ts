import { jsonResponse } from "../_shared/cors.ts";
import { enmascararParaExterno, validarSugerenciaDocumento } from "../_shared/ia.ts";
import { crearProveedor, documentoConProveedor } from "../_shared/ia_proveedor.ts";
import { allowRateDb } from "../_shared/rate_limit_db.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

function esWebp(base64: string): boolean {
  try {
    const binario = atob(base64.slice(0, 32));
    return binario.startsWith("RIFF") && binario.includes("WEBP");
  } catch {
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return jsonResponse(req, { ok: true });
  if (req.method !== "POST") return jsonResponse(req, { error: "Método no permitido" }, 405);
  const usuario = userClient(req);
  const { data: authData } = await usuario.auth.getUser();
  const userId = authData.user?.id;
  if (!userId) return jsonResponse(req, { error: "Inicia sesión." }, 401);
  const { data: consentimiento } = await usuario.rpc("ia_tiene_consentimiento");
  if (consentimiento !== true) return jsonResponse(req, { error: "Falta el consentimiento." }, 403);
  const permitido = await allowRateDb(serviceClient(), `documento:${userId}`, 8, 3_600_000);
  if (!permitido) return jsonResponse(req, { error: "Límite de validaciones de esta hora." }, 429);

  const body = await req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body || "rut" in body || "rut_completo" in body) {
    return jsonResponse(req, { error: "No envíes el RUT. Recorta esa zona en el teléfono." }, 400);
  }
  const imagen = String(body.imagen_webp_base64 ?? "");
  const nombre = enmascararParaExterno(String(body.nombre ?? "")).slice(0, 80);
  if (!esWebp(imagen) || imagen.length > 1_500_000) {
    return jsonResponse(req, { error: "La foto tiene que ser WebP y pesar menos de 1,5 MB." }, 400);
  }

  const entorno = {
    IA_PROVEEDOR: Deno.env.get("IA_PROVEEDOR"),
    OLLAMA_URL: Deno.env.get("OLLAMA_URL"),
    GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY"),
    GEMINI_MODEL: Deno.env.get("GEMINI_MODEL"),
  };
  const proveedor = crearProveedor(entorno);
  let crudo: unknown = null;
  if (proveedor.nombre === "gemini") {
    crudo = await documentoConProveedor(proveedor, { imagenBase64: imagen, nombre }, fetch, entorno).catch(() => null);
  }
  const sugerencia = validarSugerenciaDocumento(crudo) ?? validarSugerenciaDocumento({
    legible: imagen.length > 80,
    tipo: /cert/i.test(nombre) ? "certificado" : "carnet",
    nombre_coincide: nombre.length >= 3 ? null : false,
    confianza: 0.42,
    nota: "Revisión automática de una foto recortada. No se leyó el RUT. Un administrador aprueba.",
  });
  if (!sugerencia) return jsonResponse(req, { error: "No se pudo armar la sugerencia." }, 422);
  const { error } = await serviceClient().rpc("guardar_sugerencia_validacion", {
    p_usuario: userId,
    p_sugerencia: { ...sugerencia, proveedor: Deno.env.get("IA_PROVEEDOR") || "mock" },
  });
  if (error) return jsonResponse(req, { error: "No se guardó la sugerencia." }, 500);
  return jsonResponse(req, {
    sugerencia_validacion: sugerencia,
    aviso: "Sugerencia de la IA. No aprueba ni rechaza el documento.",
  });
});
