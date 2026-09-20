import {
  ArrowLeft,
  Bell,
  ChevronDown,
  Lock,
  MessageCircle,
  ShieldCheck,
  Navigation,
  Plus,
  Minus,
  Crosshair,
} from 'lucide-react';
import { BrandLogo } from './BrandLogo';

interface TrackingDashboardProps {
  workerName: string;
  workerProfession: string;
  workerPhoto: string;
  workerRating: number;
  workerJobs: number;
  serviceTitle: string;
  serviceLocation: string;
  orderId: string;
  etaMinutes: number;
  distanceKm: number;
  profileName?: string;
  onBack: () => void;
  onOpenChat: () => void;
}

export function TrackingDashboard({
  workerName,
  workerProfession: _workerProfession,
  workerPhoto,
  workerRating,
  workerJobs,
  serviceTitle,
  serviceLocation,
  orderId,
  etaMinutes,
  distanceKm,
  profileName,
  onBack,
  onOpenChat,
}: TrackingDashboardProps) {
  const arrival = new Date();
  arrival.setMinutes(arrival.getMinutes() + etaMinutes);
  const arrivalTime = arrival.toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' });

  return (
    <div className="tracking-dashboard">
      <header className="tracking-nav">
        <BrandLogo size={32} />
        <span className="tracking-premium-badge">PREMIUM</span>

        <div className="tracking-nav-center">
          <span className="tracking-secure-item">
            <Lock size={13} /> Dark Web Access
          </span>
          <span className="tracking-secure-item tracking-secure-live">
            <span className="tracking-live-dot" /> Conexión segura
          </span>
        </div>

        <div className="tracking-nav-right">
          <button type="button" className="search-nav-bell" aria-label="Notificaciones">
            <Bell size={18} />
            <span className="search-nav-badge">3</span>
          </button>
          <div className="tracking-nav-user">
            <div className="search-nav-avatar">{profileName?.charAt(0) ?? 'A'}</div>
            <div>
              <strong>{profileName ?? 'Tu cuenta'}</strong>
              <span>Plan de la cuenta</span>
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
            <span className="tracking-status-dot" /> Trabajo en progreso
          </div>

          <div className="tracking-service-head">
            <h1>{serviceTitle}</h1>
            <span className="tracking-order-id">ID: #{orderId}</span>
          </div>
          <p className="tracking-service-loc">{serviceLocation}</p>

          <div className="tracking-eta-block">
            <div className="tracking-eta-main">
              <span className="tracking-eta-label">Llegada</span>
              <strong className="tracking-eta-value">{etaMinutes} min</strong>
              <span className="tracking-eta-km">~ {distanceKm} km</span>
            </div>
            <p className="tracking-eta-arrival">Llegada estimada: {arrivalTime}</p>
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
                <span className="tracking-verified-badge">VERIFICADO</span>
              </div>
            </div>
          </div>

          <div className="tracking-status-block">
            <p className="tracking-block-label">ESTADO ACTUAL</p>
            <div className="tracking-current-status">
              <span className="tracking-status-dot" /> En camino
            </div>
            <p className="tracking-status-detail">Salió del último punto a las {arrivalTime}</p>
          </div>

          <button type="button" className="btn-primary tracking-chat-btn" onClick={onOpenChat}>
            <MessageCircle size={18} /> Abrir Chat
          </button>

          <div className="tracking-escrow-card">
            <ShieldCheck size={22} className="tracking-escrow-icon" />
            <div>
              <strong>Pago protegido</strong>
              <p>Fondos seguros en custodia. Liberación automática al completar el trabajo.</p>
              <button type="button" className="tracking-escrow-link">
                Ver detalles del pago
              </button>
            </div>
          </div>

          <p className="tracking-footer-note">
            <Lock size={12} /> Conexión enrutada • Encriptación E2E
          </p>
        </aside>

        <div className="tracking-map-full">
          <div className="tracking-map-bg">
            <div className="tracking-map-labels">
              <span style={{ top: '22%', left: '38%' }}>PROVIDENCIA</span>
              <span style={{ top: '35%', left: '52%' }}>VITACURA</span>
              <span style={{ top: '48%', left: '42%' }}>LAS CONDES</span>
            </div>
            <svg className="tracking-route-svg" viewBox="0 0 800 600" preserveAspectRatio="none">
              <path
                d="M 120 480 Q 280 380 420 320 T 620 180"
                fill="none"
                stroke="url(#routeGlow)"
                strokeWidth="6"
                strokeLinecap="round"
              />
              <defs>
                <linearGradient id="routeGlow" x1="0%" y1="100%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#F0782A" stopOpacity="0.4" />
                  <stop offset="100%" stopColor="#F0782A" />
                </linearGradient>
              </defs>
            </svg>
            <div className="tracking-route-start" />
            <div className="tracking-worker-marker">
              <img src={workerPhoto} alt="" />
              <div className="tracking-worker-tooltip">
                <span className="tracking-live-dot" /> {workerName}
                <small>Velocidad: 32 km/h</small>
              </div>
            </div>
          </div>

          <button type="button" className="tracking-compass" aria-label="Brújula">
            <Navigation size={18} />
          </button>
          <div className="tracking-scale">2 km</div>
          <div className="tracking-map-zoom">
            <button type="button" aria-label="Acercar">
              <Plus size={16} />
            </button>
            <button type="button" aria-label="Alejar">
              <Minus size={16} />
            </button>
            <button type="button" aria-label="Mi ubicación">
              <Crosshair size={16} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
