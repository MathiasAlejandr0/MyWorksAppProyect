import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { decodeBytea, isWebpBytes, webpBytesToDataUrl } from './bytea.ts';

const tinyWebpHex =
  '524946463a00000057454250565038202e0000003002009d012a0200020001402625a00274ba01f801f800061e00009bffdbb34c63f7f789ffef60b62f197faf8000';

describe('decodeBytea', () => {
  it('lee el hex de PostgREST con prefijo \\x', () => {
    const bytes = decodeBytea(`\\x${tinyWebpHex}`);
    assert.ok(bytes);
    assert.equal(bytes.length, tinyWebpHex.length / 2);
    assert.equal(isWebpBytes(bytes), true);
  });

  it('rechaza texto vacío', () => {
    assert.equal(decodeBytea(null), null);
    assert.equal(decodeBytea(''), null);
    assert.equal(decodeBytea('zz'), null);
  });
});

describe('webpBytesToDataUrl', () => {
  it('arma un data URL que el navegador puede pintar', () => {
    const bytes = decodeBytea(`\\x${tinyWebpHex}`);
    assert.ok(bytes);
    const url = webpBytesToDataUrl(bytes);
    assert.match(url, /^data:image\/webp;base64,/);
  });
});
