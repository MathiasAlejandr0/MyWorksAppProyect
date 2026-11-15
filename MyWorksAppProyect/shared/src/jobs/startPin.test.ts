import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it } from 'node:test';
import type { AppSupabase } from '../client';
import {
  clientShouldShowStartPin,
  fetchClientStartPin,
  normalizeStartPin,
  startJobWithPin,
} from './startPin.ts';

function client(rpc: AppSupabase['rpc']): AppSupabase {
  return { rpc } as AppSupabase;
}

describe('PIN de inicio', () => {
  it('el cliente lo ve al aceptar o cuando el profesional va en camino', () => {
    assert.equal(clientShouldShowStartPin('aceptado'), true);
    assert.equal(clientShouldShowStartPin('en_camino'), true);
    assert.equal(clientShouldShowStartPin('en_curso'), false);
    assert.equal(clientShouldShowStartPin('pendiente'), false);
  });

  it('rechaza un PIN que no son 4 dígitos', () => {
    assert.equal(normalizeStartPin(' 4829 '), '4829');
    assert.throws(() => normalizeStartPin('12'), /PIN de 4 dígitos/);
    assert.throws(() => normalizeStartPin('12ab'), /PIN de 4 dígitos/);
  });

  it('comprueba el PIN y recién ahí pasa a en curso por el RPC', async () => {
    const calls: Array<{ fn: string; args: Record<string, string> }> = [];
    await startJobWithPin(
      client(async (fn: string, args: Record<string, string>) => {
        calls.push({ fn, args });
        if (fn === 'intentar_pin_inicio') return { data: { ok: true }, error: null };
        return { error: null };
      }),
      'job-1',
      '4829',
    );
    assert.deepEqual(calls, [
      {
        fn: 'intentar_pin_inicio',
        args: { p_trabajo_id: 'job-1', p_pin: '4829' },
      },
      {
        fn: 'transicionar_trabajo',
        args: {
          p_trabajo_id: 'job-1',
          p_nuevo_estado: 'en_curso',
          p_pin: '4829',
        },
      },
    ]);
  });

  it('propaga los intentos que quedan y no cambia el estado', async () => {
    const calls: string[] = [];
    await assert.rejects(
      startJobWithPin(
        client(async (fn: string) => {
          calls.push(fn);
          return {
            data: { ok: false, mensaje: 'PIN incorrecto. Te quedan 3 intentos.' },
            error: null,
          };
        }),
        'job-1',
        '0000',
      ),
      /Te quedan 3 intentos/,
    );
    assert.deepEqual(calls, ['intentar_pin_inicio']);
  });

  it('lee el PIN del cliente y ignora un valor vacío', async () => {
    const pin = await fetchClientStartPin(
      client(async () => ({ data: '4829', error: null })),
      'job-1',
    );
    assert.equal(pin, '4829');
    const hidden = await fetchClientStartPin(
      client(async () => ({ data: null, error: null })),
      'job-1',
    );
    assert.equal(hidden, null);
  });
});

describe('migración de PIN', () => {
  const sql = readFileSync(
    join(
      dirname(fileURLToPath(import.meta.url)),
      '../../../myworksapp_app/supabase/migrations/20261115180001_inicio_trabajo_requiere_pin.sql',
    ),
    'utf8',
  );

  it('exige el PIN en el RPC, bloquea el UPDATE directo y limita intentos', () => {
    assert.match(sql, /SECURITY DEFINER/);
    assert.match(sql, /intentar_pin_inicio/);
    assert.match(sql, /interval '15 minutes'/);
    assert.match(sql, /v_fallos >= 5/);
    assert.match(sql, /trabajos_bloquear_en_curso_directo/);
    assert.match(sql, /mwa\.pin_inicio_ok/);
    assert.match(sql, /pin_ok_hasta/);
    assert.match(sql, /REVOKE UPDATE, DELETE ON TABLE public\.trabajos/);
    assert.match(sql, /aceptado', 'en_camino'/);
    assert.match(sql, /esta migración no agrega esa ventana/);
    assert.match(sql, /PIN incorrecto\. Te quedan %s intentos\./);
    assert.match(sql, /INSERT INTO public\.intentos_pin_inicio/);
  });

  it('webpay y la reconciliación no escriben en_curso en esta migración', () => {
    assert.match(
      sql,
      /webpay-commit, webpay-reconcile y\n-- confirmar_trabajo_tras_captura no escriben en_curso/,
    );
    assert.doesNotMatch(sql, /CREATE OR REPLACE FUNCTION public\.confirmar_trabajo_tras_captura/);
  });
});
