import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { containsContactData } from './contactFilter.ts';
import { buildJobMessageInsert } from './messages.ts';

describe('buildJobMessageInsert', () => {
  it('arma la fila que espera la tabla mensajes', () => {
    const row = buildJobMessageInsert({
      id: 'm1',
      jobId: 'job-1',
      senderId: 'user-1',
      receiverId: 'worker-1',
      content: '  Hola  ',
      createdAt: '2026-09-30T00:00:00.000Z',
    });
    assert.equal(row.id_trabajo, 'job-1');
    assert.equal(row.id_remitente, 'user-1');
    assert.equal(row.id_destinatario, 'worker-1');
    assert.equal(row.contenido, 'Hola');
    assert.equal(row.tipo, 'texto');
    assert.equal(row.leido, 0);
  });
});

describe('containsContactData', () => {
  it('bloquea correo, teléfono, enlace y evasión', () => {
    assert.equal(containsContactData('escribeme a ana@correo.cl'), true);
    assert.equal(containsContactData('mi correo es ana arroba correo.cl'), true);
    assert.equal(containsContactData('9 8765 4321'), true);
    assert.equal(containsContactData('mira https://wa.me/56911111111'), true);
    assert.equal(containsContactData('te paso mi wsp'), true);
  });

  it('deja pasar el texto del trabajo', () => {
    assert.equal(containsContactData('El enchufe de la cocina no funciona'), false);
    assert.equal(containsContactData(''), false);
  });
});
