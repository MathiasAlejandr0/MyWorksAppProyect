import type { AppSupabase } from './client';
import { reservedEmailMessage } from './emailDomain';
import { passwordPolicyMessage } from './passwordPolicy';
import type { Profile, UserRole } from './types';

export { authLinkRequiresPassword, passwordPolicyMessage, PASSWORD_SETUP_STORAGE_KEY } from './passwordPolicy';

export function isEmailNotConfirmed(message: string): boolean {
  return /email not confirmed|confirma tu correo/i.test(message);
}

/** Mensajes de GoTrue que llegan en inglés al login, el alta y el cambio de clave. */
export function translateAuthError(message: string): string {
  const text = message.trim();
  if (/email not confirmed/i.test(text)) {
    return 'Confirma tu correo antes de entrar. Revisa la bandeja o reenvía el correo.';
  }
  if (/invalid login credentials|invalid credentials|invalid email or password/i.test(text)) {
    return 'Correo o contraseña incorrectos.';
  }
  if (/rate limit|too many requests|over_request_rate_limit|only request this after/i.test(text)) {
    return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
  }
  if (/error sending (recovery|confirmation|magic link|invite) email|email address .* (is )?not authorized|email_address_invalid|email address .* is invalid/i.test(text)) {
    return 'No pudimos enviar el correo a esa dirección. Revisa que esté bien escrita o inténtalo más tarde.';
  }
  if (/same.?password|should be different from the old/i.test(text)) {
    return 'La nueva contraseña debe ser distinta a la anterior.';
  }
  if (/weak password|password should be at least|password should contain|password is known/i.test(text)) {
    return 'La contraseña es débil. Usa al menos 8 caracteres, con una letra y un número.';
  }
  return text;
}

/** Marca que agrega la web al enlace del correo de recuperación. */
export const PASSWORD_RESET_PARAM = 'restablecer';

/** El code de PKCE se abrió en otro navegador: no hay code verifier guardado. */
export function isPkceCodeVerifierError(message: string): boolean {
  return /code verifier|code_verifier|both auth code and code verifier/i.test(message);
}

/** Texto para el alta o para la recuperación, según la marca `restablecer=1`. */
export function pkceCallbackFailureMessage(recovery: boolean): string {
  return recovery
    ? 'Abre el enlace en el mismo navegador donde lo pediste o pide uno nuevo.'
    : 'Tu correo quedó confirmado. Inicia sesión.';
}

function browserOrigin(): string | undefined {
  if (typeof window === 'undefined') return undefined;
  const origin = window.location?.origin?.trim();
  if (!origin || origin === 'null') return undefined;
  return origin;
}

/** Vuelve al mismo sitio que pidió el correo (producción, preview o local). */
export function passwordResetRedirect(origin: string): string {
  return `${origin.replace(/\/+$/, '')}/?${PASSWORD_RESET_PARAM}=1`;
}

/**
 * Pide el correo para restablecer la contraseña. Por privacidad, Auth no
 * dice si el correo existe; la web muestra siempre el mismo aviso.
 */
export async function requestPasswordReset(
  supabase: AppSupabase,
  email: string,
  redirectTo: string,
): Promise<void> {
  const clean = email.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clean)) {
    throw new AuthError('Escribe un correo válido.');
  }
  const reserved = reservedEmailMessage(clean);
  if (reserved) throw new AuthError(reserved);
  const { error } = await supabase.auth.resetPasswordForEmail(clean, { redirectTo });
  if (error) throw new AuthError(translateAuthError(error.message));
}

export async function resendSignupConfirmation(
  supabase: AppSupabase,
  email: string,
): Promise<void> {
  const { error } = await supabase.auth.resend({ type: 'signup', email });
  if (error) throw new AuthError(translateAuthError(error.message));
}

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

export async function signIn(
  supabase: AppSupabase,
  email: string,
  password: string,
): Promise<Profile> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new AuthError(translateAuthError(error.message));
  if (!data.user) throw new AuthError('No se pudo iniciar sesión.');

  const profile = await getProfile(supabase, data.user.id);
  if (!profile) throw new AuthError('Perfil no encontrado.');
  if (profile.accountStatus !== 'activo') {
    await supabase.auth.signOut();
    throw new AuthError('Cuenta suspendida o bloqueada.');
  }
  return profile;
}

/**
 * Resultado del alta. Con la confirmación de correo activa, Auth crea la
 * cuenta pero no abre sesión: el perfil recién se puede leer al entrar.
 */
export type SignUpResult =
  | { status: 'signed_in'; profile: Profile }
  | { status: 'confirmation_required'; email: string };

export async function signUpUser(
  supabase: AppSupabase,
  email: string,
  password: string,
  name: string,
  captchaToken?: string,
): Promise<SignUpResult> {
  const policy = passwordPolicyMessage(password);
  if (policy) throw new AuthError(policy);

  const emailRedirectTo = browserOrigin();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { name, role: 'usuario' },
      ...(emailRedirectTo ? { emailRedirectTo } : {}),
      ...(captchaToken ? { captchaToken } : {}),
    },
  });
  if (error) throw new AuthError(translateAuthError(error.message));
  if (!data.user) throw new AuthError('No se pudo registrar la cuenta.');

  // Sin sesión no hay permiso para leer `perfiles` (el rol anónimo no tiene
  // acceso): pedirlo aquí fallaba con «permission denied» aunque la cuenta
  // ya estaba creada y el correo enviado.
  if (!data.session) {
    return { status: 'confirmation_required', email: email.trim() };
  }

  const profile = await loadProfileAfterSignup(
    () => getProfile(supabase, data.user!.id),
  );
  if (!profile) {
    throw new AuthError(
      'Tu cuenta se creó, pero el perfil todavía no está listo. Confirma el correo e ingresa de nuevo.',
    );
  }
  return { status: 'signed_in', profile };
}

/** Reintenta el perfil que crea el trigger. No inventa una cuenta activa. */
export async function loadProfileAfterSignup(
  read: () => Promise<Profile | null>,
  attempts = 4,
  delayMs = 250,
): Promise<Profile | null> {
  for (let i = 0; i < attempts; i += 1) {
    const profile = await read();
    if (profile) return profile;
    if (i < attempts - 1 && delayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  return null;
}

/** Cambio de clave (recuperación, invitación o cuenta ya iniciada). */
export async function updateAccountPassword(
  supabase: AppSupabase,
  password: string,
): Promise<void> {
  const policy = passwordPolicyMessage(password);
  if (policy) throw new AuthError(policy);
  const { error } = await supabase.auth.updateUser({ password });
  if (error) throw new AuthError(translateAuthError(error.message));
}

export async function signOut(supabase: AppSupabase): Promise<void> {
  await supabase.auth.signOut();
}

export async function getSessionProfile(supabase: AppSupabase): Promise<Profile | null> {
  const { data } = await supabase.auth.getSession();
  if (!data.session?.user) return null;
  return getProfile(supabase, data.session.user.id);
}

export async function getProfile(
  supabase: AppSupabase,
  userId: string,
): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('perfiles')
    .select('id, nombre, correo, rol, estado_cuenta, ruta_foto_perfil, creado_en')
    .eq('id', userId)
    .maybeSingle();

  if (error) throw new AuthError(translateAuthError(error.message));
  if (!data) return null;

  return {
    id: data.id,
    name: data.nombre,
    email: data.correo,
    role: data.rol as UserRole,
    accountStatus: data.estado_cuenta as Profile['accountStatus'],
    profilePhotoPath: data.ruta_foto_perfil,
    createdAt: data.creado_en,
  };
}

export function requireRole(profile: Profile, allowed: UserRole[]): void {
  if (!allowed.includes(profile.role)) {
    throw new AuthError('No tienes permisos para acceder a esta aplicación.');
  }
}

export type OAuthProviderId = 'google' | 'apple';

export async function signInWithOAuthProvider(
  supabase: AppSupabase,
  provider: OAuthProviderId,
  redirectTo: string,
): Promise<void> {
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo,
      ...(provider === 'google'
        ? { queryParams: { access_type: 'offline', prompt: 'consent' } }
        : {}),
    },
  });
  if (error) throw new AuthError(translateAuthError(error.message));
}
