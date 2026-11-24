import { useEffect, useRef, useState } from 'react';
import { KeyRound, LogIn, UserPlus, X } from 'lucide-react';
import {
  AuthError,
  isEmailNotConfirmed,
  passwordPolicyMessage,
  resendSignupConfirmation,
} from '@myworksapp/shared';
import { supabase, SUPABASE_ANON_KEY, SUPABASE_URL } from '../supabaseClient';
import { useDialogA11y } from '../hooks/useDialogA11y';
import { useAuth } from '../context/useAuth';
import { AcademicInlineNote } from './AcademicInlineNote';
import { TurnstileWidget } from './TurnstileWidget';
import { turnstileCanRender } from './turnstileSite';

interface AuthModalProps {
  open: boolean;
  onClose: () => void;
  /** Correo del invitado, solo cuando el diálogo se abre desde «Ver mi pedido». */
  initialEmail?: string;
  /** Pestaña con la que abre: «Registrarse» entra directo a crear cuenta. */
  initialMode?: 'login' | 'register';
}

export function AuthModal({ open, onClose, initialEmail = '', initialMode = 'login' }: AuthModalProps) {
  const { login, loginWithOAuth, register, sendPasswordReset } = useAuth();
  const [mode, setMode] = useState<'login' | 'register' | 'forgot'>('login');
  const [resetSent, setResetSent] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState(() => initialEmail.trim());
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [resendNote, setResendNote] = useState<string | null>(null);
  const [confirmationSentTo, setConfirmationSentTo] = useState<string | null>(null);
  const [captchaToken, setCaptchaToken] = useState('');
  const wasOpen = useRef(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  const [providers, setProviders] = useState({ google: false, apple: false });
  const [resendWait, setResendWait] = useState(0);
  useDialogA11y(open, onClose, dialogRef);

  useEffect(() => {
    if (open && !wasOpen.current) {
      setEmail(initialEmail.trim());
      setPassword('');
      setLocalError(null);
      setResendNote(null);
      setConfirmationSentTo(null);
      setResetSent(false);
      setMode(initialMode);
    }
    wasOpen.current = open;
  }, [open, initialEmail, initialMode]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    void fetch(`${SUPABASE_URL}/auth/v1/settings`, {
      headers: { apikey: SUPABASE_ANON_KEY },
    })
      .then((response) => response.json())
      .then((body: { external?: { google?: boolean; apple?: boolean } }) => {
        if (cancelled) return;
        const external = body.external ?? {};
        setProviders({
          google: external.google === true,
          apple: external.apple === true && import.meta.env.VITE_AUTH_APPLE_ENABLED === '1',
        });
      })
      .catch(() => {
        if (!cancelled) setProviders({ google: false, apple: false });
      });
    return () => {
      cancelled = true;
    };
  }, [open]);

  useEffect(() => {
    if (resendWait <= 0) return;
    const timer = window.setTimeout(() => setResendWait((value) => Math.max(0, value - 1)), 1000);
    return () => window.clearTimeout(timer);
  }, [resendWait]);

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
    setResendNote(null);
    try {
      if (mode === 'forgot') {
        await sendPasswordReset(email);
        setResetSent(true);
        return;
      }
      if (mode === 'login') {
        await login(email, password);
      } else {
        const policy = passwordPolicyMessage(password);
        if (policy) {
          setLocalError(policy);
          return;
        }
        if (turnstileCanRender() && !captchaToken) {
          setLocalError('Confirma que no eres un robot');
          return;
        }
        const status = await register(name, email, password, captchaToken || undefined);
        if (status === 'confirmation_required') {
          setConfirmationSentTo(email.trim());
          setPassword('');
          return;
        }
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
      <div className="card-3d auth-modal-card modal-rise" ref={dialogRef}>
        <button type="button" className="modal-close" onClick={onClose} aria-label="Cerrar">
          <X size={18} />
        </button>

        <p className="auth-modal-kicker">Acceso clientes</p>
        <h2 id="auth-modal-title" className="auth-modal-title">
          {mode === 'login' ? 'Iniciar sesión' : mode === 'register' ? 'Crear cuenta' : 'Recuperar contraseña'}
        </h2>
        <p className="auth-modal-lead">
          Esta web es solo para <strong>clientes</strong> que buscan un oficio. Los trabajadores usan la app móvil; el equipo interno, el panel de escritorio.
        </p>

        {confirmationSentTo ? (
          <div className="auth-modal-form" role="status">
            <p className="auth-modal-success">
              Creamos tu cuenta. Te enviamos un correo a <strong>{confirmationSentTo}</strong> para confirmarla.
              Ábrelo y toca el enlace; después inicia sesión. Si no llega, revisa spam.
            </p>
            {resendNote ? <p role="status">{resendNote}</p> : null}
            {localError ? (
              <div className="auth-modal-error" role="alert">
                {localError}
              </div>
            ) : null}
            <button
              type="button"
              className="auth-modal-switch"
              disabled={submitting}
              onClick={() => {
                setSubmitting(true);
                setResendNote(null);
                setLocalError(null);
                void resendSignupConfirmation(supabase, confirmationSentTo)
                  .then(() => setResendNote('Te enviamos el correo de nuevo.'))
                  .catch((e: unknown) => {
                    setLocalError(e instanceof AuthError ? e.message : 'No se pudo reenviar el correo.');
                  })
                  .finally(() => setSubmitting(false));
              }}
            >
              Reenviar correo de confirmación
            </button>
            <button
              type="button"
              className="btn-primary auth-modal-submit"
              onClick={() => {
                setEmail(confirmationSentTo);
                setConfirmationSentTo(null);
                setResendNote(null);
                setLocalError(null);
                setMode('login');
              }}
            >
              <LogIn size={16} /> Ir a iniciar sesión
            </button>
          </div>
        ) : (
          <>
        <form onSubmit={handleSubmit} className="auth-modal-form">
          {mode === 'register' && (
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Nombre completo"
              aria-label="Nombre completo"
              autoComplete="name"
              required
              className="auth-modal-input"
            />
          )}
          {mode === 'forgot' ? (
            <p className="auth-modal-hint" id="auth-forgot-help">
              Escribe el correo de tu cuenta y te enviaremos un enlace para crear una contraseña nueva.
            </p>
          ) : null}
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
            aria-label="Correo electrónico"
            aria-describedby={mode === 'forgot' ? 'auth-forgot-help' : undefined}
            autoComplete="email"
            required
            className="auth-modal-input"
          />
          {mode !== 'forgot' ? (
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Contraseña"
              aria-label="Contraseña"
              required
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              aria-invalid={localError ? true : undefined}
              aria-describedby={mode === 'register' ? 'auth-password-policy' : undefined}
              className="auth-modal-input"
            />
          ) : null}
          {mode === 'login' ? (
            <button
              type="button"
              className="auth-modal-switch auth-modal-forgot"
              onClick={() => {
                setMode('forgot');
                setLocalError(null);
                setResetSent(false);
              }}
            >
              ¿Olvidaste tu contraseña?
            </button>
          ) : null}
          {mode === 'forgot' && resetSent ? (
            <p role="status" className="auth-modal-success">
              Si {email.trim()} tiene una cuenta, te llegará un correo con el enlace. Revisa también la carpeta de spam.
            </p>
          ) : null}
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
          {mode === 'login' && localError && isEmailNotConfirmed(localError) ? (
            <button
              type="button"
              className="auth-modal-switch"
              disabled={submitting || resendWait > 0}
              onClick={() => {
                setSubmitting(true);
                setResendNote(null);
                void resendSignupConfirmation(supabase, email.trim())
                  .then(() => {
                    setResendNote('Te enviamos un correo para confirmar.');
                    setResendWait(60);
                  })
                  .catch((e: unknown) => {
                    setLocalError(e instanceof AuthError ? e.message : 'No se pudo reenviar el correo.');
                  })
                  .finally(() => setSubmitting(false));
              }}
            >
              {resendWait > 0 ? `Reenviar en ${resendWait} s` : 'Reenviar correo de confirmación'}
            </button>
          ) : null}
          {resendNote ? <p role="status">{resendNote}</p> : null}

          {mode === 'register' ? <AcademicInlineNote /> : null}
          <button type="submit" className="btn-primary auth-modal-submit" disabled={submitting}>
            {mode === 'login' ? <LogIn size={16} /> : mode === 'register' ? <UserPlus size={16} /> : <KeyRound size={16} />}
            {submitting
              ? 'Un momento…'
              : mode === 'login'
                ? 'Entrar'
                : mode === 'register'
                  ? 'Registrarme'
                  : resetSent
                    ? 'Reenviar enlace'
                    : 'Enviar enlace'}
          </button>
        </form>

        {mode !== 'forgot' ? (
        <>
        <div className="auth-modal-divider">
          <span>o continúa con</span>
        </div>

        {providers.google || providers.apple ? (
        <div className="auth-modal-oauth">
          {providers.google ? (
          <button type="button" className="auth-oauth-btn" disabled={submitting} onClick={() => void handleOAuth('google')}>
            Continuar con Google
          </button>
          ) : null}
          {providers.apple ? (
          <button type="button" className="auth-oauth-btn auth-oauth-apple" disabled={submitting} onClick={() => void handleOAuth('apple')}>
            Continuar con Apple
          </button>
          ) : null}
        </div>
        ) : null}
        </>
        ) : null}

        <button
          type="button"
          className="auth-modal-switch"
          onClick={() => {
            setMode(mode === 'login' ? 'register' : 'login');
            setEmail('');
            setPassword('');
            setLocalError(null);
          }}
        >
          {mode === 'login' ? '¿No tienes cuenta? Regístrate' : mode === 'forgot' ? 'Volver a iniciar sesión' : '¿Ya tienes cuenta? Inicia sesión'}
        </button>
          </>
        )}
      </div>
    </div>
  );
}
