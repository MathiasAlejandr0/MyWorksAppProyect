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
  signOut,
  signUpUser,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshProfile = useCallback(async () => {
    try {
      const current = await getSessionProfile(supabase);
      setProfile(current);
    } catch (e) {
      setProfile(null);
      setError(e instanceof AuthError ? e.message : 'Error de sesión');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshProfile();
    const { data: subscription } = supabase.auth.onAuthStateChange(() => {
      void refreshProfile();
    });
    return () => subscription.subscription.unsubscribe();
  }, [refreshProfile]);

  const login = useCallback(async (email: string, password: string) => {
    setError(null);
    const nextProfile = await signIn(supabase, email, password);
    if (nextProfile.role !== 'user') {
      await signOut(supabase);
      throw new AuthError('Esta versión web es solo para clientes.');
    }
    setProfile(nextProfile);
  }, []);

  const register = useCallback(async (name: string, email: string, password: string) => {
    setError(null);
    const nextProfile = await signUpUser(supabase, email, password, name);
    setProfile(nextProfile);
  }, []);

  const logout = useCallback(async () => {
    await signOut(supabase);
    setProfile(null);
  }, []);

  const value = useMemo(
    () => ({
      profile,
      loading,
      error,
      login,
      register,
      logout,
      clearError: () => setError(null),
    }),
    [profile, loading, error, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
