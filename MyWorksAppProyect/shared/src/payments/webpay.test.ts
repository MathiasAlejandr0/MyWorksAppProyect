import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { getPaymentsMode } from './webpay.ts';

describe('getPaymentsMode', () => {
  it('default integration', () => {
    assert.equal(getPaymentsMode(undefined), 'integration');
    assert.equal(getPaymentsMode(''), 'integration');
  });

  it('acepta production y off', () => {
    assert.equal(getPaymentsMode('production'), 'production');
    assert.equal(getPaymentsMode('off'), 'off');
  });
});
