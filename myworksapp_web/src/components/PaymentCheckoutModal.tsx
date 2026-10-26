import { useState, type FormEvent } from 'react';
import { ShieldCheck, CheckCircle2, Lock, X, CreditCard, MapPin } from 'lucide-react';
import {
  orderConfirmedMessage,
  transportCheckoutCopy,
  type OneclickChargeResult,
} from '@myworksapp/shared';

export type CheckoutPayResult =
  | OneclickChargeResult
  | { charged: false; redirected: true };

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  transportExtraClp?: number;
  insideRadar?: boolean | null;
  serviceDescription?: string;
  jobId?: string | null;
  onUseAddress?: (query: string) => Promise<unknown>;
  locatingAddress?: boolean;
  onClose: () => void;
  /** Cobra la tarjeta guardada. Si no hay, redirige a Webpay Plus. */
  onPayWithWebpay: () => Promise<CheckoutPayResult>;
  onSuccess: (details: { notice: string }) => void;
}

export function PaymentCheckoutModal({
  workerName,
  profession: _profession,
  basePrice,
  transportExtraClp = 0,
  insideRadar = null,
  serviceDescription = 'Servicio a domicilio',
  jobId,
  onUseAddress,
  locatingAddress = false,
  onClose,
  onPayWithWebpay,
  onSuccess,
}: PaymentCheckoutModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addressQuery, setAddressQuery] = useState('');
  const totalAmount = basePrice + Math.max(0, transportExtraClp);
  const needsManualSite = insideRadar == null && transportExtraClp <= 0 && Boolean(onUseAddress);

  const submitAddress = async (event: FormEvent) => {
    event.preventDefault();
    const text = addressQuery.trim();
    if (!text || !onUseAddress) return;
    setError(null);
    try {
      await onUseAddress(text);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No encontramos esa dirección.');
    }
  };

  const handlePay = async () => {
    if (needsManualSite) {
      setError('Indica la dirección del trabajo o marca el punto en el mapa.');
      return;
    }
    setIsProcessing(true);
    setError(null);
    try {
      const result = await onPayWithWebpay();
      if ('redirected' in result && result.redirected) return;
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
      setError('No se pudo abrir Webpay. Intenta de nuevo.');
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
                  <strong>El pago queda retenido</strong>
                  <p>
                    Si ya inscribiste una tarjeta en la app, se cobra esa. Si
                    no, Transbank pide la tarjeta en Webpay Plus. El monto queda
                    retenido hasta que recibas el trabajo.
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
                <div>
                  <dt>Traslado</dt>
                  <dd>
                    {transportCheckoutCopy({
                      extraClp: transportExtraClp,
                      insideRadar,
                    })}
                  </dd>
                </div>
                {jobId ? (
                  <div>
                    <dt>Trabajo</dt>
                    <dd className="checkout-v2-order">{jobId.slice(0, 8)}…</dd>
                  </div>
                ) : null}
              </dl>
              {needsManualSite ? (
                <form className="checkout-v2-address" onSubmit={(event) => void submitAddress(event)}>
                  <label htmlFor="checkout-job-address">
                    <MapPin size={14} /> Dirección del trabajo
                  </label>
                  <div>
                    <input
                      id="checkout-job-address"
                      value={addressQuery}
                      onChange={(event) => setAddressQuery(event.target.value)}
                      placeholder="Calle, barrio o ciudad"
                      disabled={isProcessing || locatingAddress}
                    />
                    <button
                      type="submit"
                      disabled={isProcessing || locatingAddress || addressQuery.trim().length < 3}
                    >
                      {locatingAddress ? 'Buscando…' : 'Usar dirección'}
                    </button>
                  </div>
                </form>
              ) : null}
            </div>

            {error ? (
              <p className="toast-error" role="alert" style={{ marginBottom: 12 }}>
                {error}
              </p>
            ) : null}

            <button
              type="button"
              onClick={() => void handlePay()}
              disabled={isProcessing || needsManualSite || locatingAddress}
              className="btn-primary checkout-v2-pay"
            >
              <CreditCard size={16} />
              {isProcessing
                ? 'Confirmando pedido…'
                : needsManualSite
                  ? 'Indica la ubicación del trabajo'
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
