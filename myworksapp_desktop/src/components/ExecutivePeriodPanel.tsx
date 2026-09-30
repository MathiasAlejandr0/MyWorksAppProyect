import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  DollarSign,
  ClipboardList,
  Smile,
  TrendingUp,
} from 'lucide-react';
import {
  fetchBusinessPeriod,
  paymentStatusLabel,
  periodRange,
  PLATFORM_COMMISSION_RATE,
  type BusinessPeriodSummary,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { KpiCardsSkeleton } from './LoadingState';

type Preset = '24h' | '7d' | '30d' | '90d';

const PRESETS: { id: Preset; label: string }[] = [
  { id: '24h', label: '24 horas' },
  { id: '7d', label: '7 días' },
  { id: '30d', label: '30 días' },
  { id: '90d', label: '90 días' },
];

function clp(value: number): string {
  return `$${Math.round(value).toLocaleString('es-CL')}`;
}

function GmvChart({ points }: { points: BusinessPeriodSummary['dailyGmv'] }) {
  if (!points.length) {
    return <p className="cell-empty">Sin cobros en este período.</p>;
  }
  const max = Math.max(...points.map((point) => point.amount), 1);
  const step = points.length === 1 ? 0 : 600 / (points.length - 1);
  const coords = points
    .map((point, index) => `${index * step},${170 - (point.amount / max) * 140}`)
    .join(' ');
  return (
    <div className="area-chart-wrap">
      <svg className="area-chart-svg" viewBox="0 0 600 180" role="img" aria-label="GMV por día">
        <polyline points={coords} fill="none" stroke="#F0782A" strokeWidth="2.5" />
      </svg>
      <div className="area-chart-x">
        {points.map((point) => (
          <span key={point.day}>{point.day.slice(5)}</span>
        ))}
      </div>
    </div>
  );
}

export function ExecutivePeriodPanel({ activeJobs }: { activeJobs: number }) {
  const [preset, setPreset] = useState<Preset>('7d');
  const range = periodRange(preset);
  const query = useQuery({
    queryKey: ['business-period', preset],
    queryFn: () => fetchBusinessPeriod(supabase, range.fromIso, range.toIso),
  });
  const summary = query.data;

  const kpis = [
    {
      label: 'GMV',
      value: summary ? clp(summary.gmv) : '—',
      trend: summary && summary.gmv === 0 ? 'Sin cobros en el período' : 'Retenido, liberado y autorizado',
      icon: DollarSign,
    },
    {
      label: 'Comisión',
      value: summary ? clp(summary.commission) : '—',
      trend: `${Math.round(PLATFORM_COMMISSION_RATE * 100)}% del GMV`,
      icon: TrendingUp,
    },
    {
      label: 'Trabajos completados',
      value: summary ? String(summary.completedJobs) : '—',
      trend: summary && summary.completedJobs === 0 ? 'Ninguno en el período' : 'Estado completado',
      icon: ClipboardList,
    },
    {
      label: 'Ticket promedio',
      value: summary?.avgTicket == null ? 'Sin ticket' : clp(summary.avgTicket),
      trend: summary?.paidOrders ? `${summary.paidOrders} cobros` : 'Sin cobros en el período',
      icon: DollarSign,
    },
    {
      label: 'CSAT',
      value: summary?.csat == null ? 'Sin calificaciones' : `${summary.csat.toFixed(1)} / 5`,
      trend: summary?.ratingCount ? `${summary.ratingCount} reseñas` : 'Sin reseñas en el período',
      icon: Smile,
    },
    {
      label: 'Trabajos activos',
      value: activeJobs.toLocaleString('es-CL'),
      trend: 'Conteo en vivo, fuera del período',
      icon: ClipboardList,
    },
  ];

  return (
    <>
      <div className="executive-subnav" style={{ marginBottom: 12 }}>
        {PRESETS.map((item) => (
          <button
            key={item.id}
            type="button"
            className={`executive-subnav-item${preset === item.id ? ' active' : ''}`}
            onClick={() => setPreset(item.id)}
          >
            {item.label}
          </button>
        ))}
      </div>
      {query.isPending ? (
        <KpiCardsSkeleton count={4} />
      ) : query.isError ? (
        <p role="alert">No se pudieron leer pagos, trabajos o calificaciones.</p>
      ) : (
        <div className="executive-kpi-grid executive-kpi-grid--4">
          {kpis.map((kpi) => {
            const Icon = kpi.icon;
            return (
              <div key={kpi.label} className="exec-kpi-card exec-kpi-card--orange">
                <div className="exec-kpi-top">
                  <div className="exec-kpi-icon-wrap">
                    <Icon size={18} />
                  </div>
                  <span className="exec-kpi-label">{kpi.label}</span>
                </div>
                <div className="exec-kpi-value">{kpi.value}</div>
                <div className="exec-kpi-bottom">
                  <span className="exec-kpi-trend">{kpi.trend}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}
      <div className="exec-chart-full card-surface">
        <div className="chart-card-head">
          <h3 className="chart-card-title">GMV del período</h3>
        </div>
        <GmvChart points={summary?.dailyGmv ?? []} />
      </div>
      <div className="card-surface exec-panel">
        <h3 className="exec-panel-title">Cobros por estado</h3>
        {!summary?.byPaymentStatus.length ? (
          <p className="cell-empty">Sin movimientos de pago en el período.</p>
        ) : (
          <ul className="donut-legend">
            {summary.byPaymentStatus.map((row) => (
              <li key={row.status}>
                <span className="donut-dot donut-dot--orange" />
                {paymentStatusLabel(row.status)} <em>{clp(row.amount)} ({row.count})</em>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
