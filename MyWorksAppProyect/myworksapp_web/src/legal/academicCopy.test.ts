import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  ACADEMIC_ACTION_NOTE,
  ACADEMIC_BANNER_TEXT,
  ACADEMIC_META_DESCRIPTION,
  PAYMENTS_CONFIRMED_AS_INTEGRATION,
  TRANSBANK_TEST_CARDS_URL,
} from './academicCopy.ts';

describe('aviso académico', () => {
  it('afirma tarjetas de prueba en el ambiente de integración de Transbank', () => {
    assert.equal(PAYMENTS_CONFIRMED_AS_INTEGRATION, true);
    assert.match(TRANSBANK_TEST_CARDS_URL, /transbankdevelopers\.cl/);
    for (const text of [ACADEMIC_BANNER_TEXT, ACADEMIC_ACTION_NOTE, ACADEMIC_META_DESCRIPTION]) {
      assert.match(text, /tarjetas de prueba de Transbank/);
      assert.match(text, /ambiente de integración/);
      assert.match(text, /no se cobra dinero real/);
    }
    assert.match(ACADEMIC_ACTION_NOTE, /No ingreses datos de tarjetas reales/);
    assert.match(ACADEMIC_META_DESCRIPTION, /Duoc UC/);
    assert.match(ACADEMIC_META_DESCRIPTION, /no es un servicio comercial/);
  });
});
