import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  changeOrderFeeClp,
  overtimeAmountClp,
  publishedServiceClp,
  roundClp,
} from './money.ts';
import {
  catalogPinTooFar,
  formatServiceRadiusKm,
  NEARBY_SERVICE_RADIUS_KM,
  transportCheckoutCopy,
  transportSurcharge,
  withinTravelRange,
} from './transport.ts';
import { transportQuote } from '../../../myworksapp_app/supabase/functions/_shared/transport.ts';

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

  it('la base del catálogo no produce un peso cobrable', () => {
    const quote = transportSurcharge({
      workerLat: -41.47,
      workerLng: -72.94,
      jobLat: -41.45,
      jobLng: -72.81,
      radiusKm: 7,
      catalogBaseIsApproximate: true,
    });
    assert.equal(quote.extraClp, 0);
    assert.equal(quote.insideRadar, null);
    assert.equal(quote.catalogBaseIsApproximate, true);
  });

  it('el radio visible no promete más kilómetros que el real', () => {
    assert.equal(formatServiceRadiusKm(7), '7');
    assert.equal(formatServiceRadiusKm(6.6), '6,6');
    assert.equal(formatServiceRadiusKm(6.54), '6,5');
  });

  it('un pin a 30,4 km no se esconde; uno a 32 km sí', () => {
    assert.equal(catalogPinTooFar(30.4), false);
    assert.equal(catalogPinTooFar(32), true);
    assert.equal(withinTravelRange(30.0004), true);
    assert.equal(withinTravelRange(30.0006), false);
  });

  it('la función del servidor y la de la app cobran el mismo traslado', () => {
    const input = {
      workerLat: centro.lat,
      workerLng: centro.lng,
      jobLat: chamiza.lat,
      jobLng: chamiza.lng,
      radiusKm: NEARBY_SERVICE_RADIUS_KM,
    };
    const shared = transportSurcharge(input);
    const edge = transportQuote(input);
    assert.equal(edge.extraClp, shared.extraClp);
    assert.equal(edge.distanceKm, shared.distanceKm);
  });

  it('m² y 8 % usan el entero, no el corte ni el binario', () => {
    assert.equal(roundClp(1500.6), 1501);
    assert.equal(roundClp(1500.5), 1501);
    assert.equal(publishedServiceClp(1500.6, 40), 60040);
    assert.equal(changeOrderFeeClp(7), 1);
    assert.equal(changeOrderFeeClp(6), 0);
    assert.equal(
      overtimeAmountClp({
        hourlyRateClp: 19250,
        extraHours: 1,
        comunaKey: 'providencia',
      }),
      23909,
    );
    assert.notEqual(Math.round(19250 * 1.08 * 1.15), 23909);
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
