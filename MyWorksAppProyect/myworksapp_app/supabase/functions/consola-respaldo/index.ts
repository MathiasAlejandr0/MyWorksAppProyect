import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

/**
 * Respaldo gzip del dominio hacia Storage privado.
 * La service role no sale de esta función. No desplegar en el remoto.
 * El cron entra con x-respaldo-secret. Una persona entra con JWT de admin.
 */

const BUCKET = "respaldos-consola";
const URL_SEGUNDOS = 60;

type Admin = ReturnType<typeof serviceClient>;

const port = Number(Deno.env.get("PORT") || "8000");
Deno.serve({ port }, async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeadersFor(req) });
  if (req.method !== "POST") return jsonResponse(req, { error: "Method not allowed" }, 405);

  const cron = secretoCron(req);
  const userSb = userClient(req);
  let adminOk = false;
  if (!cron) {
    const { data: auth } = await userSb.auth.getUser();
    if (!auth.user) return jsonResponse(req, { error: "No autenticado" }, 401);
    const gate = await requireAdmin(userSb);
    if (!gate.ok) return jsonResponse(req, { error: gate.error }, gate.status);
    adminOk = true;
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  const accion = String(body.accion || "crear");
  const admin = serviceClient();

  try {
    if (accion === "crear") return await crear(req, admin, userSb, adminOk, body);
    if (!adminOk) return jsonResponse(req, { error: "No autorizado" }, 403);
    if (accion === "firmar") return await firmar(req, admin, String(body.id || ""));
    if (accion === "verificar") return await verificar(req, admin, String(body.id || ""));
    if (accion === "restaurar") return await restaurar(req, admin, userSb, body);
    return jsonResponse(req, { error: "Acción no conocida" }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : "No se pudo completar el respaldo";
    return jsonResponse(req, { error: message }, 500);
  }
});

async function crear(req: Request, admin: Admin, userSb: Admin, adminOk: boolean, body: Record<string, unknown>) {
  const origen = body.origen === "cron" ? "cron" : "manual";
  const motivo = String(body.motivo || (origen === "cron" ? "Respaldo programado del dominio" : ""));
  const exportado = await admin.rpc("consola_exportar_dominio");
  if (exportado.error || !exportado.data) {
    return jsonResponse(req, { error: "No se pudo exportar" }, 500);
  }
  const bytes = await gzip(JSON.stringify(exportado.data));
  const sha = await sha256(bytes);
  const ruta = `${crypto.randomUUID()}.json.gz`;
  const up = await admin.storage.from(BUCKET).upload(ruta, bytes, {
    contentType: "application/gzip",
    upsert: false,
  });
  if (up.error) return jsonResponse(req, { error: "No se pudo guardar en Storage" }, 502);

  const filas = (exportado.data as { conteos?: unknown }).conteos ?? {};
  const cliente = adminOk ? userSb : admin;
  const registrado = await cliente.rpc("consola_registrar_respaldo", {
    p_sha: sha,
    p_bytes: bytes.byteLength,
    p_ruta: ruta,
    p_filas: filas,
    p_origen: origen,
    p_motivo: motivo,
  });
  if (registrado.error || !registrado.data) {
    await admin.storage.from(BUCKET).remove([ruta]);
    return jsonResponse(req, { error: "No se pudo registrar el respaldo" }, 500);
  }
  const meta = registrado.data as { id?: string; borrar?: string[]; uso_bytes?: number; limite_bytes?: number };
  const viejos = (meta.borrar ?? []).filter((item) => item.length > 0);
  if (viejos.length) await admin.storage.from(BUCKET).remove(viejos);
  return jsonResponse(req, {
    ok: true,
    id: meta.id,
    tamano_bytes: bytes.byteLength,
    sha256: sha,
    uso_bytes: meta.uso_bytes,
    limite_bytes: meta.limite_bytes,
  });
}

async function firmar(req: Request, admin: Admin, id: string) {
  const meta = await metaDe(admin, id);
  if (!meta) return jsonResponse(req, { error: "Respaldo no encontrado" }, 404);
  const firmada = await admin.storage.from(BUCKET).createSignedUrl(meta.ruta, URL_SEGUNDOS);
  if (firmada.error || !firmada.data?.signedUrl) {
    return jsonResponse(req, { error: "No se pudo firmar la descarga" }, 502);
  }
  return jsonResponse(req, { url: firmada.data.signedUrl, expira_en: URL_SEGUNDOS });
}

async function verificar(req: Request, admin: Admin, id: string) {
  const meta = await metaDe(admin, id);
  if (!meta) return jsonResponse(req, { error: "Respaldo no encontrado" }, 404);
  const bajado = await admin.storage.from(BUCKET).download(meta.ruta);
  if (bajado.error || !bajado.data) return jsonResponse(req, { ok: false });
  const sha = await sha256(new Uint8Array(await bajado.data.arrayBuffer()));
  return jsonResponse(req, { ok: sha === meta.sha256, sha256: meta.sha256, calculado: sha });
}

async function restaurar(req: Request, admin: Admin, userSb: Admin, body: Record<string, unknown>) {
  const id = String(body.id || "");
  const frase = String(body.frase || "");
  const motivo = String(body.motivo || "");
  const tablas = Array.isArray(body.tablas) ? body.tablas.map(String) : null;
  const meta = await metaDe(admin, id);
  if (!meta) return jsonResponse(req, { error: "Respaldo no encontrado" }, 404);
  const bajado = await admin.storage.from(BUCKET).download(meta.ruta);
  if (bajado.error || !bajado.data) return jsonResponse(req, { error: "No se pudo leer Storage" }, 502);
  const bytes = new Uint8Array(await bajado.data.arrayBuffer());
  if (await sha256(bytes) !== meta.sha256) return jsonResponse(req, { error: "El hash no coincide" }, 409);
  const json = await gunzip(bytes);
  const payload = JSON.parse(json) as unknown;

  const estado = await userSb.rpc("consola_estado_defensa");
  const estaba = Boolean((estado.data as { defensa_bloqueo?: boolean } | null)?.defensa_bloqueo);
  if (!estaba) {
    const bloqueo = await userSb.rpc("consola_fijar_defensa", {
      p_clave: "defensa_bloqueo",
      p_activo: true,
      p_frase: "BLOQUEAR",
      p_motivo: motivo,
    });
    if (bloqueo.error) return jsonResponse(req, { error: "No se pudo activar el bloqueo" }, 409);
  }
  const restaurado = await userSb.rpc("consola_restaurar_dominio", {
    p_payload: payload,
    p_frase: frase,
    p_motivo: motivo,
    p_tablas: tablas,
  });
  if (!estaba) {
    await userSb.rpc("consola_fijar_defensa", {
      p_clave: "defensa_bloqueo",
      p_activo: false,
      p_frase: "LIBERAR",
      p_motivo: "Fin de la restauración del respaldo",
    });
  }
  if (restaurado.error) return jsonResponse(req, { error: restaurado.error.message }, 409);
  return jsonResponse(req, { ok: true, conteos: (restaurado.data as { conteos?: unknown } | null)?.conteos ?? null });
}

async function metaDe(admin: Admin, id: string) {
  const { data } = await admin.from("respaldos_consola").select("ruta, sha256").eq("id", id).maybeSingle();
  if (!data?.ruta || !data.sha256) return null;
  return { ruta: String(data.ruta), sha256: String(data.sha256) };
}

function secretoCron(req: Request): boolean {
  const esperado = Deno.env.get("RESPALDO_CRON_SECRET")?.trim() ?? "";
  const recibido = req.headers.get("x-respaldo-secret") ?? "";
  if (!esperado || esperado.length !== recibido.length) return false;
  let diff = 0;
  for (let i = 0; i < esperado.length; i++) diff |= esperado.charCodeAt(i) ^ recibido.charCodeAt(i);
  return diff === 0;
}

async function gzip(texto: string): Promise<Uint8Array> {
  const flujo = new Blob([texto]).stream().pipeThrough(new CompressionStream("gzip"));
  return new Uint8Array(await new Response(flujo).arrayBuffer());
}

async function gunzip(bytes: Uint8Array): Promise<string> {
  const flujo = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
  return await new Response(flujo).text();
}

async function sha256(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
