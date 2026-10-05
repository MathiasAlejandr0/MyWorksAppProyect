export type TurnstileDecision = "skip" | "verify" | "fail_closed";

/**
 * Sin secreto y con TBK_ENV de integración, el checkout de la demo sigue.
 * En production, sin secreto, se rechaza.
 */
export function turnstileDecision(
  tbkEnv: string | undefined | null,
  secretPresent: boolean,
): TurnstileDecision {
  if (secretPresent) return "verify";
  const env = (tbkEnv || "integration").toLowerCase();
  if (env !== "production") return "skip";
  return "fail_closed";
}
