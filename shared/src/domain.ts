/**
 * Fuente de verdad de dominio alineada a Flutter:
 * - AppConstants (lib/core/utils/constants.dart)
 * - PricingConstants (lib/core/domain/pricing_constants.dart)
 * - WorkerJobStatus (lib/core/utils/worker_job_status.dart)
 * - DisputeModel status literals
 */

// —— Roles (AppConstants) ——
export const UserRoles = {
  user: 'user',
  worker: 'worker',
  admin: 'admin',
} as const;

export type UserRole = (typeof UserRoles)[keyof typeof UserRoles];

export const USER_ROLES = [
  UserRoles.user,
  UserRoles.worker,
  UserRoles.admin,
] as const;

// —— Job statuses (AppConstants + PricingConstants) ——
export const JobStatuses = {
  pending: 'pending',
  accepted: 'accepted',
  inProgress: 'in_progress',
  completed: 'completed',
  cancelled: 'cancelled',
  expired: 'expired',
  noShow: 'no_show',
  awaitingPayment: 'awaiting_payment',
  awaitingQuotes: 'awaiting_quotes',
  quoteSelected: 'quote_selected',
  pausedChangeOrder: 'paused_change_order',
  awaitingClientApproval: 'awaiting_client_approval',
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
  none: 'none',
  pending: 'pending',
  authorized: 'authorized',
  held: 'held',
  released: 'released',
  refunded: 'refunded',
} as const;

export type PaymentStatus = (typeof PaymentStatuses)[keyof typeof PaymentStatuses];

export const PAYMENT_STATUSES = Object.values(PaymentStatuses);

// —— Pricing modes (PricingConstants) ——
export const PricingModes = {
  legacy: 'legacy',
  fixedPrice: 'fixed_price',
  hourlyBlock: 'hourly_block',
  openQuote: 'open_quote',
} as const;

export type PricingMode = (typeof PricingModes)[keyof typeof PricingModes];

export const PRICING_MODES = Object.values(PricingModes);

// —— Dispute statuses (DisputeModel) ——
export const DisputeStatuses = {
  open: 'open',
  underReview: 'under_review',
  resolved: 'resolved',
} as const;

export type DisputeStatus =
  (typeof DisputeStatuses)[keyof typeof DisputeStatuses];

export const DISPUTE_STATUSES = Object.values(DisputeStatuses);
