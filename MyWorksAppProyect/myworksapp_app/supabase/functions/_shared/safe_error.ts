/** Errores cortos al cliente: sin tokens, JSON TBK ni secretos. */

const SENSITIVE = /token|tbk|api[-_]?key|secret|password|authorization|bearer/i;
const SECOND_CHARGE =
  /pagos_un_principal_activo|ya hay un cobro en curso|ya tiene un pago en garant[ií]a/i;

/** Misma frase que ErrorHandler cuando el índice único del pago principal choca. */
export const secondChargeMessage =
  "Este trabajo ya tiene un cobro en curso. Espera un momento antes de pagar otra vez.";

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
  if (SECOND_CHARGE.test(raw)) return secondChargeMessage;
  if (/duplicate key|violates unique constraint/i.test(raw)) {
    return "No se pudo completar el pago. Inténtalo de nuevo.";
  }
  if (raw.length > 160) return fallback;
  return raw;
}
