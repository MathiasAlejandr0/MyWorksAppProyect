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
  requireRole,
  signIn,
  signOut,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshProfile = useCallback(async () => {
    try {
      const current = await getSessionProfile(supabase);
      if (current) {
        requireRole(current, ['admin']);
      }
      setProfile(current);
    } catch {
      setProfile(null);
      await signOut(supabase);
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
    const nextProfile = await signIn(supabase, email, password);
    requireRole(nextProfile, ['admin']);
    setProfile(nextProfile);
  }, []);

  const logout = useCallback(async () => {
    await signOut(supabase);
    setProfile(null);
  }, []);

  const value = useMemo(
    () => ({ profile, loading, login, logout }),
    [profile, loading, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}

export { AuthError };
