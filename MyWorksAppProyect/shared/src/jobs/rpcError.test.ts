import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { agreementErrorMessage } from './rpcError.ts';

describe('errores de acuerdo', () => {
  it('no muestra el mensaje crudo de la base', () => {
    const raw = 'duplicate key value violates unique constraint acuerdos_trabajo_pkey';
    const text = agreementErrorMessage(raw, 'proponer');
    assert.equal(text.includes('duplicate'), false);
    assert.equal(text, 'No se pudo proponer el acuerdo.');
  });

  it('traduce un pedido cerrado', () => {
    assert.equal(
      agreementErrorMessage('el trabajo está cerrado', 'responder'),
      'Este pedido ya no admite un acuerdo.',
    );
  });
});
