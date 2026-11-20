import { corsHeadersFor, jsonResponse } from "../_shared/cors.ts";
import { renderEmail } from "../_shared/email_layout.ts";
import { sendEmail } from "../_shared/email_send.ts";
import { pickInviteRedirect } from "../_shared/invite_html.ts";
import { motivoValido, registrarAuditoria, requestClientMeta, requireAdmin } from "../_shared/require_admin.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

const ROLES = ["Admin", "Soporte", "QA"] as const;
const INVITE_ALREADY_ACTIVE =
  "Esa persona ya tiene una cuenta activa; cámbiale el rol en vez de invitarla";

function inviteAlreadyRegistered(error: { status?: number; code?: string; message?: string }): boolean {
  const code = String(error.code || "").toLowerCase();
  if (code === "email_exists") return true;
  if (Number(error.status) !== 422) return false;
  return /email_exists|already been registered|already registered|user already/i.test(
    `${code} ${error.message || ""}`,
  );
}

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
  const paragraphs = [
    `Hola ${opts.name},`,
    `Te invitaron al panel como ${opts.role}.`,
  ];
  if (opts.message.trim()) paragraphs.push(opts.message.trim());
  if (!opts.actionLink) {
    paragraphs.push("Revisa el correo de Supabase para definir tu contraseña.");
  }
  const content = renderEmail({
    preheader: `Te invitaron al panel de MyWorksApp como ${opts.role}.`,
    title: "Invitación a MyWorksApp",
    paragraphs,
    button: opts.actionLink
      ? { label: "Aceptar invitación", url: opts.actionLink }
      : undefined,
  });
  const result = await sendEmail({
    to: opts.to,
    subject: "Invitación a MyWorksApp",
    content,
  });
  if (result.ok) return null;
  if (result.reason === "correo_no_configurado") return "correo_no_configurado";
  return "correo_rechazado";
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

    const adminGate = await requireAdmin(userSb);
    if (!adminGate.ok) {
      return jsonResponse(req, { error: adminGate.error }, adminGate.status);
    }

    const rawBody = await req.json().catch(() => null);
    const parsed = parseInvite(rawBody);
    if (!parsed.ok) return jsonResponse(req, { error: parsed.error }, 400);
    const motivo = motivoValido(
      rawBody && typeof rawBody === "object" ? (rawBody as { motivo?: unknown }).motivo : null,
    ) ?? (parsed.message.length >= 10 ? parsed.message : null);
    if (!motivo) {
      return jsonResponse(req, { error: "El motivo debe tener entre 10 y 2000 caracteres" }, 400);
    }

    const provider = (Deno.env.get("INVITE_PROVIDER") || "supabase").toLowerCase();
    const redirectTo = pickInviteRedirect(
      rawBody && typeof rawBody === "object" ? (rawBody as { redirectTo?: unknown }).redirectTo : undefined,
      Deno.env.get("INVITE_REDIRECT_URL"),
    );
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
        console.error("invitar-colaborador: no se asignó el rol");
        return jsonResponse(req, { error: "No se pudo asignar el rol" }, 400);
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

    const meta = requestClientMeta(req);
    const auditInvite = (userId: string | undefined) => registrarAuditoria(admin, {
      p_accion: "invitar_colaborador",
      p_entidad: "perfiles",
      p_id_entidad: userId ?? parsed.email,
      p_antes: null,
      p_despues: { rol: panelRole },
      p_motivo: motivo,
      p_ip: meta.ip,
      p_user_agent: meta.userAgent,
      p_id_actor: authData.user.id,
      p_rol_actor: "administrador",
    });

    if (provider === "resend") {
      const link = await admin.auth.admin.generateLink({
        type: "invite",
        email: parsed.email,
        options: {
          data: { nombre: parsed.name, rol_panel: parsed.role },
          redirectTo,
        },
      });
      if (link.error) {
        console.error("invitar-colaborador: generateLink rechazado");
        return jsonResponse(req, { error: "No se pudo crear la invitación" }, 400);
      }
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
      if (mailError) {
        return jsonResponse(req, { error: "No se pudo enviar el correo de invitación" }, 502);
      }
      const auditedResend = await auditInvite(link.data?.user?.id);
      return jsonResponse(req, {
        ok: true,
        provider: "resend",
        auditoria: auditedResend,
        message: `Invitación enviada a ${parsed.email} con Resend.`,
      });
    }

    const invited = await admin.auth.admin.inviteUserByEmail(parsed.email, {
      data: { nombre: parsed.name, rol_panel: parsed.role, mensaje: parsed.message },
      redirectTo,
    });
    if (invited.error) {
      if (inviteAlreadyRegistered(invited.error)) {
        return jsonResponse(req, { error: INVITE_ALREADY_ACTIVE }, 409);
      }
      console.error("invitar-colaborador: inviteUserByEmail rechazado");
      return jsonResponse(req, { error: "No se pudo crear la invitación" }, 400);
    }

    const roleError = await promote(invited.data.user?.id);
    if (roleError) return roleError;
    const audited = await auditInvite(invited.data.user?.id);

    return jsonResponse(req, {
      ok: true,
      provider: "supabase",
      auditoria: audited,
      message: `Invitación enviada a ${parsed.email}. Supabase Auth manda el correo si el SMTP del proyecto está activo.`,
    });
  } catch (e) {
    console.error("invitar-colaborador", e instanceof Error ? e.message : "error");
    return jsonResponse(req, { error: "No se pudo enviar la invitación" }, 500);
  }
});
