import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { categoriesWithPros } from './catalog.ts';

const categories = [
  { id: 'ensamblaje', title: 'Armado' },
  { id: 'plomeria', title: 'Plomería' },
  { id: 'gasfiteria', title: 'Gasfitería' },
];

describe('categoriesWithPros', () => {
  it('muestra todas mientras el catálogo no responde', () => {
    assert.deepEqual(
      categoriesWithPros(categories, null).map((category) => category.id),
      ['ensamblaje', 'plomeria', 'gasfiteria'],
    );
  });

  it('oculta los oficios sin profesionales', () => {
    assert.deepEqual(
      categoriesWithPros(categories, new Set(['plomeria'])).map((category) => category.id),
      ['plomeria'],
    );
  });
});
