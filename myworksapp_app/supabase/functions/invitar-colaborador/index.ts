import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

const ROLES = ["Admin", "Soporte", "QA"] as const;

function parseInvite(body: unknown):
  | { ok: true; email: string; name: string; role: string; message: string }
  | { ok: false; error: string } {
  if (!body || typeof body !== "object") return { ok: false, error: "Cuerpo inválido" };
  const row = body as Record<string, unknown>;
  const email = String(row.email ?? "").trim().toLowerCase();
  const name = String(row.name ?? "").trim();
  const role = String(row.role ?? "").trim();
  const message = String(row.message ?? "").trim();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 160) {
    return { ok: false, error: "Correo inválido" };
  }
  if (name.length < 2 || name.length > 80) {
    return { ok: false, error: "El nombre debe tener entre 2 y 80 caracteres" };
  }
  if (!ROLES.includes(role as (typeof ROLES)[number])) {
    return { ok: false, error: "Rol no permitido" };
  }
  if (message.length > 500) return { ok: false, error: "El mensaje supera 500 caracteres" };
  return { ok: true, email, name, role, message };
}

async function sendResend(opts: {
  to: string;
  name: string;
  role: string;
  message: string;
  actionLink?: string;
}): Promise<string | null> {
  const key = Deno.env.get("RESEND_API_KEY")?.trim();
  const from = Deno.env.get("RESEND_FROM")?.trim();
  if (!key || !from) return "Faltan RESEND_API_KEY y RESEND_FROM";
  const link = opts.actionLink
    ? `<p><a href="${opts.actionLink}">Aceptar invitación</a></p>`
    : "<p>Revisa el correo de Supabase para definir tu contraseña.</p>";
  const note = opts.message ? `<p>${opts.message.replace(/</g, "")}</p>` : "";
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [opts.to],
      subject: "Invitación a MyWorksApp",
      html: `<p>Hola ${opts.name},</p><p>Te invitaron al panel como ${opts.role}.</p>${note}${link}`,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    return `Resend respondió ${res.status}: ${text.slice(0, 180)}`;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { error: "Método no permitido" }, 405);
  }

  try {
    const userSb = userClient(req);
    const { data: authData, error: authError } = await userSb.auth.getUser();
    if (authError || !authData.user) {
      return jsonResponse(req, { error: "No autenticado" }, 401);
    }

    const { data: profile, error: profileError } = await userSb
      .from("perfiles")
      .select("rol")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (profileError) return jsonResponse(req, { error: profileError.message }, 400);
    if (profile?.rol !== "administrador") {
      return jsonResponse(req, { error: "Solo un administrador puede invitar" }, 403);
    }

    const parsed = parseInvite(await req.json().catch(() => null));
    if (!parsed.ok) return jsonResponse(req, { error: parsed.error }, 400);

    const provider = (Deno.env.get("INVITE_PROVIDER") || "supabase").toLowerCase();
    const redirectTo = Deno.env.get("INVITE_REDIRECT_URL")?.trim() || undefined;
    const admin = serviceClient();

    const panelRole = parsed.role === "Admin"
      ? "administrador"
      : parsed.role === "Soporte"
        ? "soporte"
        : parsed.role === "QA"
          ? "qa"
          : "";
    if (!panelRole) {
      return jsonResponse(req, { error: "Rol no permitido" }, 400);
    }

    const promote = async (userId: string | undefined) => {
      if (!userId) {
        return jsonResponse(req, { error: "La invitación no devolvió el usuario" }, 400);
      }
      const updated = await admin
        .from("perfiles")
        .update({ rol: panelRole, nombre: parsed.name })
        .eq("id", userId)
        .select("id");
      if (updated.error) {
        return jsonResponse(req, { error: updated.error.message }, 400);
      }
      if (!updated.data?.length) {
        return jsonResponse(
          req,
          { error: "No se pudo asignar el rol del panel. El perfil no existe o el trigger lo rechazó." },
          400,
        );
      }
      return null;
    };

    if (provider === "resend") {
      const link = await admin.auth.admin.generateLink({
        type: "invite",
        email: parsed.email,
        options: {
          data: { nombre: parsed.name, rol_panel: parsed.role },
          redirectTo,
        },
      });
      if (link.error) return jsonResponse(req, { error: link.error.message }, 400);
      const roleError = await promote(link.data?.user?.id);
      if (roleError) return roleError;
      const actionLink = link.data?.properties?.action_link;
      const mailError = await sendResend({
        to: parsed.email,
        name: parsed.name,
        role: parsed.role,
        message: parsed.message,
        actionLink,
      });
      if (mailError) return jsonResponse(req, { error: mailError }, 502);
      return jsonResponse(req, {
        ok: true,
        provider: "resend",
        message: `Invitación enviada a ${parsed.email} con Resend.`,
      });
    }

    const invited = await admin.auth.admin.inviteUserByEmail(parsed.email, {
      data: { nombre: parsed.name, rol_panel: parsed.role, mensaje: parsed.message },
      redirectTo,
    });
    if (invited.error) return jsonResponse(req, { error: invited.error.message }, 400);

    const roleError = await promote(invited.data.user?.id);
    if (roleError) return roleError;

    return jsonResponse(req, {
      ok: true,
      provider: "supabase",
      message: `Invitación enviada a ${parsed.email}. Supabase Auth manda el correo si el SMTP del proyecto está activo.`,
    });
  } catch (e) {
    return jsonResponse(
      req,
      { error: e instanceof Error ? e.message : "No se pudo enviar la invitación" },
      500,
    );
  }
});
