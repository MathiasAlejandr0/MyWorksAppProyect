import { useState } from 'react';
import {
  ShieldCheck,
  CheckCircle2,
  Lock,
  X,
  CreditCard,
  Calendar,
  Copy,
  HelpCircle,
} from 'lucide-react';

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  serviceDescription?: string;
  onClose: () => void;
  onSuccess: (paymentDetails: { method: string; totalAmount: number; date: string; simulated: true }) => void;
}

export function PaymentCheckoutModal({
  workerName,
  profession: _profession,
  basePrice,
  serviceDescription = 'Servicio a domicilio',
  onClose,
  onSuccess,
}: PaymentCheckoutModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDone, setIsDone] = useState(false);

  const totalAmount = basePrice;
  const orderId = 'MWA-89273H-7K2L';

  const handlePay = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setIsDone(true);
      setTimeout(() => {
        onSuccess({ method: 'card', totalAmount, date: new Date().toISOString(), simulated: true });
      }, 1200);
    }, 1600);
  };

  return (
    <div className="checkout-backdrop modal-fade-in" role="dialog" aria-modal="true" aria-labelledby="checkout-title">
      <div className="checkout-card-v2 modal-rise">
        <button type="button" className="modal-close" onClick={onClose} aria-label="Cerrar">
          <X size={20} />
        </button>

        {!isDone ? (
          <>
            <div className="checkout-v2-header">
              <p className="checkout-v2-kicker">
                <Lock size={13} /> PAGO SEGURO CON ESCROW
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
                  <strong>Pago protegido con escrow</strong>
                  <p>Tu dinero se libera solo cuando apruebes el trabajo.</p>
                </div>
              </div>
              <div className="checkout-v2-escrow-shield" aria-hidden>
                <ShieldCheck size={48} strokeWidth={1.2} />
              </div>
            </div>

            <div className="checkout-v2-details">
              <h3>Detalles del pago</h3>
              <dl className="checkout-v2-dl">
                <div>
                  <dt>Servicio</dt>
                  <dd>{serviceDescription}</dd>
                </div>
                <div>
                  <dt>Vendedor</dt>
                  <dd>{workerName}</dd>
                </div>
                <div>
                  <dt>Plazo acordado</dt>
                  <dd>7 días</dd>
                </div>
                <div>
                  <dt>ID de orden</dt>
                  <dd className="checkout-v2-order">
                    {orderId}
                    <button type="button" className="checkout-v2-copy" aria-label="Copiar ID">
                      <Copy size={14} />
                    </button>
                  </dd>
                </div>
              </dl>
            </div>

            <div className="checkout-v2-payment">
              <h3>Método de pago</h3>
              <div className="checkout-v2-method-select">
                <CreditCard size={18} />
                <span>Tarjeta de crédito o débito</span>
                <span className="checkout-v2-chevron">▾</span>
              </div>

              <div className="checkout-v2-form">
                <label className="checkout-v2-field checkout-v2-field-full">
                  <span>Número de tarjeta</span>
                  <div className="checkout-v2-input-wrap">
                    <input type="text" placeholder="1234 5678 9012 3456" autoComplete="cc-number" />
                    <CreditCard size={16} className="checkout-v2-field-icon" />
                  </div>
                </label>
                <label className="checkout-v2-field checkout-v2-field-full">
                  <span>Nombre en la tarjeta</span>
                  <input type="text" placeholder="Tu nombre" autoComplete="cc-name" />
                </label>
                <label className="checkout-v2-field">
                  <span>Fecha de vencimiento</span>
                  <div className="checkout-v2-input-wrap">
                    <input type="text" placeholder="MM / AA" autoComplete="cc-exp" />
                    <Calendar size={16} className="checkout-v2-field-icon" />
                  </div>
                </label>
                <label className="checkout-v2-field">
                  <span>CVC</span>
                  <div className="checkout-v2-input-wrap">
                    <input type="text" placeholder="123" autoComplete="cc-csc" />
                    <HelpCircle size={16} className="checkout-v2-field-icon" />
                  </div>
                </label>
              </div>
            </div>

            <button
              type="button"
              onClick={handlePay}
              disabled={isProcessing}
              className="btn-primary checkout-v2-pay"
            >
              <Lock size={16} />
              {isProcessing
                ? 'Procesando…'
                : `Confirmar pago • CLP ${totalAmount.toLocaleString('es-CL')}`}
            </button>

            <div className="checkout-v2-footer">
              <span>
                <ShieldCheck size={12} /> Powered by My Works Escrow
              </span>
              <span>
                <HelpCircle size={12} /> Este pago está protegido y se mantiene en escrow hasta la aprobación.
              </span>
            </div>
          </>
        ) : (
          <div className="checkout-done page-fade-in">
            <CheckCircle2 color="var(--emerald-success)" size={56} />
            <h3>Pago confirmado</h3>
            <p>Tu pago de ${totalAmount.toLocaleString('es-CL')} CLP quedó retenido en escrow (demo).</p>
          </div>
        )}
      </div>
    </div>
  );
}
