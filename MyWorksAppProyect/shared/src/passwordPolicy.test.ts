import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  isEmailNotConfirmed,
  isPkceCodeVerifierError,
  loadProfileAfterSignup,
  pkceCallbackFailureMessage,
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

describe('signUpUser con confirmación de correo', () => {
  it('sin sesión no lee perfiles y pide confirmar el correo', async () => {
    let profileReads = 0;
    const supabase = {
      auth: {
        signUp: async () => ({
          data: { user: { id: 'u1' }, session: null },
          error: null,
        }),
      },
      from: () => {
        profileReads += 1;
        throw new Error('permission denied for table perfiles');
      },
    };

    const result = await signUpUser(supabase as never, ' ana@demo.myworksapp.cl ', sample('a', 6, '12'), 'Ana');
    assert.deepEqual(result, { status: 'confirmation_required', email: 'ana@demo.myworksapp.cl' });
    assert.equal(profileReads, 0);
  });
});

describe('loadProfileAfterSignup', () => {
  it('reintenta y no inventa un perfil activo', async () => {
    let reads = 0;
    const found = await loadProfileAfterSignup(async () => {
      reads += 1;
      return reads < 2
        ? null
        : {
            id: 'u1',
            name: 'Ana',
            email: 'ana@demo.myworksapp.cl',
            role: 'usuario',
            accountStatus: 'activo',
          };
    }, 3, 0);
    assert.equal(found?.id, 'u1');
    assert.equal(reads, 2);

    const missing = await loadProfileAfterSignup(async () => null, 2, 0);
    assert.equal(missing, null);
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

describe('signUpUser pide el enlace en el mismo origen', () => {
  it('manda emailRedirectTo con window.location.origin', async () => {
    const previous = globalThis.window;
    Object.defineProperty(globalThis, 'window', {
      value: { location: { origin: 'https://myworksapp.cl' } },
      configurable: true,
    });
    let redirect = '';
    const supabase = {
      auth: {
        signUp: async (args: { options?: { emailRedirectTo?: string } }) => {
          redirect = args.options?.emailRedirectTo ?? '';
          return { data: { user: { id: 'u1' }, session: null }, error: null };
        },
      },
    };
    try {
      await signUpUser(supabase as never, 'ana@myworksapp.cl', sample('a', 6, '12'), 'Ana');
    } finally {
      if (previous === undefined) {
        Reflect.deleteProperty(globalThis, 'window');
      } else {
        Object.defineProperty(globalThis, 'window', { value: previous, configurable: true });
      }
    }
    assert.equal(redirect, 'https://myworksapp.cl');
  });
});

describe('pkceCallbackFailureMessage', () => {
  it('distingue el alta de la recuperacion cuando falta el code verifier', () => {
    assert.equal(isPkceCodeVerifierError('PKCE code verifier not found in storage'), true);
    assert.equal(isPkceCodeVerifierError('invalid login'), false);
    assert.equal(
      pkceCallbackFailureMessage(false),
      'Tu correo quedó confirmado. Inicia sesión.',
    );
    assert.equal(
      pkceCallbackFailureMessage(true),
      'Abre el enlace en el mismo navegador donde lo pediste o pide uno nuevo.',
    );
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
