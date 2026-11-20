/**
 * Liberación manual y lista de pagos retenidos con un cliente falso (sin red).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { AppSupabase } from '../client';
import { listHeldPayments, releaseEscrowManual } from './payout.ts';

type Invoke = { name: string; body: Record<string, unknown> };

function fakeFunctions(result: { data: unknown; error: { message?: string } | null }) {
  const calls: Invoke[] = [];
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

function fakeView(rows: Record<string, unknown>[], error: { message: string } | null = null) {
  const seen: { table?: string; estados?: unknown; limit?: number } = {};
  const chain = {
    select: () => chain,
    in: (_col: string, values: unknown) => {
      seen.estados = values;
      return chain;
    },
    order: () => chain,
    limit: async (n: number) => {
      seen.limit = n;
      return { data: rows, error };
    },
  };
  const client = {
    from: (table: string) => {
      seen.table = table;
      return chain;
    },
  } as unknown as AppSupabase;
  return { client, seen };
}

describe('releaseEscrowManual', () => {
  it('llama a webpay-release con confirmación externa y proveedor manual', async () => {
    const { client, calls } = fakeFunctions({
      data: { payment: { id: 'p1', estado: 'liberado' }, liquidacion: { id: 'l1' } },
      error: null,
    });
    const r = await releaseEscrowManual(client, {
      paymentId: 'p1',
      transferRef: 'TRX-1',
      confirmExternal: true,
    });
    assert.equal(calls.length, 1);
    assert.equal(calls[0].name, 'webpay-release');
    assert.equal(calls[0].body.confirmExternal, true);
    assert.equal(calls[0].body.provider, 'manual');
    assert.equal(calls[0].body.transferRef, 'TRX-1');
    assert.deepEqual(r, { paymentId: 'p1', liquidacionId: 'l1', status: 'liberado' });
  });

  it('propaga el error de la función', async () => {
    const { client } = fakeFunctions({ data: null, error: { message: 'Solo administradores' } });
    await assert.rejects(
      releaseEscrowManual(client, { paymentId: 'p1', transferRef: 'x', confirmExternal: true }),
      /Solo administradores/,
    );
  });

  it('rechaza una respuesta con error en el cuerpo', async () => {
    const { client } = fakeFunctions({ data: { error: 'Pago no retenido' }, error: null });
    await assert.rejects(
      releaseEscrowManual(client, { paymentId: 'p1', transferRef: 'x', confirmExternal: true }),
      /Pago no retenido/,
    );
  });

  it('sin datos de pago devuelve el id pedido y estado liberado', async () => {
    const { client } = fakeFunctions({ data: {}, error: null });
    const r = await releaseEscrowManual(client, {
      paymentId: 'p9',
      transferRef: 'x',
      confirmExternal: true,
      provider: 'khipu',
    });
    assert.equal(r.paymentId, 'p9');
    assert.equal(r.status, 'liberado');
    assert.equal(r.liquidacionId, undefined);
  });
});

describe('listHeldPayments', () => {
  it('lee la vista cobros_profesional solo con pagos retenidos o autorizados', async () => {
    const { client, seen } = fakeView([
      {
        id_pago: 'p1',
        id_trabajo: 'j1',
        id_trabajador: 'w1',
        bruto_clp: 20000,
        comision_clp: 1000,
        neto_clp: 19000,
        estado_pago: 'retenido',
        creado_en: '2026-11-18T00:00:00Z',
      },
    ]);
    const rows = await listHeldPayments(client);
    assert.equal(seen.table, 'cobros_profesional');
    assert.deepEqual(seen.estados, ['retenido', 'autorizado']);
    assert.equal(seen.limit, 100);
    assert.equal(rows.length, 1);
    assert.equal(rows[0].feeClp, 1000);
    assert.equal(rows[0].netClp, 19000);
  });

  it('lanza el mensaje de la base si la consulta falla', async () => {
    const { client } = fakeView([], { message: 'permission denied for view cobros_profesional' });
    await assert.rejects(listHeldPayments(client), /permission denied/);
  });
});
