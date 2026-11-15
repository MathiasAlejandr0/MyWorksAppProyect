import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { saveJobEvidence } from './save.ts';

describe('saveJobEvidence', () => {
  it('borra el objeto si falla el insert', async () => {
    const removed: string[][] = [];
    const supabase = {
      storage: {
        from: () => ({
          upload: async () => ({ error: null }),
          remove: async (paths: string[]) => {
            removed.push(paths);
            return { error: null };
          },
          createSignedUrl: async () => ({ data: null, error: { message: 'no' } }),
        }),
      },
      from: () => ({
        insert: async () => ({ error: { message: 'rls' } }),
      }),
    };

    await assert.rejects(
      () =>
        saveJobEvidence(supabase as never, {
          jobId: 'job-1',
          userId: 'user-1',
          fileId: 'file-1',
          body: new Uint8Array([1, 2, 3]),
          mime: 'image/jpeg',
          byteLength: 3,
        }),
      /registrar la evidencia/,
    );
    assert.deepEqual(removed, [['job-1/user-1/file-1.jpg']]);
  });

  it('reintenta la subida y guarda la ruta, no una URL', async () => {
    let uploads = 0;
    let inserted: Record<string, string> | null = null;
    const supabase = {
      storage: {
        from: () => ({
          upload: async () => {
            uploads += 1;
            return uploads < 2 ? { error: { message: 'timeout' } } : { error: null };
          },
          remove: async () => ({ error: null }),
          createSignedUrl: async () => ({ data: null, error: null }),
        }),
      },
      from: () => ({
        insert: async (row: Record<string, string>) => {
          inserted = row;
          return { error: null };
        },
      }),
    };

    const saved = await saveJobEvidence(supabase as never, {
      jobId: 'job-1',
      userId: 'user-1',
      fileId: 'file-2',
      body: new Uint8Array([1]),
      mime: 'video/mp4',
      byteLength: 1,
    });
    assert.equal(uploads, 2);
    assert.equal(saved.path, 'job-1/user-1/file-2.mp4');
    assert.equal(inserted?.ruta_foto, saved.path);
    assert.equal(saved.path.includes('http'), false);
  });
});
