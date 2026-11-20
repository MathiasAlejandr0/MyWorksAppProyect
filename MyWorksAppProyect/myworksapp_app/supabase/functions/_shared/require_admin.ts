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
  ): Promise<{ data: unknown; error: { message?: string } | null }>;
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
