import { useState } from 'react';
import { CreditCard, ShieldCheck, CheckCircle2, Lock, X, Building2, Smartphone } from 'lucide-react';

interface PaymentCheckoutModalProps {
  workerName: string;
  profession: string;
  basePrice: number;
  onClose: () => void;
  onSuccess: (paymentDetails: any) => void;
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
        onSuccess({ method, totalAmount, date: new Date().toISOString() });
      }, 1500);
    }, 2000);
  };

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 300, backgroundColor: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
      <div className="card-3d" style={{ maxWidth: '520px', width: '100%', position: 'relative', overflow: 'hidden' }}>
        <button onClick={onClose} style={{ position: 'absolute', right: '16px', top: '16px', background: 'none', border: 'none', cursor: 'pointer', color: 'inherit' }}>
          <X size={20} />
        </button>

        {!isDone ? (
          <>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
              <Lock size={20} color="#F0782A" />
              <h3 style={{ fontSize: '20px', fontWeight: 800 }}>Pasarela de Pago Seguro Escrow</h3>
            </div>

            {/* Resumen del Servicio */}
            <div style={{ padding: '14px 18px', backgroundColor: 'var(--bg-elevated-light)', borderRadius: 'var(--radius-md)', marginBottom: '20px', border: '1px solid var(--border-light)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '13px', fontWeight: 600 }}>Profesional:</span>
                <span style={{ fontSize: '13px', fontWeight: 800 }}>{workerName} ({profession})</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted-light)', marginBottom: '4px' }}>
                <span>Visita / Mano de obra base:</span>
                <span>${basePrice.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted-light)', marginBottom: '4px' }}>
                <span>IVA (19%):</span>
                <span>${iva.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted-light)', marginBottom: '8px' }}>
                <span>Comisión Escrow MyWorks (10%):</span>
                <span>${serviceFee.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ borderTop: '1px solid var(--border-light)', paddingTop: '8px', display: 'flex', justifyContent: 'space-between', fontSize: '15px', fontWeight: 900, color: '#34C759' }}>
                <span>Total a Retener en Escrow:</span>
                <span>${totalAmount.toLocaleString('es-CL')} CLP</span>
              </div>
            </div>

            {/* Selección de Método de Pago */}
            <h4 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '10px' }}>Selecciona tu Método de Pago:</h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '20px' }}>
              <div 
                onClick={() => setMethod('webpay')}
                style={{ padding: '12px', borderRadius: 'var(--radius-md)', border: `2px solid ${method === 'webpay' ? '#F0782A' : 'var(--border-light)'}`, backgroundColor: method === 'webpay' ? 'var(--orange-soft)' : 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}
              >
                <Building2 size={20} color="#F0782A" />
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 800 }}>Webpay Plus</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted-light)' }}>Transbank Chile</div>
                </div>
              </div>

              <div 
                onClick={() => setMethod('mercadopago')}
                style={{ padding: '12px', borderRadius: 'var(--radius-md)', border: `2px solid ${method === 'mercadopago' ? '#F0782A' : 'var(--border-light)'}`, backgroundColor: method === 'mercadopago' ? 'var(--orange-soft)' : 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}
              >
                <Smartphone size={20} color="#009EE3" />
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 800 }}>Mercado Pago</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted-light)' }}>Dinero en cuenta / QR</div>
                </div>
              </div>

              <div 
                onClick={() => setMethod('card')}
                style={{ padding: '12px', borderRadius: 'var(--radius-md)', border: `2px solid ${method === 'card' ? '#F0782A' : 'var(--border-light)'}`, backgroundColor: method === 'card' ? 'var(--orange-soft)' : 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}
              >
                <CreditCard size={20} color="#34C759" />
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 800 }}>Tarjeta Crédito / Débito</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted-light)' }}>Hasta 12 cuotas</div>
                </div>
              </div>

              <div 
                onClick={() => setMethod('khipu')}
                style={{ padding: '12px', borderRadius: 'var(--radius-md)', border: `2px solid ${method === 'khipu' ? '#F0782A' : 'var(--border-light)'}`, backgroundColor: method === 'khipu' ? 'var(--orange-soft)' : 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}
              >
                <Building2 size={20} color="#007AFF" />
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 800 }}>Transferencia Khipu</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted-light)' }}>BancoEstado / Santander</div>
                </div>
              </div>
            </div>

            {/* Garantía */}
            <div style={{ padding: '10px 14px', backgroundColor: 'rgba(52, 199, 89, 0.1)', borderRadius: 'var(--radius-sm)', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ShieldCheck size={18} color="#34C759" />
              <span style={{ fontSize: '11.5px', color: '#34C759', fontWeight: 700 }}>Tus fondos quedan congelados en Escrow hasta que ingreses tu PIN de conformidad.</span>
            </div>

            <button 
              onClick={handlePay}
              disabled={isProcessing}
              className="btn-primary" 
              style={{ width: '100%', justifyContent: 'center' }}
            >
              {isProcessing ? 'Procesando en Transbank / Webpay...' : `Pagar $${totalAmount.toLocaleString('es-CL')} CLP`}
            </button>
          </>
        ) : (
          <div style={{ textAlign: 'center', padding: '30px 0' }}>
            <CheckCircle2 color="#34C759" size={60} style={{ margin: '0 auto 16px' }} />
            <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '8px' }}>¡Pago Autorizado Exitosamente!</h3>
            <p style={{ fontSize: '14px', color: 'var(--text-muted-light)' }}>
              Fondos de ${totalAmount.toLocaleString('es-CL')} CLP retenidos de forma segura en la cuenta Escrow MyWorks Protect.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
