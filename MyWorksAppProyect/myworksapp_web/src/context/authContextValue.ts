import { createContext } from 'react';
import type { OAuthProviderId, Profile } from '@myworksapp/shared';

export interface AuthContextValue {
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  loginWithOAuth: (provider: OAuthProviderId) => Promise<void>;
  register: (name: string, email: string, password: string, captchaToken?: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
  /** La sesión viene de un enlace «restablecer contraseña»: hay que pedir la nueva. */
  recoveringPassword: boolean;
  sendPasswordReset: (email: string) => Promise<void>;
  finishPasswordReset: (password: string) => Promise<void>;
  cancelPasswordReset: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);
