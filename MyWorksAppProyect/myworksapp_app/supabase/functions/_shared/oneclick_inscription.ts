import { tbkOneclickFinish } from "./tbk.ts";

/** Lo mínimo que se usa del cliente de servicio; así se prueba sin Supabase. */
type Admin = {
  from: (table: string) => {
    update: (values: Record<string, unknown>) => {
      eq: (column: string, value: string) => {
        eq: (column: string, value: string) => PromiseLike<{ error: unknown }>;
      };
    };
  };
};

export function cardLast4(cardNumber: unknown): string {
  const digits = String(cardNumber || "").replace(/\D/g, "");
  return digits.slice(-4);
}

export type SavedCardRow = {
  estado?: string | null;
  tbk_user?: string | null;
  token_inscripcion?: string | null;
  ultimos4?: string | null;
  tipo_tarjeta?: string | null;
  username?: string | null;
};

export function isEnrolled(card: SavedCardRow | null | undefined): boolean {
  return card?.estado === "activa" && Boolean(card.tbk_user);
}

/**
 * Si el cliente ya pagó la inscripción en Transbank pero la vuelta nunca llegó
 * al servidor (WebView cerrado, sin red, otra pestaña), la tarjeta quedaba
 * pendiente para siempre y cada pedido pedía inscribirla de nuevo.
 * Transbank deja consultar la inscripción con el mismo token, así que se cierra aquí.
 * Antes de que el cliente termine responde -96 y no pasa nada.
 */
export async function activatePendingInscription(
  admin: Admin,
  userId: string,
  card: SavedCardRow | null | undefined,
  finish: (token: string) => Promise<Record<string, unknown>> = tbkOneclickFinish,
): Promise<SavedCardRow | null> {
  if (!card || isEnrolled(card)) return card ?? null;
  const token = String(card.token_inscripcion || "").trim();
  if (card.estado !== "pendiente" || !token) return card;

  let finished: Record<string, unknown>;
  try {
    finished = await finish(token);
  } catch {
    return card;
  }
  const tbkUser = String(finished.tbk_user || "");
  if (Number(finished.response_code) !== 0 || !tbkUser) return card;

  const next = {
    estado: "activa",
    tbk_user: tbkUser,
    tipo_tarjeta: String(finished.card_type || ""),
    ultimos4: cardLast4(finished.card_number),
    actualizado_en: new Date().toISOString(),
  };
  const { error } = await admin
    .from("metodos_pago_oneclick")
    .update(next)
    .eq("id_usuario", userId)
    .eq("token_inscripcion", token);
  if (error) return card;
  return { ...card, ...next };
}
