import { useState } from 'react';
import { LogIn, UserPlus, X } from 'lucide-react';
import { AuthError } from '@myworksapp/shared';
import { useAuth } from '../context/AuthContext';

interface AuthModalProps {
  open: boolean;
  onClose: () => void;
}

export function AuthModal({ open, onClose }: AuthModalProps) {
  const { login, loginWithOAuth, register } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('usuario@demo.com');
  const [password, setPassword] = useState('demo123');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  if (!open) return null;

  const handleOAuth = async (provider: 'google' | 'apple') => {
    setSubmitting(true);
    setLocalError(null);
    try {
      await loginWithOAuth(provider);
    } catch (e) {
      setLocalError(e instanceof AuthError ? e.message : 'No se pudo iniciar sesión social.');
      setSubmitting(false);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setLocalError(null);
    try {
      if (mode === 'login') {
        await login(email, password);
      } else {
        await register(name, email, password);
      }
      onClose();
    } catch (e) {
      setLocalError(e instanceof AuthError ? e.message : 'No se pudo completar la operación.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0,0,0,0.55)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '20px',
      }}
    >
      <div className="card-3d" style={{ width: '100%', maxWidth: '420px', padding: '24px', position: 'relative' }}>
        <button
          onClick={onClose}
          style={{ position: 'absolute', top: '12px', right: '12px', border: 'none', background: 'transparent', cursor: 'pointer' }}
          aria-label="Cerrar"
        >
          <X size={18} />
        </button>

        <h2 style={{ fontSize: '22px', fontWeight: 800, marginBottom: '8px' }}>
          {mode === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}
        </h2>
        <p style={{ fontSize: '13px', color: 'var(--text-muted-dark)', marginBottom: '8px' }}>
          Solo cuentas de cliente (<strong>usuario</strong>). Trabajadores usan la app móvil; administradores, el panel desktop.
        </p>
        <p style={{ fontSize: '12px', color: 'var(--text-muted-dark)', marginBottom: '16px', opacity: 0.9 }}>
          Autenticación con Supabase Auth.
        </p>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {mode === 'register' && (
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Nombre completo"
              required
              style={{ padding: '12px 14px', borderRadius: '10px', border: '1px solid var(--border-dark)', background: 'var(--bg-elevated-dark)', color: 'var(--text-main-dark)' }}
            />
          )}
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
            required
            style={{ padding: '12px 14px', borderRadius: '10px', border: '1px solid var(--border-dark)', background: 'var(--bg-elevated-dark)', color: 'var(--text-main-dark)' }}
          />
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Contraseña"
            required
            style={{ padding: '12px 14px', borderRadius: '10px', border: '1px solid var(--border-dark)', background: 'var(--bg-elevated-dark)', color: 'var(--text-main-dark)' }}
          />

          {localError && (
            <div style={{ color: '#FF3B30', fontSize: '13px', fontWeight: 600 }}>{localError}</div>
          )}

          <button type="submit" className="btn-primary" disabled={submitting} style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
            {mode === 'login' ? <LogIn size={16} /> : <UserPlus size={16} />}
            {submitting ? 'Procesando...' : mode === 'login' ? 'Entrar' : 'Registrarme'}
          </button>
        </form>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', margin: '16px 0' }}>
          <div style={{ flex: 1, height: '1px', background: 'var(--border-dark)' }} />
          <span style={{ fontSize: '12px', color: 'var(--text-muted-dark)', fontWeight: 600 }}>o continúa con</span>
          <div style={{ flex: 1, height: '1px', background: 'var(--border-dark)' }} />
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <button
            type="button"
            disabled={submitting}
            onClick={() => void handleOAuth('google')}
            style={{
              padding: '12px 14px',
              borderRadius: '10px',
              border: '1px solid var(--border-dark)',
              background: 'var(--bg-elevated-dark)',
              color: 'var(--text-main-dark)',
              fontWeight: 700,
              cursor: submitting ? 'not-allowed' : 'pointer',
            }}
          >
            Continuar con Google
          </button>
          <button
            type="button"
            disabled={submitting}
            onClick={() => void handleOAuth('apple')}
            style={{
              padding: '12px 14px',
              borderRadius: '10px',
              border: '1px solid var(--border-light)',
              background: '#000',
              color: '#fff',
              fontWeight: 700,
              cursor: submitting ? 'not-allowed' : 'pointer',
            }}
          >
            Continuar con Apple
          </button>
        </div>

        <button
          type="button"
          onClick={() => setMode(mode === 'login' ? 'register' : 'login')}
          style={{ marginTop: '12px', background: 'transparent', border: 'none', color: '#F0782A', fontWeight: 700, cursor: 'pointer', width: '100%' }}
        >
          {mode === 'login' ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'}
        </button>
      </div>
    </div>
  );
}
