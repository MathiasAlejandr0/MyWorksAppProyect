import { useState, useEffect } from 'react';
import { MapPin, Navigation, Clock, Phone } from 'lucide-react';

interface LiveGpsTrackingMapProps {
  workerName: string;
  workerProfession?: string;
  etaMinutes: number;
}

export function LiveGpsTrackingMap({ workerName, etaMinutes: initialEta }: LiveGpsTrackingMapProps) {
  const [eta, setEta] = useState(initialEta);
  const [distanceKm, setDistanceKm] = useState(1.4);
  const [progress, setProgress] = useState(35);

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => (prev >= 95 ? 95 : prev + 5));
      setDistanceKm((prev) => Math.max(0.2, Number((prev - 0.1).toFixed(1))));
      setEta((prev) => Math.max(1, prev - 1));
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div
      style={{
        backgroundColor: '#101826',
        border: '1px solid rgba(244,242,238,0.12)',
        borderRadius: '16px',
        padding: '20px',
        color: 'white',
      }}
    >
      <div
        style={{
          marginBottom: '12px',
          padding: '8px 10px',
          borderRadius: '10px',
          backgroundColor: 'rgba(232,155,45,0.15)',
          border: '1px solid #E89B2D',
          fontSize: '12px',
          fontWeight: 700,
          color: '#E8C56A',
        }}
      >
        SIMULACIÓN / DEMO — El mapa y el ETA son ilustrativos; no hay GPS real.
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', gap: '12px', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{ backgroundColor: 'rgba(240,120,42,0.2)', padding: '8px', borderRadius: '50%', color: '#F0782A', display: 'flex' }}>
            <Navigation size={20} />
          </div>
          <div>
            <h3 style={{ fontSize: '16px', fontWeight: 800, color: 'white' }}>Vista previa de seguimiento</h3>
            <span style={{ fontSize: '12px', color: '#9AA1AD', fontWeight: 600 }}>{workerName} · llegada estimada (demo)</span>
          </div>
        </div>
        <span style={{ padding: '6px 12px', fontSize: '11px', fontWeight: 800, borderRadius: '999px', background: 'rgba(240,120,42,0.18)', color: '#F0782A' }}>
          DEMO
        </span>
      </div>

      <div style={{ position: 'relative', height: '160px', backgroundColor: '#0A1628', borderRadius: '12px', overflow: 'hidden', border: '1px solid rgba(244,242,238,0.08)', marginBottom: '16px' }}>
        <svg width="100%" height="100%" style={{ opacity: 0.25 }}>
          <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
            <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#94A3B8" strokeWidth="1" />
          </pattern>
          <rect width="100%" height="100%" fill="url(#grid)" />
          <path d="M 40 140 Q 180 40 320 110 T 480 80" fill="none" stroke="#F0782A" strokeWidth="4" strokeDasharray="8 4" />
        </svg>

        <div style={{ position: 'absolute', right: '40px', top: '70px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ backgroundColor: '#E23D35', color: 'white', padding: '4px 8px', borderRadius: '12px', fontSize: '10px', fontWeight: 800, marginBottom: '4px' }}>
            Tu domicilio
          </div>
          <MapPin size={24} color="#E23D35" fill="#E23D35" />
        </div>

        <div style={{ position: 'absolute', left: `${Math.min(progress, 72)}%`, top: '80px', transition: 'left 1s ease-in-out', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ backgroundColor: '#F0782A', color: 'white', padding: '4px 8px', borderRadius: '12px', fontSize: '10.5px', fontWeight: 800, marginBottom: '4px', whiteSpace: 'nowrap' }}>
            {workerName} ({distanceKm} km)
          </div>
          <div style={{ width: '18px', height: '18px', backgroundColor: '#F0782A', borderRadius: '50%', border: '3px solid white' }} />
        </div>
      </div>

      <div className="tracking-stats" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px' }}>
        <div style={{ backgroundColor: '#0A1628', padding: '12px', borderRadius: '12px', textAlign: 'center' }}>
          <Clock size={16} color="#F0782A" style={{ margin: '0 auto 4px' }} />
          <div style={{ fontSize: '16px', fontWeight: 800, color: '#F0782A' }}>{eta} min</div>
          <span style={{ fontSize: '11px', color: '#9AA1AD' }}>ETA demo</span>
        </div>

        <div style={{ backgroundColor: '#0A1628', padding: '12px', borderRadius: '12px', textAlign: 'center' }}>
          <Navigation size={16} color="#F0782A" style={{ margin: '0 auto 4px' }} />
          <div style={{ fontSize: '16px', fontWeight: 800 }}>{distanceKm} km</div>
          <span style={{ fontSize: '11px', color: '#9AA1AD' }}>Distancia</span>
        </div>

        <div style={{ backgroundColor: '#0A1628', padding: '12px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <button
            type="button"
            disabled
            title="Contacto real no disponible en demo"
            style={{ backgroundColor: '#1A2740', color: '#9AA1AD', border: 'none', padding: '8px 12px', borderRadius: '10px', fontWeight: 700, fontSize: '12px', cursor: 'not-allowed', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <Phone size={14} /> Llamar
          </button>
        </div>
      </div>
    </div>
  );
}
