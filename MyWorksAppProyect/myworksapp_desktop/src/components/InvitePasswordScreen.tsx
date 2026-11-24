import { useState } from 'react';
import { AuthError, passwordPolicyMessage } from '@myworksapp/shared';
import { friendlyError } from '../lib/errors';
import { Button } from '../ui/kit';

export function InvitePasswordScreen({
  onSubmit,
  onCancel,
}: {
  onSubmit: (password: string) => Promise<void>;
  onCancel: () => Promise<void>;
}) {
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [show, setShow] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="login-screen">
      <section className="login-panel">
        <form
          className="login-card stack"
          onSubmit={(event) => {
            event.preventDefault();
            const policy = passwordPolicyMessage(password);
            if (policy) {
              setError(policy);
              return;
            }
            if (password !== confirm) {
              setError('Las contraseñas no coinciden.');
              return;
            }
            setBusy(true);
            void onSubmit(password).catch((reason: unknown) => {
              const message = reason instanceof AuthError
                ? friendlyError(reason, 'No se pudo guardar la contraseña.')
                : 'No se pudo guardar la contraseña.';
              setError(message);
              setBusy(false);
            });
          }}
        >
          <h1>Define tu contraseña</h1>
          <p className="muted">El enlace de invitación o de recuperación abre esta pantalla.</p>
          <label className="field">
            <span>Nueva contraseña</span>
            <input type={show ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" required />
          </label>
          <label className="field">
            <span>Repite la contraseña</span>
            <input type={show ? 'text' : 'password'} value={confirm} onChange={(event) => setConfirm(event.target.value)} autoComplete="new-password" required />
          </label>
          <button type="button" className="btn btn-ghost" onClick={() => setShow((value) => !value)}>
            {show ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          </button>
          {error ? <p role="alert">{error}</p> : null}
          <Button type="submit" busy={busy}>Guardar contraseña</Button>
          <Button variant="secondary" onClick={() => void onCancel()}>Volver al ingreso</Button>
        </form>
      </section>
    </div>
  );
}
