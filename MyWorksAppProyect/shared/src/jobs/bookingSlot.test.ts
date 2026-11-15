import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  addWorkerHour,
  bookingSlotError,
  formatBookingSlotLabel,
  parseWorkerHours,
  tooManyPendingPaymentsMessage,
  uniqueIsoSlots,
  uniqueWorkerHours,
  workerHourDuplicateMessage,
  workerSlotTakenMessage,
  workerSlotUnpublishedMessage,
} from './bookingSlot.ts';

describe('horarios del profesional', () => {
  it('elimina el mismo día y la misma hora', () => {
    const unique = uniqueWorkerHours([
      { dia: 1, hora: '9:00' },
      { dia: 1, hora: '09:00' },
      { dia: 1, hora: '14:00' },
      { dia: 2, hora: '09:00' },
    ]);
    assert.deepEqual(
      unique.map((item) => `${item.dia}|${item.hora}`),
      ['1|09:00', '1|14:00', '2|09:00'],
    );
  });

  it('no deja agregar un bloque duplicado', () => {
    const current = parseWorkerHours([{ dia: 5, hora: '18:00' }]);
    const result = addWorkerHour(current, { dia: 5, hora: '18:00' });
    assert.equal(result.error, workerHourDuplicateMessage);
    assert.equal(result.slots.length, 1);
  });

  it('deja una sola reserva si el ISO se repite al minuto', () => {
    const unique = uniqueIsoSlots([
      '2026-11-13T12:00:00.000Z',
      '2026-11-13T12:00:30.000Z',
      '2026-11-13T15:00:00.000Z',
    ]);
    assert.equal(unique.length, 2);
    assert.equal(unique[0], '2026-11-13T12:00:00.000Z');
  });

  it('arma la etiqueta de fecha y hora en Chile', () => {
    const label = formatBookingSlotLabel('2026-11-13T12:00:00.000Z');
    assert.match(label, /13/);
    assert.match(label, /09:00|9:00/);
  });

  it('traduce el error de hora ocupada', () => {
    assert.equal(
      bookingSlotError(new Error('ese horario ya esta reservado con este profesional')),
      workerSlotTakenMessage,
    );
    assert.equal(
      bookingSlotError(new Error('esa hora no esta publicada por el profesional')),
      workerSlotUnpublishedMessage,
    );
    assert.equal(
      bookingSlotError(new Error('demasiados pedidos esperando pago')),
      tooManyPendingPaymentsMessage,
    );
  });
});
