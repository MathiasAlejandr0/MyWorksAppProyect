import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { Profile } from '@myworksapp/shared';
import {
  AuthError,
  getSessionProfile,
  PASSWORD_RESET_PARAM,
  passwordResetRedirect,
  requestPasswordReset,
  signIn,
  signInWithOAuthProvider,
  signOut,
  signUpUser,
  updateAccountPassword,
  type OAuthProviderId,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { AuthContext } from './authContextValue';

/** Mensaje claro cuando un trabajador/admin intenta usar el marketplace web. */
export const WEB_CLIENT_ROLE_MESSAGE =
  'El sitio web de clientes es solo para cuentas de usuario (cliente). Trabajadores deben usar la app móvil; administradores, el panel desktop.';



/**
 * El marketplace web solo admite rol `usuario`.
 * Cualquier otra sesión (trabajador, administrador) se cierra con mensaje explícito.
 */
async function enforceWebClientRole(profile: Profile | null): Promise<Profile | null> {
  if (!profile) return null;
  if (profile.role !== 'usuario') {
    await signOut(supabase);
    throw new AuthError(WEB_CLIENT_ROLE_MESSAGE);
  }
  return profile;
}

function urlMarksPasswordReset(): boolean {
  if (typeof window === 'undefined') return false;
  return new URLSearchParams(window.location.search).has(PASSWORD_RESET_PARAM);
}

function clearPasswordResetParam(): void {
  if (typeof window === 'undefined') return;
  const url = new URL(window.location.href);
  if (!url.searchParams.has(PASSWORD_RESET_PARAM)) return;
  url.searchParams.delete(PASSWORD_RESET_PARAM);
  window.history.replaceState(null, '', `${url.pathname}${url.search}${url.hash}`);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [recoveringPassword, setRecoveringPassword] = useState(urlMarksPasswordReset);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshProfile = useCallback(async () => {
    try {
      const current = await getSessionProfile(supabase);
      const allowed = await enforceWebClientRole(current);
      setProfile(allowed);
      if (allowed) setError(null);
    } catch (e) {
      setProfile(null);
      setError(e instanceof AuthError ? e.message : 'Error de sesión');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let inFlight: Promise<void> | null = null;
    const run = () => {
      if (inFlight) return inFlight;
      inFlight = refreshProfile().finally(() => {
        inFlight = null;
      });
      return inFlight;
    };

    void run();
    const { data: subscription } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') setRecoveringPassword(true);
      if (event === 'INITIAL_SESSION' || event === 'TOKEN_REFRESHED') return;
      void run();
    });
    return () => subscription.subscription.unsubscribe();
  }, [refreshProfile]);

  const login = useCallback(async (email: string, password: string) => {
    setError(null);
    const nextProfile = await signIn(supabase, email, password);
    try {
      const allowed = await enforceWebClientRole(nextProfile);
      setProfile(allowed);
    } catch (e) {
      setProfile(null);
      const message = e instanceof AuthError ? e.message : WEB_CLIENT_ROLE_MESSAGE;
      setError(message);
      throw e instanceof AuthError ? e : new AuthError(message);
    }
  }, []);

  const loginWithOAuth = useCallback(async (provider: OAuthProviderId) => {
    setError(null);
    // Tras el callback OAuth, getSession / onAuthStateChange aplican enforceWebClientRole.
    await signInWithOAuthProvider(supabase, provider, window.location.origin);
  }, []);

  const register = useCallback(async (
    name: string,
    email: string,
    password: string,
    captchaToken?: string,
  ) => {
    setError(null);
    const result = await signUpUser(supabase, email, password, name, captchaToken);
    if (result.status === 'confirmation_required') return result.status;
    const allowed = await enforceWebClientRole(result.profile);
    setProfile(allowed);
    return result.status;
  }, []);

  const sendPasswordReset = useCallback(async (email: string) => {
    await requestPasswordReset(supabase, email, passwordResetRedirect(window.location.origin));
  }, []);

  const finishPasswordReset = useCallback(async (password: string) => {
    const { data } = await supabase.auth.getSession();
    if (!data.session) {
      throw new AuthError('El enlace venció, ya se usó o se abrió en otro navegador. Pide uno nuevo desde «¿Olvidaste tu contraseña?» y ábrelo en este mismo navegador.');
    }
    await updateAccountPassword(supabase, password);
    clearPasswordResetParam();
    setRecoveringPassword(false);
  }, []);

  const cancelPasswordReset = useCallback(async () => {
    clearPasswordResetParam();
    setRecoveringPassword(false);
    await signOut(supabase);
    setProfile(null);
  }, []);

  const logout = useCallback(async () => {
    await signOut(supabase);
    setProfile(null);
    setError(null);
  }, []);

  const value = useMemo(
    () => ({
      profile,
      loading,
      error,
      login,
      loginWithOAuth,
      register,
      logout,
      clearError: () => setError(null),
      recoveringPassword,
      sendPasswordReset,
      finishPasswordReset,
      cancelPasswordReset,
    }),
    [
      profile,
      loading,
      error,
      login,
      loginWithOAuth,
      register,
      logout,
      recoveringPassword,
      sendPasswordReset,
      finishPasswordReset,
      cancelPasswordReset,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
