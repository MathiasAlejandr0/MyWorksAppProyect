import { ShieldCheck, Award, ThumbsUp, Scale, CheckCircle2 } from 'lucide-react';

interface PredictiveTrustMeterProps {
  score?: number; // 0 to 100
  fairPriceIndex?: string;
  reviewsCount?: number;
}

export function PredictiveTrustMeter({ score, fairPriceIndex = 'Óptimo (Basado en 420 cotizaciones)', reviewsCount = 198 }: PredictiveTrustMeterProps) {
  const hasScore = typeof score === 'number';
  const isDark = typeof document !== 'undefined' && document.body.classList.contains('dark');
  const surface = isDark ? 'var(--bg-surface-dark)' : 'var(--bg-surface-light)';
  const muted = isDark ? 'var(--text-muted-dark)' : 'var(--text-muted-light)';
  const border = isDark ? 'var(--border-dark)' : 'var(--border-light)';

  return (
    <div className="card-3d" style={{ padding: '20px', border: '1px solid rgba(52, 199, 89, 0.3)', background: 'linear-gradient(135deg, rgba(52, 199, 89, 0.05) 0%, rgba(240, 120, 42, 0.05) 100%)', marginBottom: '20px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Award size={20} color="#34C759" />
          <span style={{ fontSize: '14px', fontWeight: 800 }}>Índice de Fiabilidad y Transparencia Garantizada</span>
        </div>
        {hasScore ? (
          <span className="badge-tag badge-emerald">
            <CheckCircle2 size={12} /> {score}% Fiabilidad
          </span>
        ) : (
          <span className="badge-tag badge-orange">DEMO</span>
        )}
      </div>

      {!hasScore && (
        <p style={{ fontSize: '13px', color: muted, marginBottom: '12px', fontWeight: 600 }}>
          Sin datos medidos
        </p>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
        <div style={{ padding: '12px', borderRadius: 'var(--radius-md)', backgroundColor: surface, border: `1px solid ${border}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', color: muted, fontWeight: 700, textTransform: 'uppercase' }}>
            <Scale size={14} color="#F0782A" /> Fair Price Index
          </div>
          <div style={{ fontSize: '13.5px', fontWeight: 800, marginTop: '4px', color: '#F0782A' }}>{fairPriceIndex}</div>
        </div>

        <div style={{ padding: '12px', borderRadius: 'var(--radius-md)', backgroundColor: surface, border: `1px solid ${border}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', color: muted, fontWeight: 700, textTransform: 'uppercase' }}>
            <ThumbsUp size={14} color="#34C759" /> Respaldo de Comunidad
          </div>
          <div style={{ fontSize: '13.5px', fontWeight: 800, marginTop: '4px', color: '#34C759' }}>{reviewsCount} trabajos sin disputas</div>
        </div>

        <div style={{ padding: '12px', borderRadius: 'var(--radius-md)', backgroundColor: surface, border: `1px solid ${border}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', color: muted, fontWeight: 700, textTransform: 'uppercase' }}>
            <ShieldCheck size={14} color="#007AFF" /> Cobertura Escrow
          </div>
          <div style={{ fontSize: '13.5px', fontWeight: 800, marginTop: '4px', color: '#007AFF' }}>100% Protegido por PIN</div>
        </div>
      </div>
    </div>
  );
}
