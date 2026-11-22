import { jsonResponse } from "../_shared/cors.ts";
import { embeddingHash, enmascararParaExterno } from "../_shared/ia.ts";
import { allowRate, clientIp } from "../_shared/rate_limit.ts";
import { serviceClient } from "../_shared/supabase.ts";

type Sesion = { run: (texto: string, opts: { mean_pool: boolean; normalize: boolean }) => Promise<number[] | { embedding?: number[] }> };

function sesionGte(): Sesion | null {
  const Session = (globalThis as { Supabase?: { ai?: { Session?: new (modelo: string) => Sesion } } }).Supabase?.ai?.Session;
  if (!Session) return null;
  return new Session("gte-small");
}

async function vectorDe(texto: string): Promise<{ embedding: number[]; origen: "gte-small" | "hash" }> {
  const pedido = (Deno.env.get("IA_EMBED_PROVEEDOR") ?? "gte-small").toLowerCase();
  if (pedido !== "hash") {
    const sesion = sesionGte();
    if (sesion) {
      const salida = await sesion.run(texto, { mean_pool: true, normalize: true });
      const valores = Array.isArray(salida) ? salida : salida.embedding;
      if (Array.isArray(valores) && valores.length === 384) {
        return { embedding: valores.map(Number), origen: "gte-small" };
      }
    }
  }
  return { embedding: embeddingHash(texto), origen: "hash" };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return jsonResponse(req, { ok: true });
  if (req.method !== "POST") return jsonResponse(req, { error: "Método no permitido" }, 405);
  if (!req.headers.get("apikey")) return jsonResponse(req, { error: "Falta la clave" }, 401);
  if (!allowRate(`embed:${clientIp(req)}`, 40, 60_000)) {
    return jsonResponse(req, { error: "Demasiadas búsquedas. Espera un minuto." }, 429);
  }
  const body = await req.json().catch(() => null) as { texto?: string; tabla?: string; id?: string } | null;
  const texto = enmascararParaExterno(String(body?.texto ?? "")).slice(0, 2000);
  if (texto.trim().length < 2) return jsonResponse(req, { error: "Texto demasiado corto" }, 400);
  const vector = await vectorDe(texto);
  const secreto = Deno.env.get("EMBED_INTERNO_SECRET") ?? "";
  const interno = secreto !== "" && req.headers.get("x-embed-interno") === secreto;
  if (interno && (body?.tabla === "trabajadores" || body?.tabla === "trabajos") && body.id) {
    const { error } = await serviceClient().rpc("ia_guardar_embedding", {
      p_tabla: body.tabla,
      p_id: body.id,
      p_vector: `[${vector.embedding.join(",")}]`,
      p_origen: vector.origen,
    });
    if (error) return jsonResponse(req, { error: "No se guardó el embedding" }, 500);
  }
  return jsonResponse(req, vector);
});
