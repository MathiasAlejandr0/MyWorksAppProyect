import {
  enmascararParaExterno,
  parsearJsonModelo,
  sugerenciaDesdeTexto,
  validarSugerencia,
  type SugerenciaSolicitud,
} from "./ia.ts";

export interface CompletarOpciones {
  sistema: string;
  usuario: string;
}

export interface ProveedorGenerativo {
  nombre: "mock" | "ollama" | "gemini";
  completar(opciones: CompletarOpciones): Promise<string>;
}

type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

/** Sin clave y sin Ollama queda el mock. La clave de Gemini solo entra por el entorno. */
export function crearProveedor(
  env: Record<string, string | undefined>,
  fetchImpl: FetchLike = fetch,
): ProveedorGenerativo {
  const pedido = (env.IA_PROVEEDOR ?? "").trim().toLowerCase();
  const ollama = (env.OLLAMA_URL ?? "").trim();
  const gemini = (env.GEMINI_API_KEY ?? "").trim();
  if ((pedido === "ollama" || pedido === "") && ollama) return proveedorOllama(env, fetchImpl);
  if (pedido === "gemini" && gemini) return proveedorGemini(env, fetchImpl);
  return {
    nombre: "mock",
    completar: async ({ usuario }) => JSON.stringify(sugerenciaDesdeTexto(usuario)),
  };
}

function proveedorOllama(env: Record<string, string | undefined>, fetchImpl: FetchLike): ProveedorGenerativo {
  const base = (env.OLLAMA_URL ?? "http://127.0.0.1:11434").replace(/\/$/, "");
  const model = env.OLLAMA_MODEL ?? "llama3.2";
  return {
    nombre: "ollama",
    async completar({ sistema, usuario }) {
      const response = await fetchImpl(`${base}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model,
          stream: false,
          messages: [
            { role: "system", content: sistema },
            { role: "user", content: usuario },
          ],
        }),
      });
      if (!response.ok) throw new Error("ollama no respondió");
      const body = await response.json() as { message?: { content?: string } };
      return String(body.message?.content ?? "");
    },
  };
}

function proveedorGemini(env: Record<string, string | undefined>, fetchImpl: FetchLike): ProveedorGenerativo {
  const key = (env.GEMINI_API_KEY ?? "").trim();
  const model = env.GEMINI_MODEL ?? "gemini-2.0-flash";
  return {
    nombre: "gemini",
    async completar({ sistema, usuario }) {
      const response = await fetchImpl(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: sistema }] },
            contents: [{ role: "user", parts: [{ text: usuario }] }],
            generationConfig: { temperature: 0.2, responseMimeType: "application/json" },
          }),
        },
      );
      if (!response.ok) throw new Error("gemini no respondió");
      const body = await response.json() as {
        candidates?: { content?: { parts?: { text?: string }[] } }[];
      };
      return String(body.candidates?.[0]?.content?.parts?.[0]?.text ?? "");
    },
  };
}

const SISTEMA = "Devuelve solo JSON con categoria, urgencia, precio_min_clp, precio_max_clp y preguntas. No incluyas RUT, correos ni teléfonos.";

export async function documentoConProveedor(
  proveedor: ProveedorGenerativo,
  entrada: { imagenBase64: string; nombre: string },
  fetchImpl: FetchLike = fetch,
  env: Record<string, string | undefined> = {},
): Promise<unknown> {
  if (proveedor.nombre !== "gemini") return null;
  const key = (env.GEMINI_API_KEY ?? "").trim();
  const model = env.GEMINI_MODEL ?? "gemini-2.0-flash";
  const response = await fetchImpl(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        contents: [{
          parts: [
            {
              text: `El nombre declarado es "${entrada.nombre}". Di si la foto recortada es legible, si parece carnet o certificado, y si el nombre coincide. No transcribas RUT ni número de documento. JSON: legible, tipo (carnet|certificado|otro), nombre_coincide, confianza, nota.`,
            },
            { inline_data: { mime_type: "image/webp", data: entrada.imagenBase64 } },
          ],
        }],
        generationConfig: { temperature: 0, responseMimeType: "application/json" },
      }),
    },
  );
  if (!response.ok) throw new Error("gemini no respondió");
  const body = await response.json() as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  return parsearJsonModelo(String(body.candidates?.[0]?.content?.parts?.[0]?.text ?? ""));
}

export async function sugerenciaConProveedor(
  proveedor: ProveedorGenerativo,
  texto: string,
): Promise<SugerenciaSolicitud | null> {
  const seguro = enmascararParaExterno(texto);
  if (proveedor.nombre === "mock") return sugerenciaDesdeTexto(seguro);
  const crudo = await proveedor.completar({ sistema: SISTEMA, usuario: seguro });
  return validarSugerencia(parsearJsonModelo(crudo));
}
