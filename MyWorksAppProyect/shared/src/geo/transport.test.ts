import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  NEARBY_SERVICE_RADIUS_KM,
  transportCheckoutCopy,
  transportSurcharge,
  withinTravelRange,
} from './transport.ts';

describe('recargo de traslado', () => {
  const centro = { lat: -41.4718, lng: -72.9396 };
  const pelluco = { lat: -41.4874, lng: -72.8993 };
  const chamiza = { lat: -41.4499, lng: -72.8148 };

  it('no cobra extra si el trabajo queda dentro del radar cercano', () => {
    const quote = transportSurcharge({
      workerLat: centro.lat,
      workerLng: centro.lng,
      jobLat: pelluco.lat,
      jobLng: pelluco.lng,
      radiusKm: NEARBY_SERVICE_RADIUS_KM,
    });
    assert.equal(quote.insideRadar, true);
    assert.equal(quote.extraClp, 0);
    assert.ok((quote.distanceKm ?? 99) < NEARBY_SERVICE_RADIUS_KM);
  });

  it('cobra extra si el trabajo queda fuera del radar, no a otra ciudad', () => {
    const quote = transportSurcharge({
      workerLat: centro.lat,
      workerLng: centro.lng,
      jobLat: chamiza.lat,
      jobLng: chamiza.lng,
      radiusKm: NEARBY_SERVICE_RADIUS_KM,
    });
    assert.equal(quote.insideRadar, false);
    assert.ok((quote.distanceKm ?? 0) > NEARBY_SERVICE_RADIUS_KM);
    assert.ok(quote.extraClp >= 3000);
    assert.ok(quote.extraClp <= 18000);
    assert.equal(withinTravelRange(quote.distanceKm), true);
  });

  it('no ofrece el viaje a más de 30 km', () => {
    assert.equal(withinTravelRange(30), true);
    assert.equal(withinTravelRange(30.1), false);
    assert.equal(withinTravelRange(null), true);
  });

  it('sin coordenadas no inventa recargo', () => {
    const quote = transportSurcharge({ radiusKm: 7 });
    assert.equal(quote.insideRadar, null);
    assert.equal(quote.extraClp, 0);
  });

  it('el checkout no dice “queda cerca” si falta el GPS', () => {
    assert.equal(
      transportCheckoutCopy({ extraClp: 0, insideRadar: null }),
      'Sin extra por ahora. Usa el GPS, escribe una dirección o marca el punto en el mapa.',
    );
    assert.equal(
      transportCheckoutCopy({ extraClp: 0, insideRadar: true }),
      'Incluido: el trabajo queda cerca',
    );
    assert.match(
      transportCheckoutCopy({ extraClp: 4100, insideRadar: false }),
      /fuera del área/,
    );
  });
});
