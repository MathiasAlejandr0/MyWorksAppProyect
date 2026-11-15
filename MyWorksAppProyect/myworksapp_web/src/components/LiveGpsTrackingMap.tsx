import { MapPin, Navigation, Phone } from 'lucide-react';

interface LiveGpsTrackingMapProps {
  workerName: string;
  workerProfession?: string;
  etaMinutes: number;
}

export function LiveGpsTrackingMap({ workerName }: LiveGpsTrackingMapProps) {
  return (
    <div className="tracking-map">
      <p className="tracking-map-disclaimer">
        Vista ilustrativa — no hay seguimiento GPS en tiempo real en esta demo.
      </p>

      <div className="tracking-map-header">
        <div className="tracking-map-title-row">
          <div className="tracking-map-icon">
            <Navigation size={20} />
          </div>
          <div>
            <h3 className="tracking-map-title">Vista previa de seguimiento</h3>
            <span className="tracking-map-subtitle">{workerName} · referencia de llegada</span>
          </div>
        </div>
        <span className="tracking-map-pill">Demo</span>
      </div>

      <div className="tracking-map-canvas">
        <svg width="100%" height="100%" className="tracking-map-grid" aria-hidden>
          <pattern id="tracking-grid" width="40" height="40" patternUnits="userSpaceOnUse">
            <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#94A3B8" strokeWidth="1" />
          </pattern>
          <rect width="100%" height="100%" fill="url(#tracking-grid)" />
          <path d="M 40 140 Q 180 40 320 110 T 480 80" fill="none" stroke="#F0782A" strokeWidth="4" strokeDasharray="8 4" />
        </svg>

        <div className="tracking-map-destination">
          <div className="tracking-map-label tracking-map-label-destination">Tu domicilio</div>
          <MapPin size={24} color="#E23D35" fill="#E23D35" />
        </div>

        <div className="tracking-map-worker">
          <div className="tracking-map-label tracking-map-label-worker">
            {workerName}
          </div>
          <div className="tracking-map-dot" />
        </div>
      </div>

      <div className="tracking-stats">
        <div className="tracking-stat">
          <Navigation size={16} color="#F0782A" />
          <div className="tracking-stat-value">Sin GPS</div>
          <span className="tracking-stat-label">Ubicación en vivo</span>
        </div>

        <div className="tracking-stat tracking-stat-action">
          <button
            type="button"
            disabled
            title="Llamada no disponible en demo"
            className="tracking-call-btn"
          >
            <Phone size={14} /> Llamar
          </button>
        </div>
      </div>
    </div>
  );
}
