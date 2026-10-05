import { useMemo, useState, type ReactNode } from 'react';

import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  ClipboardList,
  MessageSquare,
  Smile,
  LayoutDashboard,
  UserCheck,
  FileText,
  Activity,
} from 'lucide-react';
import { useQuery } from '@tanstack/react-query';

import { AuditTrailViewer } from './AuditTrailViewer';
import { ExecutivePeriodPanel } from './ExecutivePeriodPanel';
import { FinancialSettlementModal } from './FinancialSettlementModal';
import { DigitalContractModal } from './DigitalContractModal';
import { KpiCardsSkeleton, TableRowsSkeleton } from './LoadingState';
import { fetchAdminMetrics, fetchBusinessPeriod, fetchWorkersForAdmin, periodRange, setWorkerVerification, verificationLabel } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { queryKeys } from '../queryClient';

interface WorkerApproval {
  id: string;
  name: string;
  profession: string;
  rut: string;
  visitFee: number;
  verification: string;
}



type ExecutiveWorkspaceProps = {

  headerActions?: ReactNode;

};



function Sparkline({ color, points }: { color: string; points: string }) {

  return (

    <svg className="kpi-sparkline" viewBox="0 0 80 24" aria-hidden>

      <polyline points={points} fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

    </svg>

  );

}





export function ExecutiveWorkspace({ headerActions }: ExecutiveWorkspaceProps) {

  const [subActiveTab, setSubActiveTab] = useState<number>(0);
  const [showSettlement, setShowSettlement] = useState(false);
  const [showContractModal, setShowContractModal] = useState(false);

  const metricsQuery = useQuery({
    queryKey: queryKeys.adminMetrics,
    queryFn: () => fetchAdminMetrics(supabase),
  });

  const workersQuery = useQuery({
    queryKey: queryKeys.adminWorkers,
    queryFn: () => fetchWorkersForAdmin(supabase),
  });

  const businessRange = periodRange('7d');
  const businessQuery = useQuery({
    queryKey: ['business-period', '7d'],
    queryFn: () => fetchBusinessPeriod(supabase, businessRange.fromIso, businessRange.toIso),
  });

  const loading = metricsQuery.isPending || workersQuery.isPending;

  const metrics = useMemo(() => {
    const adminMetrics = metricsQuery.data;
    if (!adminMetrics) {
      return { jobsCount: 0, activeJobsCount: 0, openDisputesCount: 0 };
    }
    return {
      jobsCount: adminMetrics.jobsCount,
      activeJobsCount: adminMetrics.activeJobsCount,
      openDisputesCount:
        adminMetrics.openDisputesCount + adminMetrics.underReviewDisputesCount,
    };
  }, [metricsQuery.data]);

  const workers: WorkerApproval[] = useMemo(() => {
    const rank = (status: string) =>
      status === 'en_revision' || status === 'pendiente' ? 0 : 1;
    return (workersQuery.data ?? [])
      .filter((worker) => {
        // fetchWorkersForAdmin no trae el correo, así que no sirve para detectar
        // cuentas demo. Se ocultan solo los rechazados: quedan los verificados y
        // la cola por aprobar (pendiente / en revisión), que es lo que el admin revisa.
        const demo = (worker.email ?? '').toLowerCase().endsWith('@demo.myworksapp.cl');
        if (demo) return true;
        return (worker.verificationStatus ?? 'pendiente') !== 'rechazado';
      })
      .map((worker) => ({
        id: worker.userId,
        name: worker.name,
        profession: worker.profession,
        rut: worker.email ?? '—',
        visitFee: worker.visitFee,
        verification: worker.verificationStatus ?? 'pendiente',
      }))
      .sort((a, b) => rank(a.verification) - rank(b.verification) || a.name.localeCompare(b.name, 'es'));
  }, [workersQuery.data]);

  const activeJobs = metrics.activeJobsCount;
  const disputes = metrics.openDisputesCount;
  const [verifyError, setVerifyError] = useState<string | null>(null);

  const reviewWorker = async (userId: string, status: 'verificado' | 'rechazado') => {
    try {
      await setWorkerVerification(supabase, userId, status);
      await workersQuery.refetch();
      setVerifyError(null);
    } catch {
      setVerifyError('No se pudo guardar. Aplica la migración de verificación en Supabase.');
    }
  };



  const gmv = businessQuery.data?.gmv;
  const gmvLabel = gmv == null ? '—' : `$${Math.round(gmv).toLocaleString('es-CL')}`;
  const gmvTrend = gmv == null
    ? (businessQuery.isError ? 'No se pudieron leer los pagos' : 'Leyendo pagos')
    : gmv === 0
      ? 'Sin cobros en el período'
      : 'Retenido, liberado y autorizado';

  const csat = businessQuery.data?.csat ?? null;

  const kpis = [

    {

      label: 'GMV',

      value: gmvLabel,

      trend: gmvTrend,

      up: true,

      icon: DollarSign,

      tone: 'orange',

      spark: '2,18 12,14 22,16 32,10 42,12 52,8 62,10 72,6 78,4',

    },

    {

      label: 'Trabajos activos',

      value: activeJobs.toLocaleString('es-CL'),

      trend: 'Conteo en vivo',

      up: true,

      icon: ClipboardList,

      tone: 'orange',

      spark: '2,16 14,12 26,14 38,8 50,10 62,6 74,8 78,4',

    },

    {

      label: 'Disputas',

      value: String(disputes),

      trend: 'Conteo en vivo',

      up: false,

      icon: MessageSquare,

      tone: 'purple',

      spark: '2,6 14,10 26,8 38,12 50,10 62,14 74,12 78,16',

    },

    {

      label: 'CSAT',

      value: csat == null ? '—' : `${csat.toFixed(1)} / 5`,

      trend: csat == null
        ? (businessQuery.isError ? 'No se pudieron leer las calificaciones' : 'Sin calificaciones en 7 días')
        : `${businessQuery.data?.ratingCount ?? 0} reseñas`,

      up: true,

      icon: Smile,

      tone: 'orange',

      spark: '2,14 14,12 26,10 38,12 50,8 62,10 74,6 78,4',

    },

  ];



  const opsSummary = [

    { label: 'Trabajos en la base', value: String(metrics.jobsCount), trend: 'Conteo en vivo', up: true },

    { label: 'Trabajos activos', value: String(activeJobs), trend: 'Conteo en vivo', up: true },

    { label: 'Disputas abiertas', value: String(disputes), trend: 'Conteo en vivo', up: false },

    { label: 'Tiempo promedio', value: '—', trend: 'Sin medición', up: true },

  ];



  return (

    <div className="executive-workspace">

      <div className="executive-header">

        <div>

          <h1 className="executive-title">Panel ejecutivo</h1>

          <p className="executive-subtitle">

            Vista en tiempo real del rendimiento operativo y del negocio.

          </p>

          <p className="executive-subtitle">GMV, comisión, ticket y CSAT salen de pagos, trabajos completados y calificaciones.</p>

        </div>

        <div className="executive-actions">{headerActions}</div>

      </div>



      <div className="executive-subnav">

        <button

          type="button"

          className={`executive-subnav-item${subActiveTab === 0 ? ' active' : ''}`}

          onClick={() => setSubActiveTab(0)}

        >

          <LayoutDashboard size={15} /> Resumen

        </button>

        <button

          type="button"

          className={`executive-subnav-item${subActiveTab === 1 ? ' active' : ''}`}

          onClick={() => setSubActiveTab(1)}

        >

          <UserCheck size={15} /> Trabajadores

        </button>

        <button

          type="button"

          className={`executive-subnav-item${subActiveTab === 2 ? ' active' : ''}`}

          onClick={() => setSubActiveTab(2)}

        >

          <FileText size={15} /> Auditoría

        </button>

        <div className="executive-subnav-spacer" />

        <button type="button" className="executive-demo-link" onClick={() => setShowSettlement(true)}>

          Liquidación

        </button>

        {import.meta.env.DEV ? (
          <button type="button" className="executive-demo-link" onClick={() => setShowContractModal(true)}>
            Contrato (solo desarrollo)
          </button>
        ) : null}

      </div>



      {subActiveTab === 0 && (

        <>

          {loading ? (

            <KpiCardsSkeleton count={4} />

          ) : (

            <div className="executive-kpi-grid executive-kpi-grid--4">

              {kpis.map((kpi) => {

                const Icon = kpi.icon;

                return (

                  <div key={kpi.label} className={`exec-kpi-card exec-kpi-card--${kpi.tone}`}>

                    <div className="exec-kpi-top">

                      <div className="exec-kpi-icon-wrap">

                        <Icon size={18} />

                      </div>

                      <span className="exec-kpi-label">{kpi.label}</span>

                    </div>

                    <div className="exec-kpi-value">{kpi.value}</div>

                    <div className="exec-kpi-bottom">

                      <span className={`exec-kpi-trend${kpi.up ? ' up' : ' down'}`}>

                        {kpi.up ? <TrendingUp size={12} /> : <TrendingDown size={12} />}

                        {kpi.trend}

                      </span>

                      <Sparkline

                        color={kpi.tone === 'purple' ? '#8B5CF6' : '#F0782A'}

                        points={kpi.spark}

                      />

                    </div>

                  </div>

                );

              })}

            </div>

          )}



          <div className="exec-chart-full card-surface">

            <div className="chart-card-head">

              <div>

                <div className="chart-card-title-row">

                  <span className="chart-live-dot" aria-hidden />

                  <h3 className="chart-card-title">Periodo de negocio</h3>

                </div>

              </div>

            </div>

            <ExecutivePeriodPanel activeJobs={activeJobs} />

          </div>



          <div className="executive-bottom-grid">

            <div className="card-surface exec-panel">

              <h3 className="exec-panel-title">Conteos en vivo</h3>

              <p className="cell-empty">El desglose de cobros está en el período de arriba.</p>

            </div>

            <div className="card-surface exec-panel">

              <h3 className="exec-panel-title">Resumen operativo</h3>

              <div className="ops-summary-grid">

                {opsSummary.map((item) => (

                  <div key={item.label} className="ops-summary-item">

                    <span className="ops-summary-label">{item.label}</span>

                    <strong className="ops-summary-value">{item.value}</strong>

                    <span className={`ops-summary-trend${item.up ? ' up' : ' down'}`}>

                      {item.up ? <TrendingUp size={11} /> : <TrendingDown size={11} />}

                      {item.trend}

                    </span>

                  </div>

                ))}

              </div>

              <div className="system-health">

                <span className="system-health-label">Salud del sistema</span>

                <div className="system-health-status">

                  <Activity size={14} />

                  {metricsQuery.isError ? 'Sin datos' : 'Conectado'}

                </div>

                <div className="system-health-bars" aria-hidden>

                  {[1, 2, 3, 4, 5].map((n) => (

                    <span key={n} className={n <= 4 ? 'on' : ''} />

                  ))}

                </div>

              </div>

            </div>

          </div>

        </>

      )}



      {subActiveTab === 1 && (

        <div className="card-surface" style={{ overflow: 'hidden', padding: 0 }}>
          <div className="workers-panel-head">
            <h3 className="workers-panel-title">Profesionales (Supabase)</h3>
            <p className="workers-panel-lead">Listado real desde la base de datos.</p>
          </div>
          <div className="workers-table-wrap">
            <table className="workers-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>NOMBRE</th>
                  <th>ESPECIALIDAD</th>
                  <th>CONTACTO</th>
                  <th>VISITA</th>
                  <th>VERIFICACIÓN</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={6} style={{ padding: 0 }}>
                      <div className="table-skeleton-wrap">
                        <TableRowsSkeleton rows={4} columns={6} />
                      </div>
                    </td>
                  </tr>
                )}
                {!loading && workers.length === 0 && (
                  <tr>
                    <td colSpan={6} className="cell-empty">Sin trabajadores visibles.</td>
                  </tr>
                )}
                {!loading && workers.map((w) => (
                  <tr key={w.id}>
                    <td className="cell-id">{w.id.slice(0, 8)}…</td>
                    <td style={{ fontWeight: 600 }}>{w.name}</td>
                    <td className="cell-muted">{w.profession}</td>
                    <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>{w.rut}</td>
                    <td>${Math.round(w.visitFee).toLocaleString('es-CL')}</td>
                    <td>
                      <span className={w.verification === 'verificado' ? 'badge badge-success' : 'badge badge-error'}>
                        {verificationLabel(w.verification)}
                      </span>
                      {(w.verification === 'pendiente' || w.verification === 'en_revision') && (
                        <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                          <button type="button" onClick={() => void reviewWorker(w.id, 'verificado')}>Aprobar</button>
                          <button type="button" onClick={() => void reviewWorker(w.id, 'rechazado')}>Rechazar</button>
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {verifyError && <p role="alert" style={{ padding: 16 }}>{verifyError}</p>}
        </div>

      )}



      {subActiveTab === 2 && <AuditTrailViewer />}



      {showSettlement && <FinancialSettlementModal onClose={() => setShowSettlement(false)} />}

      {import.meta.env.DEV && showContractModal && (

        <DigitalContractModal

          clientName="Cliente Demo"

          clientRut="DEMO-CL-001"

          workerName="Profesional Demo"

          workerRut="DEMO-WK-001"

          serviceDescription="Servicio de ejemplo para demostración académica"

          totalAmount={65000}

          onClose={() => setShowContractModal(false)}

        />

      )}

    </div>

  );

}

