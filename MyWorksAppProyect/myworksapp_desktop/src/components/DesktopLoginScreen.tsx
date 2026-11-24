import { useState } from 'react';
import { AuthError, requestPasswordReset } from '@myworksapp/shared';
import { useAuth } from '../context/auth-store';
import { friendlyError } from '../lib/errors';
import { authRedirectUrl } from '../lib/redirect';
import { callRpc } from '../lib/rpc';
import { supabase } from '../supabaseClient';
import { Button } from '../ui/kit';

export function DesktopLoginScreen() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  return (
    <div className="login-screen">
      <aside className="login-brand">
        <img src="/brand/mark.svg" alt="" width={40} height={40} />
        <h1>Consola MyWorksApp</h1>
        <p>Operación del marketplace para administración, soporte y QA.</p>
      </aside>
      <section className="login-panel">
        <form
          className="login-card stack"
          onSubmit={(event) => {
            event.preventDefault();
            setSubmitting(true);
            setError(null);
            void login(email, password)
              .catch((reason: unknown) => {
                void callRpc('registrar_evento_acceso', { p_tipo: 'login_fallido', p_correo: email }).catch(() => undefined);
                setError(reason instanceof AuthError ? reason.message : 'No se pudo iniciar sesión.');
              })
              .finally(() => setSubmitting(false));
          }}
        >
          <h2>Entrar</h2>
          <label className="field">
            <span>Correo</span>
            <input id="login-email" type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} required />
          </label>
          <label className="field">
            <span>Contraseña</span>
            <input
              id="login-password"
              type={showPassword ? 'text' : 'password'}
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </label>
          <button type="button" className="btn btn-ghost" onClick={() => setShowPassword((value) => !value)}>
            {showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          </button>
          {error ? <p role="alert">{error}</p> : null}
          {notice ? <p role="status">{notice}</p> : null}
          <Button type="submit" busy={submitting}>Entrar</Button>
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => {
              setError(null);
              setNotice(null);
              if (!email.trim()) {
                setError('Escribe tu correo para recuperar la clave.');
                return;
              }
              void requestPasswordReset(supabase, email, authRedirectUrl())
                .then(() => setNotice('Si el correo está registrado, te enviamos un enlace para definir la contraseña.'))
                .catch((reason: unknown) => {
                  setError(reason instanceof AuthError
                    ? friendlyError(reason, 'No se pudo enviar el correo de recuperación.')
                    : 'No se pudo enviar el correo de recuperación.');
                });
            }}
          >
            Recuperar contraseña
          </button>
        </form>
      </section>
    </div>
  );
}
