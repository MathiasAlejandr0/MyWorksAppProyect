import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { parseInviteRequest } from './parseInvite.ts';

describe('invitación de RRHH', () => {
  it('acepta un correo y un rol del panel', () => {
    const parsed = parseInviteRequest({
      email: 'Ana@Empresa.cl',
      name: 'Ana Ruiz',
      role: 'Soporte',
      message: 'Bienvenida',
    });
    assert.equal(parsed.ok, true);
    if (parsed.ok) {
      assert.equal(parsed.value.email, 'ana@empresa.cl');
      assert.equal(parsed.value.role, 'Soporte');
    }
  });

  it('rechaza rol y correo inválidos', () => {
    assert.equal(parseInviteRequest({ email: 'no', name: 'Ana', role: 'Admin' }).ok, false);
    assert.equal(
      parseInviteRequest({ email: 'ana@empresa.cl', name: 'Ana', role: 'cliente' }).ok,
      false,
    );
  });
});
