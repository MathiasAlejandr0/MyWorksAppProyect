/** Rate-limit in-memory por isolate (mitiga abuso; no es clúster-global). */

type Bucket = { count: number; resetAt: number };

const buckets = new Map<string, Bucket>();

export function clientIp(req: Request): string {
  return (
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    req.headers.get("x-real-ip") ||
    "unknown"
  );
}

/** true = permitido. Fail-closed si la clave es vacía. */
export function allowRate(key: string, max: number, windowMs: number): boolean {
  const id = key.trim() || "unknown";
  if (id === "unknown" && Deno.env.get("MWA_RATE_LIMIT_FAIL_CLOSED") === "1") {
    return false;
  }
  const now = Date.now();
  const row = buckets.get(id);
  if (!row || row.resetAt < now) {
    buckets.set(id, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (row.count >= max) return false;
  row.count += 1;
  return true;
}

export function rateLimitExceededMessage(): string {
  return "Demasiados intentos. Espera un minuto e inténtalo de nuevo.";
}
