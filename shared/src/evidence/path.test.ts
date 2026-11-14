import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  evidenceObjectPath,
  isEvidenceStoragePath,
  validateEvidenceFile,
} from './path.ts';

describe('evidencia en Storage', () => {
  it('arma una ruta privada por trabajo y usuario', () => {
    assert.equal(
      evidenceObjectPath('job-1', 'user-1', 'file-1', 'image/jpeg'),
      'job-1/user-1/file-1.jpg',
    );
    assert.equal(isEvidenceStoragePath('job-1/user-1/file-1.jpg'), true);
    assert.equal(isEvidenceStoragePath('https://cdn.example/a.jpg'), false);
    assert.equal(isEvidenceStoragePath('/data/user/0/foto.jpg'), false);
  });

  it('rechaza tipos y tamaños fuera de límite', () => {
    assert.equal(validateEvidenceFile({ mime: 'image/jpeg', byteLength: 100 }).ok, true);
    assert.equal(validateEvidenceFile({ mime: 'application/pdf', byteLength: 100 }).ok, false);
    assert.equal(validateEvidenceFile({ mime: 'video/mp4', byteLength: 51 * 1024 * 1024 }).ok, false);
    assert.equal(validateEvidenceFile({ mime: 'image/png', byteLength: 9 * 1024 * 1024 }).ok, false);
  });
});
