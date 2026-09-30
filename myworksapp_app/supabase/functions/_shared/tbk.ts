/** Cliente Transbank Webpay Plus REST (integración / producción). */

const TBK_TIMEOUT_MS = 12_000;
const TBK_RETRIES = 1;

async function tbkFetch(
  url: string,
  init: RequestInit,
): Promise<Response> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= TBK_RETRIES; attempt++) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), TBK_TIMEOUT_MS);
    try {
      const res = await fetch(url, { ...init, signal: ctrl.signal });
      if (res.status >= 500 && attempt < TBK_RETRIES) {
        lastErr = new Error(`TBK ${res.status}`);
        await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
        continue;
      }
      return res;
    } catch (e) {
      lastErr = e;
      if (attempt >= TBK_RETRIES) break;
      await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastErr instanceof Error ? lastErr : new Error("TBK timeout");
}



export type TbkEnv = "integration" | "production";

/**
 * Credenciales públicas de integración (Transbank, “Cómo empezar”).
 * La misma llave sirve para todos los códigos de comercio de integración.
 * https://www.transbankdevelopers.cl/documentacion/como_empezar#codigos-de-comercio
 */
export const TBK_INTEGRATION_API_KEY =
  "579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C";
export const TBK_WEBPAY_PLUS_COMMERCE = "597055555532";
export const TBK_ONECLICK_MALL_COMMERCE = "597055555541";
/** Tienda 1. Comercio hijo por defecto del cobro Oneclick. */
export const TBK_ONECLICK_CHILD_COMMERCE = "597055555542";
/** Tienda 2. Código oficial; el cobro de un solo local sigue usando la tienda 1. */
export const TBK_ONECLICK_CHILD_COMMERCE_2 = "597055555543";

const TBK_PUBLIC_KEY_PREFIX =
  "579B532A7440BB0C9079DED94D31EA1615BACEB566103322646";

export type TbkEnvMap = {
  TBK_ENV?: string;
  TBK_COMMERCE_CODE?: string;
  TBK_API_KEY?: string;
  TBK_ONECLICK_COMMERCE_CODE?: string;
  TBK_ONECLICK_API_KEY?: string;
  TBK_ONECLICK_CHILD_CODE?: string;
};

function envValue(value: string | undefined): string {
  return (value ?? "").trim();
}

/** Sin variable, el demo queda en integración. Cualquier otro valor que no sea production falla. */
export function resolveTbkEnv(raw: string | undefined): TbkEnv {
  const env = envValue(raw).toLowerCase() || "integration";
  if (env === "integration" || env === "production") return env;
  throw new Error(
    `TBK_ENV=${raw} no es válido. Usa integration o production. El fallback público solo aplica con TBK_ENV=integration.`,
  );
}

function fallbackOrFail(
  env: TbkEnv,
  explicit: string,
  integrationValue: string,
  missingMessage: string,
): string {
  if (explicit) return explicit;
  if (env === "integration") return integrationValue;
  throw new Error(missingMessage);
}

function isPublicIntegrationKey(apiKey: string): boolean {
  return apiKey.startsWith(TBK_PUBLIC_KEY_PREFIX);
}

export function resolveTbkConfig(envMap: TbkEnvMap) {
  const env = resolveTbkEnv(envMap.TBK_ENV);
  const isProd = env === "production";
  const missing = "TBK_COMMERCE_CODE / TBK_API_KEY requeridos en production";
  const commerceCode = fallbackOrFail(
    env,
    envValue(envMap.TBK_COMMERCE_CODE),
    TBK_WEBPAY_PLUS_COMMERCE,
    missing,
  );
  const apiKey = fallbackOrFail(
    env,
    envValue(envMap.TBK_API_KEY),
    TBK_INTEGRATION_API_KEY,
    missing,
  );
  const host = isProd
    ? "https://webpay3g.transbank.cl"
    : "https://webpay3gint.transbank.cl";

  if (
    isProd &&
    (commerceCode === TBK_WEBPAY_PLUS_COMMERCE || isPublicIntegrationKey(apiKey))
  ) {
    throw new Error(
      "TBK_ENV=production no acepta las claves públicas de integración",
    );
  }

  return { env, commerceCode, apiKey, host };
}

function denoEnv(): TbkEnvMap {
  return {
    TBK_ENV: Deno.env.get("TBK_ENV"),
    TBK_COMMERCE_CODE: Deno.env.get("TBK_COMMERCE_CODE"),
    TBK_API_KEY: Deno.env.get("TBK_API_KEY"),
    TBK_ONECLICK_COMMERCE_CODE: Deno.env.get("TBK_ONECLICK_COMMERCE_CODE"),
    TBK_ONECLICK_API_KEY: Deno.env.get("TBK_ONECLICK_API_KEY"),
    TBK_ONECLICK_CHILD_CODE: Deno.env.get("TBK_ONECLICK_CHILD_CODE"),
  };
}

export function tbkConfig() {
  return resolveTbkConfig(denoEnv());
}

export async function tbkCreateTransaction(input: {
  buyOrder: string;
  sessionId: string;
  amount: number;
  returnUrl: string;
}): Promise<{ token: string; url: string }> {
  const { commerceCode, apiKey, host } = tbkConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/webpay/v1.2/transactions`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Tbk-Api-Key-Id": commerceCode,
        "Tbk-Api-Key-Secret": apiKey,
      },
      body: JSON.stringify({
        buy_order: input.buyOrder.slice(0, 26),
        session_id: input.sessionId.slice(0, 61),
        amount: Math.round(input.amount),
        return_url: input.returnUrl,
      }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(
      typeof data === "object"
        ? JSON.stringify(data)
        : `TBK create failed ${res.status}`,
    );
  }
  return { token: data.token, url: data.url };
}

export async function tbkCommit(token: string): Promise<Record<string, unknown>> {
  const { commerceCode, apiKey, host } = tbkConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/webpay/v1.2/transactions/${token}`,
    {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "Tbk-Api-Key-Id": commerceCode,
        "Tbk-Api-Key-Secret": apiKey,
      },
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(
      typeof data === "object"
        ? JSON.stringify(data)
        : `TBK commit failed ${res.status}`,
    );
  }
  return data as Record<string, unknown>;
}

/** Anulación / reembolso Webpay Plus (monto en CLP). */
export async function tbkRefund(
  token: string,
  amount: number,
): Promise<Record<string, unknown>> {
  const { commerceCode, apiKey, host } = tbkConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/webpay/v1.2/transactions/${token}/refunds`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Tbk-Api-Key-Id": commerceCode,
        "Tbk-Api-Key-Secret": apiKey,
      },
      body: JSON.stringify({ amount: Math.round(amount) }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(
      typeof data === "object"
        ? JSON.stringify(data)
        : `TBK refund failed ${res.status}`,
    );
  }
  return data as Record<string, unknown>;
}

/** Oneclick Mall: cobro sin redirigir al portal, con tarjeta ya inscrita. */
export function resolveOneclickConfig(envMap: TbkEnvMap) {
  const { env, host } = resolveTbkConfig(envMap);
  const isProd = env === "production";
  const missing =
    "TBK_ONECLICK_COMMERCE_CODE / TBK_ONECLICK_API_KEY / TBK_ONECLICK_CHILD_CODE requeridos en production";
  const commerceCode = fallbackOrFail(
    env,
    envValue(envMap.TBK_ONECLICK_COMMERCE_CODE),
    TBK_ONECLICK_MALL_COMMERCE,
    missing,
  );
  const apiKey = fallbackOrFail(
    env,
    envValue(envMap.TBK_ONECLICK_API_KEY),
    TBK_INTEGRATION_API_KEY,
    missing,
  );
  const childCommerceCode = fallbackOrFail(
    env,
    envValue(envMap.TBK_ONECLICK_CHILD_CODE),
    TBK_ONECLICK_CHILD_COMMERCE,
    missing,
  );

  if (
    isProd &&
    (commerceCode === TBK_ONECLICK_MALL_COMMERCE ||
      childCommerceCode === TBK_ONECLICK_CHILD_COMMERCE ||
      childCommerceCode === TBK_ONECLICK_CHILD_COMMERCE_2 ||
      isPublicIntegrationKey(apiKey))
  ) {
    throw new Error(
      "TBK_ENV=production no acepta las claves públicas de integración Oneclick",
    );
  }
  return { env, host, commerceCode, apiKey, childCommerceCode };
}

export function oneclickConfig() {
  return resolveOneclickConfig(denoEnv());
}

function oneclickHeaders() {
  const { commerceCode, apiKey } = oneclickConfig();
  return {
    "Content-Type": "application/json",
    "Tbk-Api-Key-Id": commerceCode,
    "Tbk-Api-Key-Secret": apiKey,
  };
}

export function oneclickAuthorized(data: Record<string, unknown> | null): boolean {
  if (!data) return false;
  const details = Array.isArray(data.details) ? data.details : [];
  const first = details[0] as Record<string, unknown> | undefined;
  if (!first) return false;
  return Number(first.response_code) === 0;
}

/** El banco respondió y no autorizó. Esa buy_order ya no se puede repetir. */
export function oneclickDeclined(data: Record<string, unknown> | null): boolean {
  if (!data) return false;
  const details = Array.isArray(data.details) ? data.details : [];
  const first = details[0] as Record<string, unknown> | undefined;
  if (!first || first.response_code == null || first.response_code === "") return false;
  return Number(first.response_code) !== 0;
}

export function oneclickAuthCode(data: Record<string, unknown> | null): string {
  if (!data) return "";
  const details = Array.isArray(data.details) ? data.details : [];
  const first = details[0] as Record<string, unknown> | undefined;
  return String(first?.authorization_code || "");
}

export async function tbkOneclickStart(input: {
  username: string;
  email: string;
  responseUrl: string;
}): Promise<{ token: string; url: string }> {
  const { host } = oneclickConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/oneclick/v1.2/inscriptions`,
    {
      method: "POST",
      headers: oneclickHeaders(),
      body: JSON.stringify({
        username: input.username.slice(0, 40),
        email: input.email.slice(0, 100),
        response_url: input.responseUrl,
      }),
    },
  );
  const data = await res.json();
  if (!res.ok || !data?.token || !data?.url_webpay) {
    console.error("oneclick start", res.status);
    throw new Error("No se pudo iniciar la inscripción de la tarjeta.");
  }
  return { token: String(data.token), url: String(data.url_webpay) };
}

export async function tbkOneclickFinish(token: string): Promise<Record<string, unknown>> {
  const { host } = oneclickConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/oneclick/v1.2/inscriptions/${token}`,
    { method: "PUT", headers: oneclickHeaders() },
  );
  const data = await res.json();
  if (!res.ok) {
    console.error("oneclick finish", res.status);
    throw new Error("Transbank no confirmó la tarjeta.");
  }
  return data as Record<string, unknown>;
}

export async function tbkOneclickStatus(
  buyOrder: string,
): Promise<Record<string, unknown> | null> {
  const { host } = oneclickConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/oneclick/v1.2/transactions/${encodeURIComponent(buyOrder)}`,
    { method: "GET", headers: oneclickHeaders() },
  );
  if (res.status === 404) return null;
  const data = await res.json().catch(() => null);
  if (!res.ok || !data || typeof data !== "object") return null;
  return data as Record<string, unknown>;
}

export async function tbkOneclickAuthorize(input: {
  username: string;
  tbkUser: string;
  buyOrder: string;
  detailBuyOrder: string;
  amount: number;
}): Promise<Record<string, unknown>> {
  const { host, childCommerceCode } = oneclickConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/oneclick/v1.2/transactions`,
    {
      method: "POST",
      headers: oneclickHeaders(),
      body: JSON.stringify({
        username: input.username.slice(0, 40),
        tbk_user: input.tbkUser,
        buy_order: input.buyOrder.slice(0, 26),
        details: [
          {
            commerce_code: childCommerceCode,
            buy_order: input.detailBuyOrder.slice(0, 26),
            amount: Math.round(input.amount),
            installments_number: 1,
          },
        ],
      }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    console.error("oneclick authorize", res.status);
    throw new Error("El banco rechazó el cobro a tu tarjeta.");
  }
  return data as Record<string, unknown>;
}

export async function tbkOneclickRefund(input: {
  buyOrder: string;
  detailBuyOrder: string;
  amount: number;
}): Promise<Record<string, unknown>> {
  const { host, childCommerceCode } = oneclickConfig();
  const res = await tbkFetch(
    `${host}/rswebpaytransaction/api/oneclick/v1.2/transactions/${encodeURIComponent(input.buyOrder)}/refunds`,
    {
      method: "POST",
      headers: oneclickHeaders(),
      body: JSON.stringify({
        commerce_code: childCommerceCode,
        detail_buy_order: input.detailBuyOrder.slice(0, 26),
        amount: Math.round(input.amount),
      }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    console.error("oneclick refund", res.status);
    throw new Error("No se pudo devolver el cobro a la tarjeta.");
  }
  return data as Record<string, unknown>;
}
