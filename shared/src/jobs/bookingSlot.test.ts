import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { visitSlotIso } from './bookingSlot.ts';

describe('horario de la reserva web', () => {
  it('guarda el próximo viernes a la hora elegida', () => {
    const wednesday = new Date(2026, 8, 30, 15, 0, 0);
    const slot = new Date(visitSlotIso('14', wednesday));
    assert.equal(slot.getFullYear(), 2026);
    assert.equal(slot.getMonth(), 9);
    assert.equal(slot.getDate(), 2);
    assert.equal(slot.getHours(), 14);
    assert.equal(slot.getMinutes(), 0);
  });
});
