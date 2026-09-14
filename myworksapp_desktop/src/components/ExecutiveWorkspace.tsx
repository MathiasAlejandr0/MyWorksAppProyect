import { useEffect, useState } from 'react';
import { TrendingUp, Wallet, CheckCircle2, XCircle, DollarSign, Lock, AlertTriangle, LayoutDashboard, UserCheck, FileText, PieChart, Clock, Award } from 'lucide-react';
import { AuditTrailViewer } from './AuditTrailViewer';
import { FinancialSettlementModal } from './FinancialSettlementModal';
import { DigitalContractModal } from './DigitalContractModal';
import { KpiCardsSkeleton, TableRowsSkeleton } from './LoadingState';
import { fetchAdminMetrics, fetchWorkersForAdmin } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface WorkerApproval {
  id: string;
  name: string;
  profession: string;
  rut: string;
  status: 'Verified' | 'Pending';
}

const INITIAL_WORKERS: WorkerApproval[] = [];

export function ExecutiveWorkspace() {
  const [workers, setWorkers] = useState<WorkerApproval[]>(INITIAL_WORKERS);
  const [metrics, setMetrics] = useState({
    usersCount: 0,
    workersCount: 0,
    jobsCount: 0,
    openDisputesCount: 0,
    activeJobsCount: 0,
  });
  const [loading, setLoading] = useState(true);
  const [subActiveTab, setSubActiveTab] = useState<number>(0);
  const [showSettlement, setShowSettlement] = useState(false);
  const [showContractModal, setShowContractModal] = useState(false);
  const [isFrozen, setIsFrozen] = useState(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [adminMetrics, workerRows] = await Promise.all([
          fetchAdminMetrics(supabase),
          fetchWorkersForAdmin(supabase),
        ]);
        setMetrics({
          usersCount: adminMetrics.usersCount,
          workersCount: adminMetrics.workersCount,
          jobsCount: adminMetrics.jobsCount,
          openDisputesCount: adminMetrics.openDisputesCount + adminMetrics.underReviewDisputesCount,
          activeJobsCount: adminMetrics.activeJobsCount,
        });
        setWorkers(
          workerRows.map((worker) => ({
            id: worker.userId,
            name: worker.name,
            profession: worker.profession,
            rut: worker.email ?? '—',
            status: worker.pricingConfigured === 1 ? 'Verified' : 'Pending',
          })),
        );
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  const toggleVerification = (id: string) => {
    setWorkers(prev => prev.map(w => w.id === id ? { ...w, status: w.status === 'Verified' ? 'Pending' : 'Verified' } : w));
  };

  const weeklyData = [
    { week: 'Sem 1', gmv: 2400000, fee: 240000 },
    { week: 'Sem 2', gmv: 3800000, fee: 380000 },
    { week: 'Sem 3', gmv: 4200000, fee: 420000 },
    { week: 'Sem 4', gmv: 4450000, fee: 445000 },
  ];

  return (
    <div>
      {isFrozen && (
        <div style={{ backgroundColor: 'rgba(255,59,48,0.2)', border: '2px solid #FF3B30', color: '#FF3B30', padding: '14px 20px', borderRadius: '12px', marginBottom: '20px', fontWeight: 800, fontSize: '14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertTriangle size={20} />
            <span>Congelamiento de emergencia (UI demo — no bloquea pagos reales).</span>
          </div>
          <button onClick={() => setIsFrozen(false)} className="btn-action-danger">
            Desactivar
          </button>
        </div>
      )}

      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '16px', gap: '16px', flexWrap: 'wrap' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: 900 }}>Panel ejecutivo</h1>
          <p style={{ fontSize: '13.5px', color: '#98989D', marginTop: '4px' }}>
            Contadores desde Supabase. Gráficos GMV y audit trail son demostración académica.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button onClick={() => setShowContractModal(true)} className="btn-action-primary">
            <FileText size={14} /> Contrato (demo)
          </button>
          <button onClick={() => setShowSettlement(true)} className="btn-action-success">
            <DollarSign size={14} /> Liquidación (demo)
          </button>
          <button onClick={() => setIsFrozen(!isFrozen)} className={isFrozen ? "btn-action-success" : "btn-action-danger"}>
            <Lock size={14} /> {isFrozen ? 'Descongelar' : 'Freeze (demo)'}
          </button>
        </div>
      </div>

      <div className="sub-tabs-bar">
        <div className={`sub-tab-item ${subActiveTab === 0 ? 'active' : ''}`} onClick={() => setSubActiveTab(0)}>
          <LayoutDashboard size={16} /> Métricas
        </div>
        <div className={`sub-tab-item ${subActiveTab === 1 ? 'active' : ''}`} onClick={() => setSubActiveTab(1)}>
          <UserCheck size={16} /> Trabajadores ({workers.filter(w => w.status === 'Pending').length} pend.)
        </div>
        <div className={`sub-tab-item ${subActiveTab === 2 ? 'active' : ''}`} onClick={() => setSubActiveTab(2)}>
          <FileText size={16} /> Audit trail (demo)
        </div>
      </div>

      {subActiveTab === 0 && (
        <div>
          {loading ? (
            <KpiCardsSkeleton count={4} />
          ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#34C759', marginBottom: '8px' }}>
                <Wallet size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Trabajos (Supabase)</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>{metrics.jobsCount.toLocaleString('es-CL')}</div>
              <span style={{ fontSize: '11.5px', color: '#34C759', fontWeight: 700 }}>{metrics.activeJobsCount} activos</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#F0782A', marginBottom: '8px' }}>
                <TrendingUp size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Profesionales</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>{metrics.workersCount}</div>
              <span style={{ fontSize: '11.5px', color: '#F0782A', fontWeight: 700 }}>{metrics.usersCount} usuarios</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#007AFF', marginBottom: '8px' }}>
                <Award size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Disputas abiertas</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>{metrics.openDisputesCount}</div>
              <span style={{ fontSize: '11.5px', color: '#007AFF', fontWeight: 700 }}>Datos en vivo</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#AF52DE', marginBottom: '8px' }}>
                <Clock size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Tiempo asignación</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>—</div>
              <span style={{ fontSize: '11.5px', color: '#AF52DE', fontWeight: 700 }}>Sin métrica real aún</span>
            </div>
          </div>
          )}

          {!loading && (
          <>
          <div className="demo-banner" style={{ marginBottom: '16px' }}>
            Gráficos GMV / categorías: DEMO (no calculados desde pagos reales).
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px', marginBottom: '24px' }}>
            <div className="card-3d" style={{ padding: '22px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px', gap: '8px', flexWrap: 'wrap' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <h3 style={{ fontSize: '16px', fontWeight: 900 }}>Tendencia GMV (ejemplo)</h3>
                    <span className="demo-badge">DEMO</span>
                  </div>
                  <span style={{ fontSize: '12px', color: '#98989D' }}>Serie ficticia para presentación académica</span>
                </div>
              </div>

              {/* Gráfico de Barras SVG Interactivo */}
              <div style={{ height: '180px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: '16px', paddingBottom: '20px', borderBottom: '1px solid #E2E8F0' }}>
                {weeklyData.map((d, idx) => (
                  <div key={idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%', justifyContent: 'flex-end' }}>
                    <div style={{ fontSize: '11px', fontWeight: 800, color: '#F0782A', marginBottom: '6px' }}>${(d.gmv / 1000000).toFixed(1)}M</div>
                    <div style={{ width: '100%', maxWidth: '48px', height: `${(d.gmv / 5000000) * 100}%`, backgroundColor: '#F0782A', borderRadius: '8px 8px 0 0', position: 'relative', transition: 'height 0.4s ease' }}>
                      <div style={{ position: 'absolute', top: 0, width: '100%', height: '35%', backgroundColor: '#FF9500', borderRadius: '8px 8px 0 0' }} />
                    </div>
                    <span style={{ fontSize: '11.5px', color: '#6E6E73', marginTop: '8px', fontWeight: 700 }}>{d.week}</span>
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-around', paddingTop: '14px', fontSize: '12px', color: '#6E6E73', fontWeight: 600 }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><span style={{ width: '10px', height: '10px', backgroundColor: '#F0782A', borderRadius: '50%' }} /> GMV Bruto</span>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><span style={{ width: '10px', height: '10px', backgroundColor: '#FF9500', borderRadius: '50%' }} /> Comisiones 10%</span>
              </div>
            </div>

            <div className="card-3d" style={{ padding: '22px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px', flexWrap: 'wrap' }}>
                <PieChart size={18} color="#007AFF" />
                <h3 style={{ fontSize: '16px', fontWeight: 900 }}>Demanda por categoría</h3>
                <span className="demo-badge">DEMO</span>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>Electricidad SEC</span>
                    <span>38%</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '38%', height: '100%', backgroundColor: '#F0782A' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>Gasfitería</span>
                    <span>27%</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '27%', height: '100%', backgroundColor: '#007AFF' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>Cerrajería</span>
                    <span>20%</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '20%', height: '100%', backgroundColor: '#34C759' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>Pintura & reformas</span>
                    <span>15%</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '15%', height: '100%', backgroundColor: '#AF52DE' }} />
                  </div>
                </div>
              </div>
            </div>
          </div>
          </>
          )}
        </div>
      )}

      {subActiveTab === 1 && (
        <div className="card-3d" style={{ overflow: 'hidden', padding: 0 }}>
          <div style={{ padding: '20px', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Profesionales (Supabase)</h3>
            <p style={{ fontSize: '12.5px', color: '#98989D' }}>Listado real. Aprobar/revocar es solo estado local en esta sesión (no escribe verificación SEC).</p>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ backgroundColor: 'rgba(255,255,255,0.04)', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ID</th>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>NOMBRE</th>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ESPECIALIDAD</th>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>CONTACTO</th>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>PRICING</th>
                  <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ACCIÓN (local)</th>
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
                    <td colSpan={6} style={{ padding: '24px 20px', color: '#98989D', textAlign: 'center' }}>
                      Sin trabajadores visibles o sin permisos.
                    </td>
                  </tr>
                )}
                {!loading && workers.map(w => (
                  <tr key={w.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                    <td style={{ padding: '16px 20px', fontWeight: 800, color: '#F0782A' }}>{w.id.slice(0, 8)}…</td>
                    <td style={{ padding: '16px 20px', fontWeight: 600 }}>{w.name}</td>
                    <td style={{ padding: '16px 20px', color: '#98989D' }}>{w.profession}</td>
                    <td style={{ padding: '16px 20px', fontFamily: 'monospace', fontSize: '12px' }}>{w.rut}</td>
                    <td style={{ padding: '16px 20px' }}>
                      <span className={w.status === 'Verified' ? "badge badge-success" : "badge badge-error"}>
                        {w.status === 'Verified' ? 'Configurado' : 'Pendiente'}
                      </span>
                    </td>
                    <td style={{ padding: '16px 20px' }}>
                      <button
                        onClick={() => toggleVerification(w.id)}
                        className={w.status === 'Verified' ? "btn-action-danger" : "btn-action-success"}
                        style={{ padding: '6px 12px', fontSize: '12px' }}
                      >
                        {w.status === 'Verified' ? <XCircle size={14} /> : <CheckCircle2 size={14} />}
                        {w.status === 'Verified' ? 'Marcar pend.' : 'Marcar OK'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {subActiveTab === 2 && (
        <AuditTrailViewer />
      )}

      {showSettlement && (
        <FinancialSettlementModal onClose={() => setShowSettlement(false)} />
      )}

      {showContractModal && (
        <DigitalContractModal
          clientName="Cliente Demo"
          clientRut="DEMO-CL-001"
          workerName="Profesional Demo"
          workerRut="DEMO-WK-001"
          serviceDescription="Servicio de ejemplo para demostración académica (sin PII real)"
          totalAmount={65000}
          onClose={() => setShowContractModal(false)}
        />
      )}
    </div>
  );
}
