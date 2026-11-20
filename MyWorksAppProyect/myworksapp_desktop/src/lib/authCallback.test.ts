import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { authDeepLinkNeedsPassword, parseAuthDeepLink } from './authCallback.ts';

describe('parseAuthDeepLink', () => {
  it('lee el code de PKCE', () => {
    const parsed = parseAuthDeepLink(
      'myworksapp-admin://auth/callback?code=abc123&type=invite',
    );
    assert.deepEqual(parsed, { kind: 'code', code: 'abc123', type: 'invite' });
    assert.equal(authDeepLinkNeedsPassword(parsed.kind === 'code' ? parsed.type : null), true);
  });

  it('lee token_hash y type', () => {
    const parsed = parseAuthDeepLink(
      'myworksapp-admin://auth/callback?token_hash=hash-1&type=recovery',
    );
    assert.deepEqual(parsed, { kind: 'otp', tokenHash: 'hash-1', type: 'recovery' });
  });

  it('lee el fragmento con los dos tokens', () => {
    const parsed = parseAuthDeepLink(
      'myworksapp-admin://auth/callback#access_token=aaa&refresh_token=bbb&type=invite',
    );
    assert.deepEqual(parsed, {
      kind: 'session',
      accessToken: 'aaa',
      refreshToken: 'bbb',
      type: 'invite',
    });
  });

  it('ignora basura', () => {
    assert.deepEqual(parseAuthDeepLink('no es una url'), { kind: 'ignore' });
    assert.deepEqual(parseAuthDeepLink(''), { kind: 'ignore' });
    assert.equal(authDeepLinkNeedsPassword('signup'), false);
  });
});
