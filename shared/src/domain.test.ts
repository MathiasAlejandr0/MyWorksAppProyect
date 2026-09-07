import { describe, expect, it } from 'vitest';
import {
  DISPUTE_STATUSES,
  DisputeStatuses,
  isWorkerActiveJobStatus,
  JOB_STATUSES,
  JobStatuses,
  PAYMENT_STATUSES,
  PaymentStatuses,
  PRICING_MODES,
  PricingModes,
  USER_ROLES,
  UserRoles,
  WORKER_ACTIVE_JOB_STATUSES,
} from './domain';

describe('domain constants', () => {
  it('expone roles alineados a AppConstants', () => {
    expect(UserRoles).toEqual({
      user: 'user',
      worker: 'worker',
      admin: 'admin',
    });
    expect(USER_ROLES).toEqual(['user', 'worker', 'admin']);
  });

  it('incluye job statuses de AppConstants y PricingConstants', () => {
    expect(JobStatuses.pending).toBe('pending');
    expect(JobStatuses.inProgress).toBe('in_progress');
    expect(JobStatuses.awaitingPayment).toBe('awaiting_payment');
    expect(JobStatuses.awaitingClientApproval).toBe('awaiting_client_approval');
    expect(JOB_STATUSES).toContain('quote_selected');
    expect(JOB_STATUSES).toContain('paused_change_order');
  });

  it('expone payment statuses y pricing modes', () => {
    expect(PaymentStatuses.authorized).toBe('authorized');
    expect(PAYMENT_STATUSES).toContain('held');
    expect(PricingModes.fixedPrice).toBe('fixed_price');
    expect(PRICING_MODES).toEqual([
      'legacy',
      'fixed_price',
      'hourly_block',
      'open_quote',
    ]);
  });

  it('expone dispute statuses', () => {
    expect(DisputeStatuses.underReview).toBe('under_review');
    expect(DISPUTE_STATUSES).toEqual(['open', 'under_review', 'resolved']);
  });
});

describe('isWorkerActiveJobStatus', () => {
  it('espeja WorkerJobStatus.activeStatuses', () => {
    expect(WORKER_ACTIVE_JOB_STATUSES).toEqual([
      'accepted',
      'in_progress',
      'awaiting_client_approval',
      'awaiting_payment',
      'paused_change_order',
      'quote_selected',
    ]);

    for (const status of WORKER_ACTIVE_JOB_STATUSES) {
      expect(isWorkerActiveJobStatus(status)).toBe(true);
    }
  });

  it('rechaza estados no activos', () => {
    expect(isWorkerActiveJobStatus('pending')).toBe(false);
    expect(isWorkerActiveJobStatus('completed')).toBe(false);
    expect(isWorkerActiveJobStatus('cancelled')).toBe(false);
    expect(isWorkerActiveJobStatus('awaiting_quotes')).toBe(false);
    expect(isWorkerActiveJobStatus('')).toBe(false);
  });
});
