import { useContext } from 'react';
import { AuthContext, type AuthContextValue } from './authContextValue';

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
