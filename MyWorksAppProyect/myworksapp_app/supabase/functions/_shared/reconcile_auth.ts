// Autorización de webpay-reconcile. Acepta, en este orden:
// 1. Bearer con la service role key.
// 2. x-reconcile-secret igual a RECONCILE_CRON_SECRET (si está configurado).
// 3. x-reconcile-secret validado contra Vault vía la RPC reconcile_secret_valido
//    (solo service_role puede ejecutarla). Así el plan free no necesita copiar
//    el secreto a las variables de la función.
// Nunca registra el secreto.

export interface ReconcileAuthInput {
  header: string;
  bearer: string;
  envSecret: string;
  serviceKey: string;
  vaultCheck: (secret: string) => Promise<boolean>;
}

export function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  const n = Math.max(x.length, y.length);
  for (let i = 0; i < n; i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export async function reconcileAuthorized(input: ReconcileAuthInput): Promise<boolean> {
  const { header, bearer, envSecret, serviceKey, vaultCheck } = input;
  if (serviceKey && bearer && safeEqual(bearer, serviceKey)) return true;
  if (!header) return false;
  if (envSecret && safeEqual(header, envSecret)) return true;
  try {
    return (await vaultCheck(header)) === true;
  } catch {
    return false;
  }
}
