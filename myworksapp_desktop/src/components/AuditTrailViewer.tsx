import { useState } from 'react';
import { FileText, Download, Search, Calendar, User } from 'lucide-react';

export interface AuditLog {
  id: string;
  timestamp: string;
  operator: string;
  action: string;
  details: string;
  ipAddress: string;
  severity: 'NORMAL' | 'CRITICAL' | 'FINANCIAL';
}

/** Datos ficticios solo para demostración académica — no es un trail real ni inmutable. */
const DEMO_LOGS: AuditLog[] = [
  { id: 'DEMO-001', timestamp: '2026-08-17 00:30:15', operator: 'ADM-DEMO', action: 'RELEASE_PAYOUT', details: 'Ejemplo: liberación de payout (monto ficticio)', ipAddress: '0.0.0.0', severity: 'FINANCIAL' },
  { id: 'DEMO-002', timestamp: '2026-08-16 23:45:00', operator: 'ADM-DEMO', action: 'VERIFY_WORKER', details: 'Ejemplo: verificación de profesional (sin PII real)', ipAddress: '0.0.0.0', severity: 'NORMAL' },
  { id: 'DEMO-003', timestamp: '2026-08-16 22:10:33', operator: 'SYSTEM_DEMO', action: 'ESCROW_LOCK', details: 'Ejemplo: retención en garantía (simulado)', ipAddress: '127.0.0.1', severity: 'FINANCIAL' },
  { id: 'DEMO-004', timestamp: '2026-08-16 20:05:12', operator: 'SOPORTE-DEMO', action: 'REFUND_ESCROW', details: 'Ejemplo: reembolso de disputa (simulado)', ipAddress: '0.0.0.0', severity: 'CRITICAL' },
];

export function AuditTrailViewer() {
  const [logs] = useState<AuditLog[]>(DEMO_LOGS);
  const [search, setSearch] = useState('');

  const filteredLogs = logs.filter(l =>
    l.action.toLowerCase().includes(search.toLowerCase()) ||
    l.operator.toLowerCase().includes(search.toLowerCase()) ||
    l.details.toLowerCase().includes(search.toLowerCase())
  );

  const exportCsv = () => {
    const headers = 'ID,Timestamp,Operador,Acción,Detalles,IP,Nota\n';
    const rows = filteredLogs.map(l => `"${l.id}","${l.timestamp}","${l.operator}","${l.action}","${l.details}","${l.ipAddress}","DEMO — no es auditoría real"`).join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Audit_Trail_DEMO_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="card-3d" style={{ marginTop: '8px' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '12px', marginBottom: '18px', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <FileText size={22} color="#F0782A" />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              <h3 style={{ fontSize: '16px', fontWeight: 900 }}>Registro de auditoría (ejemplo)</h3>
              <span className="demo-badge">DEMO</span>
            </div>
            <p style={{ fontSize: '12px', color: '#98989D', marginTop: '4px' }}>
              Datos de ejemplo para la demo académica. No es un log inmutable ni proviene de producción.
            </p>
          </div>
        </div>

        <button onClick={exportCsv} className="btn-primary" style={{ padding: '8px 16px', fontSize: '12.5px' }}>
          <Download size={14} /> Exportar CSV (demo)
        </button>
      </div>

      <div style={{ position: 'relative', marginBottom: '14px' }}>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por operador, acción o detalle..."
          style={{ width: '100%', padding: '10px 16px 10px 40px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.1)', backgroundColor: 'rgba(255,255,255,0.03)', color: 'white', fontSize: '13px', outline: 'none' }}
        />
        <Search size={16} style={{ position: 'absolute', left: '14px', top: '12px', color: '#98989D' }} />
      </div>

      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '12.5px' }}>
          <thead>
            <tr style={{ backgroundColor: 'rgba(255,255,255,0.04)', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>ID</th>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>FECHA / HORA</th>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>OPERADOR</th>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>ACCIÓN</th>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>DETALLE</th>
              <th style={{ padding: '12px 16px', color: '#98989D' }}>IP</th>
            </tr>
          </thead>
          <tbody>
            {filteredLogs.map(l => (
              <tr key={l.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <td style={{ padding: '12px 16px', fontWeight: 800, color: '#F0782A' }}>{l.id}</td>
                <td style={{ padding: '12px 16px', color: '#98989D' }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                    <Calendar size={12} /> {l.timestamp}
                  </span>
                </td>
                <td style={{ padding: '12px 16px', fontWeight: 700 }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                    <User size={12} color="#007AFF" /> {l.operator}
                  </span>
                </td>
                <td style={{ padding: '12px 16px' }}>
                  <span className="badge-tag" style={{ backgroundColor: l.severity === 'CRITICAL' ? 'rgba(255,59,48,0.15)' : l.severity === 'FINANCIAL' ? 'rgba(52,199,89,0.15)' : 'rgba(0,122,255,0.15)', color: l.severity === 'CRITICAL' ? '#FF3B30' : l.severity === 'FINANCIAL' ? '#34C759' : '#007AFF' }}>
                    {l.action}
                  </span>
                </td>
                <td style={{ padding: '12px 16px', maxWidth: '320px' }}>{l.details}</td>
                <td style={{ padding: '12px 16px', fontFamily: 'monospace', color: '#98989D' }}>{l.ipAddress}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
