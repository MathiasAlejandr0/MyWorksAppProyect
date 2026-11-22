import { useEffect, useRef, useState, type FormEvent } from 'react';
import { ShieldCheck, CheckCircle2, Lock, X, CreditCard, MapPin } from 'lucide-react';
import {
  orderConfirmedMessage,
  type OneclickChargeResult,
  type SavedCardStatus,
} from '@myworksapp/shared';
import { useDialogA11y } from '../hooks/useDialogA11y';
import { AcademicInlineNote } from './AcademicInlineNote';

export type CheckoutPayResult =
  | OneclickChargeResult
  | { charged: false; redirected: true };

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  /** Total que cobra el servidor. Null mientras se calcula: no se muestra otro monto. */
  payableTotalClp?: number | null;
  chargeLocking?: boolean;
  chargeError?: string | null;
  onRetryCharge?: () => void;
  serviceDescription?: string;
  jobId?: string | null;
  onUseAddress?: (query: string) => Promise<unknown>;
  locatingAddress?: boolean;
  hasJobSite?: boolean;
  onClose: () => void;
  /**
   * Cobra la tarjeta guardada. Si no hay, inscribe la tarjeta (`saveCard`) o
   * redirige a Webpay Plus para pagar solo este pedido.
   */
  onPayWithWebpay: (options: { saveCard: boolean }) => Promise<CheckoutPayResult>;
  /** Tarjeta que ya tiene guardada el cliente. */
  loadSavedCard?: () => Promise<SavedCardStatus>;
  /** Quita la tarjeta guardada para inscribir otra. */
  onRemoveSavedCard?: () => Promise<void>;
  onSuccess: (details: { notice: string }) => void;
}

export function PaymentCheckoutModal({
  workerName,
  profession: _profession,
  payableTotalClp = null,
  chargeLocking = false,
  chargeError = null,
  onRetryCharge,
  serviceDescription = 'Servicio a domicilio',
  jobId,
  onUseAddress,
  locatingAddress = false,
  hasJobSite = false,
  onClose,
  onPayWithWebpay,
  loadSavedCard,
  onRemoveSavedCard,
  onSuccess,
}: PaymentCheckoutModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addressQuery, setAddressQuery] = useState('');
  const [savedCard, setSavedCard] = useState<SavedCardStatus | null>(null);
  const [saveCard, setSaveCard] = useState(true);
  const [changingCard, setChangingCard] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  useDialogA11y(true, onClose, dialogRef);

  // Se consulta una sola vez al abrir el pedido, aunque el padre se vuelva a pintar.
  const [loadOnce] = useState(() => loadSavedCard);

  useEffect(() => {
    if (!loadOnce) return;
    let cancelled = false;
    loadOnce()
      .then((card) => {
        if (!cancelled) setSavedCard(card.enrolled ? card : null);
      })
      .catch(() => {
        // Sin saber si hay tarjeta guardada, el cobro decide al confirmar.
      });
    return () => {
      cancelled = true;
    };
  }, [loadOnce]);

  const changeCard = async () => {
    if (!onRemoveSavedCard) return;
    setChangingCard(true);
    setError(null);
    try {
      await onRemoveSavedCard();
      setSavedCard(null);
      setSaveCard(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No se pudo quitar la tarjeta.');
    } finally {
      setChangingCard(false);
    }
  };
  const lockedTotal = payableTotalClp != null && payableTotalClp > 0
    ? payableTotalClp
    : null;
  const canPay = lockedTotal != null && !chargeLocking;
  const needsManualSite = !hasJobSite && Boolean(onUseAddress);

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
    if (!canPay) return;
    if (needsManualSite) {
      setError('Indica la dirección del trabajo o marca el punto en el mapa.');
      return;
    }
    setIsProcessing(true);
    setError(null);
    try {
      const result = await onPayWithWebpay({ saveCard: saveCard && !savedCard });
      if ('redirected' in result && result.redirected) return;
      if (result.charged) {
        setIsDone(true);
        onSuccess({
          notice: orderConfirmedMessage({
            amountClp: result.amount || lockedTotal || 0,
            last4: result.last4,
            workerName,
          }),
        });
        return;
      }
      setSavedCard(null);
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
      <div className="checkout-card-v2 modal-rise" ref={dialogRef}>
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
              <strong>
                {chargeLocking || lockedTotal == null
                  ? 'Calculando tarifa y traslado…'
                  : `${lockedTotal.toLocaleString('es-CL')} CLP`}
              </strong>
            </div>
            {chargeError ? (
              <p className="toast-error" role="alert">
                {chargeError}
                {onRetryCharge ? (
                  <>
                    {' '}
                    <button type="button" onClick={onRetryCharge}>Reintentar</button>
                  </>
                ) : null}
              </p>
            ) : null}

            <div className="checkout-v2-escrow-banner">
              <div className="checkout-v2-escrow-copy">
                <ShieldCheck size={22} color="var(--orange-accent)" />
                <div>
                  <strong>El pago queda retenido</strong>
                  <p>
                    Si ya guardaste una tarjeta, se cobra esa sin pedirla otra
                    vez. Si no, Transbank pide la tarjeta una sola vez y puedes
                    dejarla guardada. El monto queda retenido hasta que recibas
                    el trabajo.
                  </p>
                </div>
              </div>
            </div>

            {savedCard ? (
              <div className="checkout-v2-saved-card" data-testid="saved-card">
                <CreditCard size={16} />
                <span>
                  Se cobrará a tu tarjeta {savedCard.cardType || 'guardada'} •••• {savedCard.last4}
                </span>
                {onRemoveSavedCard ? (
                  <button
                    type="button"
                    className="checkout-v2-link"
                    onClick={() => void changeCard()}
                    disabled={isProcessing || changingCard}
                  >
                    {changingCard ? 'Quitando…' : 'Cambiar tarjeta'}
                  </button>
                ) : null}
              </div>
            ) : (
              <label className="checkout-v2-save-card">
                <input
                  type="checkbox"
                  checked={saveCard}
                  onChange={(event) => setSaveCard(event.target.checked)}
                  disabled={isProcessing}
                />
                <span>
                  Guardar mi tarjeta para pagar los próximos pedidos sin volver a
                  ingresarla
                </span>
              </label>
            )}

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
                    {lockedTotal == null
                      ? 'Se confirma antes de habilitar el pago'
                      : 'Incluido en el total'}
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

            <AcademicInlineNote />
            <button
              type="button"
              onClick={() => void handlePay()}
              disabled={isProcessing || needsManualSite || locatingAddress || !canPay}
              className="btn-primary checkout-v2-pay"
            >
              <CreditCard size={16} />
              {isProcessing
                ? 'Confirmando pedido…'
                : !canPay
                  ? 'Calculando el total…'
                  : needsManualSite
                    ? 'Indica la ubicación del trabajo'
                    : `Confirmar pedido · CLP ${(lockedTotal ?? 0).toLocaleString('es-CL')}`}
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
              Se descontará ${(lockedTotal ?? 0).toLocaleString('es-CL')} CLP de tu
              tarjeta. {workerName} va en camino.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
