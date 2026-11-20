/**
 * createWebpaySession y fetchPaymentStatus con un cliente falso (sin red ni Transbank).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { AppSupabase } from '../client';
import { createWebpaySession, fetchPaymentStatus } from './webpay.ts';

function fake(result: { data: unknown; error: unknown }) {
  const calls: { name: string; body: Record<string, unknown> }[] = [];
  const client = {
    functions: {
      invoke: async (name: string, opts: { body: Record<string, unknown> }) => {
        calls.push({ name, body: opts.body });
        return result;
      },
    },
  } as unknown as AppSupabase;
  return { client, calls };
}

describe('createWebpaySession', () => {
  it('envía el monto y usa embed por defecto; no expone el token si no viene', async () => {
    const { client, calls } = fake({
      data: { paymentId: 'p1', buyOrder: 'MWA1', redirectUrl: 'https://x/handoff?t=1', ambiente: 'integration' },
      error: null,
    });
    const r = await createWebpaySession(client, { jobId: 'j1', amountClp: 20000 });
    assert.equal(calls[0].name, 'webpay-create');
    assert.equal(calls[0].body.amountClp, 20000);
    assert.equal(calls[0].body.presentMode, 'embed');
    assert.equal(r.redirectUrl, 'https://x/handoff?t=1');
    assert.equal(r.token, undefined);
    assert.equal(r.ambiente, 'integration');
  });

  it('falla si la función no devuelve redirectUrl', async () => {
    const { client } = fake({ data: { paymentId: 'p1' }, error: null });
    await assert.rejects(createWebpaySession(client, { jobId: 'j1', amountClp: 1 }), /redirectUrl/);
  });

  it('falla con el error del cuerpo (monto que no coincide)', async () => {
    const { client } = fake({ data: { error: 'Monto 1 no coincide con tarifa/cotización 20000' }, error: null });
    await assert.rejects(createWebpaySession(client, { jobId: 'j1', amountClp: 1 }), /no coincide/);
  });

  it('respeta presentMode redirect y la orden de cambio', async () => {
    const { client, calls } = fake({ data: { redirectUrl: 'https://x' }, error: null });
    const r = await createWebpaySession(client, {
      jobId: 'j1',
      amountClp: 5000,
      presentMode: 'redirect',
      changeOrderId: 'oc1',
    });
    assert.equal(calls[0].body.changeOrderId, 'oc1');
    assert.equal(r.presentMode, 'redirect');
  });
});

describe('fetchPaymentStatus', () => {
  it('devuelve id, estado y trabajo', async () => {
    const { client, calls } = fake({
      data: { payment: { id: 'p1', estado: 'retenido', id_trabajo: 'j1' } },
      error: null,
    });
    const r = await fetchPaymentStatus(client, 'p1', 'j1');
    assert.equal(calls[0].name, 'webpay-status');
    assert.deepEqual(r, { id: 'p1', estado: 'retenido', id_trabajo: 'j1' });
  });

  it('devuelve null si no hay pago', async () => {
    const { client } = fake({ data: { error: 'no encontrado' }, error: null });
    assert.equal(await fetchPaymentStatus(client, 'p1'), null);
  });
});
