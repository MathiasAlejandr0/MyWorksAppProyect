import React, { useState } from 'react';
import { Edit3, AlertCircle, CheckCircle2, DollarSign, RefreshCw } from 'lucide-react';

interface Ticket {
  id: string;
  client: string;
  worker: string;
  issue: string;
  escrowAmount: number;
  date: string;
  status: 'Pending' | 'Resolved';
}

interface JobScopeAdjustmentModalProps {
  ticket: Ticket;
  onClose: () => void;
  onUpdateScope: (updatedTicket: Ticket, newTariff: number, newReason: string) => void;
}

export function JobScopeAdjustmentModal({ ticket, onClose, onUpdateScope }: JobScopeAdjustmentModalProps) {
  const [newReason, setNewReason] = useState(ticket.issue);
  const [newTariff, setNewTariff] = useState<number>(ticket.escrowAmount === 38000 ? 850000 : ticket.escrowAmount * 2);
  const [isSent, setIsSent] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSent(true);
    setTimeout(() => {
      onUpdateScope(ticket, newTariff, newReason);
    }, 1500);
  };

  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999, padding: '20px' }}>
      <div style={{ maxWidth: '520px', width: '100%', backgroundColor: '#1E293B', borderRadius: '18px', border: '2px solid #F0782A', padding: '28px', color: '#FFFFFF', boxShadow: '0 20px 50px rgba(0,0,0,0.6)', position: 'relative' }}>
        <button onClick={onClose} style={{ position: 'absolute', right: '20px', top: '20px', background: 'rgba(255,255,255,0.1)', border: 'none', color: '#94A3B8', width: '32px', height: '32px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          ✕
        </button>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#F0782A', marginBottom: '16px' }}>
          <Edit3 size={24} color="#F0782A" />
          <h3 style={{ fontSize: '20px', fontWeight: 900, color: '#FFFFFF' }}>Modificar Alcance & Re-Cotización</h3>
        </div>

        {isSent ? (
          <div style={{ padding: '30px 20px', textAlign: 'center' }}>
            <CheckCircle2 size={48} color="#34C759" style={{ margin: '0 auto 16px' }} />
            <h4 style={{ fontSize: '18px', fontWeight: 900, color: '#FFFFFF', marginBottom: '8px' }}>Propuesta de Ajuste Enviada al Cliente</h4>
            <p style={{ fontSize: '13px', color: '#CBD5E1', lineHeight: 1.5 }}>
              Se envió una notificación oficial a <strong>{ticket.client}</strong> para aprobar el nuevo monto Escrow de <strong>${newTariff.toLocaleString('es-CL')} CLP</strong>.
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', padding: '14px', borderRadius: '12px', fontSize: '12.5px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                <span style={{ color: '#94A3B8' }}>Ticket & Cliente:</span>
                <span style={{ color: '#F8FAFC', fontWeight: 700 }}>{ticket.id} - {ticket.client}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: '#94A3B8' }}>Tarifa Escrow Actual:</span>
                <span style={{ color: '#34C759', fontWeight: 900 }}>${ticket.escrowAmount.toLocaleString('es-CL')} CLP</span>
              </div>
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: 700, color: '#94A3B8', marginBottom: '4px', display: 'block' }}>Nuevo Alcance Real del Trabajo</label>
              <textarea 
                value={newReason}
                onChange={e => setNewReason(e.target.value)}
                required
                rows={3}
                style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: '1px solid #334155', backgroundColor: '#0F172A', color: 'white', fontSize: '13px', outline: 'none' }}
                placeholder="Ej: Cambio de requerimiento en terreno. Trabajo requiere reconstrucción de tabiquería y tablero trifásico."
              />
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: 700, color: '#94A3B8', marginBottom: '4px', display: 'block' }}>Nueva Tarifa Escrow Propuesta (CLP)</label>
              <div style={{ position: 'relative' }}>
                <input 
                  type="number" 
                  value={newTariff}
                  onChange={e => setNewTariff(Number(e.target.value))}
                  required
                  step={5000}
                  style={{ width: '100%', padding: '10px 12px 10px 36px', borderRadius: '8px', border: '1px solid #334155', backgroundColor: '#0F172A', color: '#34C759', fontSize: '16px', fontWeight: 900, outline: 'none' }}
                />
                <DollarSign size={18} style={{ position: 'absolute', left: '10px', top: '12px', color: '#34C759' }} />
              </div>
            </div>

            <div style={{ backgroundColor: 'rgba(240,120,42,0.15)', border: '1px solid #F0782A', padding: '10px 12px', borderRadius: '8px', fontSize: '11.5px', color: '#F0782A', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <AlertCircle size={18} />
              <span>Nota: El cobro adicional se actualizará en Escrow ÚNICAMENTE cuando el cliente acepte la re-cotización.</span>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginTop: '8px' }}>
              <button type="button" onClick={onClose} style={{ padding: '12px', borderRadius: '10px', border: '1px solid #334155', background: 'transparent', color: '#94A3B8', fontWeight: 700, cursor: 'pointer' }}>
                Cancelar
              </button>
              <button type="submit" className="btn-action-primary" style={{ padding: '12px', justifyContent: 'center' }}>
                <RefreshCw size={16} /> Enviar al Cliente
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
