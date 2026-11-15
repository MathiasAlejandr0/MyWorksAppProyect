import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import type { Profile } from '@myworksapp/shared';
import {
  AuthError,
  PASSWORD_SETUP_STORAGE_KEY,
  authLinkRequiresPassword,
  getSessionProfile,
  requireRole,
  signIn,
  signOut,
  updateAccountPassword,
} from '@myworksapp/shared';
import { canAccessDesktopHub } from '../authAccess';
import { supabase } from '../supabaseClient';

interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  needsMfa: boolean;
  mustSetPassword: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  completeMfa: () => Promise<void>;
  finishPasswordSetup: (password: string) => Promise<void>;
}

function locationRequiresPassword(): boolean {
  if (typeof window === 'undefined') return false;
  return (
    authLinkRequiresPassword(window.location.hash) ||
    authLinkRequiresPassword(window.location.search)
  );
}

function readMustSetPassword(): boolean {
  if (locationRequiresPassword()) {
    sessionStorage.setItem(PASSWORD_SETUP_STORAGE_KEY, '1');
    return true;
  }
  return sessionStorage.getItem(PASSWORD_SETUP_STORAGE_KEY) === '1';
}

function clearPasswordSetupFlag(): void {
  sessionStorage.removeItem(PASSWORD_SETUP_STORAGE_KEY);
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [needsMfa, setNeedsMfa] = useState(false);
  const [mustSetPassword, setMustSetPassword] = useState(readMustSetPassword);
  const [loading, setLoading] = useState(true);
  const mustSetPasswordRef = useRef(mustSetPassword);
  mustSetPasswordRef.current = mustSetPassword;

  const sessionNeedsMfa = useCallback(async () => {
    const { data } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    return data?.currentLevel !== 'aal2';
  }, []);

  const refreshProfile = useCallback(async (options?: { skipPasswordGate?: boolean }) => {
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      const gating = !options?.skipPasswordGate && mustSetPasswordRef.current;
      if (gating) {
        const urlStillRequires = locationRequiresPassword();
        if (!sessionData.session && !urlStillRequires) {
          clearPasswordSetupFlag();
          mustSetPasswordRef.current = false;
          setMustSetPassword(false);
        } else {
          setProfile(null);
          setNeedsMfa(false);
          return;
        }
      }
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
      if (event === 'PASSWORD_RECOVERY') {
        sessionStorage.setItem(PASSWORD_SETUP_STORAGE_KEY, '1');
        mustSetPasswordRef.current = true;
        setMustSetPassword(true);
        setNeedsMfa(false);
        setProfile(null);
        setLoading(false);
        return;
      }
      if (event === 'INITIAL_SESSION' || event === 'TOKEN_REFRESHED') return;
      if (mustSetPasswordRef.current) return;
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
    clearPasswordSetupFlag();
    mustSetPasswordRef.current = false;
    setMustSetPassword(false);
    await signOut(supabase);
    setProfile(null);
    setNeedsMfa(false);
  }, []);

  const finishPasswordSetup = useCallback(async (password: string) => {
    await updateAccountPassword(supabase, password);
    clearPasswordSetupFlag();
    mustSetPasswordRef.current = false;
    setMustSetPassword(false);
    const url = new URL(window.location.href);
    url.hash = '';
    url.searchParams.delete('code');
    url.searchParams.delete('type');
    window.history.replaceState(null, '', `${url.pathname}${url.search}`);
    await refreshProfile({ skipPasswordGate: true });
  }, [refreshProfile]);

  const completeMfa = useCallback(async () => {
    await refreshProfile();
  }, [refreshProfile]);

  const value = useMemo(
    () => ({
      profile,
      loading,
      needsMfa,
      mustSetPassword,
      login,
      logout,
      completeMfa,
      finishPasswordSetup,
    }),
    [profile, loading, needsMfa, mustSetPassword, login, logout, completeMfa, finishPasswordSetup],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}

export { AuthError };
