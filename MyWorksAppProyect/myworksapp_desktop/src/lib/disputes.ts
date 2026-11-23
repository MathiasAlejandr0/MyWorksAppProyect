/** Estados que disputa_esta_activa deja en la cola de la consola. */
export const OPEN_DISPUTE_STATES = [
  'abierta',
  'en_revision',
  'requiere_humano',
  'reembolso_pendiente',
] as const;

export type OpenDisputeState = (typeof OPEN_DISPUTE_STATES)[number];

export function isOpenDispute(estado: string | null | undefined): boolean {
  return (OPEN_DISPUTE_STATES as readonly string[]).includes(estado ?? '');
}
