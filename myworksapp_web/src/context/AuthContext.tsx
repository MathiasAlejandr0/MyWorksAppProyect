import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { Profile } from '@myworksapp/shared';
import {
  AuthError,
  getSessionProfile,
  signIn,
  signInWithOAuthProvider,
  signOut,
  signUpUser,
  type OAuthProviderId,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

/** Mensaje claro cuando un trabajador/admin intenta usar el marketplace web. */
export const WEB_CLIENT_ROLE_MESSAGE =
  'El sitio web de clientes es solo para cuentas de usuario (cliente). Trabajadores deben usar la app móvil; administradores, el panel desktop.';

interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  loginWithOAuth: (provider: OAuthProviderId) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

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

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
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

  const register = useCallback(async (name: string, email: string, password: string) => {
    setError(null);
    const nextProfile = await signUpUser(supabase, email, password, name);
    const allowed = await enforceWebClientRole(nextProfile);
    setProfile(allowed);
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
    }),
    [profile, loading, error, login, loginWithOAuth, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
