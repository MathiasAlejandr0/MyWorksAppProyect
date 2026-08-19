import { useEffect, useState } from 'react';
import { TicketCheck, CheckCircle2, RefreshCw, ArrowUpRight, Image, MessageSquare, Send, Scale, ShieldAlert, Edit3 } from 'lucide-react';
import { JobScopeAdjustmentModal } from './JobScopeAdjustmentModal';
import { fetchOpenDisputes, updateDisputeStatus } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface Ticket {
  id: string;
  client: string;
  worker: string;
  issue: string;
  escrowAmount: number;
  date: string;
  status: 'Pending' | 'Resolved';
}

interface ChatMessage {
  id: string;
  sender: 'ADMIN' | 'CLIENT' | 'WORKER';
  text: string;
  timestamp: string;
}

interface SupportWorkspaceProps {
  adminId: string;
}

export function SupportWorkspace({ adminId }: SupportWorkspaceProps) {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [scopeModalTicket, setScopeModalTicket] = useState<Ticket | null>(null);
  const [modalTab, setModalTab] = useState<number>(0); // 0: Evidencias, 1: Mensajería Dual, 2: Veredicto
  const [notification, setNotification] = useState<string | null>(null);

  const loadTickets = async () => {
    setLoading(true);
    try {
      const disputes = await fetchOpenDisputes(supabase);
      setTickets(
        disputes.map((dispute) => ({
          id: dispute.id,
          client: dispute.clientName,
          worker: dispute.workerName,
          issue: dispute.description ?? dispute.reason,
          escrowAmount: dispute.escrowAmount,
          date: new Date(dispute.createdAt).toLocaleString('es-CL'),
          status: dispute.status === 'resolved' ? 'Resolved' : 'Pending',
        })),
      );
    } catch {
      setTickets([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadTickets();
  }, []);

  const handleUpdateScope = (updatedTicket: Ticket, newTariff: number, newReason: string) => {
    setTickets(prev => prev.map(t => t.id === updatedTicket.id ? { ...t, escrowAmount: newTariff, issue: newReason } : t));
    setScopeModalTicket(null);
    setNotification(`🔴 Notificación enviada a ${updatedTicket.client}: Propuesta de re-cotización a $${newTariff.toLocaleString('es-CL')} CLP pendiente de aceptación.`);
    setTimeout(() => setNotification(null), 5000);
  };

  // Estado de Mensajería Dual
  const [targetRecipient, setTargetRecipient] = useState<'CLIENT' | 'WORKER' | 'BOTH'>('BOTH');
  const [messageInput, setMessageInput] = useState('');
  const [messages, setMessages] = useState<ChatMessage[]>([
    { id: '1', sender: 'CLIENT', text: 'El profesional dejó los cables al descubierto y no terminó la instalación.', timestamp: '18:42' },
    { id: '2', sender: 'WORKER', text: 'El tablero existente no tenía diferencial SEC, se requieren materiales adicionales.', timestamp: '19:05' },
  ]);

  const sendMessage = (textToSend?: string) => {
    const text = textToSend || messageInput;
    if (!text.trim()) return;
    const recipientText = targetRecipient === 'CLIENT' ? '(Para Cliente)' : targetRecipient === 'WORKER' ? '(Para Profesional)' : '(Para Ambos)';
    const newMsg: ChatMessage = {
      id: Date.now().toString(),
      sender: 'ADMIN',
      text: `🔴 Mensaje Oficial Admin ${recipientText}: ${text}`,
      timestamp: new Date().toLocaleTimeString().slice(0, 5),
    };
    setMessages(prev => [...prev, newMsg]);
    setMessageInput('');
  };

  const resolveTicket = async (ticketId: string, action: 'refund' | 'payout' | 'split') => {
    const resolution =
      action === 'refund'
        ? 'Reembolso total al cliente'
        : action === 'payout'
          ? 'Pago liberado al profesional'
          : 'Resolución parcial 50/50';

    try {
      await updateDisputeStatus(supabase, ticketId, 'resolved', resolution, adminId);
      setTickets((prev) => prev.map((t) => (t.id === ticketId ? { ...t, status: 'Resolved' } : t)));
      setSelectedTicket(null);
      setNotification(`Disputa actualizada en Supabase: ${resolution}.`);
      setTimeout(() => setNotification(null), 4000);
    } catch {
      setNotification('No se pudo resolver la disputa en Supabase.');
      setTimeout(() => setNotification(null), 4000);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 900 }}>Centro de Soporte & Mediación Escrow</h1>
          <p style={{ fontSize: '13.5px', color: '#98989D' }}>Resolución de disputas con expediente de evidencias multimedia y mensajería dual.</p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="badge-tag" style={{ backgroundColor: 'rgba(255, 149, 0, 0.15)', color: '#FF9500' }}>
            <TicketCheck size={14} /> {tickets.filter(t => t.status === 'Pending').length} Disputas Activas
          </span>
          <button onClick={() => void loadTickets()} className="btn-action-secondary">
            <RefreshCw size={14} /> Actualizar
          </button>
        </div>
      </div>

      {loading && (
        <p style={{ color: '#98989D', marginBottom: '16px' }}>Cargando disputas desde Supabase...</p>
      )}

      {notification && (
        <div style={{ backgroundColor: 'rgba(52, 199, 89, 0.15)', border: '1px solid #34C759', color: '#34C759', padding: '12px 18px', borderRadius: '12px', marginBottom: '20px', fontWeight: 700, fontSize: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <CheckCircle2 size={18} /> {notification}
        </div>
      )}

      {/* Tabla de Tickets de Soporte */}
      <div className="card-3d" style={{ overflow: 'hidden', padding: 0 }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: 'rgba(255,255,255,0.04)', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>TICKET ID</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>CLIENTE</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>PROFESIONAL</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>MOTIVO DE DISPUTA</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ESCROW</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ESTADO</th>
              <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>EXPEDIENTE</th>
            </tr>
          </thead>
          <tbody>
            {tickets.map(ticket => (
              <tr key={ticket.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <td style={{ padding: '16px 20px', fontWeight: 800, color: '#F0782A' }}>{ticket.id}</td>
                <td style={{ padding: '16px 20px', fontWeight: 600 }}>{ticket.client}</td>
                <td style={{ padding: '16px 20px', color: '#98989D' }}>{ticket.worker}</td>
                <td style={{ padding: '16px 20px', maxWidth: '240px' }}>{ticket.issue}</td>
                <td style={{ padding: '16px 20px', fontWeight: 800, color: '#34C759' }}>
                  ${ticket.escrowAmount.toLocaleString('es-CL')} CLP
                </td>
                <td style={{ padding: '16px 20px' }}>
                  <span className="badge-tag" style={{ backgroundColor: ticket.status === 'Pending' ? 'rgba(255, 59, 48, 0.15)' : 'rgba(52, 199, 89, 0.15)', color: ticket.status === 'Pending' ? '#FF3B30' : '#34C759' }}>
                    {ticket.status === 'Pending' ? 'Pendiente' : 'Resuelto'}
                  </span>
                </td>
                <td style={{ padding: '16px 20px' }}>
                  {ticket.status === 'Pending' ? (
                    <div style={{ display: 'flex', gap: '6px' }}>
                      <button onClick={() => { setSelectedTicket(ticket); setModalTab(0); }} className="btn-action-primary" style={{ padding: '6px 12px', fontSize: '11.5px' }}>
                        Abrir Expediente
                      </button>
                      <button onClick={() => setScopeModalTicket(ticket)} className="btn-action-secondary" style={{ padding: '6px 12px', fontSize: '11.5px', color: '#F0782A', borderColor: '#F0782A' }}>
                        <Edit3 size={12} /> Modificar Alcance
                      </button>
                    </div>
                  ) : (
                    <span style={{ fontSize: '12px', color: '#98989D' }}>Cerrado</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal del Expediente de Mediación Admin */}
      {selectedTicket && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999, padding: '20px' }}>
          <div style={{ maxWidth: '680px', width: '100%', backgroundColor: '#1E293B', borderRadius: '18px', border: '2px solid #FF3B30', padding: '28px', color: '#FFFFFF', boxShadow: '0 20px 50px rgba(0,0,0,0.6)', position: 'relative' }}>
            <button onClick={() => setSelectedTicket(null)} style={{ position: 'absolute', right: '20px', top: '20px', background: 'rgba(255,255,255,0.1)', border: 'none', color: '#94A3B8', width: '32px', height: '32px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              ✕
            </button>

            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#FF3B30', marginBottom: '14px' }}>
              <ShieldAlert size={26} color="#FF3B30" />
              <div>
                <h3 style={{ fontSize: '20px', fontWeight: 900, color: '#FFFFFF' }}>Expediente de Mediación: {selectedTicket.id}</h3>
                <span style={{ fontSize: '12px', color: '#94A3B8' }}>Cliente: {selectedTicket.client} vs Profesional: {selectedTicket.worker}</span>
              </div>
            </div>

            {/* Pestañas del Expediente Admin */}
            <div className="sub-tabs-bar" style={{ marginBottom: '18px' }}>
              <div className={`sub-tab-item ${modalTab === 0 ? 'active' : ''}`} onClick={() => setModalTab(0)}>
                <Image size={15} /> 1. Evidencias Fotografías & Video
              </div>
              <div className={`sub-tab-item ${modalTab === 1 ? 'active' : ''}`} onClick={() => setModalTab(1)}>
                <MessageSquare size={15} /> 2. Mensajería Dual ({messages.length})
              </div>
              <div className={`sub-tab-item ${modalTab === 2 ? 'active' : ''}`} onClick={() => setModalTab(2)}>
                <Scale size={15} /> 3. Veredicto & Custodia Escrow
              </div>
            </div>

            {/* PESTAÑA 1: Evidencias Multimedia Comparativas */}
            {modalTab === 0 && (
              <div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '18px' }}>
                  {/* Evidencias del Cliente */}
                  <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', borderRadius: '12px', padding: '14px' }}>
                    <div style={{ fontSize: '12px', fontWeight: 800, color: '#EF4444', textTransform: 'uppercase', marginBottom: '8px' }}>
                      📸 Evidencia Subida por Cliente
                    </div>
                    <img 
                      src="https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=400&q=80" 
                      alt="Falla Cliente" 
                      style={{ width: '100%', height: '140px', objectFit: 'cover', borderRadius: '8px', marginBottom: '8px' }} 
                    />
                    <p style={{ fontSize: '11.5px', color: '#CBD5E1' }}>"Fotografía del tablero con cableado expuesto sin protección."</p>
                  </div>

                  {/* Evidencias del Trabajador */}
                  <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', borderRadius: '12px', padding: '14px' }}>
                    <div style={{ fontSize: '12px', fontWeight: 800, color: '#10B981', textTransform: 'uppercase', marginBottom: '8px' }}>
                      📸 Prueba Entregada por Trabajador
                    </div>
                    <img 
                      src="https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=400&q=80" 
                      alt="Trabajo Entregado" 
                      style={{ width: '100%', height: '140px', objectFit: 'cover', borderRadius: '8px', marginBottom: '8px' }} 
                    />
                    <p style={{ fontSize: '11.5px', color: '#CBD5E1' }}>"Comprobante de instalación parcial y orden de materiales."</p>
                  </div>
                </div>

                <div style={{ backgroundColor: '#0F172A', padding: '12px', borderRadius: '10px', fontSize: '12.5px', color: '#34C759', fontWeight: 800, display: 'flex', justifyContent: 'space-between' }}>
                  <span>Monto Retenido en Custodia Escrow:</span>
                  <span>${selectedTicket.escrowAmount.toLocaleString('es-CL')} CLP</span>
                </div>
              </div>
            )}

            {/* PESTAÑA 2: Mensajería Directa Dual (Cliente & Trabajador) */}
            {modalTab === 1 && (
              <div>
                {/* Historial de Chat */}
                <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', borderRadius: '12px', padding: '14px', height: '180px', overflowY: 'auto', marginBottom: '14px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {messages.map(m => (
                    <div key={m.id} style={{ padding: '8px 12px', borderRadius: '8px', backgroundColor: m.sender === 'ADMIN' ? 'rgba(239,68,68,0.2)' : m.sender === 'CLIENT' ? 'rgba(0,122,255,0.15)' : 'rgba(52,199,89,0.15)', border: `1px solid ${m.sender === 'ADMIN' ? '#EF4444' : m.sender === 'CLIENT' ? '#007AFF' : '#34C759'}` }}>
                      <div style={{ fontSize: '10.5px', fontWeight: 800, color: m.sender === 'ADMIN' ? '#EF4444' : m.sender === 'CLIENT' ? '#007AFF' : '#34C759', marginBottom: '2px' }}>
                        {m.sender === 'ADMIN' ? '🔴 ADMIN (Oficial)' : m.sender === 'CLIENT' ? '👤 CLIENTE' : '🧰 TRABAJADOR'} - {m.timestamp}
                      </div>
                      <div style={{ fontSize: '12.5px', color: '#F8FAFC' }}>{m.text}</div>
                    </div>
                  ))}
                </div>

                {/* Selector de Destinatario */}
                <div style={{ display: 'flex', gap: '8px', marginBottom: '8px', alignItems: 'center' }}>
                  <span style={{ fontSize: '11px', color: '#94A3B8', fontWeight: 700 }}>Enviar mensaje a:</span>
                  <button onClick={() => setTargetRecipient('BOTH')} style={{ padding: '4px 10px', borderRadius: '12px', border: 'none', backgroundColor: targetRecipient === 'BOTH' ? '#EF4444' : '#334155', color: 'white', fontSize: '11px', fontWeight: 700, cursor: 'pointer' }}>Ambos</button>
                  <button onClick={() => setTargetRecipient('CLIENT')} style={{ padding: '4px 10px', borderRadius: '12px', border: 'none', backgroundColor: targetRecipient === 'CLIENT' ? '#007AFF' : '#334155', color: 'white', fontSize: '11px', fontWeight: 700, cursor: 'pointer' }}>Cliente</button>
                  <button onClick={() => setTargetRecipient('WORKER')} style={{ padding: '4px 10px', borderRadius: '12px', border: 'none', backgroundColor: targetRecipient === 'WORKER' ? '#34C759' : '#334155', color: 'white', fontSize: '11px', fontWeight: 700, cursor: 'pointer' }}>Trabajador</button>
                </div>

                {/* Caja de Texto */}
                <div style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
                  <input 
                    type="text" 
                    value={messageInput}
                    onChange={(e) => setMessageInput(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
                    placeholder="Escribe un mensaje oficial de mediación..."
                    style={{ flex: 1, padding: '10px 14px', borderRadius: '8px', border: '1px solid #334155', backgroundColor: '#0F172A', color: 'white', fontSize: '13px', outline: 'none' }}
                  />
                  <button onClick={() => sendMessage()} className="btn-action-primary" style={{ padding: '10px 16px' }}>
                    <Send size={14} /> Enviar
                  </button>
                </div>

                {/* Action Chips Rápidos */}
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                  <button onClick={() => sendMessage('Por favor adjuntar foto del tablero con la tapa cerrada antes de 24h.')} style={{ backgroundColor: 'rgba(255,255,255,0.06)', border: '1px solid #334155', color: '#CBD5E1', padding: '4px 10px', borderRadius: '12px', fontSize: '11px', cursor: 'pointer' }}>
                    📍 Pedir foto final en 24h
                  </button>
                  <button onClick={() => sendMessage('Se otorga un plazo final de 12h para descargos antes de liberar o reembolsar.')} style={{ backgroundColor: 'rgba(255,255,255,0.06)', border: '1px solid #334155', color: '#CBD5E1', padding: '4px 10px', borderRadius: '12px', fontSize: '11px', cursor: 'pointer' }}>
                    ⏰ Dar plazo final 12h
                  </button>
                </div>
              </div>
            )}

            {/* PESTAÑA 3: Veredicto & Resolución Escrow */}
            {modalTab === 2 && (
              <div>
                <div style={{ backgroundColor: '#0F172A', border: '1px solid #334155', padding: '16px', borderRadius: '12px', marginBottom: '18px', fontSize: '13px' }}>
                  <div style={{ fontWeight: 800, color: '#F0782A', marginBottom: '6px' }}>dictamen de Custodia Escrow MyWorks Protect</div>
                  <p style={{ color: '#CBD5E1', marginBottom: '10px' }}>Tras evaluar las evidencias multimedia y las respuestas del canal de mediación, selecciona la decisión definitiva:</p>
                  <div style={{ color: '#34C759', fontWeight: 900, fontSize: '16px' }}>Total a Disposición: ${selectedTicket.escrowAmount.toLocaleString('es-CL')} CLP</div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <button onClick={() => resolveTicket(selectedTicket.id, 'refund')} className="btn-action-danger" style={{ padding: '12px', justifyContent: 'center' }}>
                    <RefreshCw size={16} /> Reembolsar 100% al Cliente (${selectedTicket.escrowAmount.toLocaleString('es-CL')} CLP)
                  </button>
                  <button onClick={() => resolveTicket(selectedTicket.id, 'payout')} className="btn-action-success" style={{ padding: '12px', justifyContent: 'center' }}>
                    <ArrowUpRight size={16} /> Liberar 100% al Profesional (${selectedTicket.escrowAmount.toLocaleString('es-CL')} CLP)
                  </button>
                  <button onClick={() => resolveTicket(selectedTicket.id, 'split')} className="btn-action-secondary" style={{ padding: '12px', justifyContent: 'center', color: '#F0782A', borderColor: '#F0782A' }}>
                    <Scale size={16} /> Resolución Parcial 50% / 50% (${(selectedTicket.escrowAmount / 2).toLocaleString('es-CL')} CLP c/u)
                  </button>
                </div>
              </div>
            )}

            <div style={{ marginTop: '18px', paddingTop: '12px', borderTop: '1px solid #334155' }}>
              <button onClick={() => setSelectedTicket(null)} style={{ width: '100%', padding: '10px', background: 'transparent', border: 'none', color: '#94A3B8', cursor: 'pointer', fontSize: '12.5px', fontWeight: 700 }}>
                Cerrar Expediente
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Re-Cotización y Ajuste de Alcance */}
      {scopeModalTicket && (
        <JobScopeAdjustmentModal 
          ticket={scopeModalTicket}
          onClose={() => setScopeModalTicket(null)}
          onUpdateScope={handleUpdateScope}
        />
      )}
    </div>
  );
}
