/** Escape de texto que va a un correo HTML. Cubre nombre, rol y mensaje. */
export function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

const REDIRECT_ALLOWLIST = new Set([
  "myworksapp-admin://auth/callback",
  "http://127.0.0.1:3001",
  "http://localhost:3001",
  "http://127.0.0.1:3001/",
  "http://localhost:3001/",
]);

/** Solo el deep link de la app instalada o el vite local. Si no hay nada, el deep link. */
export function pickInviteRedirect(requested: unknown, envValue: string | undefined): string {
  const env = envValue?.trim() ?? "";
  const ask = typeof requested === "string" ? requested.trim() : "";
  if (ask && (ask === env || REDIRECT_ALLOWLIST.has(ask))) return ask;
  if (env && (REDIRECT_ALLOWLIST.has(env) || env.startsWith("https://"))) return env;
  return "myworksapp-admin://auth/callback";
}

/** Href de invitación: solo http(s) o el esquema de la consola, ya escapado. */
export function safeInviteHref(value: string | undefined): string | null {
  if (!value) return null;
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" && url.protocol !== "http:" && url.protocol !== "myworksapp-admin:") {
    return null;
  }
  return escapeHtml(url.toString());
}

export function invitationHtml(opts: {
  name: string;
  role: string;
  message: string;
  actionLink?: string;
}): string {
  const href = safeInviteHref(opts.actionLink);
  const link = href
    ? `<p><a href="${href}">Aceptar invitación</a></p>`
    : "<p>Revisa el correo de Supabase para definir tu contraseña.</p>";
  const note = opts.message ? `<p>${escapeHtml(opts.message)}</p>` : "";
  return `<p>Hola ${escapeHtml(opts.name)},</p><p>Te invitaron al panel como ${escapeHtml(opts.role)}.</p>${note}${link}`;
}
