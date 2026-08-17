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
  const [progress, setProgress] = useState(35); // 0 to 100%

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress(prev => {
        if (prev >= 95) return 95;
        return prev + 5;
      });
      setDistanceKm(prev => Math.max(0.2, Number((prev - 0.1).toFixed(1))));
      setEta(prev => Math.max(1, prev - 1));
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div style={{ backgroundColor: '#1E293B', border: '1px solid #334155', borderRadius: '20px', padding: '24px', color: 'white', boxShadow: '0 20px 40px rgba(0,0,0,0.5)' }}>
      {/* Header de Seguimiento GPS */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{ backgroundColor: 'rgba(240,120,42,0.2)', padding: '8px', borderRadius: '50%', color: '#F0782A', display: 'flex' }}>
            <Navigation size={22} className="pulse" />
          </div>
          <div>
            <h3 style={{ fontSize: '17px', fontWeight: 900, color: 'white' }}>Seguimiento GPS en Tiempo Real</h3>
            <span style={{ fontSize: '12px', color: '#34C759', fontWeight: 700 }}>● {workerName} va en camino a tu domicilio</span>
          </div>
        </div>
        <span className="badge badge-success" style={{ padding: '6px 12px', fontSize: '12px' }}>
          GPS 100% ACTIVO
        </span>
      </div>

      {/* Mapa Visual Simulado SVG de Alta Fidelidad */}
      <div style={{ position: 'relative', height: '180px', backgroundColor: '#0F172A', borderRadius: '14px', overflow: 'hidden', border: '1px solid #334155', marginBottom: '18px' }}>
        {/* Renderizado de Calles / Map Grid SVG */}
        <svg width="100%" height="100%" style={{ opacity: 0.25 }}>
          <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
            <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#94A3B8" strokeWidth="1" />
          </pattern>
          <rect width="100%" height="100%" fill="url(#grid)" />
          {/* Ruta Trazada */}
          <path d="M 40 140 Q 180 40 320 110 T 480 80" fill="none" stroke="#F0782A" strokeWidth="4" strokeDasharray="8 4" />
        </svg>

        {/* Pin del Domicilio del Cliente */}
        <div style={{ position: 'absolute', right: '40px', top: '70px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ backgroundColor: '#EF4444', color: 'white', padding: '4px 8px', borderRadius: '12px', fontSize: '10px', fontWeight: 800, marginBottom: '4px' }}>
            Tu Domicilio
          </div>
          <MapPin size={26} color="#EF4444" fill="#EF4444" />
        </div>

        {/* Pin Animado del Trabajador en Movimiento */}
        <div style={{ position: 'absolute', left: `${progress}%`, top: '80px', transition: 'left 1s ease-in-out', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ backgroundColor: '#F0782A', color: 'white', padding: '4px 8px', borderRadius: '12px', fontSize: '10.5px', fontWeight: 800, marginBottom: '4px', whiteSpace: 'nowrap', boxShadow: '0 4px 12px rgba(240,120,42,0.5)' }}>
            🚗 {workerName} ({distanceKm} km)
          </div>
          <div style={{ width: '20px', height: '20px', backgroundColor: '#F0782A', borderRadius: '50%', border: '3px solid white', boxShadow: '0 0 15px #F0782A' }} />
        </div>
      </div>

      {/* Grid de Información de ETA & Contacto Directo */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
        <div style={{ backgroundColor: '#0F172A', padding: '12px', borderRadius: '12px', border: '1px solid #334155', textAlign: 'center' }}>
          <Clock size={18} color="#F0782A" style={{ margin: '0 auto 4px' }} />
          <div style={{ fontSize: '18px', fontWeight: 900, color: '#F0782A' }}>{eta} min</div>
          <span style={{ fontSize: '11px', color: '#94A3B8' }}>Tiempo Estimado (ETA)</span>
        </div>

        <div style={{ backgroundColor: '#0F172A', padding: '12px', borderRadius: '12px', border: '1px solid #334155', textAlign: 'center' }}>
          <Navigation size={18} color="#007AFF" style={{ margin: '0 auto 4px' }} />
          <div style={{ fontSize: '18px', fontWeight: 900, color: '#007AFF' }}>{distanceKm} km</div>
          <span style={{ fontSize: '11px', color: '#94A3B8' }}>Distancia Restante</span>
        </div>

        <div style={{ backgroundColor: '#0F172A', padding: '12px', borderRadius: '12px', border: '1px solid #334155', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <button style={{ backgroundColor: '#34C759', color: 'white', border: 'none', padding: '8px 12px', borderRadius: '10px', fontWeight: 800, fontSize: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Phone size={14} /> Llamar
          </button>
        </div>
      </div>
    </div>
  );
}
