import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { applyPublicStatsRow } from './workers.ts';
import type { WorkerWithProfile } from '../types.ts';

function worker(overrides: Partial<WorkerWithProfile> = {}): WorkerWithProfile {
  return {
    userId: '11111111-1111-4111-8111-000000000206',
    profession: 'Gasfíter',
    description: null,
    rating: 4.9,
    isAvailable: 1,
    visitFee: 32000,
    serviceCategory: 'gasfiteria',
    pricingConfigured: 1,
    workZone: 'Puerto Montt',
    name: 'Mateo Oyarzo',
    completedJobs: 8,
    isElite: true,
    ...overrides,
  };
}

describe('applyPublicStatsRow', () => {
  it('no inventa nota cuando no hay reseñas reales', () => {
    const next = applyPublicStatsRow(worker(), {
      id_usuario: '11111111-1111-4111-8111-000000000206',
      calificacion: 4.9,
      n_calificaciones: 0,
      trabajos_completados: 0,
      es_elite: false,
    });
    assert.equal(next.rating, 0);
    assert.equal(next.completedJobs, 0);
    assert.equal(next.isElite, false);
  });

  it('usa el promedio y el recuento reales', () => {
    const next = applyPublicStatsRow(worker({ rating: 0, completedJobs: 0 }), {
      id_usuario: 'x',
      calificacion: 4.8,
      n_calificaciones: 5,
      trabajos_completados: 5,
      es_elite: true,
    });
    assert.equal(next.rating, 4.8);
    assert.equal(next.completedJobs, 5);
    assert.equal(next.isElite, true);
  });
});
