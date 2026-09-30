/** 15 minutos. Un solo uso, atado al navegador que inició el checkout. */
export const GUEST_TICKET_TTL_SEC = 15 * 60;

export function shouldIssueGuestPasswordTicket(input: {
  alreadyHeld: boolean;
  approved: boolean;
  guest: boolean;
}): boolean {
  return input.guest && input.approved && !input.alreadyHeld;
}

/** True solo si el UPDATE comparó estado pendiente y escribió una fila. */
export function paymentHoldTransitioned(result: {
  error: unknown;
  data: readonly unknown[] | null | undefined;
}): boolean {
  return !result.error && (result.data?.length ?? 0) > 0;
}

/**
 * demo_modo=1 confirma el correo: el ticket de un solo uso prueba el navegador que pagó.
 * En producción el correo sigue sin confirmar y hay que reenviar el alta.
 */
export function guestPasswordConfirmPlan(demoMode: boolean): {
  emailConfirmed: boolean;
  resendSignup: boolean;
} {
  if (demoMode) return { emailConfirmed: true, resendSignup: false };
  return { emailConfirmed: false, resendSignup: true };
}

/** El jti se quema solo después de cargar la cuenta y guardar la clave. */
export function shouldConsumeGuestTicket(input: {
  userLoaded: boolean;
  passwordSaved: boolean;
}): boolean {
  return input.userLoaded && input.passwordSaved;
}

export function guestTicketPayload(userId: string, exp: number, jti: string): string {
  return `pwd.${userId}.${exp}.${jti}`;
}

export function parseGuestTicket(ticket: string):
  | { ok: true; userId: string; exp: number; jti: string; sig: string; payload: string }
  | { ok: false; error: string } {
  const parts = ticket.split(".");
  if (parts.length !== 5 || parts[0] !== "pwd") {
    return { ok: false, error: "enlace inválido" };
  }
  const [, userId, expStr, jti, sig] = parts;
  const exp = Number(expStr);
  if (!userId || !jti || !sig || !Number.isFinite(exp)) {
    return { ok: false, error: "enlace inválido" };
  }
  if (exp < Math.floor(Date.now() / 1000)) {
    return { ok: false, error: "el enlace para crear la contraseña expiró" };
  }
  return {
    ok: true,
    userId,
    exp,
    jti,
    sig,
    payload: guestTicketPayload(userId, exp, jti),
  };
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
