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
  it('expone roles alineados a AppConstants (ES)', () => {
    expect(UserRoles).toEqual({
      user: 'usuario',
      worker: 'trabajador',
      admin: 'administrador',
    });
    expect(USER_ROLES).toEqual(['usuario', 'trabajador', 'administrador']);
  });

  it('incluye job statuses de AppConstants y PricingConstants (ES)', () => {
    expect(JobStatuses.pending).toBe('pendiente');
    expect(JobStatuses.inProgress).toBe('en_curso');
    expect(JobStatuses.awaitingPayment).toBe('esperando_pago');
    expect(JobStatuses.awaitingClientApproval).toBe(
      'esperando_aprobacion_cliente',
    );
    expect(JOB_STATUSES).toContain('cotizacion_seleccionada');
    expect(JOB_STATUSES).toContain('pausado_orden_cambio');
  });

  it('expone payment statuses y pricing modes (ES)', () => {
    expect(PaymentStatuses.authorized).toBe('autorizado');
    expect(PAYMENT_STATUSES).toContain('retenido');
    expect(PricingModes.fixedPrice).toBe('precio_fijo');
    expect(PRICING_MODES).toEqual([
      'legado',
      'precio_fijo',
      'bloque_horas',
      'cotizacion_abierta',
    ]);
  });

  it('expone dispute statuses (ES)', () => {
    expect(DisputeStatuses.underReview).toBe('en_revision');
    expect(DISPUTE_STATUSES).toEqual(['abierta', 'en_revision', 'resuelta']);
  });
});

describe('isWorkerActiveJobStatus', () => {
  it('espeja WorkerJobStatus.activeStatuses (ES)', () => {
    expect(WORKER_ACTIVE_JOB_STATUSES).toEqual([
      'aceptado',
      'en_curso',
      'esperando_aprobacion_cliente',
      'esperando_pago',
      'pausado_orden_cambio',
      'cotizacion_seleccionada',
    ]);

    for (const status of WORKER_ACTIVE_JOB_STATUSES) {
      expect(isWorkerActiveJobStatus(status)).toBe(true);
    }
  });

  it('rechaza estados no activos', () => {
    expect(isWorkerActiveJobStatus('pendiente')).toBe(false);
    expect(isWorkerActiveJobStatus('completado')).toBe(false);
    expect(isWorkerActiveJobStatus('cancelado')).toBe(false);
    expect(isWorkerActiveJobStatus('esperando_cotizaciones')).toBe(false);
    expect(isWorkerActiveJobStatus('')).toBe(false);
  });
});
