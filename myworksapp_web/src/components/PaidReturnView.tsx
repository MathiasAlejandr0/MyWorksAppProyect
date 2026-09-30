import { useState } from 'react';
import { edgeFunctionErrorMessage, passwordPolicyMessage } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { BrandLogo } from './BrandLogo';

type PaidReturnViewProps = {
  workerName?: string;
  jobId?: string | null;
  verifying?: boolean;
  verifyError?: string | null;
  passwordToken?: string | null;
  onContinueTracking: () => void;
  onGoHome: () => void;
};

/** Pantalla post-Webpay (invitado o retorno). */
export function PaidReturnView({
  workerName,
  jobId,
  verifying = false,
  verifyError = null,
  passwordToken = null,
  onContinueTracking,
  onGoHome,
}: PaidReturnViewProps) {
  const [password, setPassword] = useState('');
  const [passwordAgain, setPasswordAgain] = useState('');
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordBusy, setPasswordBusy] = useState(false);
  const [passwordReady, setPasswordReady] = useState(false);
  const [emailConfirmed, setEmailConfirmed] = useState(true);
  if (verifying) {
    return (
      <div className="min-h-screen app-shell paid-return">
        <div className="paid-return-card">
          <BrandLogo size={40} />
          <h1>Confirmando pago…</h1>
          <p>Estamos verificando con Transbank. Un momento.</p>
        </div>
      </div>
    );
  }

  if (verifyError) {
    return (
      <div className="min-h-screen app-shell paid-return">
        <div className="paid-return-card">
          <BrandLogo size={40} />
          <h1>No pudimos confirmar el pago</h1>
          <p>{verifyError}</p>
          {passwordToken ? (
            <button type="button" className="btn-primary" onClick={onContinueTracking}>
              Ver mi pedido
            </button>
          ) : null}
          <button type="button" className={passwordToken ? 'btn-ghost' : 'btn-primary'} onClick={onGoHome}>
            Volver al inicio
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen app-shell paid-return">
      <div className="paid-return-card">
        <BrandLogo size={40} />
        <h1>Pago recibido</h1>
        <p>
          Tu pago quedó retenido en garantía
          {workerName ? ` para ${workerName}` : ''}.
          {jobId ? ` Referencia ${jobId.slice(0, 8)}…` : ''} Te contactaremos
          para coordinar la visita.
        </p>
        {passwordToken && !passwordReady ? (
          <form
            onSubmit={(event) => {
              event.preventDefault();
              const policy = passwordPolicyMessage(password);
              if (policy) {
                setPasswordError(policy);
                return;
              }
              if (password !== passwordAgain) {
                setPasswordError('Las contraseñas no coinciden');
                return;
              }
              setPasswordBusy(true);
              setPasswordError(null);
              const nonce = sessionStorage.getItem('mwa-guest-alta-nonce') || '';
              if (!nonce) {
                setPasswordError('Abre esta página en el mismo navegador donde pagaste.');
                setPasswordBusy(false);
                return;
              }
              void supabase.functions.invoke('definir-clave-invitado', {
                body: { token: passwordToken, password, nonce },
              }).then(async ({ data, error }) => {
                const payload = data as { error?: string; ok?: boolean; emailConfirmed?: boolean } | null;
                if (error || payload?.error || !payload?.ok) {
                  setPasswordError(
                    payload?.error ||
                      (error
                        ? await edgeFunctionErrorMessage(error, 'No se pudo guardar la contraseña')
                        : 'No se pudo guardar la contraseña'),
                  );
                  setPasswordBusy(false);
                  return;
                }
                setEmailConfirmed(payload.emailConfirmed !== false);
                setPasswordReady(true);
                setPasswordBusy(false);
              });
            }}
          >
            <h2>Crea tu contraseña</h2>
            <p>
              Así entras después. En la demo el correo queda listo para entrar.
              Fuera de la demo te llega un correo para confirmarlo.
            </p>
            <input
              type="password"
              autoComplete="new-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Mínimo 8, con letra y número"
            />
            <input
              type="password"
              autoComplete="new-password"
              value={passwordAgain}
              onChange={(event) => setPasswordAgain(event.target.value)}
              placeholder="Repite la contraseña"
            />
            {passwordError ? <p role="alert">{passwordError}</p> : null}
            <button type="submit" className="btn-primary" disabled={passwordBusy}>
              {passwordBusy ? 'Guardando…' : 'Crea tu contraseña'}
            </button>
          </form>
        ) : null}
        {passwordReady ? (
          <p role="status">
            {emailConfirmed
              ? 'Contraseña lista. Entra con tu correo en la próxima visita.'
              : 'Te enviamos un correo para confirmar.'}
          </p>
        ) : null}
        {passwordToken ? (
          <button type="button" className="btn-primary" onClick={onContinueTracking}>
            Ver mi pedido
          </button>
        ) : null}
        <button
          type="button"
          className={passwordToken ? 'btn-ghost' : 'btn-primary'}
          onClick={onGoHome}
        >
          Volver al inicio
        </button>
      </div>
    </div>
  );
}
