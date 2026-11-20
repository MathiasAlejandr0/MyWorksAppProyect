import { createContext, useContext } from 'react';
import type { Profile } from '@myworksapp/shared';

export interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  needsMfa: boolean;
  mustSetPassword: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  completeMfa: () => Promise<void>;
  finishPasswordSetup: (password: string) => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
