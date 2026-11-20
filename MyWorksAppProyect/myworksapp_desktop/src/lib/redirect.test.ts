import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { DESKTOP_AUTH_CALLBACK, authRedirectUrl } from './redirect.ts';

describe('redirect de autenticación', () => {
  it('en el navegador vuelve al origen con la marca de restablecer', () => {
    const url = authRedirectUrl('http://127.0.0.1:3001');
    assert.equal(url.startsWith('http://127.0.0.1:3001'), true);
    assert.match(url, /restablecer=1/);
  });

  it('el esquema de la app instalada es estable', () => {
    assert.equal(DESKTOP_AUTH_CALLBACK, 'myworksapp-admin://auth/callback');
  });
});
