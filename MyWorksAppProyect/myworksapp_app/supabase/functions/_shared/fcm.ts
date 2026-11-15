/**
 * Envío de push con Firebase Cloud Messaging (API HTTP v1).
 * Sin dependencias: firma el JWT de la cuenta de servicio con WebCrypto,
 * así corre igual en Deno (Edge Functions) y en Node (tests).
 */

export type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

export type NotificationRecord = {
  id?: string;
  id_usuario?: string;
  tipo?: string;
  titulo?: string;
  cuerpo?: string;
  id_relacionado?: string | null;
};

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
/** Mismo canal que crea flutter_local_notifications en la app. */
export const ANDROID_CHANNEL_ID = "myworksapp_channel";

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  try {
    const sa = JSON.parse(raw) as Partial<ServiceAccount>;
    if (!sa.project_id || !sa.client_email || !sa.private_key) return null;
    return {
      project_id: sa.project_id,
      client_email: sa.client_email,
      private_key: sa.private_key,
    };
  } catch {
    return null;
  }
}

function base64Url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlJson(value: unknown): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemToPkcs8(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");
  const bin = atob(body);
  const out = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** JWT RS256 que Google cambia por un access token (válido 1 h). */
export async function createSignedJwt(
  sa: ServiceAccount,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };
  const unsigned = `${base64UrlJson(header)}.${base64UrlJson(claims)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64Url(new Uint8Array(sig))}`;
}

export async function fetchAccessToken(
  sa: ServiceAccount,
  fetchFn: typeof fetch = fetch,
): Promise<string> {
  const assertion = await createSignedJwt(sa);
  const res = await fetchFn(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`OAuth de Google respondió ${res.status}`);
  const json = (await res.json()) as { access_token?: string };
  if (!json.access_token) throw new Error("OAuth de Google sin access_token");
  return json.access_token;
}

function clip(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
}

/** Mensaje FCM para un aviso de la tabla notificaciones. */
export function buildFcmMessage(deviceToken: string, n: NotificationRecord) {
  const data: Record<string, string> = {
    tipo: String(n.tipo ?? ""),
    id_notificacion: String(n.id ?? ""),
  };
  if (n.id_relacionado) data.id_relacionado = String(n.id_relacionado);
  return {
    message: {
      token: deviceToken,
      notification: {
        title: clip(String(n.titulo ?? "My Works App"), 120),
        body: clip(String(n.cuerpo ?? ""), 400),
      },
      data,
      android: {
        priority: "HIGH",
        notification: { channel_id: ANDROID_CHANNEL_ID },
      },
    },
  };
}

/** true si FCM dice que el token ya no sirve (app desinstalada, etc.). */
export function isDeadTokenResponse(status: number, body: string): boolean {
  if (status === 404) return true;
  if (status !== 400) return false;
  return /UNREGISTERED|registration-token-not-registered|Invalid registration token/i
    .test(body);
}

export function fcmSendUrl(projectId: string): string {
  return `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/messages:send`;
}
