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

  it('deja el Webpay del invitado para verificar y crear clave', () => {
    const result = parseCheckoutReturn(
      '?pago=ok&paymentId=pay-1&jobId=job-1&invitado=1&alta=pwd.token',
    );
    assert.equal(result.kind, 'verify');
    if (result.kind === 'verify') {
      assert.equal(result.guest, true);
      assert.equal(result.passwordToken, 'pwd.token');
      assert.equal(result.paymentId, 'pay-1');
    }
  });

  it('avisa en español cuando el invitado cancela en Webpay', () => {
    const result = parseCheckoutReturn('?pago=fail');
    assert.equal(result.kind, 'failed');
    if (result.kind === 'failed') {
      assert.equal(result.message, 'Pago cancelado. No se realizó ningún cargo.');
    }
  });

  it('explica un cobro rechazado', () => {
    const result = parseCheckoutReturn('?pago=fail&motivo=cobro');
    assert.equal(result.kind, 'failed');
    if (result.kind === 'failed') {
      assert.match(result.message, /no autorizó/);
    }
  });
});
