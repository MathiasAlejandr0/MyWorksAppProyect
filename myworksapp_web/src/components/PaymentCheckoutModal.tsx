import { useEffect, useRef, useState } from 'react';
import {
  ShieldCheck,
  CheckCircle2,
  Lock,
  X,
  CreditCard,
} from 'lucide-react';
import { fetchPaymentStatus } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export type PaymentCheckoutSuccess = {
  method: 'webpay';
  totalAmount: number;
  date: string;
  /** true solo si el entorno es integración Transbank */
  integration: boolean;
  transactionId?: string;
  paymentId?: string;
};

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  serviceDescription?: string;
  jobId?: string | null;
  onClose: () => void;
  /** Inicia Webpay (Edge). Debe devolver URL de handoff (+ paymentId). */
  onPayWithWebpay: () => Promise<{
    redirectUrl: string;
    paymentId?: string;
    token?: string;
  } | void>;
  onSuccess: (paymentDetails: PaymentCheckoutSuccess) => void;
}

const paymentsMode =
  (import.meta.env.VITE_PAYMENTS_MODE as string | undefined)?.trim() ||
  'integration';

const MWA_WEBPAY_MSG = 'mwa-webpay';

function allowedPostMessageOrigin(origin: string): boolean {
  if (origin === window.location.origin) return true;
  const env = (import.meta.env.VITE_WEBPAY_POSTMESSAGE_ORIGINS as string | undefined)
    ?.split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (env?.includes(origin)) return true;
  // Commit Edge puede vivir en *.supabase.co
  try {
    const u = new URL(origin);
    if (u.hostname.endsWith('.supabase.co')) return true;
  } catch {
    // ignore
  }
  return false;
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
  const [isWaitingBank, setIsWaitingBank] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const popupRef = useRef<Window | null>(null);
  const paymentIdRef = useRef<string | null>(null);
  const settledRef = useRef(false);

  const totalAmount = basePrice;
  const isIntegration = paymentsMode !== 'production';

  const settleSuccess = async (paymentId?: string) => {
    if (settledRef.current) return;
    const pid = paymentId || paymentIdRef.current;
    if (!pid) {
      setError('No se pudo confirmar el pago (sin paymentId).');
      return;
    }
    try {
      const status = await fetchPaymentStatus(supabase, pid, jobId ?? undefined);
      if (!status || !['retenido', 'autorizado', 'liberado'].includes(status.estado)) {
        setError('El banco aún no confirma el pago. Espera unos segundos e inténtalo de nuevo.');
        return;
      }
      settledRef.current = true;
      setIsDone(true);
      setIsWaitingBank(false);
      setIsProcessing(false);
      onSuccess({
        method: 'webpay',
        totalAmount,
        date: new Date().toISOString(),
        integration: isIntegration,
        paymentId: pid,
      });
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : 'No se pudo verificar el estado del pago.',
      );
    }
  };

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      if (!allowedPostMessageOrigin(event.origin)) return;
      const data = event.data as {
        type?: string;
        ok?: boolean;
        paymentId?: string;
      };
      if (!data || data.type !== MWA_WEBPAY_MSG) return;
      if (
        paymentIdRef.current &&
        data.paymentId &&
        data.paymentId !== paymentIdRef.current
      ) {
        return;
      }
      setIsWaitingBank(false);
      setIsProcessing(false);
      try {
        popupRef.current?.close();
      } catch {
        // ignore
      }
      if (data.ok) {
        void settleSuccess(data.paymentId);
      } else {
        setError('El pago no fue autorizado en Transbank. Puedes reintentar.');
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
    // settleSuccess closes over stable refs + env
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isIntegration, onSuccess, totalAmount, jobId]);

  useEffect(() => {
    if (!isWaitingBank) return;
    const timer = window.setInterval(() => {
      if (popupRef.current && popupRef.current.closed) {
        setIsWaitingBank(false);
        setIsProcessing(false);
        // Popup cerrado: intentar confirmar por status (puede haber pagado)
        if (paymentIdRef.current && !settledRef.current) {
          void settleSuccess(paymentIdRef.current);
        } else {
          setError(
            (prev) =>
              prev ??
              'Cerraste la ventana de pago. Si ya pagaste, el estado se actualizará en unos segundos.',
          );
        }
      }
    }, 800);
    return () => window.clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isWaitingBank]);

  const handlePay = async () => {
    setIsProcessing(true);
    setError(null);
    settledRef.current = false;
    try {
      const session = await onPayWithWebpay();
      if (!session?.redirectUrl) {
        throw new Error('Webpay no devolvió URL de pago.');
      }

      paymentIdRef.current = session.paymentId ?? null;

      const w = 480;
      const h = 720;
      const left = Math.max(0, window.screenX + (window.outerWidth - w) / 2);
      const top = Math.max(0, window.screenY + (window.outerHeight - h) / 2);
      const popup = window.open(
        session.redirectUrl,
        'mwa_webpay',
        `popup=yes,width=${w},height=${h},left=${left},top=${top}`,
      );
      if (!popup) {
        setError(
          'El navegador bloqueó la ventana de pago. Permite popups para My Works App e inténtalo de nuevo.',
        );
        return;
      }
      popupRef.current = popup;
      setIsWaitingBank(true);
    } catch (e) {
      setError(
        e instanceof Error ? e.message : 'No se pudo iniciar el pago con Webpay.',
      );
    } finally {
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
                <Lock size={13} /> WEBPAY · ESCROW
              </p>
              <h2 id="checkout-title">Resumen de pago</h2>
            </div>

            <div className="checkout-v2-total-row">
              <span>Total</span>
              <strong>{totalAmount.toLocaleString('es-CL')} CLP</strong>
            </div>

            <div className="checkout-v2-escrow-banner">
              <div className="checkout-v2-escrow-copy">
                <ShieldCheck size={22} color="var(--orange-accent)" />
                <div>
                  <strong>
                    {isIntegration
                      ? 'Ambiente de integración Transbank'
                      : 'Pago protegido con Webpay'}
                  </strong>
                  <p>
                    Pagas en una ventana segura de Transbank sin abandonar My
                    Works App. No ingreses datos de tarjeta en nuestro sitio.
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

            {isWaitingBank ? (
              <p className="checkout-waiting" role="status">
                Esperando confirmación de Transbank… No cierres esta pestaña.
              </p>
            ) : null}

            {error ? (
              <p className="toast-error" role="alert" style={{ marginBottom: 12 }}>
                {error}
              </p>
            ) : null}

            <button
              type="button"
              onClick={() => void handlePay()}
              disabled={isProcessing || isWaitingBank}
              className="btn-primary checkout-v2-pay"
            >
              <CreditCard size={16} />
              {isProcessing
                ? 'Conectando con Webpay…'
                : isWaitingBank
                  ? 'Pago en curso…'
                  : `Pagar con Webpay · CLP ${totalAmount.toLocaleString('es-CL')}`}
            </button>

            <div className="checkout-v2-footer">
              <span>
                <ShieldCheck size={12} /> Procesado por Transbank Webpay Plus
              </span>
              <span>
                {isIntegration
                  ? 'Modo integración: usar tarjetas de prueba Transbank.'
                  : 'El pago queda retenido hasta aprobación del trabajo.'}
              </span>
            </div>
          </>
        ) : (
          <div className="checkout-done page-fade-in">
            <CheckCircle2 color="var(--emerald-success)" size={56} />
            <h3>Pago retenido</h3>
            <p>
              ${totalAmount.toLocaleString('es-CL')} CLP — escrow activo hasta
              que apruebes el trabajo.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
