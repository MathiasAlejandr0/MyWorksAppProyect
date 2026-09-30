import { useState } from 'react';
import {
  ArrowLeft,
  Bell,
  ChevronDown,
  Lock,
  MessageCircle,
  ShieldCheck,
} from 'lucide-react';
import { jobStatusDetail, jobStatusLabel, paymentStatusLabel } from '@myworksapp/shared';
import { BrandLogo } from './BrandLogo';
import { JobLocationMap } from './JobLocationMap';

interface TrackingDashboardProps {
  workerName: string;
  workerProfession: string;
  workerPhoto: string;
  workerRating: number;
  workerJobs: number;
  serviceTitle: string;
  serviceLocation: string;
  orderId: string;
  jobStatus?: string | null;
  paymentStatus?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  profileName?: string;
  paymentNotice?: string | null;
  unreadCount?: number;
  onBack: () => void;
  onOpenChat: () => void;
  onOpenNotifications?: () => void;
}

export function TrackingDashboard({
  workerName,
  workerProfession,
  workerPhoto,
  workerRating,
  workerJobs,
  serviceTitle,
  serviceLocation,
  orderId,
  jobStatus,
  paymentStatus,
  latitude,
  longitude,
  profileName,
  paymentNotice,
  unreadCount = 0,
  onBack,
  onOpenChat,
  onOpenNotifications,
}: TrackingDashboardProps) {
  const [showPayment, setShowPayment] = useState(false);
  const hasPoint = typeof latitude === 'number' && typeof longitude === 'number'
    && Number.isFinite(latitude) && Number.isFinite(longitude);
  const statusLabel = jobStatusLabel(jobStatus);
  const statusDetail = jobStatusDetail(jobStatus);

  return (
    <div className="tracking-dashboard">
      <header className="tracking-nav">
        <BrandLogo size={32} />
        <span className="tracking-premium-badge">CLIENTE</span>

        <div className="tracking-nav-center">
          <span className="tracking-secure-item tracking-secure-live">
            <span className="tracking-live-dot" /> Sesión del sitio
          </span>
        </div>

        <div className="tracking-nav-right">
          <button
            type="button"
            className="search-nav-bell"
            aria-label="Notificaciones"
            onClick={onOpenNotifications}
          >
            <Bell size={18} />
            {unreadCount > 0 ? <span className="search-nav-badge">{unreadCount}</span> : null}
          </button>
          <div className="tracking-nav-user">
            <div className="search-nav-avatar">{profileName?.charAt(0) ?? 'C'}</div>
            <div>
              <strong>{profileName ?? 'Invitado'}</strong>
              <span>Cuenta de cliente</span>
            </div>
            <ChevronDown size={14} />
          </div>
        </div>
      </header>

      <div className="tracking-layout">
        <aside className="tracking-sidebar">
          <button type="button" className="tracking-back-link" onClick={onBack}>
            <ArrowLeft size={16} /> Seguimiento del trabajo
          </button>

          <div className="tracking-status-pill">
            <span className="tracking-status-dot" /> {statusLabel}
          </div>

          <div className="tracking-service-head">
            <h1>{serviceTitle}</h1>
            <span className="tracking-order-id">ID: {orderId}</span>
          </div>
          <p className="tracking-service-loc">{serviceLocation}</p>
          <p className="tracking-service-loc">{workerProfession}</p>

          <div className="tracking-eta-block">
            <div className="tracking-eta-main">
              <span className="tracking-eta-label">Llegada</span>
              <strong className="tracking-eta-value">Sin GPS</strong>
            </div>
            <p className="tracking-eta-arrival">
              No hay seguimiento de ubicación del profesional. El estado cambia cuando él actualiza el trabajo en la app.
            </p>
          </div>

          <div className="tracking-worker-block">
            <p className="tracking-block-label">TRABAJADOR</p>
            <div className="tracking-worker-row">
              <img src={workerPhoto} alt="" className="tracking-worker-photo" />
              <div>
                <strong>{workerName}</strong>
                <div className="tracking-worker-rating">
                  ★ {workerRating.toFixed(1)} ({workerJobs} trabajos)
                </div>
              </div>
            </div>
          </div>

          <div className="tracking-status-block">
            <p className="tracking-block-label">ESTADO ACTUAL</p>
            <div className="tracking-current-status">
              <span className="tracking-status-dot" /> {statusLabel}
            </div>
            <p className="tracking-status-detail">{statusDetail}</p>
          </div>

          <button type="button" className="btn-primary tracking-chat-btn" onClick={onOpenChat}>
            <MessageCircle size={18} /> Abrir chat
          </button>

          <div className="tracking-escrow-card">
            <ShieldCheck size={22} className="tracking-escrow-icon" />
            <div>
              <strong>Pago protegido</strong>
              <p>
                {paymentStatusLabel(paymentStatus)}. Se libera cuando das tu conformidad.
                Si abres una disputa, solo el equipo de atención puede liberarlo o devolverlo.
              </p>
              <button
                type="button"
                className="tracking-escrow-link"
                onClick={() => setShowPayment((open) => !open)}
              >
                {showPayment ? 'Ocultar detalles del pago' : 'Ver detalles del pago'}
              </button>
              {showPayment && (
                <p>
                  Pedido {orderId}. Estado del trabajo: {statusLabel}. Estado del pago: {paymentStatusLabel(paymentStatus)}.
                </p>
              )}
            </div>
          </div>

          <p className="tracking-footer-note">
            <Lock size={12} /> Conexión HTTPS con Supabase. El chat no usa cifrado de extremo a extremo aparte del transporte.
          </p>
        </aside>

        <div className="tracking-map-full">
          {paymentNotice ? (
            <p className="tracking-payment-banner" role="status">
              {paymentNotice}
            </p>
          ) : null}
          {hasPoint ? (
            <JobLocationMap
              latitude={latitude}
              longitude={longitude}
              label={serviceLocation}
            />
          ) : (
            <div className="tracking-map-empty">
              <p>Este pedido no tiene coordenadas.</p>
              <p>La dirección queda en el panel de la izquierda.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
