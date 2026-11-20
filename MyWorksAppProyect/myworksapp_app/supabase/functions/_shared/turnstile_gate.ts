export type TurnstileDecision = "skip" | "verify" | "fail_closed";

/**
 * Sin secreto el checkout se rechaza, sea cual sea TBK_ENV.
 * Solo MWA_ALLOW_NO_CAPTCHA=1 (allowNoCaptcha) deja pasar sin verificar.
 * Ese flag es para una base local; no se usa en el sitio publicado.
 */
export function turnstileDecision(
  secretPresent: boolean,
  allowNoCaptcha = false,
): TurnstileDecision {
  if (secretPresent) return "verify";
  if (allowNoCaptcha) return "skip";
  return "fail_closed";
}
