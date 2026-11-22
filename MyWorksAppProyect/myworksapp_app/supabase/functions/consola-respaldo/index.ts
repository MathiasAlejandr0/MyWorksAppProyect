import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Sube a Storage el respaldo que ya creó consola_crear_respaldo.
 * El navegador no ve la service role: esta function la usa solo en el servidor.
 * No desplegar en el proyecto remoto desde esta rama.
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeadersFor(req) });
  if (req.method !== "POST") return jsonResponse(req, { error: "Method not allowed" }, 405);
  try {
    const userSb = userClient(req);
    const { data: auth } = await userSb.auth.getUser();
    if (!auth.user) return jsonResponse(req, { error: "No autenticado" }, 401);
    const gate = await requireAdmin(userSb);
    if (!gate.ok) return jsonResponse(req, { error: gate.error }, gate.status);

    const body = await req.json();
    const id = String(body.id || "");
    if (!id) return jsonResponse(req, { error: "id requerido" }, 400);
    const verificado = await userSb.rpc("consola_verificar_respaldo", { p_id: id });
    if (verificado.error || verificado.data?.ok !== true) {
      return jsonResponse(req, { error: "El respaldo no pasa la verificación" }, 409);
    }

    const admin = serviceClient();
    const { data: row, error } = await admin
      .from("respaldos_consola")
      .select("contenido, sha256")
      .eq("id", id)
      .maybeSingle();
    if (error || !row?.contenido) return jsonResponse(req, { error: "Respaldo no encontrado" }, 404);

    const gzip = new Blob([row.contenido]).stream().pipeThrough(new CompressionStream("gzip"));
    const bytes = new Uint8Array(await new Response(gzip).arrayBuffer());
    const path = `${id}.json.gz`;
    const up = await admin.storage.from("respaldos-consola").upload(path, bytes, {
      contentType: "application/gzip",
      upsert: true,
    });
    if (up.error) return jsonResponse(req, { error: "No se pudo guardar en Storage" }, 502);
    return jsonResponse(req, { ok: true, path, bytes: bytes.byteLength, sha256: row.sha256 });
  } catch {
    return jsonResponse(req, { error: "No se pudo copiar el respaldo" }, 500);
  }
});
