import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
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
} from './domain.ts';

describe('domain constants', () => {
  it('expone roles alineados a AppConstants (ES)', () => {
    assert.deepEqual(UserRoles, {
      user: 'usuario',
      worker: 'trabajador',
      admin: 'administrador',
    });
    assert.deepEqual(USER_ROLES, ['usuario', 'trabajador', 'administrador']);
  });

  it('incluye job statuses de AppConstants y PricingConstants (ES)', () => {
    assert.equal(JobStatuses.pending, 'pendiente');
    assert.equal(JobStatuses.inProgress, 'en_curso');
    assert.equal(JobStatuses.awaitingPayment, 'esperando_pago');
    assert.equal(
      JobStatuses.awaitingClientApproval,
      'esperando_aprobacion_cliente',
    );
    assert.ok(JOB_STATUSES.includes('cotizacion_seleccionada'));
    assert.ok(JOB_STATUSES.includes('pausado_orden_cambio'));
  });

  it('expone payment statuses y pricing modes (ES)', () => {
    assert.equal(PaymentStatuses.authorized, 'autorizado');
    assert.ok(PAYMENT_STATUSES.includes('retenido'));
    assert.equal(PricingModes.fixedPrice, 'precio_fijo');
    assert.deepEqual(PRICING_MODES, [
      'legado',
      'precio_fijo',
      'bloque_horas',
      'cotizacion_abierta',
    ]);
  });

  it('expone dispute statuses (ES)', () => {
    assert.equal(DisputeStatuses.underReview, 'en_revision');
    assert.deepEqual(DISPUTE_STATUSES, [
      'abierta',
      'en_revision',
      'resuelta',
    ]);
  });
});

describe('isWorkerActiveJobStatus', () => {
  it('espeja WorkerJobStatus.activeStatuses (ES)', () => {
    assert.deepEqual(WORKER_ACTIVE_JOB_STATUSES, [
      'aceptado',
      'en_curso',
      'esperando_aprobacion_cliente',
      'esperando_pago',
      'pausado_orden_cambio',
      'cotizacion_seleccionada',
    ]);

    for (const status of WORKER_ACTIVE_JOB_STATUSES) {
      assert.equal(isWorkerActiveJobStatus(status), true);
    }
  });

  it('rechaza estados no activos', () => {
    assert.equal(isWorkerActiveJobStatus('pendiente'), false);
    assert.equal(isWorkerActiveJobStatus('completado'), false);
    assert.equal(isWorkerActiveJobStatus('cancelado'), false);
    assert.equal(isWorkerActiveJobStatus('esperando_cotizaciones'), false);
    assert.equal(isWorkerActiveJobStatus(''), false);
  });
});
