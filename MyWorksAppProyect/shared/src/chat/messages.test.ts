import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import { contactBlockedMessage, containsContactData } from './contactFilter.ts';
import contactCases from './contactCases.json' with { type: 'json' };
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
  const sqlCases = readFileSync(
    new URL(
      '../../../myworksapp_app/supabase/tests/texto_tiene_contacto_casos.sql',
      import.meta.url,
    ),
    'utf8',
  );

  it('coincide con los casos compartidos y con el script SQL', () => {
    assert.equal(containsContactData(''), false);
    for (const row of contactCases) {
      assert.equal(
        containsContactData(row.text),
        row.contact,
        row.text,
      );
      assert.equal(
        sqlCases.includes(row.text),
        true,
        `falta en el script SQL: ${row.text}`,
      );
    }
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
