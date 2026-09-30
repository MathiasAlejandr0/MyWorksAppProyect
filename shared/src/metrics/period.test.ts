import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { formatDbDateTime, parseDbTimestamp, summarizeBusinessPeriod } from './period.ts';

describe('métricas del período', () => {
  const fromIso = '2026-09-01T00:00:00.000Z';
  const toIso = '2026-09-30T23:59:59.000Z';

  it('suma GMV retenido y liberado, comisión y ticket', () => {
    const summary = summarizeBusinessPeriod({
      fromIso,
      toIso,
      payments: [
        { amount: 10000, status: 'retenido', createdAt: '2026-09-10T12:00:00.000Z' },
        { amount: 20000, status: 'liberado', createdAt: '2026-09-11T12:00:00.000Z' },
        { amount: 99999, status: 'pendiente', createdAt: '2026-09-11T12:00:00.000Z' },
        { amount: 5000, status: 'retenido', createdAt: '2026-08-01T12:00:00.000Z' },
      ],
      jobs: [
        { status: 'completado', updatedAt: '2026-09-12T12:00:00.000Z' },
        { status: 'cancelado', updatedAt: '2026-09-12T12:00:00.000Z' },
      ],
      ratings: [
        { score: 5, createdAt: '2026-09-12T12:00:00.000Z' },
        { score: 3, createdAt: '2026-09-13T12:00:00.000Z' },
      ],
    });
    assert.equal(summary.gmv, 30000);
    assert.equal(summary.commission, 4500);
    assert.equal(summary.completedJobs, 1);
    assert.equal(summary.avgTicket, 15000);
    assert.equal(summary.csat, 4);
    assert.equal(summary.dailyGmv.length, 2);
  });

  it('deja ceros y nulos cuando el período no tiene movimientos', () => {
    const summary = summarizeBusinessPeriod({
      fromIso,
      toIso,
      payments: [],
      jobs: [],
      ratings: [],
    });
    assert.equal(summary.gmv, 0);
    assert.equal(summary.commission, 0);
    assert.equal(summary.completedJobs, 0);
    assert.equal(summary.avgTicket, null);
    assert.equal(summary.csat, null);
    assert.equal(summary.ratingCount, 0);
    assert.deepEqual(summary.dailyGmv, []);
  });
});

it('parseDbTimestamp lee valores sin zona como UTC', () => {
  assert.equal(parseDbTimestamp('2026-09-30T07:58:44.929384'), Date.parse('2026-09-30T07:58:44.929Z'));
  assert.equal(parseDbTimestamp('2026-09-30 08:14:15.246791+00'), Date.parse('2026-09-30T08:14:15.246Z'));
  assert.equal(parseDbTimestamp('2026-09-30T08:16:44.147Z'), Date.parse('2026-09-30T08:16:44.147Z'));
  assert.equal(parseDbTimestamp('2026-09-30T05:16:44-03:00'), Date.parse('2026-09-30T08:16:44Z'));
  const summary = summarizeBusinessPeriod({
    payments: [{ amount: 1000, status: 'liberado', createdAt: '2026-09-30T07:58:44.929384' }],
    jobs: [{ status: 'completado', updatedAt: '2026-09-30T07:58:44.929384' }],
    ratings: [],
    fromIso: '2026-09-29T08:00:00.000Z',
    toIso: '2026-09-30T08:00:00.000Z',
  });
  assert.equal(summary.completedJobs, 1);
  assert.equal(summary.gmv, 1000);
  const hour = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'America/Santiago',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(new Date(Date.parse('2026-09-30T07:58:00.000Z')));
  assert.match(formatDbDateTime('2026-09-30T07:58:44.929384'), new RegExp(hour.replace(':', '\\:')));
});
