const ROLES = ['Admin', 'Soporte', 'QA'] as const;
export type PanelRole = (typeof ROLES)[number];

export type InviteRequest = {
  email: string;
  name: string;
  role: PanelRole;
  message: string;
};

export function parseInviteRequest(
  body: unknown,
): { ok: true; value: InviteRequest } | { ok: false; error: string } {
  if (!body || typeof body !== 'object') {
    return { ok: false, error: 'Cuerpo inválido' };
  }
  const row = body as Record<string, unknown>;
  const email = String(row.email ?? '').trim().toLowerCase();
  const name = String(row.name ?? '').trim();
  const role = String(row.role ?? '').trim();
  const message = String(row.message ?? '').trim();

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 160) {
    return { ok: false, error: 'Correo inválido' };
  }
  if (name.length < 2 || name.length > 80) {
    return { ok: false, error: 'El nombre debe tener entre 2 y 80 caracteres' };
  }
  if (!ROLES.includes(role as PanelRole)) {
    return { ok: false, error: 'Rol no permitido' };
  }
  if (message.length > 500) {
    return { ok: false, error: 'El mensaje supera 500 caracteres' };
  }
  return {
    ok: true,
    value: { email, name, role: role as PanelRole, message },
  };
}
