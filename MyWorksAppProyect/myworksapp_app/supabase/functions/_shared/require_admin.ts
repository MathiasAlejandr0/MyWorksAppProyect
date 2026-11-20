/**
 * Puerta de administrador para Edge Functions de la consola.
 *
 * No lee `perfiles.rol`. Llama `is_admin()` con el JWT del usuario: esa
 * función exige rol administrador, `estado_cuenta` activo y, si
 * `admin_requiere_aal2 = 1`, nivel `aal2`. Un JWT aal1 o una cuenta
 * suspendida devuelve false y la función no debe mutar nada.
 */

export const ADMIN_DENIED = "No autorizado";

export interface AdminRpc {
  rpc(
    fn: "is_admin",
  ): PromiseLike<{ data: unknown; error: { message?: string } | null }>;
}

export function adminSessionAllowed(data: unknown, error: unknown): boolean {
  return error == null && data === true;
}

export async function requireAdmin(
  userSb: AdminRpc,
  log: (line: string) => void = (line) => console.error(line),
): Promise<
  { ok: true } | { ok: false; status: 403; error: typeof ADMIN_DENIED }
> {
  let data: unknown = null;
  let error: { message?: string } | null = null;
  try {
    const result = await userSb.rpc("is_admin");
    data = result?.data;
    error = result?.error ?? null;
  } catch (e) {
    log(`is_admin no se pudo evaluar: ${e instanceof Error ? e.message : "error"}`);
    return { ok: false, status: 403, error: ADMIN_DENIED };
  }
  if (!adminSessionAllowed(data, error)) {
    const detail = error?.message ? "rpc_error" : `data=${String(data)}`;
    log(`is_admin rechazó la sesión (${detail})`);
    return { ok: false, status: 403, error: ADMIN_DENIED };
  }
  return { ok: true };
}

export function requestClientMeta(req: Request): { ip: string | null; userAgent: string | null } {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "";
  const ip = forwarded || req.headers.get("cf-connecting-ip")?.trim() || "";
  const userAgent = req.headers.get("user-agent")?.slice(0, 300) ?? "";
  return {
    ip: ip ? ip.slice(0, 80) : null,
    userAgent: userAgent || null,
  };
}

export function motivoValido(value: unknown): string | null {
  const text = String(value ?? "").trim();
  if (text.length < 10 || text.length > 2000) return null;
  return text;
}

type AuditClient = {
  rpc: (
    fn: "registrar_auditoria",
    args: Record<string, unknown>,
  ) => PromiseLike<{ error: { message?: string } | null }>;
};

/** Registra la acción. Si falla, no relanza: el dinero ya se movió y un reintento lo duplicaría. */
export async function registrarAuditoria(
  admin: AuditClient,
  args: Record<string, unknown>,
): Promise<boolean> {
  try {
    const { error } = await admin.rpc("registrar_auditoria", args);
    if (error) {
      console.error("registrar_auditoria rechazó la fila");
      return false;
    }
    return true;
  } catch {
    console.error("registrar_auditoria no respondió");
    return false;
  }
}

/** Ejecuta `mutate` solo si `is_admin()` es true. Si no, no la llama. */
export async function guardAdminMutation<T>(
  userSb: AdminRpc,
  mutate: () => Promise<T>,
  log?: (line: string) => void,
): Promise<
  | { status: 200; value: T }
  | { status: 403; error: typeof ADMIN_DENIED }
> {
  const gate = await requireAdmin(userSb, log);
  if (!gate.ok) return { status: 403, error: gate.error };
  return { status: 200, value: await mutate() };
}
