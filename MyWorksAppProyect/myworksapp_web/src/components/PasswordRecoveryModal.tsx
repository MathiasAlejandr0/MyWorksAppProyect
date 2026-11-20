import { useRef, useState } from 'react';
import { KeyRound } from 'lucide-react';
import { AuthError, passwordPolicyMessage } from '@myworksapp/shared';
import { useAuth } from '../context/useAuth';
import { useDialogA11y } from '../hooks/useDialogA11y';

/** Se abre al volver del enlace «restablecer contraseña» del correo. */
export function PasswordRecoveryModal() {
  const { recoveringPassword, finishPasswordReset, cancelPasswordReset } = useAuth();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  const open = recoveringPassword || done;
  useDialogA11y(open, () => { void cancelPasswordReset(); }, dialogRef);

  if (!open) return null;

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    const policy = passwordPolicyMessage(password);
    if (policy) {
      setError(policy);
      return;
    }
    if (password !== confirm) {
      setError('Las contraseñas no coinciden.');
      return;
    }
    setSubmitting(true);
    try {
      await finishPasswordReset(password);
      setDone(true);
      setPassword('');
      setConfirm('');
    } catch (e) {
      setError(e instanceof AuthError ? e.message : 'No se pudo guardar la contraseña.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth-modal-backdrop modal-fade-in" role="dialog" aria-modal="true" aria-labelledby="reset-title">
      <div className="card-3d auth-modal-card modal-rise" ref={dialogRef}>
        <p className="auth-modal-kicker">Acceso clientes</p>
        <h2 id="reset-title" className="auth-modal-title">
          {done ? 'Contraseña actualizada' : 'Crea tu nueva contraseña'}
        </h2>
        {done ? (
          <>
            <p className="auth-modal-lead" role="status">
              Listo. Ya puedes seguir usando MyWorksApp con tu nueva contraseña.
            </p>
            <button type="button" className="btn-primary auth-modal-submit" onClick={() => setDone(false)}>
              Continuar
            </button>
          </>
        ) : (
          <form onSubmit={submit} className="auth-modal-form">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nueva contraseña"
              aria-label="Nueva contraseña"
              aria-describedby="reset-policy"
              autoComplete="new-password"
              required
              className="auth-modal-input"
            />
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              placeholder="Repite la contraseña"
              aria-label="Repite la contraseña"
              autoComplete="new-password"
              required
              className="auth-modal-input"
            />
            <p id="reset-policy" className="auth-modal-hint">
              Mínimo 8 caracteres, con al menos una letra y un número.
            </p>
            {error ? (
              <div className="auth-modal-error" role="alert">
                {error}
              </div>
            ) : null}
            <button type="submit" className="btn-primary auth-modal-submit" disabled={submitting}>
              <KeyRound size={16} /> {submitting ? 'Guardando…' : 'Guardar contraseña'}
            </button>
            <button type="button" className="auth-modal-switch" onClick={() => void cancelPasswordReset()}>
              Cancelar
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
