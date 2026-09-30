import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { summarizeBusinessPeriod } from './period.ts';

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
