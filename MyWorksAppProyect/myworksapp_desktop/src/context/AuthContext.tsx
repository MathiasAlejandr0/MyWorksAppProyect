import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import type { Profile } from '@myworksapp/shared';
import { AuthContext } from './auth-store';
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
import { authDeepLinkPending, passwordSetupMarked } from '../lib/authCallback';
import { CONSOLE_ACCESS_DENIED, CONSOLE_ROLES, canAccessDesktopHub } from '../authAccess';
import { markTotpVerified } from '../lib/totp';
import { supabase } from '../supabaseClient';

let signOutTask: Promise<void> | null = null;

/** Un solo logout a la vez. Si no, rechazar un cliente dispara dos y el segundo responde 403. */
function signOutOnce(): Promise<void> {
  if (!signOutTask) {
    signOutTask = signOut(supabase).finally(() => {
      signOutTask = null;
    });
  }
  return signOutTask;
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

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [needsMfa, setNeedsMfa] = useState(false);
  const [mustSetPassword, setMustSetPassword] = useState(readMustSetPassword);
  const [loading, setLoading] = useState(true);
  const mustSetPasswordRef = useRef(mustSetPassword);
  useEffect(() => {
    mustSetPasswordRef.current = mustSetPassword;
  }, [mustSetPassword]);

  const sessionNeedsMfa = useCallback(async () => {
    const { data } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    return data?.currentLevel !== 'aal2';
  }, []);

  const refreshProfile = useCallback(async (options?: { skipPasswordGate?: boolean }) => {
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!options?.skipPasswordGate && passwordSetupMarked()) {
        mustSetPasswordRef.current = true;
      }
      const gating = !options?.skipPasswordGate && mustSetPasswordRef.current;
      const pendingLink = authDeepLinkPending();
      if (gating || pendingLink) {
        const urlStillRequires = locationRequiresPassword();
        if (!sessionData.session && !urlStillRequires && !pendingLink) {
          clearPasswordSetupFlag();
          mustSetPasswordRef.current = false;
          setMustSetPassword(false);
        } else if (gating || urlStillRequires) {
          setProfile(null);
          setNeedsMfa(false);
          setMustSetPassword(true);
          return;
        }
      }
      const current = await getSessionProfile(supabase);
      if (!current) {
        setProfile(null);
        setNeedsMfa(false);
        return;
      }
      requireRole(current, [...CONSOLE_ROLES]);
      if (!canAccessDesktopHub(current.role)) {
        throw new AuthError(CONSOLE_ACCESS_DENIED);
      }
      if (current.accountStatus !== 'activo') {
        throw new AuthError('Cuenta suspendida o bloqueada.');
      }
      if (!options?.skipPasswordGate && (passwordSetupMarked() || mustSetPasswordRef.current)) {
        sessionStorage.setItem(PASSWORD_SETUP_STORAGE_KEY, '1');
        mustSetPasswordRef.current = true;
        setMustSetPassword(true);
        setNeedsMfa(false);
        setProfile(null);
        return;
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
      await signOutOnce();
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
      // La invitación llega como SIGNED_IN. Se trata igual que la recuperación.
      const invite = event === 'SIGNED_IN' && passwordSetupMarked();
      if (event === 'PASSWORD_RECOVERY' || invite) {
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
      requireRole(nextProfile, [...CONSOLE_ROLES]);
      if (!canAccessDesktopHub(nextProfile.role)) {
        throw new AuthError(CONSOLE_ACCESS_DENIED);
      }
      if (await sessionNeedsMfa()) {
        setProfile(null);
        setNeedsMfa(true);
        return;
      }
      setNeedsMfa(false);
      setProfile(nextProfile);
    } catch (err) {
      await signOutOnce();
      setProfile(null);
      setNeedsMfa(false);
      throw err instanceof AuthError
        ? err
        : new AuthError(CONSOLE_ACCESS_DENIED);
    }
  }, [sessionNeedsMfa]);

  const logout = useCallback(async () => {
    clearPasswordSetupFlag();
    mustSetPasswordRef.current = false;
    setMustSetPassword(false);
    await signOutOnce();
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
    markTotpVerified();
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
