import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  evidenceIndexMatches,
  missingEvidenceIds,
  reconcileEvidencePhotos,
  type JobEvidencePhoto,
} from './jobs.ts';

const known: JobEvidencePhoto = {
  id: 'foto-1',
  mediaType: 'foto',
  src: 'data:image/webp;base64,xx',
};

describe('evidenceIndexMatches', () => {
  it('exige el mismo orden y que ya haya src', () => {
    assert.equal(evidenceIndexMatches(['foto-1'], [known]), true);
    assert.equal(evidenceIndexMatches(['foto-2'], [known]), false);
    assert.equal(
      evidenceIndexMatches(['foto-1'], [{ ...known, src: null }]),
      false,
    );
  });
});

describe('missingEvidenceIds / reconcileEvidencePhotos', () => {
  it('solo pide las fotos nuevas y conserva las que ya están', () => {
    assert.deepEqual(missingEvidenceIds(['foto-1', 'foto-2'], [known]), ['foto-2']);
    const fetched: JobEvidencePhoto = {
      id: 'foto-2',
      mediaType: 'foto',
      src: 'data:image/webp;base64,yy',
    };
    const next = reconcileEvidencePhotos(
      [
        { id: 'foto-2', mediaType: 'foto' },
        { id: 'foto-1', mediaType: 'foto' },
      ],
      [known],
      [fetched],
    );
    assert.equal(next[0]?.id, 'foto-2');
    assert.equal(next[0]?.src, fetched.src);
    assert.equal(next[1]?.src, known.src);
  });
});
