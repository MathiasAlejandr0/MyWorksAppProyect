/**
 * Fuente de verdad de dominio alineada a Flutter (códigos BD en español):
 * - AppConstants (lib/core/utils/constants.dart)
 * - PricingConstants (lib/core/domain/pricing_constants.dart)
 * - WorkerJobStatus (lib/core/utils/worker_job_status.dart)
 * - DisputeModel status literals
 */

// —— Roles (AppConstants) ——
export const UserRoles = {
  user: 'usuario',
  worker: 'trabajador',
  admin: 'administrador',
} as const;

export type UserRole = (typeof UserRoles)[keyof typeof UserRoles];

export const USER_ROLES = [
  UserRoles.user,
  UserRoles.worker,
  UserRoles.admin,
] as const;

// —— Job statuses (AppConstants + PricingConstants) ——
export const JobStatuses = {
  pending: 'pendiente',
  accepted: 'aceptado',
  inProgress: 'en_curso',
  completed: 'completado',
  cancelled: 'cancelado',
  expired: 'expirado',
  noShow: 'no_asistio',
  awaitingPayment: 'esperando_pago',
  awaitingQuotes: 'esperando_cotizaciones',
  quoteSelected: 'cotizacion_seleccionada',
  pausedChangeOrder: 'pausado_orden_cambio',
  awaitingClientApproval: 'esperando_aprobacion_cliente',
} as const;

export type JobStatus = (typeof JobStatuses)[keyof typeof JobStatuses];

export const JOB_STATUSES = Object.values(JobStatuses);

/**
 * Espejo de WorkerJobStatus.activeStatuses:
 * estados que mantienen al profesional "ocupado".
 */
export const WORKER_ACTIVE_JOB_STATUSES: readonly JobStatus[] = [
  JobStatuses.accepted,
  JobStatuses.inProgress,
  JobStatuses.awaitingClientApproval,
  JobStatuses.awaitingPayment,
  JobStatuses.pausedChangeOrder,
  JobStatuses.quoteSelected,
];

export function isWorkerActiveJobStatus(status: string): boolean {
  return (WORKER_ACTIVE_JOB_STATUSES as readonly string[]).includes(status);
}

// —— Payment statuses (PricingConstants / PaymentModel) ——
export const PaymentStatuses = {
  none: 'ninguno',
  pending: 'pendiente',
  authorized: 'autorizado',
  held: 'retenido',
  released: 'liberado',
  refunded: 'reembolsado',
} as const;

export type PaymentStatus = (typeof PaymentStatuses)[keyof typeof PaymentStatuses];

export const PAYMENT_STATUSES = Object.values(PaymentStatuses);

// —— Pricing modes (PricingConstants) ——
export const PricingModes = {
  legacy: 'legado',
  fixedPrice: 'precio_fijo',
  hourlyBlock: 'bloque_horas',
  openQuote: 'cotizacion_abierta',
} as const;

export type PricingMode = (typeof PricingModes)[keyof typeof PricingModes];

export const PRICING_MODES = Object.values(PricingModes);

// —— Dispute statuses (DisputeModel) ——
export const DisputeStatuses = {
  open: 'abierta',
  underReview: 'en_revision',
  resolved: 'resuelta',
} as const;

export type DisputeStatus =
  (typeof DisputeStatuses)[keyof typeof DisputeStatuses];

export const DISPUTE_STATUSES = Object.values(DisputeStatuses);
