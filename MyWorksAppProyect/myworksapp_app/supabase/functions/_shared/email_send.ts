import { isReservedEmailDomain } from "./guest_ticket.ts";
import type { RenderedEmail } from "./email_layout.ts";

export type EmailTag = { name: string; value: string };

export type SendEmailInput = {
  to: string;
  subject: string;
  content: RenderedEmail;
  idempotencyKey?: string;
  tags?: EmailTag[];
};

export type SendEmailResult =
  | { ok: true; id: string }
  | { ok: false; reason: string };

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function logStatus(status: number): void {
  console.log(`email: resend ${status}`);
}

/**
 * Envía con Resend. Nunca lanza: un fallo de correo no revierte el pago.
 * El log solo dice el estado HTTP, sin correo ni cuerpo.
 */
export async function sendEmail(input: SendEmailInput): Promise<SendEmailResult> {
  try {
    const key = Deno.env.get("RESEND_API_KEY")?.trim();
    const from = Deno.env.get("RESEND_FROM")?.trim();
    if (!key || !from) return { ok: false, reason: "correo_no_configurado" };
    const to = input.to.trim().toLowerCase();
    if (!EMAIL.test(to) || to.length > 160) return { ok: false, reason: "correo_invalido" };
    if (isReservedEmailDomain(to)) return { ok: false, reason: "correo_reservado" };

    const headers: Record<string, string> = {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    };
    if (input.idempotencyKey) headers["Idempotency-Key"] = input.idempotencyKey;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers,
      body: JSON.stringify({
        from,
        to: [to],
        subject: input.subject,
        html: input.content.html,
        text: input.content.text,
        ...(input.tags && input.tags.length > 0 ? { tags: input.tags } : {}),
      }),
    });
    logStatus(res.status);
    if (!res.ok) return { ok: false, reason: "correo_rechazado" };
    const body = await res.json().catch(() => null) as { id?: unknown } | null;
    const id = body && typeof body.id === "string" ? body.id : "";
    return { ok: true, id };
  } catch {
    logStatus(0);
    return { ok: false, reason: "correo_error" };
  }
}

/** Deja el envío vivo después de responder. Si no hay EdgeRuntime, no bloquea. */
export function scheduleAfterResponse(task: Promise<unknown>): void {
  const safe = task.catch(() => undefined);
  const runtime = (globalThis as {
    EdgeRuntime?: { waitUntil?: (promise: Promise<unknown>) => void };
  }).EdgeRuntime;
  if (typeof runtime?.waitUntil === "function") {
    runtime.waitUntil(safe);
  }
}
