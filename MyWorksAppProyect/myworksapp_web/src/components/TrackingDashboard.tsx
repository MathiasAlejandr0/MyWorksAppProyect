import { useEffect, useState, type ReactNode } from 'react';
import {
  ArrowLeft,
  Bell,
  Home,
  Lock,
  MessageCircle,
  ShieldCheck,
} from 'lucide-react';
import { jobStatusDetail, jobStatusLabel, paymentStatusLabel, type JobEvidencePhoto } from '@myworksapp/shared';
import { BrandLogo } from './BrandLogo';
import { profileLabel } from '../profileLabel';
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
  startPin?: string | null;
  paymentStatus?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  workerLatitude?: number | null;
  workerLongitude?: number | null;
  etaMinutes?: number | null;
  distanceKm?: number | null;
  gpsError?: string | null;
  profileName?: string;
  paymentNotice?: string | null;
  unreadCount?: number;
  onBack: () => void;
  onGoHome: () => void;
  onOpenChat: () => void;
  onOpenNotifications?: () => void;
  onLogout?: () => void;
  onConfirmReceipt?: () => void;
  confirmBusy?: boolean;
  confirmError?: string | null;
  onOpenDispute?: (reason: string, detail: string) => Promise<void>;
  onAddDisputeComment?: (comment: string) => Promise<void>;
  onProposeAgreement?: (tipo: 'aceptar' | 'rehacer' | 'anular') => Promise<void>;
  onRespondAgreement?: (acepta: boolean) => Promise<void>;
  pendingAgreement?: { id: string; tipo: string } | null;
  /** Sin disputa abierta no se ofrecen acuerdos ni comentarios. */
  disputeOpen?: boolean;
  evidencePhotos?: JobEvidencePhoto[];
  evidence?: ReactNode;
  /** Cancelar, reagendar y calificar (JobClientActions). */
  clientActions?: ReactNode;
}

const CLOSED_STATUSES = ['completado', 'cancelado', 'expirado', 'no_asistio'];
/** Mismos estados que acepta abrir_disputa en la base. */
const DISPUTE_STATUSES = [
  'aceptado',
  'en_camino',
  'en_curso',
  'esperando_aprobacion_cliente',
  'pausado_orden_cambio',
];

function escrowCopy(jobStatus: string | null | undefined, paymentStatus: string | null | undefined): string {
  const payment = paymentStatusLabel(paymentStatus);
  switch (jobStatus) {
    case 'cancelado':
    case 'expirado':
    case 'no_asistio':
      return `${payment}. El trabajo se cerró sin entregar el cobro al profesional.`;
    case 'completado':
      return `${payment}. Diste tu conformidad y el pago se entregó al profesional.`;
    case 'esperando_pago':
      return 'Todavía no hay un cobro retenido: el pedido espera el pago.';
      default:
      return `${payment}. Se libera cuando das tu conformidad. Si abriste la disputa, puedes cancelar y recuperar todos los cobros. Si la abrió el profesional, el cierre lo acuerdan ustedes o lo ve atención al cliente.`;
  }
}

function agreementLabel(tipo: string): string {
  if (tipo === 'aceptar') return 'aceptar la entrega';
  if (tipo === 'rehacer') return 'rehacer el trabajo';
  if (tipo === 'anular') return 'anular y devolver el pago';
  return tipo;
}

function jobsLabel(count: number): string {
  return `${count} ${count === 1 ? 'trabajo' : 'trabajos'}`;
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
  startPin,
  paymentStatus,
  latitude,
  longitude,
  workerLatitude,
  workerLongitude,
  etaMinutes,
  distanceKm,
  gpsError,
  profileName,
  paymentNotice,
  unreadCount = 0,
  onBack,
  onGoHome,
  onOpenChat,
  onOpenNotifications,
  onLogout,
  onConfirmReceipt,
  confirmBusy = false,
  confirmError = null,
  onOpenDispute,
  onAddDisputeComment,
  onProposeAgreement,
  onRespondAgreement,
  pendingAgreement = null,
  disputeOpen = false,
  evidencePhotos = [],
  evidence,
  clientActions,
}: TrackingDashboardProps) {
  const [showPayment, setShowPayment] = useState(false);
  const [previewSrc, setPreviewSrc] = useState<string | null>(null);
  // La evidencia ampliada se cierra también con Escape, como cualquier diálogo.
  useEffect(() => {
    if (!previewSrc) return undefined;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setPreviewSrc(null);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [previewSrc]);
  const [disputeReason, setDisputeReason] = useState('calidad');
  const [disputeDetail, setDisputeDetail] = useState('');
  const [disputeComment, setDisputeComment] = useState('');
  const [disputeBusy, setDisputeBusy] = useState(false);
  const [disputeNote, setDisputeNote] = useState<string | null>(null);
  const hasPoint = typeof latitude === 'number' && typeof longitude === 'number'
    && Number.isFinite(latitude) && Number.isFinite(longitude);
  const hasWorker = typeof workerLatitude === 'number' && typeof workerLongitude === 'number'
    && Number.isFinite(workerLatitude) && Number.isFinite(workerLongitude);
  const statusLabel = jobStatusLabel(jobStatus);
  const statusDetail = jobStatusDetail(jobStatus);
  const closedJob = CLOSED_STATUSES.includes(jobStatus ?? '');
  const disputeAllowed = DISPUTE_STATUSES.includes(jobStatus ?? '');
  const arrivalHint = gpsError
    ?? (etaMinutes != null
      ? `A ${distanceKm?.toFixed(1) ?? '—'} km. Estimación a 28 km/h, sin tráfico en vivo.`
      : hasWorker
        ? 'El profesional publicó su ubicación. El pedido no tiene coordenadas para estimar la llegada.'
        : closedJob
          ? null
          : 'La llegada aparece cuando el profesional publica su ubicación en camino o en curso.');

  const leaveTracking = closedJob ? onGoHome : onBack;

  return (
    <div className="tracking-dashboard">
      <header className="tracking-nav">
        <BrandLogo size={32} onClick={onGoHome} />
        <span className="tracking-premium-badge">CLIENTE</span>

        <div className="tracking-nav-center">
          <span className="tracking-secure-item tracking-secure-live">
            <span className="tracking-live-dot" /> Sesión del sitio
          </span>
        </div>

        <div className="tracking-nav-right">
          <button
            type="button"
            className="tracking-nav-home"
            onClick={onGoHome}
          >
            <Home size={16} />
            Inicio
          </button>
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
            <div className="search-nav-avatar">{profileName?.trim().charAt(0).toUpperCase() || 'C'}</div>
            <div>
              <strong>{profileName ? profileLabel(profileName) : 'Invitado'}</strong>
              <span>Cuenta de cliente</span>
            </div>
          </div>
          {profileName && onLogout ? (
            <button type="button" className="btn-ghost" onClick={() => onLogout()}>
              Salir
            </button>
          ) : null}
        </div>
      </header>

      <div className="tracking-layout">
        <aside className="tracking-sidebar">
          <button type="button" className="tracking-back-link" onClick={leaveTracking}>
            <ArrowLeft size={16} /> {closedJob ? 'Volver al inicio' : 'Volver'}
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
              <strong className="tracking-eta-value">
                {etaMinutes != null ? `${etaMinutes} min` : hasWorker ? 'En vivo' : closedJob ? '—' : 'Sin GPS'}
              </strong>
            </div>
            {arrivalHint ? <p className="tracking-eta-arrival">{arrivalHint}</p> : null}
          </div>

          <div className="tracking-worker-block">
            <p className="tracking-block-label">TRABAJADOR</p>
            <div className="tracking-worker-row">
              <img src={workerPhoto} alt={`Foto de ${workerName}`} className="tracking-worker-photo" />
              <div>
                <strong>{workerName}</strong>
                <div className="tracking-worker-rating">
                  <span aria-hidden>★</span> {workerRating > 0 ? workerRating.toFixed(1) : 'Nuevo'} ({jobsLabel(workerJobs)})
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
            {startPin ? (
              <div className="tracking-start-pin">
                <span>PIN para iniciar</span>
                <strong>{startPin}</strong>
                <p>Díselo al profesional cuando llegue. Sin este PIN no puede dejar el trabajo en curso.</p>
              </div>
            ) : null}
          </div>

          {evidencePhotos.length > 0 ? (
            <div className="tracking-evidence-block">
              <p className="tracking-block-label">EVIDENCIA</p>
              <div className="tracking-evidence-grid">
                {evidencePhotos.map((photo) => (
                  photo.src ? (
                    <button
                      type="button"
                      key={photo.id}
                      className="tracking-evidence-thumb"
                      onClick={() => setPreviewSrc(photo.src ?? null)}
                    >
                      <img src={photo.src} alt="Evidencia del trabajo" />
                    </button>
                  ) : (
                    <div key={photo.id} className="tracking-evidence-video">Video</div>
                  )
                ))}
              </div>
            </div>
          ) : jobStatus === 'esperando_aprobacion_cliente' ? (
            <p className="tracking-status-detail">Aún no hay fotos del especialista.</p>
          ) : null}

          {jobStatus === 'esperando_aprobacion_cliente' && onConfirmReceipt ? (
            <button
              type="button"
              className="btn-primary tracking-chat-btn"
              onClick={onConfirmReceipt}
              disabled={confirmBusy}
            >
              {confirmBusy ? 'Liberando el pago…' : 'Recibo conforme'}
            </button>
          ) : null}
          {confirmError ? (
            <p className="tracking-status-detail" role="alert">{confirmError}</p>
          ) : null}

          {closedJob ? (
            <div className="tracking-complete-card">
              <strong>{jobStatus === 'completado' ? 'Pago liberado' : 'Trabajo cerrado sin cobro al profesional'}</strong>
              <p>
                {paymentNotice
                  ?? (jobStatus === 'completado'
                    ? 'El trabajo quedó cerrado y el retenido se liberó al profesional.'
                    : 'El trabajo se anuló y el cobro retenido no se entregó al profesional.')}
              </p>
              <button type="button" className="btn-primary" onClick={onGoHome}>
                Volver al inicio
              </button>
            </div>
          ) : null}


          {clientActions}
          {evidence}
          <button type="button" className="btn-primary tracking-chat-btn" onClick={onOpenChat}>
            <MessageCircle size={18} /> Abrir chat
          </button>

          {disputeOpen && onProposeAgreement ? (
            <div className="tracking-escrow-card">
              <strong>Resolver entre ustedes</strong>
              <p>Si los dos están de acuerdo, el sistema cierra el caso sin una persona de soporte.</p>
              {pendingAgreement ? (
                <p>Hay un acuerdo pendiente: {agreementLabel(pendingAgreement.tipo)}.</p>
              ) : null}
              <div>
                <button type="button" className="btn-primary" onClick={() => void onProposeAgreement('aceptar').then(() => setDisputeNote('Acuerdo enviado. Falta que la otra parte lo confirme.')).catch((error: unknown) => setDisputeNote(error instanceof Error ? error.message : 'No se pudo proponer el acuerdo.'))}>Aceptar la entrega</button>
                <button type="button" className="btn-ghost" onClick={() => void onProposeAgreement('rehacer').then(() => setDisputeNote('Acuerdo enviado. Falta que la otra parte lo confirme.')).catch((error: unknown) => setDisputeNote(error instanceof Error ? error.message : 'No se pudo proponer el acuerdo.'))}>Pedir que lo rehaga</button>
                <button type="button" className="btn-ghost" onClick={() => void onProposeAgreement('anular').then(() => setDisputeNote('Acuerdo enviado. Falta que la otra parte lo confirme.')).catch((error: unknown) => setDisputeNote(error instanceof Error ? error.message : 'No se pudo proponer el acuerdo.'))}>Anular y devolver el pago</button>
                {pendingAgreement && onRespondAgreement ? (
                  <>
                    <button type="button" className="btn-primary" onClick={() => void onRespondAgreement(true)}>Confirmar acuerdo</button>
                    <button type="button" className="btn-ghost" onClick={() => void onRespondAgreement(false)}>Rechazar acuerdo</button>
                  </>
                ) : null}
              </div>
            </div>
          ) : null}

          {disputeAllowed && !disputeOpen && onOpenDispute ? (
            <form
              className="tracking-escrow-card"
              onSubmit={(event) => {
                event.preventDefault();
                setDisputeBusy(true);
                setDisputeNote(null);
                void onOpenDispute(disputeReason, disputeDetail)
                  .then(() => setDisputeNote('Disputa abierta. El pago sigue retenido.'))
                  .catch((error: unknown) => {
                    setDisputeNote(error instanceof Error ? error.message : 'No se pudo abrir la disputa.');
                  })
                  .finally(() => setDisputeBusy(false));
              }}
            >
              <div>
                <strong>Abrir disputa</strong>
                <p>El pago sigue retenido. Si el caso es simple, se cierra solo al vencer el plazo. Conducta, reincidencia o un monto alto los ve una persona.</p>
                <label>
                  Motivo
                  <select value={disputeReason} onChange={(event) => setDisputeReason(event.target.value)}>
                    <option value="calidad">Calidad del trabajo</option>
                    <option value="pago">Pago</option>
                    <option value="conducta">Conducta</option>
                    <option value="otro">Otro</option>
                  </select>
                </label>
                <textarea
                  value={disputeDetail}
                  onChange={(event) => setDisputeDetail(event.target.value)}
                  placeholder="Qué pasó"
                  rows={3}
                />
                <button type="submit" className="btn-primary" disabled={disputeBusy}>
                  {disputeBusy ? 'Enviando…' : 'Enviar disputa'}
                </button>
              </div>
            </form>
          ) : null}
          {disputeOpen && onAddDisputeComment ? (
            <form
              className="tracking-escrow-card"
              onSubmit={(event) => {
                event.preventDefault();
                setDisputeBusy(true);
                setDisputeNote(null);
                void onAddDisputeComment(disputeComment)
                  .then(() => {
                    setDisputeComment('');
                    setDisputeNote('Comentario agregado a la disputa.');
                  })
                  .catch((error: unknown) => {
                    setDisputeNote(error instanceof Error ? error.message : 'No se pudo agregar el comentario.');
                  })
                  .finally(() => setDisputeBusy(false));
              }}
            >
              <div>
                <strong>Comentario en la disputa</strong>
                <textarea
                  value={disputeComment}
                  onChange={(event) => setDisputeComment(event.target.value)}
                  placeholder="Agrega un detalle"
                  rows={2}
                />
                <button type="submit" className="btn-primary" disabled={disputeBusy || !disputeComment.trim()}>
                  Agregar comentario
                </button>
              </div>
            </form>
          ) : null}
          {disputeNote ? <p className="tracking-status-detail" role="status">{disputeNote}</p> : null}

          <div className="tracking-escrow-card">
            <ShieldCheck size={22} className="tracking-escrow-icon" />
            <div>
              <strong>{closedJob ? 'Pago' : 'Pago protegido'}</strong>
              <p>{escrowCopy(jobStatus, paymentStatus)}</p>
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
              worker={hasWorker ? {
                latitude: workerLatitude,
                longitude: workerLongitude,
                label: workerName,
              } : null}
            />
          ) : hasWorker ? (
            <JobLocationMap
              latitude={workerLatitude as number}
              longitude={workerLongitude as number}
              label={workerName}
              worker={null}
            />
          ) : (
            <div className="tracking-map-empty">
              <p>Este pedido no tiene coordenadas.</p>
              <p>La dirección queda en el panel de la izquierda.</p>
            </div>
          )}
        </div>
      </div>
      {previewSrc ? (
        <button
          type="button"
          className="tracking-evidence-lightbox"
          onClick={() => setPreviewSrc(null)}
          aria-label="Cerrar evidencia"
        >
          <img src={previewSrc} alt="Evidencia ampliada" />
        </button>
      ) : null}
    </div>
  );
}
