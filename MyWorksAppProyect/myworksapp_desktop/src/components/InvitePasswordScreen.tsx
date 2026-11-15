import { useState } from 'react';
import { KeyRound, Eye, EyeOff } from 'lucide-react';
import { AuthError, passwordPolicyMessage } from '@myworksapp/shared';

interface InvitePasswordScreenProps {
  onSubmit: (password: string) => Promise<void>;
  onCancel: () => Promise<void>;
}

/** La invitación de RRHH abre la consola con sesión y sin clave elegida por la persona. */
export function InvitePasswordScreen({ onSubmit, onCancel }: InvitePasswordScreenProps) {
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const policy = passwordPolicyMessage(password);
    if (policy) {
      setError(policy);
      return;
    }
    if (password !== confirm) {
      setError('Las contraseñas no coinciden');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await onSubmit(password);
    } catch (e) {
      setError(e instanceof AuthError ? e.message : 'No se pudo guardar la contraseña.');
      setSubmitting(false);
    }
  };

  return (
    <div className="login-screen login-screen-single">
      <section className="login-form-panel">
        <div className="login-form-card">
          <p className="login-form-kicker">— INVITACIÓN RRHH —</p>
          <h2 className="login-form-title">Activa tu acceso</h2>
          <p className="login-form-subtitle" id="invite-password-policy">
            Elige una contraseña de al menos 8 caracteres, con una letra y un número.
          </p>

          <form onSubmit={(event) => void handleSubmit(event)}>
            <label className="login-field-label" htmlFor="invite-password">
              NUEVA CONTRASEÑA
            </label>
            <div className="login-field-wrap">
              <KeyRound size={16} className="login-field-icon" />
              <input
                id="invite-password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="new-password"
                placeholder="Mínimo 8 caracteres"
                className="login-input login-input-password"
                aria-describedby="invite-password-policy"
                aria-invalid={error ? true : undefined}
                required
              />
              <button
                type="button"
                className="login-eye-btn"
                onClick={() => setShowPassword((v) => !v)}
                aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>

            <label className="login-field-label" htmlFor="invite-password-confirm">
              CONFIRMAR CONTRASEÑA
            </label>
            <div className="login-field-wrap">
              <KeyRound size={16} className="login-field-icon" />
              <input
                id="invite-password-confirm"
                type={showPassword ? 'text' : 'password'}
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                autoComplete="new-password"
                placeholder="Repite la contraseña"
                className="login-input"
                required
              />
            </div>

            {error && (
              <p className="login-error" role="alert">
                {error}
              </p>
            )}

            <button type="submit" className="login-submit" disabled={submitting}>
              {submitting ? 'Guardando…' : 'Guardar contraseña'}
            </button>
          </form>

          <button
            type="button"
            className="sidebar-profile-btn"
            onClick={() => void onCancel()}
          >
            Volver al inicio de sesión
          </button>
        </div>
      </section>
    </div>
  );
}
