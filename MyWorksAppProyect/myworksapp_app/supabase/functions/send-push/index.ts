import { jsonResponse } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import {
  buildFcmMessage,
  fcmSendUrl,
  fetchAccessToken,
  isDeadTokenResponse,
  type NotificationRecord,
  parseServiceAccount,
} from "../_shared/fcm.ts";

/**
 * Manda un push FCM a los equipos del destinatario de un aviso nuevo.
 * La invoca un Database Webhook (INSERT en public.notificaciones) con el
 * header Authorization: Bearer <service role>. Ver docs/PUSH_NOTIFICACIONES.md.
 *
 * Secreto requerido: FCM_SERVICE_ACCOUNT (JSON de la cuenta de servicio).
 * Sin él responde 200 { skipped } para que el webhook no reintente.
 */

let cachedToken: { value: string; expiresAt: number } | null = null;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Method not allowed" }, 405);
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  const auth = req.headers.get("Authorization") || "";
  if (!serviceKey || auth !== `Bearer ${serviceKey}`) {
    return jsonResponse(req, { error: "No autorizado" }, 401);
  }

  const sa = parseServiceAccount(Deno.env.get("FCM_SERVICE_ACCOUNT"));
  if (!sa) return jsonResponse(req, { skipped: "FCM no configurado" });

  let record: NotificationRecord | undefined;
  try {
    const body = await req.json() as { type?: string; table?: string; record?: NotificationRecord };
    if (body.type !== "INSERT" || body.table !== "notificaciones") {
      return jsonResponse(req, { skipped: "evento ignorado" });
    }
    record = body.record;
  } catch {
    return jsonResponse(req, { error: "JSON inválido" }, 400);
  }
  const userId = String(record?.id_usuario || "");
  if (!record || !userId) return jsonResponse(req, { skipped: "sin destinatario" });

  const admin = serviceClient();
  const { data: devices, error } = await admin
    .from("dispositivos_push")
    .select("token")
    .eq("id_usuario", userId);
  if (error) return jsonResponse(req, { error: "No se pudieron leer los equipos" }, 500);
  if (!devices?.length) return jsonResponse(req, { sent: 0 });

  try {
    const now = Date.now();
    if (!cachedToken || cachedToken.expiresAt <= now) {
      cachedToken = { value: await fetchAccessToken(sa), expiresAt: now + 50 * 60 * 1000 };
    }
  } catch (e) {
    console.error("send-push oauth", e instanceof Error ? e.message : "error");
    return jsonResponse(req, { error: "No se pudo autenticar con FCM" }, 502);
  }

  const dead: string[] = [];
  let sent = 0;
  await Promise.all(
    devices.map(async ({ token }: { token: string }) => {
      const res = await fetch(fcmSendUrl(sa.project_id), {
        method: "POST",
        headers: {
          Authorization: `Bearer ${cachedToken!.value}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(buildFcmMessage(token, record!)),
      });
      if (res.ok) {
        sent++;
        return;
      }
      const text = await res.text();
      if (isDeadTokenResponse(res.status, text)) dead.push(token);
      else console.error("send-push fcm", res.status);
    }),
  );

  if (dead.length) {
    await admin.from("dispositivos_push").delete().in("token", dead);
  }
  return jsonResponse(req, { sent, removed: dead.length });
});
