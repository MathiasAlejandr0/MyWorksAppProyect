import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isReservedEmailDomain, reservedEmailMessage } from './emailDomain.ts';

describe('isReservedEmailDomain', () => {
  it('detecta dominios y TLD reservados', () => {
    for (const email of ['ana@example.com', 'a@sub.example.org', 'x@demo.test', 'y@foo.invalid', 'z@EXAMPLE.NET']) {
      assert.equal(isReservedEmailDomain(email), true, email);
    }
  });

  it('deja pasar correos reales', () => {
    for (const email of ['ana@gmail.com', 'ana@examples.com', 'ana@test.cl', 'sin-arroba']) {
      assert.equal(isReservedEmailDomain(email), false, email);
    }
    assert.equal(reservedEmailMessage('ana@gmail.com'), null);
  });
});

describe('requestPasswordReset', () => {
  it('valida antes de llamar a Auth y traduce el error', async () => {
    const { requestPasswordReset, translateAuthError } = await import('./auth.ts');
    const calls: Array<[string, unknown]> = [];
    const fake = {
      auth: {
        resetPasswordForEmail: async (email: string, opts: unknown) => {
          calls.push([email, opts]);
          return { error: null };
        },
      },
    } as never;
    await assert.rejects(requestPasswordReset(fake, 'no-es-correo', 'https://x'), /correo válido/);
    await assert.rejects(requestPasswordReset(fake, 'ana@example.com', 'https://x'), /de ejemplo/);
    assert.equal(calls.length, 0);
    await requestPasswordReset(fake, ' Ana@Gmail.com ', 'https://myworksapp-cl.vercel.app/?restablecer=1');
    assert.deepEqual(calls[0], ['ana@gmail.com', { redirectTo: 'https://myworksapp-cl.vercel.app/?restablecer=1' }]);
    assert.match(translateAuthError('Error sending recovery email'), /No pudimos enviar el correo/);
    const { passwordResetRedirect } = await import('./auth.ts');
    assert.equal(
      passwordResetRedirect('https://myworksapp-cl.vercel.app/'),
      'https://myworksapp-cl.vercel.app/?restablecer=1',
    );
  });
});
