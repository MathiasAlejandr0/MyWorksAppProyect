import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  estimateEtaMinutes,
  haversineKm,
  publishesLiveGps,
} from './distance.ts';

describe('distancia y llegada', () => {
  it('aproxima Santiago–Valparaíso en torno a 100 km', () => {
    const km = haversineKm(-33.4489, -70.6693, -33.0472, -71.6127);
    assert.ok(km > 90 && km < 120, String(km));
  });

  it('estima minutos y no inventa llegada si la distancia no es un número', () => {
    assert.equal(estimateEtaMinutes(0), 1);
    assert.equal(estimateEtaMinutes(28), 60);
    assert.equal(estimateEtaMinutes(Number.NaN), null);
  });

  it('el GPS solo corre en camino o en curso', () => {
    assert.equal(publishesLiveGps('en_camino'), true);
    assert.equal(publishesLiveGps('en_curso'), true);
    assert.equal(publishesLiveGps('aceptado'), false);
    assert.equal(publishesLiveGps('completado'), false);
    assert.equal(publishesLiveGps(null), false);
  });
});
