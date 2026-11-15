import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isOpenAt, visitFitsSchedule, type WeeklyHours } from './weeklyHours.ts';

const office: WeeklyHours = {
  enabled: true,
  days: [
    { weekday: 1, startMinute: 9 * 60, endMinute: 18 * 60, enabled: true },
  ],
};

describe('horario semanal', () => {
  it('un lunes a las 15 en Santiago está abierto', () => {
    const mondayAfternoon = new Date('2026-11-16T18:00:00.000Z');
    assert.equal(isOpenAt(office, mondayAfternoon), true);
  });

  it('fuera de rango o con el horario apagado', () => {
    const mondayNight = new Date('2026-11-16T02:00:00.000Z');
    assert.equal(isOpenAt(office, mondayNight), false);
    assert.equal(isOpenAt({ enabled: false, days: office.days }, mondayNight), true);
  });

  it('la visita del viernes a las 10 entra en un viernes hábil', () => {
    const fridayTen = new Date('2026-11-20T13:00:00.000Z');
    const friday: WeeklyHours = {
      enabled: true,
      days: [{ weekday: 5, startMinute: 9 * 60, endMinute: 18 * 60, enabled: true }],
    };
    assert.equal(visitFitsSchedule(friday, fridayTen), true);
    assert.equal(visitFitsSchedule(friday, new Date('2026-11-16T13:00:00.000Z')), false);
  });
});
