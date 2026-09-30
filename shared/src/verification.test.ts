import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isVerificationStatus, verificationLabel } from './verification.ts';

describe('verificación de profesionales', () => {
  it('etiqueta los estados de la base', () => {
    assert.equal(verificationLabel('en_revision'), 'En revisión');
    assert.equal(verificationLabel('verificado'), 'Verificado');
    assert.equal(verificationLabel(null), 'Pendiente');
    assert.equal(verificationLabel('inventado'), 'Pendiente');
  });

  it('solo acepta los cuatro estados', () => {
    assert.equal(isVerificationStatus('rechazado'), true);
    assert.equal(isVerificationStatus('aprobado'), false);
  });
});
