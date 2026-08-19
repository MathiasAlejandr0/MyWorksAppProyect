import type { SupabaseClient } from '@supabase/supabase-js';
import type { Profile, UserRole } from './types';

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

export async function signIn(
  supabase: SupabaseClient,
  email: string,
  password: string,
): Promise<Profile> {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new AuthError(error.message);
  if (!data.user) throw new AuthError('No se pudo iniciar sesión.');

  const profile = await getProfile(supabase, data.user.id);
  if (!profile) throw new AuthError('Perfil no encontrado.');
  if (profile.accountStatus !== 'active') {
    await supabase.auth.signOut();
    throw new AuthError('Cuenta suspendida o bloqueada.');
  }
  return profile;
}

export async function signUpUser(
  supabase: SupabaseClient,
  email: string,
  password: string,
  name: string,
): Promise<Profile> {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { name, role: 'user' } },
  });
  if (error) throw new AuthError(error.message);
  if (!data.user) throw new AuthError('No se pudo registrar la cuenta.');

  const profile = await getProfile(supabase, data.user.id);
  if (profile) return profile;

  return {
    id: data.user.id,
    name,
    email,
    role: 'user',
    accountStatus: 'active',
  };
}

export async function signOut(supabase: SupabaseClient): Promise<void> {
  await supabase.auth.signOut();
}

export async function getSessionProfile(supabase: SupabaseClient): Promise<Profile | null> {
  const { data } = await supabase.auth.getSession();
  if (!data.session?.user) return null;
  return getProfile(supabase, data.session.user.id);
}

export async function getProfile(
  supabase: SupabaseClient,
  userId: string,
): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, email, role, accountStatus, profilePhotoPath, createdAt')
    .eq('id', userId)
    .maybeSingle();

  if (error) throw new AuthError(error.message);
  if (!data) return null;

  return {
    id: data.id as string,
    name: data.name as string,
    email: data.email as string,
    role: data.role as UserRole,
    accountStatus: data.accountStatus as Profile['accountStatus'],
    profilePhotoPath: data.profilePhotoPath as string | null | undefined,
    createdAt: data.createdAt as string | undefined,
  };
}

export function requireRole(profile: Profile, allowed: UserRole[]): void {
  if (!allowed.includes(profile.role)) {
    throw new AuthError('No tienes permisos para acceder a esta aplicación.');
  }
}
