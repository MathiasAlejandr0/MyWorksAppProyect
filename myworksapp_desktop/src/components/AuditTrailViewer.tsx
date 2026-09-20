import { useEffect, useState } from 'react';
import { FileText, Download, Search, Calendar, User } from 'lucide-react';
import { listLiquidaciones } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export interface AuditLog {
  id: string;
  timestamp: string;
  operator: string;
  action: string;
  details: string;
  ipAddress: string;
  severity: 'NORMAL' | 'CRITICAL' | 'FINANCIAL';
}

export function AuditTrailViewer() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const rows = await listLiquidaciones(supabase, 80);
        if (cancelled) return;
        setLogs(
          rows.map((r) => ({
            id: r.id.slice(0, 8),
            timestamp: new Date(r.createdAt).toLocaleString('es-CL'),
            operator: r.operatorId.slice(0, 8),
            action: 'RELEASE_PAYOUT',
            details: `${r.provider} · ${r.amountClp.toLocaleString('es-CL')} CLP · ref ${r.transferRef}${r.notes ? ` · ${r.notes}` : ''}`,
            ipAddress: '—',
            severity: 'FINANCIAL' as const,
          })),
        );
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : 'No se pudo cargar auditoría');
          setLogs([]);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const filteredLogs = logs.filter(
    (l) =>
      l.action.toLowerCase().includes(search.toLowerCase()) ||
      l.operator.toLowerCase().includes(search.toLowerCase()) ||
      l.details.toLowerCase().includes(search.toLowerCase()),
  );

  const exportCsv = () => {
    const headers = 'ID,Timestamp,Operador,Acción,Detalles\n';
    const rows = filteredLogs
      .map(
        (l) =>
          `"${l.id}","${l.timestamp}","${l.operator}","${l.action}","${l.details}"`,
      )
      .join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Audit_liquidaciones_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="card-3d" style={{ marginTop: '8px' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          gap: '12px',
          marginBottom: '18px',
          flexWrap: 'wrap',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <FileText size={22} color="#F0782A" />
          <div>
            <h3 style={{ fontSize: '16px', fontWeight: 900 }}>
              Auditoría de liquidaciones
            </h3>
            <p style={{ fontSize: '12px', color: '#98989D', marginTop: '4px' }}>
              Registros reales de `liquidaciones` (liberaciones de escrow).
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={exportCsv}
          className="btn-primary"
          style={{ padding: '8px 16px', fontSize: '12.5px' }}
          disabled={filteredLogs.length === 0}
        >
          <Download size={14} /> Exportar CSV
        </button>
      </div>

      {error ? (
        <p style={{ color: '#FF3B30', fontSize: 13, marginBottom: 12 }} role="alert">
          {error}
        </p>
      ) : null}

      <div style={{ position: 'relative', marginBottom: '14px' }}>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por operador, acción o detalle..."
          style={{
            width: '100%',
            padding: '10px 16px 10px 40px',
            borderRadius: '8px',
            border: '1px solid rgba(255,255,255,0.1)',
            backgroundColor: 'rgba(255,255,255,0.03)',
            color: 'white',
            fontSize: '13px',
            outline: 'none',
          }}
        />
        <Search
          size={16}
          style={{ position: 'absolute', left: '14px', top: '12px', color: '#98989D' }}
        />
      </div>

      {loading ? (
        <p style={{ color: '#98989D', fontSize: 13 }}>Cargando…</p>
      ) : filteredLogs.length === 0 ? (
        <p style={{ color: '#98989D', fontSize: 13, padding: '8px 0 16px' }}>
          Aún no hay liquidaciones registradas.
        </p>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table
            style={{
              width: '100%',
              borderCollapse: 'collapse',
              textAlign: 'left',
              fontSize: '12.5px',
            }}
          >
            <thead>
              <tr
                style={{
                  backgroundColor: 'rgba(255,255,255,0.04)',
                  borderBottom: '1px solid rgba(255,255,255,0.08)',
                }}
              >
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ID</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>FECHA</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>OPERADOR</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ACCIÓN</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>DETALLE</th>
              </tr>
            </thead>
            <tbody>
              {filteredLogs.map((l) => (
                <tr key={l.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <td style={{ padding: '12px 16px', fontWeight: 800, color: '#F0782A' }}>
                    {l.id}
                  </td>
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
                    <span
                      className="badge-tag"
                      style={{
                        backgroundColor: 'rgba(52,199,89,0.15)',
                        color: '#34C759',
                      }}
                    >
                      {l.action}
                    </span>
                  </td>
                  <td style={{ padding: '12px 16px', maxWidth: '360px' }}>{l.details}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
