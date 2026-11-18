import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { foldSearchText, matchesSearchText } from './searchText';

describe('búsqueda sin tildes', () => {
  it('«electrico» encuentra «Eléctrico» y al revés', () => {
    assert.equal(matchesSearchText('Eléctrico', 'electrico'), true);
    assert.equal(matchesSearchText('Electrico', 'ELÉCTRICO'), true);
    assert.equal(matchesSearchText('Jardín y poda', 'jardin'), true);
  });

  it('pliega la ñ y las mayúsculas acentuadas', () => {
    assert.equal(foldSearchText('Ñuñoa'), 'nunoa');
    assert.equal(foldSearchText('ÁÉÍÓÚ'), 'aeiou');
  });

  it('una búsqueda vacía no filtra y otro texto no coincide', () => {
    assert.equal(matchesSearchText('Plomería', '  '), true);
    assert.equal(matchesSearchText('Plomería', 'pintura'), false);
  });
});
