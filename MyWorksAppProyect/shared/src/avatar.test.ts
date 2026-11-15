import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { initialsAvatarDataUrl, nameInitials, profilePhotoOrInitials } from './avatar.ts';

describe('avatar con iniciales', () => {
  it('toma la primera letra del nombre y del apellido', () => {
    assert.equal(nameInitials('Juana Colil'), 'JC');
    assert.equal(nameInitials('  óscar  de la  Núñez '), 'ÓN');
    assert.equal(nameInitials('Mateo'), 'M');
    assert.equal(nameInitials(''), '?');
  });

  it('cada persona sin foto tiene un avatar distinto', () => {
    const a = initialsAvatarDataUrl('Mateo Oyarzo', 'id-1');
    const b = initialsAvatarDataUrl('Juana Colil', 'id-2');
    assert.ok(a.startsWith('data:image/svg+xml'));
    assert.notEqual(a, b);
    assert.match(decodeURIComponent(b), />JC</);
  });

  it('respeta la foto real cuando existe', () => {
    assert.equal(profilePhotoOrInitials('https://x/y.jpg', 'Ana'), 'https://x/y.jpg');
    assert.ok(profilePhotoOrInitials(null, 'Ana').startsWith('data:'));
  });
});
