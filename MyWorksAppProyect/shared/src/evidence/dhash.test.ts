import assert from 'node:assert/strict';
import test from 'node:test';
import { dhashDesdeLuma } from './dhash.ts';

test('dHash de una muestra negra es cero', () => {
  assert.equal(dhashDesdeLuma(new Uint8Array(72)), '0000000000000000');
});

test('dHash marca el primer pixel de cada fila', () => {
  const luma = new Uint8Array(72);
  for (let row = 0; row < 8; row += 1) luma[row * 9] = 255;
  assert.equal(dhashDesdeLuma(luma), '8080808080808080');
});

test('rechaza una muestra de otro tamaño', () => {
  assert.throws(() => dhashDesdeLuma(new Uint8Array(8)), /72 bytes/);
});
