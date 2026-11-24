import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { AppSupabase } from '../client';
import {
  canClientCancel,
  canClientRate,
  cancelJobAsClient,
  rateJobAsClient,
  validateRating,
} from './clientActions.ts';

type Call = { kind: string; name: string; payload?: unknown };

function fakeClient(opts: { refundError?: string; rpcError?: string; insertError?: { code?: string; message: string } }) {
  const calls: Call[] = [];
  const client = {
    functions: {
      invoke: async (name: string, init: { body: unknown }) => {
        calls.push({ kind: 'fn', name, payload: init.body });
        return opts.refundError
          ? { data: { error: opts.refundError }, error: null }
          : { data: { skipped: true }, error: null };
      },
    },
    rpc: async (name: string, payload: unknown) => {
      calls.push({ kind: 'rpc', name, payload });
      return { data: null, error: opts.rpcError ? { message: opts.rpcError } : null };
    },
    from: (table: string) => ({
      insert: async (payload: unknown) => {
        calls.push({ kind: 'insert', name: table, payload });
        return { error: opts.insertError ?? null };
      },
    }),
  } as unknown as AppSupabase;
  return { client, calls };
}

describe('Acciones del cliente en la web', () => {
  it('cancela antes de aceptar, en la conformidad, o si el cliente abrió la disputa', () => {
    assert.equal(canClientCancel('pendiente'), true);
    assert.equal(canClientCancel('esperando_pago'), true);
    assert.equal(canClientCancel('esperando_aprobacion_cliente'), true);
    assert.equal(canClientCancel('aceptado'), false);
    assert.equal(canClientCancel('completado'), false);
    assert.equal(
      canClientCancel('en_curso', { disputeOpen: true, disputeOpenedBy: 'cliente', userId: 'cliente' }),
      true,
    );
    assert.equal(
      canClientCancel('en_curso', { disputeOpen: true, disputeOpenedBy: 'pro', userId: 'cliente' }),
      false,
    );
  });

  it('si el aviso no se guarda, no dice que todo salió bien', async () => {
    const { client } = fakeClient({ insertError: { message: 'permission denied' } });
    await assert.rejects(
      cancelJobAsClient(client, { jobId: 'j', userId: 'u', workerId: 'w', reason: 'Ya no lo necesito' }),
      /se canceló/,
    );
  });

  it('devuelve el pago antes de cancelar y avisa al profesional', async () => {
    const { client, calls } = fakeClient({});
    await cancelJobAsClient(client, { jobId: 'j', userId: 'u', workerId: 'w', reason: 'Ya no lo necesito' });
    assert.deepEqual(
      calls.map((c) => `${c.kind}:${c.name}`),
      ['fn:webpay-refund-cancellation', 'rpc:transicionar_trabajo', 'insert:cancelaciones_trabajo', 'insert:notificaciones'],
    );
  });

  it('si la devolución falla no cancela', async () => {
    const { client, calls } = fakeClient({ refundError: 'Hay una disputa abierta' });
    await assert.rejects(
      cancelJobAsClient(client, { jobId: 'j', userId: 'u', workerId: null, reason: 'x' }),
      /disputa abierta/,
    );
    assert.equal(calls.some((c) => c.kind === 'rpc'), false);
  });

  it('exige motivo', async () => {
    const { client } = fakeClient({});
    await assert.rejects(
      cancelJobAsClient(client, { jobId: 'j', userId: 'u', workerId: null, reason: '  ' }),
      /por qué/,
    );
  });

  it('califica de 1 a 5 un trabajo completado una sola vez', async () => {
    assert.equal(canClientRate('completado', false), true);
    assert.equal(canClientRate('completado', true), false);
    assert.equal(canClientRate('en_curso', false), false);
    assert.equal(validateRating(0, ''), 'Elige de 1 a 5 estrellas.');
    assert.equal(validateRating(5, 'Excelente'), null);

    const ok = fakeClient({});
    await rateJobAsClient(ok.client, { jobId: 'j', userId: 'u', workerId: 'w', score: 5, comment: 'Bien' });
    const insert = ok.calls.find((c) => c.kind === 'insert');
    assert.equal(insert?.name, 'calificaciones');
    assert.equal((insert?.payload as { direccion: string }).direccion, 'cliente_a_trabajador');

    const dup = fakeClient({ insertError: { code: '23505', message: 'duplicate key' } });
    await assert.rejects(
      rateJobAsClient(dup.client, { jobId: 'j', userId: 'u', workerId: 'w', score: 4, comment: '' }),
      /Ya calificaste/,
    );
    const rls = fakeClient({ insertError: { message: 'new row violates row-level security policy' } });
    await assert.rejects(
      rateJobAsClient(rls.client, { jobId: 'j', userId: 'u', workerId: 'w', score: 4, comment: '' }),
      /completado y sin disputa/,
    );
  });
});
