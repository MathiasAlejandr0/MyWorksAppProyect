import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  isEmailNotConfirmed,
  signUpUser,
  translateAuthError,
  updateAccountPassword,
} from './auth.ts';
import {
  authLinkRequiresPassword,
  passwordPolicyMessage,
} from './passwordPolicy.ts';

function sample(chars: string, times: number, extra = ''): string {
  return chars.repeat(times) + extra;
}

describe('passwordPolicyMessage', () => {
  it('rechaza vacía, corta, solo letras y solo números', () => {
    assert.equal(passwordPolicyMessage(''), 'La contraseña es requerida');
    assert.equal(
      passwordPolicyMessage(sample('a', 7)),
      'La contraseña debe tener al menos 8 caracteres',
    );
    assert.equal(
      passwordPolicyMessage(sample('a', 8)),
      'Incluye al menos un número',
    );
    assert.equal(
      passwordPolicyMessage(sample('1', 8)),
      'Incluye al menos una letra',
    );
  });

  it('acepta letra y número con 8 o más caracteres', () => {
    assert.equal(passwordPolicyMessage(sample('a', 6, '12')), null);
    assert.equal(passwordPolicyMessage(`Ñandú${sample('1', 3)}`), null);
  });
});

describe('signUpUser y updateAccountPassword', () => {
  it('no llama a Auth si la clave no cumple', async () => {
    let calls = 0;
    const supabase = {
      auth: {
        signUp: async () => {
          calls += 1;
          return { data: { user: null }, error: null };
        },
        updateUser: async () => {
          calls += 1;
          return { error: null };
        },
      },
    };

    await assert.rejects(
      () => signUpUser(supabase as never, 'ana@demo.myworksapp.cl', sample('a', 8), 'Ana'),
      /al menos un número/,
    );
    await assert.rejects(
      () => updateAccountPassword(supabase as never, sample('1', 8)),
      /al menos una letra/,
    );
    assert.equal(calls, 0);
  });
});

describe('authLinkRequiresPassword', () => {
  it('detecta invitación y recuperación en hash o query', () => {
    assert.equal(authLinkRequiresPassword('#access_token=abc&type=invite'), true);
    assert.equal(authLinkRequiresPassword('?code=abc&type=recovery'), true);
    assert.equal(authLinkRequiresPassword('#type=signup'), false);
    assert.equal(authLinkRequiresPassword(''), false);
  });
});

describe('isEmailNotConfirmed', () => {
  it('reconoce el error de Auth y deja pasar el resto', () => {
    assert.equal(isEmailNotConfirmed('Email not confirmed'), true);
    assert.equal(isEmailNotConfirmed('email not confirmed'), true);
    assert.equal(isEmailNotConfirmed('Confirma tu correo antes de entrar.'), true);
    assert.equal(isEmailNotConfirmed('Invalid login credentials'), false);
  });
});

describe('translateAuthError', () => {
  it('traduce los errores de Auth que ve el usuario', () => {
    assert.match(translateAuthError('Email not confirmed'), /confirma tu correo/i);
    assert.equal(
      translateAuthError('Invalid login credentials'),
      'Correo o contraseña incorrectos.',
    );
    assert.match(translateAuthError('email rate limit exceeded'), /demasiados intentos/i);
    assert.match(translateAuthError('Password should be at least 8 characters'), /débil/i);
    assert.equal(translateAuthError('Perfil no encontrado.'), 'Perfil no encontrado.');
  });
});
