import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { pluralize } from './plural.ts';

describe('pluralize', () => {
  it('usa singular solo con 1', () => {
    assert.equal(pluralize(1, 'reseña'), '1 reseña');
    assert.equal(pluralize(0, 'reseña'), '0 reseñas');
    assert.equal(pluralize(4, 'trabajo bien cerrado', 'trabajos bien cerrados'), '4 trabajos bien cerrados');
  });
});
