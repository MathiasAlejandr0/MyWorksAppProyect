export const VerificationStatuses = [
  'pendiente',
  'en_revision',
  'verificado',
  'rechazado',
] as const;

export type VerificationStatus = (typeof VerificationStatuses)[number];

export function isVerificationStatus(value: string): value is VerificationStatus {
  return (VerificationStatuses as readonly string[]).includes(value);
}

export function verificationLabel(status: string | null | undefined): string {
  switch (status) {
    case 'en_revision':
      return 'En revisión';
    case 'verificado':
      return 'Verificado';
    case 'rechazado':
      return 'Rechazado';
    default:
      return 'Pendiente';
  }
}
