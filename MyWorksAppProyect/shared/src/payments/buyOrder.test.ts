import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  detailBuyOrder,
  freshBuyOrder,
} from '../../../myworksapp_app/supabase/functions/_shared/buy_order.ts';

describe('freshBuyOrder', () => {
  const paymentId = '11111111-2222-3333-4444-555555555555';

  it('arma una orden de 26 caracteres', () => {
    const order = freshBuyOrder(paymentId, null);
    assert.equal(order.length, 26);
    assert.equal(detailBuyOrder(order).length, 26);
  });

  it('después de un rechazo no repite la orden', () => {
    const first = freshBuyOrder(paymentId, null);
    const second = freshBuyOrder(paymentId, first);
    assert.notEqual(first, second);
    assert.equal(second.slice(0, 24), first.slice(0, 24));
  });
});
