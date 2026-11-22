import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { PNG } from 'pngjs';
import jsQR from 'jsqr';
import {
  isOtpauthUri,
  makeScannableTotpQr,
  sanitizeTotpQrDataUri,
} from './totpQr.ts';

const SAMPLE_SECRET = 'JBSWY3DPEHPK3PXP';
const SAMPLE_URI =
  'otpauth://totp/MyWorksApp:admin.ops@demo.myworksapp.cl?secret=' +
  SAMPLE_SECRET +
  '&issuer=MyWorksApp';

describe('QR TOTP de la consola', () => {
  it('reconoce un otpauth de TOTP con secreto base32', () => {
    assert.equal(isOtpauthUri(SAMPLE_URI), true);
    assert.equal(isOtpauthUri('otpauth://totp/x'), false);
    assert.equal(isOtpauthUri('https://example.com'), false);
  });

  it('codifica el # del SVG para que el <img> no corte el data URI', () => {
    const raw =
      'data:image/svg+xml;utf-8,<svg xmlns="http://www.w3.org/2000/svg"><rect fill="#000000"/></svg>';
    const fixed = sanitizeTotpQrDataUri(raw);
    assert.equal(fixed.includes('#'), false);
    assert.equal(fixed.includes('%23'), true);
    assert.match(fixed, /fill="%23000000"/);
    const afterComma = fixed.slice(fixed.indexOf(',') + 1);
    const decoded = decodeURIComponent(afterComma);
    assert.equal(decoded.includes('<svg'), true);
    assert.equal(decoded.includes('fill="#000000"'), true);
  });

  it('genera un PNG escaneable cuyo contenido es el otpauth', async () => {
    const src = await makeScannableTotpQr({ uri: SAMPLE_URI, qr_code: null });
    assert.ok(src);
    assert.match(src, /^data:image\/png;base64,/);
    const buf = Buffer.from(src.split(',')[1], 'base64');
    const png = PNG.sync.read(buf);
    const decoded = jsQR(new Uint8ClampedArray(png.data), png.width, png.height);
    assert.ok(decoded, 'el QR no se pudo decodificar');
    assert.equal(decoded.data, SAMPLE_URI);
    assert.equal(isOtpauthUri(decoded.data), true);
    const secret = new URL(decoded.data).searchParams.get('secret');
    assert.equal(secret, SAMPLE_SECRET);
  });
});
