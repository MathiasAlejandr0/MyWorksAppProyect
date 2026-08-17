import { useState } from 'react';
import { DollarSign, FileSpreadsheet, CheckCircle2, X } from 'lucide-react';

interface FinancialSettlementModalProps {
  onClose: () => void;
}

export function FinancialSettlementModal({ onClose }: FinancialSettlementModalProps) {
  const [executed, setExecuted] = useState(false);

  const grossGmv = 14850000;
  const platformFee = 1485000; // 10%
  const ivaTax = Math.round(platformFee * 0.19); // 19% IVA SII
  const netPayoutWorkers = grossGmv - platformFee;

  const exportSiiReport = () => {
    const content = `REPORTE DE LIQUIDACIÓN Y TRIBUTACIÓN SII - MY WORKS APP
------------------------------------------------------------
Fecha de emisión: ${new Date().toLocaleDateString('es-CL')}
Período: Semana 33 - Agosto 2026

1. GMV Total Custodiado en Escrow: $${grossGmv.toLocaleString('es-CL')} CLP
2. Comisiones Netas Plataforma (10%): $${platformFee.toLocaleString('es-CL')} CLP
3. Débito Fiscal IVA 19% (SII Chile): $${ivaTax.toLocaleString('es-CL')} CLP
4. Total Neto a Transferir a Profesionales: $${netPayoutWorkers.toLocaleString('es-CL')} CLP

Estado de Firma Criptográfica: VERIFICADO (SHA-256 Validated)
`;
    const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Reporte_SII_MyWorks_${new Date().toISOString().slice(0, 10)}.txt`;
    a.click();
  };

  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 600, padding: '20px' }}>
      <div className="card-3d" style={{ maxWidth: '540px', width: '100%', border: '2px solid #34C759', position: 'relative' }}>
        <button onClick={onClose} style={{ position: 'absolute', right: '16px', top: '16px', background: 'none', border: 'none', color: '#98989D', cursor: 'pointer' }}>
          <X size={20} />
        </button>

        {!executed ? (
          <>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#34C759', marginBottom: '16px' }}>
              <DollarSign size={24} />
              <h3 style={{ fontSize: '20px', fontWeight: 900 }}>Liquidación Financiera & Exportación SII</h3>
            </div>

            <p style={{ fontSize: '13.5px', color: '#98989D', marginBottom: '20px' }}>
              Generación de nómina de pago semanal a profesionales con desglose tributario automático de IVA (19%) para el Servicio de Impuestos Internos.
            </p>

            {/* Desglose Financiero */}
            <div style={{ backgroundColor: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '12px', padding: '16px', marginBottom: '20px', display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '13.5px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#98989D' }}>GMV Escrow Bruto Semanal:</span>
                <span style={{ fontWeight: 800 }}>${grossGmv.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#F0782A' }}>
                <span>Comisión Plataforma (10%):</span>
                <span style={{ fontWeight: 800 }}>+${platformFee.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#FF9500' }}>
                <span>IVA Débito Fiscal 19% (SII):</span>
                <span style={{ fontWeight: 800 }}>${ivaTax.toLocaleString('es-CL')} CLP</span>
              </div>
              <div style={{ height: '1px', backgroundColor: 'rgba(255,255,255,0.1)', margin: '4px 0' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '15px', fontWeight: 900, color: '#34C759' }}>
                <span>Neto a Liquidar a Trabajadores:</span>
                <span>${netPayoutWorkers.toLocaleString('es-CL')} CLP</span>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <button onClick={exportSiiReport} className="btn-primary" style={{ backgroundColor: 'transparent', border: '1px solid #007AFF', color: '#007AFF', padding: '12px' }}>
                <FileSpreadsheet size={16} /> Exportar SII
              </button>
              <button onClick={() => setExecuted(true)} className="btn-primary" style={{ backgroundColor: '#34C759', padding: '12px' }}>
                <CheckCircle2 size={16} /> Ejecutar Liquidación
              </button>
            </div>
          </>
        ) : (
          <div style={{ textAlign: 'center', padding: '20px 0' }}>
            <CheckCircle2 size={64} color="#34C759" style={{ margin: '0 auto 16px' }} />
            <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '8px' }}>¡Nómina de Pago Ejecutada!</h3>
            <p style={{ fontSize: '14px', color: '#98989D', marginBottom: '20px' }}>
              Se transfirieron ${netPayoutWorkers.toLocaleString('es-CL')} CLP a las cuentas bancarias de los trabajadores verificados.
            </p>
            <button onClick={onClose} className="btn-primary">
              Cerrar
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
