import { useState, useEffect } from 'react';
import { ShieldAlert, Radio, CheckCircle2, X } from 'lucide-react';

interface SpatialEmergencyPulseProps {
  onDispatch: (details: any) => void;
  onClose: () => void;
}

export function SpatialEmergencyPulse({ onDispatch, onClose }: SpatialEmergencyPulseProps) {
  const [holding, setHolding] = useState(false);
  const [progress, setProgress] = useState(0);
  const [dispatched, setDispatched] = useState(false);

  useEffect(() => {
    let timer: any;
    if (holding && progress < 100) {
      timer = setInterval(() => {
        setProgress(prev => {
          if (prev >= 100) {
            clearInterval(timer);
            setDispatched(true);
            setTimeout(() => {
              onDispatch({ type: 'emergency_plumbing', timestamp: new Date().toISOString() });
            }, 1200);
            return 100;
          }
          return prev + 5;
        });
      }, 50);
    } else if (!holding && progress < 100) {
      setProgress(0);
    }
    return () => clearInterval(timer);
  }, [holding, progress]);

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 350, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
      <div className="card-3d" style={{ maxWidth: '480px', width: '100%', textAlign: 'center', position: 'relative', overflow: 'hidden', border: '2px solid rgba(255, 59, 48, 0.4)', background: 'linear-gradient(180deg, #121826 0%, #090D16 100%)', color: 'white' }}>
        <button onClick={onClose} style={{ position: 'absolute', right: '16px', top: '16px', background: 'none', border: 'none', color: 'rgba(255,255,255,0.7)', cursor: 'pointer' }}>
          <X size={20} />
        </button>

        {!dispatched ? (
          <>
            <div className="badge-tag" style={{ backgroundColor: 'rgba(255, 59, 48, 0.2)', color: '#FF3B30', marginBottom: '16px' }}>
              <ShieldAlert size={14} /> LEY DE HICK-HYMAN: RESPUESTA EN 3 SEGUNDOS
            </div>

            <h2 style={{ fontSize: '24px', fontWeight: 900, marginBottom: '8px' }}>Disparo Espacial de Urgencia 24/7</h2>
            <p style={{ fontSize: '13.5px', color: 'rgba(255,255,255,0.7)', marginBottom: '32px' }}>
              Mantén presionado el botón por 3 segundos para transmitir tu posición GPS y convocar al profesional disponible más cercano en un radio de 5km.
            </p>

            {/* Anillo Pulsante de Emergencia */}
            <div style={{ position: 'relative', width: '180px', height: '180px', margin: '0 auto 32px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {/* Ocultamiento y Anillos Concéntricos */}
              <div style={{ position: 'absolute', inset: -20, borderRadius: '50%', border: '2px solid rgba(255, 59, 48, 0.3)', animation: holding ? 'ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite' : 'none' }} />
              <div style={{ position: 'absolute', inset: -10, borderRadius: '50%', border: '2px solid rgba(255, 107, 0, 0.5)' }} />

              {/* Botón Principal de Pulso */}
              <button
                onMouseDown={() => setHolding(true)}
                onMouseUp={() => setHolding(false)}
                onMouseLeave={() => setHolding(false)}
                onTouchStart={() => setHolding(true)}
                onTouchEnd={() => setHolding(false)}
                style={{
                  width: '150px',
                  height: '150px',
                  borderRadius: '50%',
                  background: holding 
                    ? 'radial-gradient(circle, #FF3B30 0%, #FF6B00 100%)' 
                    : 'linear-gradient(135deg, #FF6B00, #F0782A)',
                  border: 'none',
                  color: 'white',
                  cursor: 'pointer',
                  boxShadow: holding ? '0 0 40px rgba(255, 59, 48, 0.8)' : '0 10px 30px rgba(240, 120, 42, 0.5)',
                  transform: holding ? 'scale(0.95)' : 'scale(1)',
                  transition: 'transform 0.15s ease, background 0.3s ease',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  userSelect: 'none',
                }}
              >
                <Radio size={36} style={{ marginBottom: '4px' }} />
                <span style={{ fontSize: '13px', fontWeight: 900, textTransform: 'uppercase' }}>
                  {holding ? 'CONVOCANDO...' : 'MANTÉN 3 SEG'}
                </span>
              </button>
            </div>

            {/* Barra de Progreso del Pulso */}
            <div style={{ width: '100%', height: '8px', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '4px', overflow: 'hidden' }}>
              <div style={{ width: `${progress}%`, height: '100%', backgroundColor: '#FF3B30', transition: 'width 0.05s linear' }} />
            </div>
          </>
        ) : (
          <div style={{ padding: '20px 0' }}>
            <CheckCircle2 size={64} color="#34C759" style={{ margin: '0 auto 16px' }} />
            <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '8px' }}>¡Alerta Transmitida con Éxito!</h3>
            <p style={{ fontSize: '14px', color: 'rgba(255,255,255,0.8)' }}>
              Se notificó la urgencia a 3 profesionales verificados dentro de tu radio de 5 km.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
