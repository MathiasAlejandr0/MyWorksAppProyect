import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { contactBlockedMessage } from '../chat/contactFilter.ts';
import { createPendingJob } from './jobs.ts';

const input = {
  userId: 'user-1',
  workerId: 'worker-1',
  serviceId: 'svc-1',
  scheduledAt: '2026-11-20T15:00:00.000Z',
};

describe('createPendingJob', () => {
  it('no abre el pedido si la descripción trae contacto', async () => {
    await assert.rejects(
      () => createPendingJob({} as never, {
        ...input,
        description: 'llámame al +56912345678',
      }),
      (err: unknown) => err instanceof Error && err.message === contactBlockedMessage,
    );
  });

  it('deja pasar una descripción de oficio', async () => {
    await assert.rejects(
      () => createPendingJob({} as never, {
        ...input,
        description: 'Configurar Facebook en el televisor del living',
      }),
      (err: unknown) => {
        assert.ok(err instanceof Error);
        assert.equal(err.message.includes('no está permitido'), false);
        return true;
      },
    );
  });
});
