/** 15 minutos. Un solo uso, atado al navegador que inició el checkout. */
export const GUEST_TICKET_TTL_SEC = 15 * 60;

export function shouldIssueGuestPasswordTicket(input: {
  alreadyHeld: boolean;
  approved: boolean;
  guest: boolean;
}): boolean {
  return input.guest && input.approved && !input.alreadyHeld;
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
