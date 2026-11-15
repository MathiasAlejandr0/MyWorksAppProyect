import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { contactBlockedMessage, containsContactData } from './contactFilter.ts';
import {
  buildJobMessageInsert,
  jobChatSendError,
  mapJobMessage,
  mergeJobMessage,
} from './messages.ts';

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
    assert.equal(containsContactData('el fijo es 2 2345 6789'), true);
    assert.equal(
      containsContactData('nueve uno dos tres cuatro cinco seis siete ocho'),
      true,
    );
    assert.equal(containsContactData('te paso el wasap'), true);
  });

  it('deja pasar el texto del trabajo', () => {
    assert.equal(containsContactData('El enchufe de la cocina no funciona'), false);
    assert.equal(containsContactData(''), false);
  });
});

describe('mapJobMessage / mergeJobMessage', () => {
  it('lee la fila de Realtime y no duplica por id', () => {
    const mapped = mapJobMessage({
      id: 'm1',
      id_trabajo: 'job-1',
      id_remitente: 'user-1',
      id_destinatario: 'worker-1',
      contenido: 'Hola',
      creado_en: '2026-11-08T15:40:00.000Z',
    });
    assert.ok(mapped);
    assert.equal(mapped.jobId, 'job-1');
    const once = mergeJobMessage([], mapped);
    assert.equal(mergeJobMessage(once, mapped).length, 1);
  });

  it('ignora un payload vacío', () => {
    assert.equal(mapJobMessage(null), null);
    assert.equal(mapJobMessage({ contenido: 'sin id' }), null);
  });
});

describe('jobChatSendError', () => {
  it('muestra el bloqueo de contacto, no un error de sesión', () => {
    assert.equal(
      jobChatSendError(new Error(contactBlockedMessage)),
      contactBlockedMessage,
    );
    assert.equal(
      jobChatSendError(new Error('mensaje bloqueado: no compartas telefono, correo ni enlaces')),
      contactBlockedMessage,
    );
  });

  it('reserva el texto de sesión para RLS', () => {
    assert.match(
      jobChatSendError(new Error('new row violates row-level security policy')),
      /Inicia sesión/,
    );
  });
});
