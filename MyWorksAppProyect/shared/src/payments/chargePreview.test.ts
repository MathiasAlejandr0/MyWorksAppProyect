import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  chargePreviewBlockedMessage,
  parseJobChargePreview,
  payableTotalClp,
} from './chargePreview.ts';

describe('cobro que se muestra', () => {
  it('solo habilita el pago con el entero del servidor', () => {
    assert.equal(payableTotalClp(74829), 74829);
    assert.equal(payableTotalClp(74829.4), 74829);
    assert.equal(payableTotalClp(null), null);
    assert.equal(payableTotalClp(0), null);
    assert.equal(payableTotalClp(Number.NaN), null);
  });

  it('no inventa un total si el resumen viene incompleto', () => {
    assert.equal(parseJobChargePreview(null), null);
    assert.equal(parseJobChargePreview({ total_clp: 1000 }), null);
    assert.deepEqual(
      parseJobChargePreview({
        total_clp: 74829,
        tarifa_clp: 65000,
        traslado_clp: 9829,
        comision_clp: 3741,
        neto_clp: 71088,
      }),
      {
        totalClp: 74829,
        serviceClp: 65000,
        transportClp: 9829,
        feeClp: 3741,
        payoutClp: 71088,
      },
    );
  });

  it('el aviso de reintento no pide confirmar otra vez', () => {
    assert.equal(chargePreviewBlockedMessage.includes('Confirma otra vez'), false);
  });
});
