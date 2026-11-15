/** Errores cortos al cliente: sin tokens, JSON TBK ni secretos. */

const SENSITIVE = /token|tbk|api[-_]?key|secret|password|authorization|bearer/i;

export function publicErrorMessage(e: unknown, fallback = "Error interno"): string {
  let raw = "";
  if (e instanceof Error) raw = e.message;
  else if (e && typeof e === "object" && "message" in e) {
    raw = String((e as { message?: unknown }).message ?? "");
  } else {
    raw = String(e ?? "");
  }
  if (!raw || raw === "[object Object]") return fallback;
  if (SENSITIVE.test(raw)) return "No se pudo completar el pago. Inténtalo de nuevo.";
  if (raw.length > 160) return fallback;
  return raw;
}
