import { useState } from 'react';
import { TrendingUp, Wallet, CheckCircle2, XCircle, DollarSign, Lock, AlertTriangle, LayoutDashboard, UserCheck, FileText, PieChart, Clock, Award } from 'lucide-react';
import { AuditTrailViewer } from './AuditTrailViewer';
import { FinancialSettlementModal } from './FinancialSettlementModal';
import { DigitalContractModal } from './DigitalContractModal';

interface WorkerApproval {
  id: string;
  name: string;
  profession: string;
  rut: string;
  status: 'Verified' | 'Pending';
}

const INITIAL_WORKERS: WorkerApproval[] = [
  { id: 'W-101', name: 'Carlos Silva', profession: 'Electricista Certificado', rut: '16.892.410-K', status: 'Verified' },
  { id: 'W-102', name: 'Felipe Araya', profession: 'Gásfiter SEC', rut: '15.441.209-4', status: 'Verified' },
  { id: 'W-103', name: 'Marcela Tapia', profession: 'Técnico en Climatización', rut: '18.120.301-8', status: 'Pending' },
  { id: 'W-104', name: 'Gonzalo Pérez', profession: 'Pintor & Remodelador', rut: '17.339.112-1', status: 'Pending' },
];

export function ExecutiveWorkspace() {
  const [workers, setWorkers] = useState<WorkerApproval[]>(INITIAL_WORKERS);
  const [subActiveTab, setSubActiveTab] = useState<number>(0);
  const [showSettlement, setShowSettlement] = useState(false);
  const [showContractModal, setShowContractModal] = useState(false);
  const [isFrozen, setIsFrozen] = useState(false);

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
      {/* Alerta de Freeze Switch Activo */}
      {isFrozen && (
        <div style={{ backgroundColor: 'rgba(255,59,48,0.2)', border: '2px solid #FF3B30', color: '#FF3B30', padding: '14px 20px', borderRadius: '12px', marginBottom: '20px', fontWeight: 800, fontSize: '14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertTriangle size={20} />
            <span>MODO CONGELAMIENTO DE EMERGENCIA ACTIVO: Custodia de pagos bloqueada preventivamente.</span>
          </div>
          <button onClick={() => setIsFrozen(false)} className="btn-action-danger">
            Desactivar
          </button>
        </div>
      )}

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 900 }}>Panel Ejecutivo & Intelligence C-Level</h1>
          <p style={{ fontSize: '13.5px', color: '#98989D' }}>Métricas GMV, gráficos de rendimiento, custodia Escrow y validación corporativa.</p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button onClick={() => setShowContractModal(true)} className="btn-action-primary">
            <FileText size={14} /> Contrato Digital (Ley 19.799)
          </button>
          <button onClick={() => setShowSettlement(true)} className="btn-action-success">
            <DollarSign size={14} /> Liquidación SII (19%)
          </button>
          <button onClick={() => setIsFrozen(!isFrozen)} className={isFrozen ? "btn-action-success" : "btn-action-danger"}>
            <Lock size={14} /> {isFrozen ? 'Descongelar Sistema' : 'Freeze Switch'}
          </button>
        </div>
      </div>

      {/* Sub-Barra de Navegación Organizada */}
      <div className="sub-tabs-bar">
        <div className={`sub-tab-item ${subActiveTab === 0 ? 'active' : ''}`} onClick={() => setSubActiveTab(0)}>
          <LayoutDashboard size={16} /> 1. Analytics & Gráficos KPI
        </div>
        <div className={`sub-tab-item ${subActiveTab === 1 ? 'active' : ''}`} onClick={() => setSubActiveTab(1)}>
          <UserCheck size={16} /> 2. Verificación de Trabajadores ({workers.filter(w => w.status === 'Pending').length} pend.)
        </div>
        <div className={`sub-tab-item ${subActiveTab === 2 ? 'active' : ''}`} onClick={() => setSubActiveTab(2)}>
          <FileText size={16} /> 3. Audit Trail Legal & Logs
        </div>
      </div>

      {/* 1. Sub-Pestaña: Analytics & Gráficos KPI */}
      {subActiveTab === 0 && (
        <div>
          {/* Tarjetas de Métricas Top C-Level */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#34C759', marginBottom: '8px' }}>
                <Wallet size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>GMV Custodiado Escrow</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>$14.850.000 CLP</div>
              <span style={{ fontSize: '11.5px', color: '#34C759', fontWeight: 700 }}>+18.4% este mes</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#F0782A', marginBottom: '8px' }}>
                <TrendingUp size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Comisiones Netas (10%)</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>$1.485.000 CLP</div>
              <span style={{ fontSize: '11.5px', color: '#F0782A', fontWeight: 700 }}>Margen operaciones activo</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#007AFF', marginBottom: '8px' }}>
                <Award size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Trust Score & Calidad</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>99.4% CSAT</div>
              <span style={{ fontSize: '11.5px', color: '#007AFF', fontWeight: 700 }}>Peak-End Rule Trust Index</span>
            </div>

            <div className="card-3d">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#AF52DE', marginBottom: '8px' }}>
                <Clock size={20} />
                <span style={{ fontSize: '11px', fontWeight: 800, textTransform: 'uppercase', color: '#98989D' }}>Tiempo Asignación</span>
              </div>
              <div style={{ fontSize: '26px', fontWeight: 900 }}>3.2 min</div>
              <span style={{ fontSize: '11.5px', color: '#AF52DE', fontWeight: 700 }}>Despacho rápido 3s</span>
            </div>
          </div>

          {/* Sección de Gráficos Financieros & Mercado */}
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '20px', marginBottom: '24px' }}>
            {/* Gráfico 1: Tendencia GMV Semanal SVG */}
            <div className="card-3d" style={{ padding: '22px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: 900 }}>Tendencia de Crecimiento GMV & Comisiones</h3>
                  <span style={{ fontSize: '12px', color: '#98989D' }}>Evolución mensual de volumen custodiado en CLP</span>
                </div>
                <span className="badge badge-success" style={{ fontSize: '11px' }}>En alza +18.4%</span>
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

            {/* Gráfico 2: Distribución por Categorías de Oficio */}
            <div className="card-3d" style={{ padding: '22px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
                <PieChart size={18} color="#007AFF" />
                <h3 style={{ fontSize: '16px', fontWeight: 900 }}>Demanda por Categoría</h3>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>⚡ Electricidad SEC</span>
                    <span>38% ($5.64M)</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '38%', height: '100%', backgroundColor: '#F0782A' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>🚰 Gasfitería & Calefón</span>
                    <span>27% ($4.00M)</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '27%', height: '100%', backgroundColor: '#007AFF' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>🔑 Cerrajería 24/7</span>
                    <span>20% ($2.97M)</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '20%', height: '100%', backgroundColor: '#34C759' }} />
                  </div>
                </div>

                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12.5px', fontWeight: 700, marginBottom: '4px' }}>
                    <span>🎨 Pintura & Reformas</span>
                    <span>15% ($2.22M)</span>
                  </div>
                  <div style={{ height: '8px', backgroundColor: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: '15%', height: '100%', backgroundColor: '#AF52DE' }} />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 2. Sub-Pestaña: Verificación de Trabajadores */}
      {subActiveTab === 1 && (
        <div className="card-3d" style={{ overflow: 'hidden', padding: 0 }}>
          <div style={{ padding: '20px', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Aprobación y Verificación de Trabajadores</h3>
            <p style={{ fontSize: '12.5px', color: '#98989D' }}>Validación legal de RUT, certificados SEC y antecedentes.</p>
          </div>

          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ backgroundColor: 'rgba(255,255,255,0.04)', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ID</th>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>NOMBRE</th>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ESPECIALIDAD</th>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>RUT</th>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ESTADO SEC</th>
                <th style={{ padding: '16px 20px', fontSize: '12px', color: '#98989D' }}>ACCIÓN</th>
              </tr>
            </thead>
            <tbody>
              {workers.map(w => (
                <tr key={w.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <td style={{ padding: '16px 20px', fontWeight: 800, color: '#F0782A' }}>{w.id}</td>
                  <td style={{ padding: '16px 20px', fontWeight: 600 }}>{w.name}</td>
                  <td style={{ padding: '16px 20px', color: '#98989D' }}>{w.profession}</td>
                  <td style={{ padding: '16px 20px', fontFamily: 'monospace' }}>{w.rut}</td>
                  <td style={{ padding: '16px 20px' }}>
                    <span className={w.status === 'Verified' ? "badge badge-success" : "badge badge-error"}>
                      {w.status === 'Verified' ? 'Verificado SEC' : 'Pendiente Rev.'}
                    </span>
                  </td>
                  <td style={{ padding: '16px 20px' }}>
                    <button 
                      onClick={() => toggleVerification(w.id)} 
                      className={w.status === 'Verified' ? "btn-action-danger" : "btn-action-success"}
                      style={{ padding: '6px 12px', fontSize: '12px' }}
                    >
                      {w.status === 'Verified' ? <XCircle size={14} /> : <CheckCircle2 size={14} />}
                      {w.status === 'Verified' ? 'Revocar' : 'Aprobar'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* 3. Sub-Pestaña: Audit Trail Legal & Logs */}
      {subActiveTab === 2 && (
        <AuditTrailViewer />
      )}

      {/* Modal de Liquidación Financiera SII */}
      {showSettlement && (
        <FinancialSettlementModal onClose={() => setShowSettlement(false)} />
      )}

      {/* Modal de Contrato Digital Ley 19.799 */}
      {showContractModal && (
        <DigitalContractModal 
          clientName="Carolina Mendoza"
          clientRut="17.892.401-K"
          workerName="Carlos Silva"
          workerRut="16.892.410-K"
          serviceDescription="Instalación y normalización de tablero eléctrico trifásico bajo norma SEC"
          totalAmount={65000}
          onClose={() => setShowContractModal(false)}
        />
      )}
    </div>
  );
}
