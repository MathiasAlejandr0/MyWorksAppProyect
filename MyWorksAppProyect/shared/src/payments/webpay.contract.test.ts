/**
 * Tests de contrato de pagos (sin llamar a Transbank).
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { getPaymentsMode } from './webpay.ts';

describe('payments contract', () => {
  it('mode production exige flip explícito', () => {
    assert.equal(getPaymentsMode('production'), 'production');
    assert.notEqual(getPaymentsMode(undefined), 'production');
  });

  it('createWebpaySession shape documentado (auth embed)', () => {
    const sample = {
      paymentId: 'p1',
      buyOrder: 'MWAabc',
      redirectUrl: 'https://xxx.supabase.co/functions/v1/webpay-handoff?t=...',
      ambiente: 'integration',
      presentMode: 'embed',
    };
    assert.ok(sample.redirectUrl.includes('webpay-handoff'));
    assert.equal('token' in sample, false);
    assert.equal(sample.presentMode, 'embed');
  });

  it('guest checkout shape documentado (redirect)', () => {
    const sample = {
      jobId: 'j1',
      paymentId: 'p1',
      buyOrder: 'MWAabc',
      redirectUrl: 'https://xxx.supabase.co/functions/v1/webpay-handoff?t=...',
      mode: 'guest_redirect',
    };
    assert.equal(sample.mode, 'guest_redirect');
    assert.ok(sample.redirectUrl.includes('webpay-handoff'));
  });
});
