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
import { canAccessDesktopHub } from '../authAccess';
import { supabase } from '../supabaseClient';

interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  needsMfa: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  completeMfa: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [needsMfa, setNeedsMfa] = useState(false);
  const [loading, setLoading] = useState(true);

  const sessionNeedsMfa = useCallback(async () => {
    const { data } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    return data?.currentLevel !== 'aal2';
  }, []);

  const refreshProfile = useCallback(async () => {
    try {
      const current = await getSessionProfile(supabase);
      if (!current) {
        setProfile(null);
        setNeedsMfa(false);
        return;
      }
      requireRole(current, ['administrador']);
      if (!canAccessDesktopHub(current.role)) {
        throw new AuthError('Solo el rol administrador puede usar la consola ops.');
      }
      if (await sessionNeedsMfa()) {
        setProfile(null);
        setNeedsMfa(true);
        return;
      }
      setNeedsMfa(false);
      setProfile(current);
    } catch {
      setProfile(null);
      setNeedsMfa(false);
      await signOut(supabase);
    } finally {
      setLoading(false);
    }
  }, [sessionNeedsMfa]);

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
    const nextProfile = await signIn(supabase, email, password);
    try {
      requireRole(nextProfile, ['administrador']);
      if (!canAccessDesktopHub(nextProfile.role)) {
        throw new AuthError('Solo el rol administrador puede usar la consola ops.');
      }
      if (await sessionNeedsMfa()) {
        setProfile(null);
        setNeedsMfa(true);
        return;
      }
      setNeedsMfa(false);
      setProfile(nextProfile);
    } catch (err) {
      await signOut(supabase);
      setProfile(null);
      setNeedsMfa(false);
      throw err instanceof AuthError
        ? err
        : new AuthError('Solo el rol administrador puede usar la consola ops.');
    }
  }, [sessionNeedsMfa]);

  const logout = useCallback(async () => {
    await signOut(supabase);
    setProfile(null);
    setNeedsMfa(false);
  }, []);

  const completeMfa = useCallback(async () => {
    await refreshProfile();
  }, [refreshProfile]);

  const value = useMemo(
    () => ({ profile, loading, needsMfa, login, logout, completeMfa }),
    [profile, loading, needsMfa, login, logout, completeMfa],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}

export { AuthError };
