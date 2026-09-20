import { useEffect, useState } from 'react';
import {
  Search,
  Filter,
  CheckCircle2,
  Send,
  ShieldAlert,
  Lock,
  Shield,
  ChevronDown,
  Bell,
  HelpCircle,
  ArrowLeftRight,
  Paperclip,
} from 'lucide-react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { JobScopeAdjustmentModal } from './JobScopeAdjustmentModal';
import { TableRowsSkeleton } from './LoadingState';
import { fetchOpenDisputes, updateDisputeStatus } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { queryKeys } from '../queryClient';

interface Ticket {
  id: string;
  client: string;
  worker: string;
  issue: string;
  escrowAmount: number;
  date: string;
  status: 'Pending' | 'Resolved';
}

interface SupportWorkspaceProps {
  adminId: string;
}

const DEMO_MESSAGES = {
  client: 'El trabajo entregado no cumple con los requisitos acordados en el contrato. Solicito revisión inmediata.',
  worker: 'El alcance original no incluía las revisiones adicionales solicitadas. Adjunto evidencia del acuerdo inicial.',
};

function mapDisputesToTickets(
  disputes: Awaited<ReturnType<typeof fetchOpenDisputes>>,
): Ticket[] {
  return disputes.map((dispute) => ({
    id: dispute.id,
    client: dispute.clientName,
    worker: dispute.workerName,
    issue: dispute.description ?? dispute.reason,
    escrowAmount: dispute.escrowAmount,
    date: new Date(dispute.createdAt).toLocaleString('es-CL'),
    status: dispute.status === 'resuelta' ? ('Resolved' as const) : ('Pending' as const),
  }));
}

export function SupportWorkspace({ adminId }: SupportWorkspaceProps) {
  const queryClient = useQueryClient();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [scopeModalTicket, setScopeModalTicket] = useState<Ticket | null>(null);
  const [notification, setNotification] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [messageInput, setMessageInput] = useState('');

  const ticketsQuery = useQuery({
    queryKey: queryKeys.openDisputes,
    queryFn: async () => mapDisputesToTickets(await fetchOpenDisputes(supabase)),
  });

  const tickets = ticketsQuery.data ?? [];
  const loading = ticketsQuery.isPending;

  const resolveMutation = useMutation({
    mutationFn: async ({
      ticketId,
      resolution,
    }: {
      ticketId: string;
      resolution: string;
    }) => {
      await updateDisputeStatus(supabase, ticketId, 'resuelta', resolution, adminId);
      return ticketId;
    },
    onSuccess: (ticketId) => {
      queryClient.setQueryData<Ticket[]>(queryKeys.openDisputes, (prev) =>
        (prev ?? []).map((t) =>
          t.id === ticketId ? { ...t, status: 'Resolved' } : t,
        ),
      );
    },
  });

  // Auto-select first ticket once data arrives
  useEffect(() => {
    if (!selectedId && tickets.length > 0) {
      setSelectedId(tickets[0].id);
    }
  }, [selectedId, tickets]);

  const selectedTicket = tickets.find((t) => t.id === selectedId) ?? null;

  const filtered = tickets.filter(
    (t) =>
      t.id.toLowerCase().includes(search.toLowerCase()) ||
      t.client.toLowerCase().includes(search.toLowerCase()) ||
      t.worker.toLowerCase().includes(search.toLowerCase()),
  );

  const resolveTicket = async (ticketId: string, action: 'refund' | 'payout' | 'split') => {
    const resolution =
      action === 'refund'
        ? 'Reembolso total al cliente'
        : action === 'payout'
          ? 'Pago liberado al profesional'
          : 'Resolución parcial 50/50';

    try {
      await resolveMutation.mutateAsync({ ticketId, resolution });
      setNotification(`Disputa actualizada: ${resolution}.`);
      setTimeout(() => setNotification(null), 4000);
    } catch {
      setNotification('No se pudo resolver la disputa.');
      setTimeout(() => setNotification(null), 4000);
    }
  };

  const displayId = selectedTicket?.id.slice(0, 8).toUpperCase() ?? '—';



  return (

    <div className="support-workspace">

      <header className="support-topbar">

        <div className="support-topbar-brand">

          <div className="support-topbar-logo" aria-hidden />

          <div>

            <strong>My Works App</strong>

            <span>Centro de soporte</span>

          </div>

        </div>

        <div className="support-search">

          <Search size={16} />

          <input type="search" placeholder="Buscar tickets, usuarios o disputas…" />

          <kbd>⌘ K</kbd>

        </div>

        <div className="support-topbar-actions">

          <button type="button" className="icon-btn support-notify" aria-label="Notificaciones">

            <Bell size={18} />

            <span className="notify-badge">3</span>

          </button>

          <button type="button" className="icon-btn" aria-label="Ayuda">

            <HelpCircle size={18} />

          </button>

          <div className="support-user-chip">

            <div className="support-user-avatar">MS</div>

            <div>

              <strong>Mediador Senior</strong>

              <span>Centro de Mediación</span>

            </div>

          </div>

        </div>

      </header>



      <div className="support-body">

        <aside className="support-sidebar">

          <div className="support-sidebar-head">

            <strong>Disputas</strong>

          </div>

          <nav className="support-sidebar-nav">

            <span className="support-nav-item active">Disputas</span>

            <span className="support-nav-item">Panel principal</span>

            <span className="support-nav-item">Tickets</span>

            <span className="support-nav-item">Clientes</span>

            <span className="support-nav-item">Trabajadores</span>

            <span className="support-nav-item">Pagos en custodia</span>

          </nav>

          <div className="support-sidebar-footer">

            <div className="support-online">

              <span className="live-pill-dot" aria-hidden />

              CENTRO DE MEDIACIÓN · En línea

            </div>

            <span className="support-tier">Nivel de servicio: Platino</span>

            <span className="support-plan"><Shield size={12} /> Plan de operación</span>

          </div>

        </aside>



        <section className="support-list-panel">

          <div className="support-list-head">

            <div>

              <h2>Disputas y Tickets de Soporte</h2>

              <span className="support-breadcrumb">Disputas › #{displayId}</span>

            </div>

            <button
              type="button"
              className="btn-filter"
              onClick={() => void ticketsQuery.refetch()}
            >

              <Filter size={14} /> Filtros

            </button>

          </div>



          <div className="support-list-toolbar">

            <span>Tickets de Disputa <em>{filtered.length || 128}</em></span>

            <div className="support-list-search">

              <Search size={14} />

              <input

                type="search"

                value={search}

                onChange={(e) => setSearch(e.target.value)}

                placeholder="Buscar…"

              />

            </div>

          </div>



          {notification && (

            <div className="support-toast">

              <CheckCircle2 size={16} /> {notification}

            </div>

          )}



          <div className="support-ticket-list">

            {loading && <TableRowsSkeleton rows={4} columns={1} />}

            {!loading && filtered.length === 0 && (

              <p className="support-empty">No hay disputas abiertas.</p>

            )}

            {!loading && filtered.map((ticket) => (

              <button

                key={ticket.id}

                type="button"

                className={`support-ticket-card${selectedId === ticket.id ? ' active' : ''}`}

                onClick={() => setSelectedId(ticket.id)}

              >

                <div className="support-ticket-card-top">

                  <strong>#{ticket.id.slice(0, 8).toUpperCase()}</strong>

                  <span className={`status-badge status-badge--${ticket.status === 'Pending' ? 'review' : 'resolved'}`}>

                    {ticket.status === 'Pending' ? 'En revisión' : 'Resuelto'}

                  </span>

                </div>

                <p className="support-ticket-issue">{ticket.issue}</p>

                <div className="support-ticket-meta">

                  <span>{ticket.client}</span>

                  <span>{ticket.worker}</span>

                </div>

                <div className="support-ticket-foot">

                  <span>{ticket.date.split(',')[0]}</span>

                  {ticket.status === 'Pending' && <span className="support-ticket-dot" aria-hidden />}

                </div>

              </button>

            ))}

          </div>



          <div className="support-pagination">

            <button type="button" disabled>‹</button>

            <button type="button" className="active">1</button>

            <button type="button">2</button>

            <button type="button">3</button>

            <span>…</span>

            <button type="button">›</button>

          </div>

        </section>



        <section className="support-detail-panel">

          {!selectedTicket ? (

            <div className="support-detail-empty">Selecciona un ticket para ver el expediente.</div>

          ) : (

            <>

              <div className="support-detail-head">

                <div>

                  <h2>Disputa #{displayId}</h2>

                  <span className={`status-badge status-badge--review`}>En revisión</span>

                </div>

                <div className="support-detail-meta">

                  <span>Abierto el {selectedTicket.date}</span>

                  <span><Shield size={12} /> Prioridad: Media</span>

                </div>

              </div>



              <div className="support-parties">

                <div className="support-party">

                  <span className="support-party-label">CLIENTE</span>

                  <strong>{selectedTicket.client}</strong>

                  <span>Representante legal</span>

                </div>

                <div className="support-party-swap"><ArrowLeftRight size={16} /></div>

                <div className="support-party">

                  <span className="support-party-label">TRABAJADOR</span>

                  <strong>{selectedTicket.worker}</strong>

                  <span>Profesional asignado</span>

                </div>

              </div>



              <div className="support-evidence">

                <h3>EVIDENCIA: COMPARACIÓN ANTES / DESPUÉS</h3>

                <div className="support-evidence-grid">

                  <div className="support-evidence-card">

                    <span className="support-evidence-tag">ANTES (ACORDADO)</span>

                    <div className="support-evidence-img support-evidence-img--before" />

                  </div>

                  <div className="support-evidence-vs">VS</div>

                  <div className="support-evidence-card">

                    <span className="support-evidence-tag support-evidence-tag--after">DESPUÉS (ENTREGADO)</span>

                    <div className="support-evidence-img support-evidence-img--after" />

                  </div>

                </div>

                <div className="support-evidence-footer">

                  <span>Acuerdo: {selectedTicket.issue}</span>

                  <span>Monto en custodia: ${selectedTicket.escrowAmount.toLocaleString('es-CL')} CLP</span>

                </div>

              </div>



              <div className="support-threads">

                <div className="support-thread support-thread--client">

                  <div className="support-thread-head">

                    <span className="support-thread-avatar support-thread-avatar--client">C</span>

                    <div>

                      <strong>{selectedTicket.client}</strong>

                      <span>Hace 2h</span>

                    </div>

                  </div>

                  <p>{DEMO_MESSAGES.client}</p>

                  <a className="support-attachment" href="#"><Paperclip size={12} /> evidencia_cliente.pdf</a>

                </div>

                <div className="support-thread support-thread--worker">

                  <div className="support-thread-head">

                    <span className="support-thread-avatar support-thread-avatar--worker">T</span>

                    <div>

                      <strong>{selectedTicket.worker}</strong>

                      <span>Hace 1h</span>

                    </div>

                  </div>

                  <p>{DEMO_MESSAGES.worker}</p>

                  <a className="support-attachment" href="#"><Paperclip size={12} /> entrega.zip</a>

                </div>

              </div>



              <div className="support-compose">

                <input

                  type="text"

                  value={messageInput}

                  onChange={(e) => setMessageInput(e.target.value)}

                  placeholder="Escribe un mensaje…"

                />

                <button type="button" className="support-send-btn" aria-label="Enviar">

                  <Send size={16} />

                </button>

              </div>



              <footer className="support-escrow-bar">

                <div>

                  <strong>Resolución del pago retenido</strong>

                  <p>Como mediador, decide la distribución de fondos retenidos.</p>

                </div>

                <div className="support-escrow-actions">

                  {selectedTicket.status === 'Pending' ? (

                    <>

                      <button type="button" className="btn-escrow-release" onClick={() => resolveTicket(selectedTicket.id, 'payout')}>

                        <Lock size={14} /> LIBERAR FONDOS

                      </button>

                      <button type="button" className="btn-escrow-hold" onClick={() => resolveTicket(selectedTicket.id, 'refund')}>

                        <ShieldAlert size={14} /> RETENER FONDOS

                      </button>

                      <button type="button" className="btn-escrow-more" onClick={() => resolveTicket(selectedTicket.id, 'split')}>

                        Otras acciones <ChevronDown size={14} />

                      </button>

                    </>

                  ) : (

                    <span className="status-badge status-badge--resolved">Resuelto</span>

                  )}

                </div>

              </footer>

            </>

          )}

        </section>

      </div>



      {scopeModalTicket && (

        <JobScopeAdjustmentModal

          ticket={scopeModalTicket}

          onClose={() => setScopeModalTicket(null)}

          onUpdateScope={(updated, newTariff, newReason) => {

            queryClient.setQueryData<Ticket[]>(queryKeys.openDisputes, (prev) =>

              (prev ?? []).map((t) =>

                t.id === updated.id ? { ...t, escrowAmount: newTariff, issue: newReason } : t,

              ),

            );

            setScopeModalTicket(null);

          }}

        />

      )}

    </div>

  );

}

