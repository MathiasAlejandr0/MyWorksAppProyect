/** Cliente Transbank Webpay Plus REST (integración / producción). */

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

  return { env, commerceCode, apiKey, host };
}

export async function tbkCreateTransaction(input: {
  buyOrder: string;
  sessionId: string;
  amount: number;
  returnUrl: string;
}): Promise<{ token: string; url: string }> {
  const { commerceCode, apiKey, host } = tbkConfig();
  const res = await fetch(
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
  const res = await fetch(
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
  const res = await fetch(
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
