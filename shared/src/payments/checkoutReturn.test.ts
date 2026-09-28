import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { parseCheckoutReturn } from './checkoutReturn.ts';

describe('parseCheckoutReturn', () => {
  it('ignora la vuelta de una inscripción de tarjeta', () => {
    assert.deepEqual(parseCheckoutReturn('?tarjeta=ok'), { kind: 'card' });
  });

  it('confirma el pedido con seguimiento', () => {
    assert.deepEqual(
      parseCheckoutReturn('?pago=ok&tracking=1&amount=35000&last4=6623&jobId=job-1&paymentId=pay-9'),
      {
        kind: 'tracked',
        jobId: 'job-1',
        paymentId: 'pay-9',
        amount: 35000,
        last4: '6623',
      },
    );
  });

  it('deja el Webpay del invitado para verificar', () => {
    assert.equal(
      parseCheckoutReturn('?pago=ok&paymentId=pay-1').kind,
      'verify',
    );
  });

  it('explica un cobro rechazado', () => {
    const result = parseCheckoutReturn('?pago=fail&motivo=cobro');
    assert.equal(result.kind, 'failed');
    if (result.kind === 'failed') {
      assert.match(result.message, /no autorizó/);
    }
  });
});
