import { JobStatuses, PaymentStatuses } from '../domain';

const JOB_LABELS: Record<string, string> = {
  [JobStatuses.pending]: 'Pendiente de aceptación',
  [JobStatuses.accepted]: 'Aceptado',
  [JobStatuses.enRoute]: 'En camino',
  [JobStatuses.inProgress]: 'En curso',
  [JobStatuses.completed]: 'Completado',
  [JobStatuses.cancelled]: 'Cancelado',
  [JobStatuses.expired]: 'Expirado',
  [JobStatuses.noShow]: 'No asistió',
  [JobStatuses.awaitingPayment]: 'Esperando el pago',
  [JobStatuses.awaitingQuotes]: 'Esperando cotizaciones',
  [JobStatuses.quoteSelected]: 'Cotización elegida',
  [JobStatuses.pausedChangeOrder]: 'Pausado por un cambio',
  [JobStatuses.awaitingClientApproval]: 'Esperando tu conformidad',
};

const JOB_DETAILS: Record<string, string> = {
  [JobStatuses.pending]: 'El profesional todavía puede aceptar o rechazar.',
  [JobStatuses.accepted]: 'El profesional aceptó. El GPS parte cuando marca que va en camino.',
  [JobStatuses.enRoute]: 'Va hacia el domicilio. La app publica su ubicación en primer plano.',
  [JobStatuses.inProgress]: 'El trabajo está en curso. El GPS sigue activo en primer plano.',
  [JobStatuses.completed]: 'El trabajo quedó cerrado.',
  [JobStatuses.cancelled]: 'El trabajo fue cancelado.',
  [JobStatuses.expired]: 'La solicitud venció sin aceptación.',
  [JobStatuses.noShow]: 'Se registró una inasistencia.',
  [JobStatuses.awaitingPayment]: 'El pedido espera el cobro retenido.',
  [JobStatuses.awaitingQuotes]: 'Estás recibiendo cotizaciones.',
  [JobStatuses.quoteSelected]: 'Elegiste una cotización.',
  [JobStatuses.pausedChangeOrder]: 'El alcance cambió y el trabajo está en pausa.',
  [JobStatuses.awaitingClientApproval]: 'Revisa la evidencia y da tu conformidad para liberar el pago.',
};

const PAYMENT_LABELS: Record<string, string> = {
  [PaymentStatuses.none]: 'Sin cobro',
  [PaymentStatuses.pending]: 'Pago pendiente',
  [PaymentStatuses.authorized]: 'Pago autorizado',
  [PaymentStatuses.held]: 'Pago retenido',
  [PaymentStatuses.released]: 'Pago liberado al profesional',
  [PaymentStatuses.refunded]: 'Pago devuelto',
  [PaymentStatuses.voided]: 'Pago anulado',
  [PaymentStatuses.failed]: 'Pago fallido',
};

export function jobStatusLabel(status: string | null | undefined): string {
  if (!status) return 'Sin estado';
  return JOB_LABELS[status] ?? 'Estado no reconocido';
}

export function jobStatusDetail(status: string | null | undefined): string {
  if (!status) return 'Todavía no hay un trabajo asociado.';
  return JOB_DETAILS[status] ?? 'El estado se actualiza cuando cambia el trabajo en la base.';
}

export function paymentStatusLabel(status: string | null | undefined): string {
  if (!status) return 'Sin información de pago';
  return PAYMENT_LABELS[status] ?? 'Estado de pago no reconocido';
}
