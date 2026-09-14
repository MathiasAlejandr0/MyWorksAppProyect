import { useState } from 'react';
import { CreditCard, ShieldCheck, CheckCircle2, Lock, X, Building2, Smartphone } from 'lucide-react';

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  onClose: () => void;
  onSuccess: (paymentDetails: { method: string; totalAmount: number; date: string; simulated: true }) => void;
}

export function PaymentCheckoutModal({ workerName, profession, basePrice, onClose, onSuccess }: PaymentCheckoutModalProps) {
  const [method, setMethod] = useState<'webpay' | 'mercadopago' | 'card' | 'khipu'>('webpay');
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDone, setIsDone] = useState(false);

  const iva = Math.round(basePrice * 0.19);
  const serviceFee = Math.round(basePrice * 0.10);
  const totalAmount = basePrice + iva + serviceFee;

  const handlePay = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setIsDone(true);
      setTimeout(() => {
        onSuccess({ method, totalAmount, date: new Date().toISOString(), simulated: true });
      }, 1200);
    }, 1600);
  };

  return (
    <div className="checkout-backdrop modal-fade-in" role="dialog" aria-modal="true" aria-labelledby="checkout-title">
      <div className="card-3d checkout-card modal-rise">
        <button type="button" className="modal-close" onClick={onClose} aria-label="Cerrar">
          <X size={20} />
        </button>

        {!isDone ? (
          <>
            <div className="checkout-demo-banner">
              <span className="checkout-demo-pill">DEMO</span>
              <p>Simulación de pago — no hay cobro real. Webpay, Mercado Pago y Khipu son solo referencia de interfaz.</p>
            </div>

            <div className="checkout-header">
              <Lock size={20} color="#F0782A" aria-hidden />
              <div>
                <h3 id="checkout-title">Checkout de prueba</h3>
                <p>Revisa el resumen y elige un método ilustrativo</p>
              </div>
            </div>

            <div className="checkout-summary">
              <div className="checkout-summary-row">
                <span>Profesional</span>
                <strong>
                  {workerName} · {profession}
                </strong>
              </div>
              <div className="checkout-summary-row muted">
                <span>Visita / mano de obra (estimado)</span>
                <span>${basePrice.toLocaleString('es-CL')} CLP</span>
              </div>
              <div className="checkout-summary-row muted">
                <span>IVA referencial (19%)</span>
                <span>${iva.toLocaleString('es-CL')} CLP</span>
              </div>
              <div className="checkout-summary-row muted">
                <span>Comisión plataforma (demo 10%)</span>
                <span>${serviceFee.toLocaleString('es-CL')} CLP</span>
              </div>
              <div className="checkout-summary-total">
                <span>Total simulado</span>
                <span>${totalAmount.toLocaleString('es-CL')} CLP</span>
              </div>
            </div>

            <h4 className="checkout-methods-label">Método de pago (solo demo)</h4>
            <div className="payment-methods-grid checkout-methods">
              {(
                [
                  { id: 'webpay' as const, label: 'Webpay Plus', hint: 'Demo UI', icon: Building2, color: '#F0782A' },
                  { id: 'mercadopago' as const, label: 'Mercado Pago', hint: 'Demo UI', icon: Smartphone, color: '#009EE3' },
                  { id: 'card' as const, label: 'Tarjeta', hint: 'Demo UI', icon: CreditCard, color: '#2F9E64' },
                  { id: 'khipu' as const, label: 'Khipu', hint: 'Demo UI', icon: Building2, color: '#007AFF' },
                ] as const
              ).map((item) => {
                const Icon = item.icon;
                const active = method === item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    className={`checkout-method${active ? ' is-active' : ''}`}
                    onClick={() => setMethod(item.id)}
                  >
                    <Icon size={20} color={item.color} aria-hidden />
                    <span>
                      <strong>{item.label}</strong>
                      <small>{item.hint}</small>
                    </span>
                  </button>
                );
              })}
            </div>

            <div className="checkout-escrow-note">
              <ShieldCheck size={18} color="#2F9E64" aria-hidden />
              <p>
                Flujo de escrow ilustrativo: en producción el dinero se retendría hasta confirmar el servicio. Aquí no se cobra ni se retiene nada.
              </p>
            </div>

            <button type="button" onClick={handlePay} disabled={isProcessing} className="btn-primary checkout-pay-btn">
              {isProcessing ? 'Simulando pago…' : `Simular pago $${totalAmount.toLocaleString('es-CL')} CLP`}
            </button>
          </>
        ) : (
          <div className="checkout-done page-fade-in">
            <CheckCircle2 color="#2F9E64" size={56} />
            <h3>Simulación completada</h3>
            <p>No se realizó ningún cobro. Total de referencia: ${totalAmount.toLocaleString('es-CL')} CLP.</p>
          </div>
        )}
      </div>
    </div>
  );
}
