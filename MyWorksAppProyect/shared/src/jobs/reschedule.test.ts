import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { AppSupabase } from '../client';
import {
  canProposeReschedule,
  canRespondReschedule,
  mapRescheduleRow,
  normalizeDbTimestamp,
  proposeReschedule,
  rescheduleSlotOptions,
  rescheduleStatusLabel,
} from './reschedule.ts';

const now = new Date('2026-11-16T12:00:00Z');

describe('Reagendar', () => {
  it('solo antes de en camino y antes de la hora', () => {
    const base = { workerId: 'w', scheduledAt: '2026-11-17T13:00:00Z' };
    assert.equal(canProposeReschedule({ ...base, status: 'aceptado' }, now), true);
    assert.equal(canProposeReschedule({ ...base, status: 'pendiente' }, now), true);
    assert.equal(canProposeReschedule({ ...base, status: 'en_camino' }, now), false);
    assert.equal(canProposeReschedule({ ...base, status: 'completado' }, now), false);
    assert.equal(
      canProposeReschedule({ ...base, status: 'aceptado', scheduledAt: '2026-11-16T11:00:00Z' }, now),
      false,
    );
    assert.equal(canProposeReschedule({ ...base, status: 'aceptado', workerId: null }, now), false);
  });

  it('ofrece horas libres con una hora de margen y distintas a la actual', () => {
    const slots = [
      '2026-11-16 12:30:00+00',
      '2026-11-16 14:00:00+00',
      '2026-11-17 13:00:00+00',
      '2026-11-18 13:00:00+00',
    ];
    assert.deepEqual(rescheduleSlotOptions(slots, '2026-11-17T13:00:00Z', now), [
      '2026-11-16 14:00:00+00',
      '2026-11-18 13:00:00+00',
    ]);
  });

  it('normaliza el formato de Postgres', () => {
    assert.equal(normalizeDbTimestamp('2026-11-17 14:00:00+00'), '2026-11-17T14:00:00+00:00');
    assert.equal(normalizeDbTimestamp('2026-11-17T14:00:00.000Z'), '2026-11-17T14:00:00.000Z');
  });

  it('responde solo la otra parte y con la propuesta pendiente', () => {
    const p = mapRescheduleRow({
      id: 'r',
      id_trabajo: 'j',
      propuesta_por: 'cliente-1',
      rol_proponente: 'cliente',
      fecha_anterior: 'a',
      fecha_propuesta: 'b',
      estado: 'pendiente',
      creado_en: 'c',
    });
    assert.equal(canRespondReschedule(p, 'cliente-1'), false);
    assert.equal(canRespondReschedule(p, 'pro-1'), true);
    assert.equal(canRespondReschedule({ ...p, status: 'aceptada' }, 'pro-1'), false);
    assert.equal(rescheduleStatusLabel('vencida'), 'Venció');
  });

  it('traduce el error de la base y oculta los internos', async () => {
    const fail = (message: string) =>
      ({
        rpc: async () => ({ data: null, error: { message } }),
      }) as unknown as AppSupabase;
    await assert.rejects(
      proposeReschedule(fail('Esa hora no está publicada o ya está tomada por el profesional'), 'j', 'x'),
      /ya está tomada/,
    );
    await assert.rejects(proposeReschedule(fail('forbidden'), 'j', 'x'), /No se pudo proponer/);
  });
});
