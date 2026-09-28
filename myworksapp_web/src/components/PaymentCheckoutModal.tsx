import { useState } from 'react';
import { ShieldCheck, CheckCircle2, Lock, X, CreditCard } from 'lucide-react';
import {
  orderConfirmedMessage,
  type OneclickChargeResult,
} from '@myworksapp/shared';

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  serviceDescription?: string;
  jobId?: string | null;
  onClose: () => void;
  /** Cobra la tarjeta guardada. Si no hay tarjeta, el pedido no abre Webpay. */
  onPayWithWebpay: () => Promise<OneclickChargeResult>;
  onSuccess: (details: { notice: string }) => void;
}

export function PaymentCheckoutModal({
  workerName,
  profession: _profession,
  basePrice,
  serviceDescription = 'Servicio a domicilio',
  jobId,
  onClose,
  onPayWithWebpay,
  onSuccess,
}: PaymentCheckoutModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const totalAmount = basePrice;

  const handlePay = async () => {
    setIsProcessing(true);
    setError(null);
    try {
      const result = await onPayWithWebpay();
      if (result.charged) {
        setIsDone(true);
        onSuccess({
          notice: orderConfirmedMessage({
            amountClp: result.amount || totalAmount,
            last4: result.last4,
            workerName,
          }),
        });
        return;
      }
      setError(
        'Con tu cuenta el cobro sale de la tarjeta inscrita en la app. Entra a la app e inscribe la tarjeta la primera vez. Sin cuenta, este pedido se paga en Webpay.',
      );
      setIsProcessing(false);
    } catch (e) {
      setError(
        e instanceof Error ? e.message : 'No se pudo confirmar el pedido.',
      );
      setIsProcessing(false);
    }
  };

  return (
    <div
      className="checkout-backdrop modal-fade-in"
      role="dialog"
      aria-modal="true"
      aria-labelledby="checkout-title"
    >
      <div className="checkout-card-v2 modal-rise">
        <button
          type="button"
          className="modal-close"
          onClick={onClose}
          aria-label="Cerrar"
        >
          <X size={20} />
        </button>

        {!isDone ? (
          <>
            <div className="checkout-v2-header">
              <p className="checkout-v2-kicker">
                <Lock size={13} /> TARJETA · PEDIDO
              </p>
              <h2 id="checkout-title">Confirmar pedido</h2>
            </div>

            <div className="checkout-v2-total-row">
              <span>Total</span>
              <strong>{totalAmount.toLocaleString('es-CL')} CLP</strong>
            </div>

            <div className="checkout-v2-escrow-banner">
              <div className="checkout-v2-escrow-copy">
                <ShieldCheck size={22} color="var(--orange-accent)" />
                <div>
                  <strong>Se cobra la tarjeta de tu cuenta</strong>
                  <p>
                    Como iniciaste sesión, no vas a Webpay. Se descuenta la
                    tarjeta que inscribiste la primera vez que entraste a la
                    app, y vuelves al mapa con el pedido confirmado.
                  </p>
                </div>
              </div>
            </div>

            <div className="checkout-v2-details">
              <h3>Detalles</h3>
              <dl className="checkout-v2-dl">
                <div>
                  <dt>Servicio</dt>
                  <dd>{serviceDescription}</dd>
                </div>
                <div>
                  <dt>Profesional</dt>
                  <dd>{workerName}</dd>
                </div>
                {jobId ? (
                  <div>
                    <dt>Trabajo</dt>
                    <dd className="checkout-v2-order">{jobId.slice(0, 8)}…</dd>
                  </div>
                ) : null}
              </dl>
            </div>

            {error ? (
              <p className="toast-error" role="alert" style={{ marginBottom: 12 }}>
                {error}
              </p>
            ) : null}

            <button
              type="button"
              onClick={() => void handlePay()}
              disabled={isProcessing}
              className="btn-primary checkout-v2-pay"
            >
              <CreditCard size={16} />
              {isProcessing
                ? 'Confirmando pedido…'
                : `Confirmar pedido · CLP ${totalAmount.toLocaleString('es-CL')}`}
            </button>

            <div className="checkout-v2-footer">
              <span>
                <ShieldCheck size={12} /> Cobro con tarjeta vía Transbank
              </span>
              <span>El monto queda retenido hasta que recibas el trabajo.</span>
            </div>
          </>
        ) : (
          <div className="checkout-done page-fade-in">
            <CheckCircle2 color="var(--emerald-success)" size={56} />
            <h3>Pedido confirmado</h3>
            <p>
              Se descontará ${totalAmount.toLocaleString('es-CL')} CLP de tu
              tarjeta. {workerName} va en camino.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
