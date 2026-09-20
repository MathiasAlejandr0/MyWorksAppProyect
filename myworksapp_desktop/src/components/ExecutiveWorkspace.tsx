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
import { FinancialSettlementModal } from './FinancialSettlementModal';
import { DigitalContractModal } from './DigitalContractModal';
import { KpiCardsSkeleton, TableRowsSkeleton } from './LoadingState';
import { fetchAdminMetrics, fetchWorkersForAdmin } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { queryKeys } from '../queryClient';

interface WorkerApproval {
  id: string;
  name: string;
  profession: string;
  rut: string;
  status: 'Verified' | 'Pending';
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



function AreaChart() {

  const hours = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'];

  return (

    <div className="area-chart-wrap">

      <div className="area-chart-y">

        {['$16M', '$12M', '$8M', '$4M', '$0'].map((label) => (

          <span key={label}>{label}</span>

        ))}

      </div>

      <div className="area-chart-body">

        <svg className="area-chart-svg" viewBox="0 0 600 180" preserveAspectRatio="none">

          <defs>

            <linearGradient id="gmvFill" x1="0" y1="0" x2="0" y2="1">

              <stop offset="0%" stopColor="#F0782A" stopOpacity="0.35" />

              <stop offset="100%" stopColor="#F0782A" stopOpacity="0" />

            </linearGradient>

          </defs>

          <path

            d="M0,140 L60,120 L120,130 L180,90 L240,100 L300,70 L360,85 L420,55 L480,65 L540,40 L600,35 L600,180 L0,180 Z"

            fill="url(#gmvFill)"

          />

          <polyline

            points="0,140 60,120 120,130 180,90 240,100 300,70 360,85 420,55 480,65 540,40 600,35"

            fill="none"

            stroke="#F0782A"

            strokeWidth="2.5"

          />

          <circle cx="600" cy="35" r="5" fill="#F0782A" />

        </svg>

        <div className="area-chart-tooltip">$14.8M · 23:40</div>

        <div className="area-chart-x">

          {hours.map((h) => (

            <span key={h}>{h}</span>

          ))}

        </div>

      </div>

    </div>

  );

}



function DonutChart() {

  return (

    <div className="donut-chart-wrap">

      <div

        className="donut-chart-ring"

        style={{

          background: `conic-gradient(

            #F0782A 0% 41.4%,

            #8B5CF6 41.4% 71%,

            #3B82F6 71% 88.8%,

            #2F9E64 88.8% 100%

          )`,

        }}

      >

        <div className="donut-chart-center">

          <strong>$14.8M</strong>

          <span>GMV total</span>

        </div>

      </div>

      <ul className="donut-legend">

        <li><span className="donut-dot donut-dot--orange" /> Servicios Profesionales <em>$6.12M (41.4%)</em></li>

        <li><span className="donut-dot donut-dot--purple" /> Desarrollo de Software <em>$4.38M (29.6%)</em></li>

        <li><span className="donut-dot donut-dot--blue" /> Infraestructura y Cloud <em>$2.64M (17.8%)</em></li>

        <li><span className="donut-dot donut-dot--green" /> Soporte y Operaciones <em>$1.66M (11.2%)</em></li>

      </ul>

      <a className="donut-report-link" href="#">Ver reporte completo →</a>

    </div>

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

  const workers: WorkerApproval[] = useMemo(
    () =>
      (workersQuery.data ?? []).map((worker) => ({
        id: worker.userId,
        name: worker.name,
        profession: worker.profession,
        rut: worker.email ?? '—',
        status: worker.pricingConfigured === 1 ? 'Verified' : 'Pending',
      })),
    [workersQuery.data],
  );

  const activeJobs = metrics.activeJobsCount || 1246;
  const disputes = metrics.openDisputesCount || 32;



  const kpis = [

    {

      label: 'GMV',

      value: '$14.8M',

      trend: '+12.6% vs ayer',

      up: true,

      icon: DollarSign,

      tone: 'orange',

      spark: '2,18 12,14 22,16 32,10 42,12 52,8 62,10 72,6 78,4',

    },

    {

      label: 'Trabajos activos',

      value: activeJobs.toLocaleString('es-CL'),

      trend: '+8.3% vs ayer',

      up: true,

      icon: ClipboardList,

      tone: 'orange',

      spark: '2,16 14,12 26,14 38,8 50,10 62,6 74,8 78,4',

    },

    {

      label: 'Disputas',

      value: String(disputes),

      trend: '-11.4% vs ayer',

      up: false,

      icon: MessageSquare,

      tone: 'purple',

      spark: '2,6 14,10 26,8 38,12 50,10 62,14 74,12 78,16',

    },

    {

      label: 'CSAT',

      value: '4.78 / 5',

      trend: '+2.7% vs ayer',

      up: true,

      icon: Smile,

      tone: 'orange',

      spark: '2,14 14,12 26,10 38,12 50,8 62,10 74,6 78,4',

    },

  ];



  const opsSummary = [

    { label: 'Trabajos completados', value: '1,932', trend: '+9.7% vs ayer', up: true },

    { label: 'Tiempo promedio de resolución', value: '4.6h', trend: '-6.1% vs ayer', up: true },

    { label: 'Disputas abiertas', value: String(disputes), trend: '+6.7% vs ayer', up: false },

    { label: 'Nuevos trabajos', value: '287', trend: '+14.3% vs ayer', up: true },

  ];



  return (

    <div className="executive-workspace">

      <div className="executive-header">

        <div>

          <h1 className="executive-title">Panel ejecutivo</h1>

          <p className="executive-subtitle">

            Vista en tiempo real del rendimiento operativo y del negocio.

          </p>

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

          <FileText size={15} /> Audit trail

        </button>

        <div className="executive-subnav-spacer" />

        <button type="button" className="executive-demo-link" onClick={() => setShowSettlement(true)}>

          Liquidación

        </button>

        {import.meta.env.DEV ? (
          <button type="button" className="executive-demo-link" onClick={() => setShowContractModal(true)}>
            Contrato (solo DEV)
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

                  <h3 className="chart-card-title">GMV en tiempo real</h3>

                  <span className="chart-card-caption">Últimas 24 horas</span>

                </div>

              </div>

              <select className="chart-select" defaultValue="24h" aria-label="Rango temporal">

                <option value="24h">24 horas</option>

                <option value="7d">7 días</option>

              </select>

            </div>

            <AreaChart />

          </div>



          <div className="executive-bottom-grid">

            <div className="card-surface exec-panel">

              <h3 className="exec-panel-title">Desglose por categoría</h3>

              <DonutChart />

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

                  Excelente

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
                  <th>PRECIO</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={5} style={{ padding: 0 }}>
                      <div className="table-skeleton-wrap">
                        <TableRowsSkeleton rows={4} columns={5} />
                      </div>
                    </td>
                  </tr>
                )}
                {!loading && workers.length === 0 && (
                  <tr>
                    <td colSpan={5} className="cell-empty">Sin trabajadores visibles.</td>
                  </tr>
                )}
                {!loading && workers.map((w) => (
                  <tr key={w.id}>
                    <td className="cell-id">{w.id.slice(0, 8)}…</td>
                    <td style={{ fontWeight: 600 }}>{w.name}</td>
                    <td className="cell-muted">{w.profession}</td>
                    <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>{w.rut}</td>
                    <td>
                      <span className={w.status === 'Verified' ? 'badge badge-success' : 'badge badge-error'}>
                        {w.status === 'Verified' ? 'Configurado' : 'Pendiente'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
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

