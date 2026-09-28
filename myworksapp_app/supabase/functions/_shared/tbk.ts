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

export function tbkConfig() {
  const env = (Deno.env.get("TBK_ENV") || "integration").toLowerCase() as TbkEnv;
  const isProd = env === "production";
  // Credenciales oficiales de integración Transbank (documentación pública).
  const commerceCode =
    Deno.env.get("TBK_COMMERCE_CODE") ||
    (isProd ? "" : "597055555532");
  const apiKey =
    Deno.env.get("TBK_API_KEY") ||
    (isProd
      ? ""
      : "579B532A7440BB0C9079DED94D31EA1615BACEB56610332264625D42D0A1428");
  const host = isProd
    ? "https://webpay3g.transbank.cl"
    : "https://webpay3gint.transbank.cl";

  if (!commerceCode || !apiKey) {
    throw new Error("TBK_COMMERCE_CODE / TBK_API_KEY requeridos en production");
  }
  if (
    isProd &&
    (commerceCode === "597055555532" ||
      apiKey.startsWith("579B532A7440BB0C9079DED94D31EA1615BACEB566103322646"))
  ) {
    throw new Error(
      "TBK_ENV=production no acepta las claves públicas de integración",
    );
  }

  return { env, commerceCode, apiKey, host };
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
export function oneclickConfig() {
  const { env, host } = tbkConfig();
  const isProd = env === "production";
  const commerceCode =
    Deno.env.get("TBK_ONECLICK_COMMERCE_CODE") ||
    (isProd ? "" : "597055555541");
  const apiKey =
    Deno.env.get("TBK_ONECLICK_API_KEY") ||
    (isProd
      ? ""
      : "579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A1438");
  const childCommerceCode =
    Deno.env.get("TBK_ONECLICK_CHILD_CODE") ||
    (isProd ? "" : "597055555542");

  if (!commerceCode || !apiKey || !childCommerceCode) {
    throw new Error(
      "TBK_ONECLICK_COMMERCE_CODE / TBK_ONECLICK_API_KEY / TBK_ONECLICK_CHILD_CODE requeridos en production",
    );
  }
  if (
    isProd &&
    (commerceCode === "597055555541" ||
      childCommerceCode === "597055555542" ||
      apiKey.startsWith("579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630"))
  ) {
    throw new Error(
      "TBK_ENV=production no acepta las claves públicas de integración Oneclick",
    );
  }
  return { env, host, commerceCode, apiKey, childCommerceCode };
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
