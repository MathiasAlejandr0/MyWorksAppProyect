import assert from 'node:assert/strict';
import test from 'node:test';
import { asNum, asRows, asText } from './seguridad-model.ts';

test('asNum ignora valores que no son número', () => {
  assert.equal(asNum('12'), 12);
  assert.equal(asNum('no'), 0);
  assert.equal(asNum(null), 0);
});

test('asRows solo conserva objetos', () => {
  assert.deepEqual(asRows([{ id: 1 }, null, 'x']), [{ id: 1 }]);
  assert.deepEqual(asRows(undefined), []);
});

test('asText muestra un guion cuando falta el dato', () => {
  assert.equal(asText(''), '—');
  assert.equal(asText('alta'), 'alta');
});
