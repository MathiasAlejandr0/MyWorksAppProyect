import assert from 'node:assert/strict';
import { test } from 'node:test';
import { publicErrorMessage, secondChargeMessage } from './safe_error.ts';

test('el índice de un solo cobro se explica en español', () => {
  const msg = publicErrorMessage({
    message:
      'duplicate key value violates unique constraint "pagos_un_principal_activo_uidx"',
  });
  assert.equal(msg, secondChargeMessage);
  assert.equal(msg.includes('duplicate key'), false);
  assert.equal(msg.includes('pagos_un_principal_activo'), false);
});

test('un RAISE de cobro en curso conserva la frase de negocio', () => {
  const msg = publicErrorMessage({
    message: 'ya hay un cobro en curso para este trabajo',
  });
  assert.equal(msg, secondChargeMessage);
});
