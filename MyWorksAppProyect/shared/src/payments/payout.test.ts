/**
 * Contrato payout providers (sin llamadas de red).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { getPayoutProviderStatus, toHeldPaymentRow } from './payout.ts';

describe('payout providers', () => {
  it('manual está listo', () => {
    const s = getPayoutProviderStatus('manual');
    assert.equal(s.ready, true);
  });

  it('khipu y fintoc quedan stub hasta empresa', () => {
    assert.equal(getPayoutProviderStatus('khipu').ready, false);
    assert.equal(getPayoutProviderStatus('fintoc').ready, false);
  });
});

describe('pagos por liquidar', () => {
  it('lleva bruto, comisión y neto tal como los entrega la base', () => {
    const row = toHeldPaymentRow({
      id_pago: 'p1',
      id_trabajo: 'j1',
      id_trabajador: 'w1',
      bruto_clp: 32000,
      comision_clp: 1600,
      neto_clp: 30400,
      estado_pago: 'retenido',
      creado_en: '2026-11-18 00:30:36+00',
    });
    assert.equal(row.amountClp, 32000);
    assert.equal(row.feeClp, 1600);
    assert.equal(row.netClp, 30400);
    assert.equal(row.workerId, 'w1');
    assert.equal(row.status, 'retenido');
  });

  it('sin neto en la fila, el neto es bruto menos comisión', () => {
    const row = toHeldPaymentRow({
      id_pago: 'p2',
      id_trabajo: 'j2',
      bruto_clp: 12000,
      comision_clp: 1000,
      estado_pago: 'autorizado',
    });
    assert.equal(row.netClp, 11000);
    assert.equal(row.workerId, null);
  });
});
