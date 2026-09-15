import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { canAccessDesktopHub } from './authAccess.ts';

describe('canAccessDesktopHub', () => {
  it('permite solo administrador', () => {
    assert.equal(canAccessDesktopHub('administrador'), true);
  });

  it('rechaza usuario, trabajador y legacy admin', () => {
    assert.equal(canAccessDesktopHub('usuario'), false);
    assert.equal(canAccessDesktopHub('trabajador'), false);
    assert.equal(canAccessDesktopHub('admin'), false);
    assert.equal(canAccessDesktopHub(''), false);
  });
});
