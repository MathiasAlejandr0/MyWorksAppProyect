import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertTransbankUrl,
  checkoutLane,
  orderConfirmedMessage,
  parseOneclickCharge,
} from './oneclick.ts';

describe('oneclick', () => {
  it('arma el mensaje de pedido confirmado', () => {
    assert.equal(
      orderConfirmedMessage({
        amountClp: 35000,
        last4: '6623',
        workerName: 'Ana',
      }),
      'Pedido confirmado. Se descontará $35.000 de tu tarjeta •••• 6623. Ana ya puede aceptar el pedido.',
    );
  });

  it('rechaza una URL que no es Transbank', () => {
    assert.throws(
      () => assertTransbankUrl('https://ejemplo.cl/pago'),
      /URL de pago inválida/,
    );
  });

  it('parsea cobro inmediato y no pide redirect', () => {
    const result = parseOneclickCharge({
      charged: true,
      paymentId: 'p1',
      jobId: 'j1',
      amount: 12000,
      last4: '6623',
      cardType: 'Visa',
    });
    assert.equal(result.charged, true);
    if (result.charged) assert.equal(result.paymentId, 'p1');
  });

  it('sin tarjeta no abre Transbank en el navegador', () => {
    const result = parseOneclickCharge({
      needsCard: true,
      url: 'https://evil.example/robo',
      token: 'no-debe-usarse',
    });
    assert.deepEqual(result, { charged: false, needsCard: true });
  });

  it('manda a Webpay Plus a quien no tiene tarjeta inscrita', () => {
    assert.equal(checkoutLane({ signedIn: false, cardEnrolled: false }), 'webpay');
    assert.equal(checkoutLane({ signedIn: true, cardEnrolled: false }), 'webpay');
    assert.equal(checkoutLane({ signedIn: true, cardEnrolled: true }), 'charge');
  });
});
