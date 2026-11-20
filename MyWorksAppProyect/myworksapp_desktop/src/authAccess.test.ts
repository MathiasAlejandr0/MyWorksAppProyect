import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  canAccessDesktopHub,
  consolePermissions,
  consoleRoleLabel,
} from './authAccess.ts';

describe('canAccessDesktopHub', () => {
  it('permite administrador, soporte y qa', () => {
    assert.equal(canAccessDesktopHub('administrador'), true);
    assert.equal(canAccessDesktopHub('soporte'), true);
    assert.equal(canAccessDesktopHub('qa'), true);
  });

  it('rechaza usuario, trabajador y legacy admin', () => {
    assert.equal(canAccessDesktopHub('usuario'), false);
    assert.equal(canAccessDesktopHub('trabajador'), false);
    assert.equal(canAccessDesktopHub('admin'), false);
    assert.equal(canAccessDesktopHub(''), false);
  });
});

describe('consolePermissions (mínimo privilegio)', () => {
  it('solo administrador mueve dinero, ve métricas e invita', () => {
    for (const role of ['soporte', 'qa', 'usuario']) {
      const p = consolePermissions(role);
      assert.equal(p.resolveDisputes, false, role);
      assert.equal(p.executive, false, role);
      assert.equal(p.people, false, role);
    }
    const admin = consolePermissions('administrador');
    assert.equal(admin.resolveDisputes && admin.executive && admin.people, true);
    assert.equal(consolePermissions('soporte').viewMoney, false);
    assert.equal(consolePermissions('qa').viewErrors, true);
    assert.equal(consolePermissions('qa').disputeEvidence, false);
    assert.equal(consolePermissions('soporte').proposeReviews, true);
    assert.equal(consolePermissions('soporte').moderateReviews, false);
  });

  it('soporte ve evidencia y deja notas; QA solo lee la cola y seguridad', () => {
    const soporte = consolePermissions('soporte');
    assert.deepEqual(
      [soporte.supportQueue, soporte.disputeEvidence, soporte.disputeNotes, soporte.security],
      [true, true, true, false],
    );
    const qa = consolePermissions('qa');
    assert.deepEqual(
      [qa.supportQueue, qa.disputeEvidence, qa.disputeNotes, qa.security],
      [true, false, false, true],
    );
  });

  it('etiqueta legible por rol', () => {
    assert.equal(consoleRoleLabel('soporte'), 'Soporte');
    assert.equal(consoleRoleLabel('qa'), 'QA');
  });
});
