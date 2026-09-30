import { useState } from 'react';
import { LogIn, UserPlus, X } from 'lucide-react';
import { AuthError, passwordPolicyMessage } from '@myworksapp/shared';
import { useAuth } from '../context/AuthContext';
import { TurnstileWidget } from './TurnstileWidget';
import { turnstileSiteKey } from './turnstileSite';

interface AuthModalProps {
  open: boolean;
  onClose: () => void;
}

export function AuthModal({ open, onClose }: AuthModalProps) {
  const { login, loginWithOAuth, register } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [name, setName] = useState('');
  const [email, setEmail] = useState(
    import.meta.env.DEV ? 'usuario@demo.com' : '',
  );
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [captchaToken, setCaptchaToken] = useState('');

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
        const policy = passwordPolicyMessage(password);
        if (policy) {
          setLocalError(policy);
          return;
        }
        if (turnstileSiteKey() && !captchaToken) {
          setLocalError('Confirma que no eres un robot');
          return;
        }
        await register(name, email, password, captchaToken || undefined);
      }
      onClose();
    } catch (e) {
      setLocalError(e instanceof AuthError ? e.message : 'No se pudo completar la operación.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth-modal-backdrop modal-fade-in" role="dialog" aria-modal="true" aria-labelledby="auth-modal-title">
      <div className="card-3d auth-modal-card modal-rise">
        <button type="button" className="modal-close" onClick={onClose} aria-label="Cerrar">
          <X size={18} />
        </button>

        <p className="auth-modal-kicker">Acceso clientes</p>
        <h2 id="auth-modal-title" className="auth-modal-title">
          {mode === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}
        </h2>
        <p className="auth-modal-lead">
          Esta web es solo para <strong>clientes</strong> que buscan un oficio. Los trabajadores usan la app móvil; el equipo interno, el panel de escritorio.
        </p>

        <form onSubmit={handleSubmit} className="auth-modal-form">
          {mode === 'register' && (
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Nombre completo"
              required
              className="auth-modal-input"
            />
          )}
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
            required
            className="auth-modal-input"
          />
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Contraseña"
            required
            autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
            aria-invalid={localError ? true : undefined}
            aria-describedby={mode === 'register' ? 'auth-password-policy' : undefined}
            className="auth-modal-input"
          />
          {mode === 'register' && (
            <p id="auth-password-policy" className="auth-modal-hint">
              Mínimo 8 caracteres, con al menos una letra y un número.
            </p>
          )}
          {mode === 'register' ? <TurnstileWidget onToken={setCaptchaToken} /> : null}

          {localError && (
            <div className="auth-modal-error" role="alert">
              {localError}
            </div>
          )}

          <button type="submit" className="btn-primary auth-modal-submit" disabled={submitting}>
            {mode === 'login' ? <LogIn size={16} /> : <UserPlus size={16} />}
            {submitting ? 'Un momento…' : mode === 'login' ? 'Entrar' : 'Registrarme'}
          </button>
        </form>

        <div className="auth-modal-divider">
          <span>o continúa con</span>
        </div>

        <div className="auth-modal-oauth">
          <button type="button" className="auth-oauth-btn" disabled={submitting} onClick={() => void handleOAuth('google')}>
            Continuar con Google
          </button>
          <button type="button" className="auth-oauth-btn auth-oauth-apple" disabled={submitting} onClick={() => void handleOAuth('apple')}>
            Continuar con Apple
          </button>
        </div>

        <button
          type="button"
          className="auth-modal-switch"
          onClick={() => {
            setMode(mode === 'login' ? 'register' : 'login');
            setLocalError(null);
          }}
        >
          {mode === 'login' ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'}
        </button>
      </div>
    </div>
  );
}
