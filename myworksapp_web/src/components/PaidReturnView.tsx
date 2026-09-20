import { BrandLogo } from './BrandLogo';

type PaidReturnViewProps = {
  workerName?: string;
  jobId?: string | null;
  verifying?: boolean;
  verifyError?: string | null;
  onContinueTracking: () => void;
  onGoHome: () => void;
};

/** Pantalla post-Webpay (invitado o retorno). */
export function PaidReturnView({
  workerName,
  jobId,
  verifying = false,
  verifyError = null,
  onContinueTracking,
  onGoHome,
}: PaidReturnViewProps) {
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
          <button type="button" className="btn-primary" onClick={onGoHome}>
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
          Tu pago quedó retenido en escrow
          {workerName ? ` para ${workerName}` : ''}.
          {jobId ? ` Referencia ${jobId.slice(0, 8)}…` : ''} Te contactaremos
          para coordinar la visita.
        </p>
        <button
          type="button"
          className="btn-primary"
          onClick={workerName ? onContinueTracking : onGoHome}
        >
          {workerName ? 'Ver seguimiento' : 'Volver al inicio'}
        </button>
      </div>
    </div>
  );
}
