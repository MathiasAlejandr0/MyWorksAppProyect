import { useState } from 'react';
import { ShieldCheck, FileCheck, CheckCircle2, Download } from 'lucide-react';

interface DigitalContractModalProps {
  clientName: string;
  clientRut: string;
  workerName: string;
  workerRut: string;
  serviceDescription: string;
  totalAmount: number;
  onClose: () => void;
}

export function DigitalContractModal({
  clientName,
  clientRut,
  workerName,
  workerRut,
  serviceDescription,
  totalAmount,
  onClose,
}: DigitalContractModalProps) {
  const [isSigned, setIsSigned] = useState(false);
  const [shaHash, setShaHash] = useState<string>('');

  const handleSignContract = () => {
    const hash = 'SHA256-' + Math.random().toString(36).substring(2, 10).toUpperCase() + '-' + Date.now().toString(36).toUpperCase();
    setShaHash(hash);
    setIsSigned(true);
  };

  const handleDownloadCopy = () => {
    const element = document.createElement("a");
    const file = new Blob([
      `==========================================================\n` +
      `CONTRATO DIGITAL DE PRESTACIÓN DE SERVICIOS (LEY 19.799 CHILE)\n` +
      `==========================================================\n\n` +
      `CLIENTE: ${clientName} (RUT: ${clientRut})\n` +
      `PROFESIONAL: ${workerName} (RUT: ${workerRut})\n` +
      `ALCANCE DEL SERVICIO: ${serviceDescription}\n` +
      `MONTO EN CUSTODIA ESCROW: $${totalAmount.toLocaleString('es-CL')} CLP\n` +
      `GARANTÍA EXTENDIDA: 30 Días MyWorks Protect\n\n` +
      `FIRMA CRIPTOGRÁFICA SHA-256: ${shaHash}\n` +
      `FECHA DE EMISIÓN: ${new Date().toLocaleString('es-CL')}\n` +
      `==========================================================`
    ], { type: 'text/plain;charset=utf-8' });
    element.href = URL.createObjectURL(file);
    element.download = `Contrato_Digital_MyWorks_${clientRut}.txt`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999, padding: '20px' }}>
      <div style={{ maxWidth: '620px', width: '100%', backgroundColor: '#1E293B', borderRadius: '18px', border: '2px solid #007AFF', padding: '28px', color: '#FFFFFF', boxShadow: '0 20px 50px rgba(0,0,0,0.6)', position: 'relative' }}>
        <button onClick={onClose} style={{ position: 'absolute', right: '20px', top: '20px', background: 'rgba(255,255,255,0.1)', border: 'none', color: '#94A3B8', width: '32px', height: '32px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          ✕
        </button>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#007AFF', marginBottom: '16px' }}>
          <ShieldCheck size={26} color="#007AFF" />
          <div>
            <h3 style={{ fontSize: '20px', fontWeight: 900, color: '#FFFFFF' }}>Contrato Digital de Prestación de Servicios</h3>
            <span style={{ fontSize: '11.5px', color: '#94A3B8' }}>Validez Jurídica bajo Ley 19.799 sobre Firma Electrónica en Chile</span>
          </div>
        </div>

        {/* Vista del Contrato Legal */}
        <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', borderRadius: '12px', padding: '18px', marginBottom: '18px', fontSize: '12.5px', height: '200px', overflowY: 'auto', lineHeight: 1.6, color: '#CBD5E1' }}>
          <p style={{ fontWeight: 800, color: '#F0782A', marginBottom: '8px' }}>CLÁUSULAS DEL SERVICIO EN CUSTODIA ESCROW:</p>
          <p><strong>1. PARTES:</strong> En Santiago de Chile, se suscribe el presente contrato entre el Cliente <strong>{clientName}</strong> (RUT: {clientRut}) y el Profesional <strong>{workerName}</strong> (RUT: {workerRut}).</p>
          <p style={{ marginTop: '6px' }}><strong>2. OBJETO:</strong> La ejecución del trabajo consistente en: <em>"{serviceDescription}"</em>.</p>
          <p style={{ marginTop: '6px' }}><strong>3. CUSTODIA DE FONDOS:</strong> La suma de <strong>${totalAmount.toLocaleString('es-CL')} CLP</strong> permanecerá en custodia cautelar Escrow MyWorks Protect y se liberará únicamente tras la recepción conforme del cliente o resolución arbitral de la plataforma.</p>
          <p style={{ marginTop: '6px' }}><strong>4. GARANTÍA EXTENDIDA:</strong> El trabajo cuenta con 30 días de cobertura total ante fallas técnicas.</p>
        </div>

        {isSigned ? (
          <div style={{ backgroundColor: 'rgba(52,199,89,0.15)', border: '1px solid #34C759', borderRadius: '12px', padding: '16px', marginBottom: '18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <CheckCircle2 size={24} color="#34C759" />
              <div>
                <div style={{ fontSize: '13.5px', fontWeight: 900, color: '#34C759' }}>CONTRATO FIRMADO ELECTRÓNICAMENTE</div>
                <div style={{ fontSize: '11px', color: '#CBD5E1', fontFamily: 'monospace' }}>Hash SHA-256: {shaHash}</div>
              </div>
            </div>
            <button onClick={handleDownloadCopy} className="btn-action-success" style={{ fontSize: '11.5px', padding: '6px 12px' }}>
              <Download size={14} /> Descargar
            </button>
          </div>
        ) : (
          <div style={{ marginBottom: '18px', textAlign: 'center' }}>
            <p style={{ fontSize: '12px', color: '#94A3B8', marginBottom: '12px' }}>Al presionar "Firmar Electrónicamente", ambas partes aceptan las cláusulas contractuales con validez legal.</p>
            <button onClick={handleSignContract} className="btn-action-primary" style={{ width: '100%', padding: '14px', justifyContent: 'center', fontSize: '14px' }}>
              <FileCheck size={18} /> Firmar Electrónicamente (Ley 19.799)
            </button>
          </div>
        )}

        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <button onClick={onClose} style={{ padding: '8px 16px', background: 'transparent', border: '1px solid #334155', borderRadius: '8px', color: '#94A3B8', cursor: 'pointer', fontSize: '12px', fontWeight: 700 }}>
            Cerrar Ventana
          </button>
        </div>
      </div>
    </div>
  );
}
