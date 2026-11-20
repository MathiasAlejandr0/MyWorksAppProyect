import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { groupNoticesByJob, type GroupableNotice } from './group.ts';

const a: GroupableNotice = {
  id: '1',
  title: 'Aceptado',
  body: 'ok',
  createdAt: '2026-11-19T15:00:00.000Z',
  read: false,
  relatedId: 'job-a',
};
const b: GroupableNotice = {
  id: '2',
  title: 'Mensaje',
  body: 'hola',
  createdAt: '2026-11-19T16:00:00.000Z',
  read: true,
  relatedId: 'job-a',
};
const general: GroupableNotice = {
  id: '3',
  title: 'Aviso',
  body: 'sistema',
  createdAt: '2026-11-19T14:00:00.000Z',
  read: false,
  relatedId: null,
};

describe('avisos por trabajo', () => {
  it('agrupa por id_relacionado y deja sueltos en Generales', () => {
    const folders = groupNoticesByJob([a, general, b], { 'job-a': 'Fuga en la cocina' });
    assert.equal(folders[0]?.title, 'Fuga en la cocina');
    assert.equal(folders[0]?.unreadCount, 1);
    assert.deepEqual(folders[0]?.items.map((item) => item.id), ['2', '1']);
    assert.equal(folders[1]?.title, 'Generales');
    assert.equal(folders[1]?.key, 'generales');
  });

  it('un trabajo sin nombre se llama Pedido', () => {
    const folders = groupNoticesByJob([a], {});
    assert.equal(folders[0]?.title, 'Pedido');
  });
});
