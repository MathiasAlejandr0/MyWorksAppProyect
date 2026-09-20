/**
 * Contrato payout providers (sin llamadas de red).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { getPayoutProviderStatus } from './payout.ts';

describe('payout providers', () => {
  it('manual está listo', () => {
    const s = getPayoutProviderStatus('manual');
    assert.equal(s.ready, true);
  });

  it('khipu y fintoc quedan stub hasta empresa', () => {
    assert.equal(getPayoutProviderStatus('khipu').ready, false);
    assert.equal(getPayoutProviderStatus('fintoc').ready, false);
  });
});
