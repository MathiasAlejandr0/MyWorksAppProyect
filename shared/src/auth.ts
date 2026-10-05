import type { AppSupabase } from './client';
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
  if (/weak password|password should be at least|password should contain|password is known/i.test(text)) {
    return 'La contraseña es débil. Usa al menos 8 caracteres, con una letra y un número.';
  }
  return text;
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

export async function signUpUser(
  supabase: AppSupabase,
  email: string,
  password: string,
  name: string,
  captchaToken?: string,
): Promise<Profile> {
  const policy = passwordPolicyMessage(password);
  if (policy) throw new AuthError(policy);

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { name, role: 'usuario' },
      ...(captchaToken ? { captchaToken } : {}),
    },
  });
  if (error) throw new AuthError(translateAuthError(error.message));
  if (!data.user) throw new AuthError('No se pudo registrar la cuenta.');

  const profile = await getProfile(supabase, data.user.id);
  if (profile) return profile;

  return {
    id: data.user.id,
    name,
    email,
    role: 'usuario',
    accountStatus: 'activo',
  };
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
