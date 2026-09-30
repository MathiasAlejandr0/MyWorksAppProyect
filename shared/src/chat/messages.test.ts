import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
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
