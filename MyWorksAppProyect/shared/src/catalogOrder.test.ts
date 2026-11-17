import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import {
  catalogDistanceBand,
  compareCatalogOrder,
  roundCoord2,
  sortCatalog,
  type CatalogOrderItem,
  type CatalogOrderOrigin,
} from './catalogOrder.ts';

type Fixture = {
  cases: {
    name: string;
    origin: CatalogOrderOrigin;
    workers: CatalogOrderItem[];
    expected: string[];
  }[];
};

const fixture = JSON.parse(
  readFileSync(new URL('../fixtures/catalog_order_cases.json', import.meta.url), 'utf8'),
) as Fixture;

describe('orden único del catálogo (cercanía, nota, precio)', () => {
  for (const testCase of fixture.cases) {
    it(testCase.name, () => {
      const sorted = sortCatalog(testCase.workers, (w) => w, testCase.origin);
      assert.deepEqual(
        sorted.map((w) => w.id),
        testCase.expected,
      );
    });
  }

  it('el orden no depende del orden de llegada', () => {
    const testCase = fixture.cases[0];
    const reversed = [...testCase.workers].reverse();
    assert.deepEqual(
      sortCatalog(reversed, (w) => w, testCase.origin).map((w) => w.id),
      testCase.expected,
    );
  });

  it('redondea como Postgres, también con coordenadas negativas', () => {
    assert.equal(roundCoord2(-41.235), -41.24);
    assert.equal(roundCoord2(-72.9396), -72.94);
    assert.equal(roundCoord2(41.235), 41.24);
  });

  it('banda en km completos y null sin ubicación', () => {
    const origin = { latitude: -41.4693, longitude: -72.9424 };
    assert.equal(catalogDistanceBand({ latitude: -41.48, longitude: -72.96 }, origin), 1);
    assert.equal(catalogDistanceBand({ latitude: null, longitude: null }, origin), null);
    assert.equal(catalogDistanceBand({ latitude: -41.48, longitude: -72.96 }, null), null);
  });

  it('la cercanía pesa más que la nota y la nota más que el precio', () => {
    const origin = { latitude: -41.4718, longitude: -72.9396 };
    const near = { id: 'n', rating: 3.5, price: 90000, latitude: -41.47, longitude: -72.94 };
    const far = { id: 'f', rating: 5, price: 1000, latitude: -41.32, longitude: -72.99 };
    assert.ok(compareCatalogOrder(near, far, origin) < 0);
    const better = { ...near, id: 'b', rating: 4.8 };
    assert.ok(compareCatalogOrder(better, near, origin) < 0);
  });
});
