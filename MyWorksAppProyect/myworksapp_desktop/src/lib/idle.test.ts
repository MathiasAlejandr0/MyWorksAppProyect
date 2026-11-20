import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { IDLE_LOGOUT_MS, IDLE_WARN_MS, idlePhase } from './idle.ts';

describe('cierre por inactividad', () => {
  it('avisa a los 13 minutos y cierra a los 15', () => {
    assert.equal(idlePhase(IDLE_WARN_MS - 1), 'active');
    assert.equal(idlePhase(IDLE_WARN_MS), 'warning');
    assert.equal(idlePhase(IDLE_LOGOUT_MS - 1), 'warning');
    assert.equal(idlePhase(IDLE_LOGOUT_MS), 'expired');
  });
});
