import { useState, useEffect, useCallback } from 'react';
import {
  Shield,
  Activity,
  CheckCircle2,
  FlaskConical,
  Database,
  RefreshCw,
  Settings,
  Box,
  GraduationCap,
  Copy,
} from 'lucide-react';
import { supabase, supabaseConfigStatus } from '../supabaseClient';

const TEST_SUITES = [
  'Flutter analyze + test',
  'shared (pagos, dominio, chat)',
  'desktop authAccess',
  'web Playwright smoke',
  'gitleaks en GitHub Actions',
];

export function DevSecOpsWorkspace({ operatorEmail }: { operatorEmail?: string }) {
  const [latency, setLatency] = useState<number | null>(null);
  const [dbReachable, setDbReachable] = useState<boolean | null>(null);
  const [checking, setChecking] = useState(false);
  const [copied, setCopied] = useState(false);
  const [showNote, setShowNote] = useState(false);
  const [clock, setClock] = useState(new Date());

  const testConnection = useCallback(async () => {
    setChecking(true);
    const start = Date.now();
    try {
      const { error } = await supabase.from('perfiles').select('id').limit(1);
      setLatency(Date.now() - start);
      setDbReachable(!error);
    } catch {
      setLatency(null);
      setDbReachable(false);
    } finally {
      setChecking(false);
    }
  }, []);

  useEffect(() => {
    const tick = setInterval(() => setClock(new Date()), 1000);
    return () => clearInterval(tick);
  }, []);

  useEffect(() => {
    void testConnection();
  }, [testConnection]);

  const timeStr = clock.toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit', second: '2-digit', timeZone: 'America/Santiago' });
  const dateStr = clock.toLocaleDateString('es-CL', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'America/Santiago' });

  return (
    <div className="devsecops-workspace">
      <header className="devsecops-header">
        <div className="devsecops-header-left">
          <h1>Controles de calidad</h1>
          <span className="devsecops-status">
            <span className="live-pill-dot" aria-hidden />
            {dbReachable === false ? 'Base no alcanzable' : checking ? 'Comprobando…' : 'Conexión revisada'}
          </span>
        </div>
        <div className="devsecops-header-center">
          <span className="devsecops-clock">{timeStr}</span>
          <span className="devsecops-date">{dateStr}</span>
        </div>
        <div className="devsecops-header-right">
          <button type="button" className="icon-btn" aria-label="Actualizar" onClick={() => void testConnection()}>
            <RefreshCw size={18} />
          </button>
          <button type="button" className="icon-btn" aria-label="Almacenamiento" onClick={() => setShowNote(true)}>
            <Box size={18} />
          </button>
          <button type="button" className="icon-btn" aria-label="Configuración" onClick={() => setShowNote(true)}>
            <Settings size={18} />
          </button>
          <div className="devsecops-user">
            <span>{operatorEmail ?? 'Sin sesión'}</span>
            <em>Administración</em>
          </div>
        </div>
      </header>

      {showNote && (
        <p className="devsecops-mock-desc" role="status">
          Las variables viven en el entorno: VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY.
          Los documentos de verificación van al bucket verificacion-profesional después de aplicar la migración.
        </p>
      )}

      <div className="devsecops-kpi-row">
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><CheckCircle2 size={16} /> Pruebas</div>
          <strong>En CI</strong>
          <span className="devsecops-kpi-sub">Este panel no las ejecuta</span>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Shield size={16} /> Secretos</div>
          <strong>gitleaks</strong>
          <span className="devsecops-kpi-sub">Corre en GitHub Actions</span>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Database size={16} /> Supabase</div>
          <strong>{latency == null ? '—' : `${latency} ms`}</strong>
          <span className="devsecops-kpi-sub">
            {dbReachable === null ? 'Sin medición' : dbReachable ? 'Respuesta recibida' : 'Sin respuesta'}
          </span>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Activity size={16} /> Salud</div>
          <strong>{dbReachable === false ? 'Degradado' : dbReachable ? 'Alcanzable' : '…'}</strong>
          <span className="devsecops-kpi-sub">
            {supabaseConfigStatus.urlConfigured ? 'URL configurada' : 'Falta la URL'}
          </span>
        </div>
      </div>

      <div className="devsecops-grid">
        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><CheckCircle2 size={16} /> Suites del repositorio</h3>
            <span className="devsecops-panel-badge">No ejecutadas aquí</span>
          </div>
          <table className="devsecops-table">
            <thead>
              <tr>
                <th>Prueba</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              {TEST_SUITES.map((suite) => (
                <tr key={suite}>
                  <td>{suite}</td>
                  <td>Se corre en CI, no en este botón</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="devsecops-panel-foot">Actualizar solo vuelve a medir la latencia de Supabase.</p>
        </div>

        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><Database size={16} /> Telemetría</h3>
            <span className="devsecops-panel-badge">
              <span className="live-pill-dot" aria-hidden /> {dbReachable ? 'Responde' : 'Sin datos'}
            </span>
          </div>
          <div className="devsecops-telemetry-stats">
            <div><span>Latencia</span><strong>{latency == null ? '—' : `${latency} ms`}</strong></div>
            <div><span>Consulta</span><strong>perfiles.id</strong></div>
            <div><span>Error</span><strong>{dbReachable === false ? 'Sí' : 'No'}</strong></div>
            <div><span>Solicitudes/s</span><strong>—</strong></div>
          </div>
          <p className="devsecops-panel-foot">No hay un contador de tráfico en este cliente.</p>
        </div>

        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><FlaskConical size={16} /> Datos de ejemplo</h3>
          </div>
          <p className="devsecops-mock-desc">
            Este panel no inserta filas. Los seeds viven en las migraciones SQL.
          </p>
          <button type="button" className="btn-mock-generate" disabled>
            <FlaskConical size={18} /> Generar datos de ejemplo
          </button>
          <p className="devsecops-panel-foot">Botón desactivado a propósito.</p>
        </div>
      </div>

      <aside className="devsecops-sidebar-info card-surface">
        <div className="devsecops-demo-badge"><GraduationCap size={14} /> Operaciones</div>
        <p>Herramientas de operación</p>
        <div className="devsecops-env-card">
          <div><span className="live-pill-dot" aria-hidden /> Entorno: {import.meta.env.PROD ? 'Producción' : 'Desarrollo'}</div>
          <div>Panel interno My Works</div>
          <div className="devsecops-workspace-path">
            Workspace: myworksapp_desktop
            <button
              type="button"
              className="icon-btn icon-btn--sm"
              aria-label="Copiar"
              onClick={() => {
                void navigator.clipboard.writeText('myworksapp_desktop').then(() => {
                  setCopied(true);
                }).catch(() => setCopied(false));
              }}
            >
              <Copy size={12} />
            </button>
            {copied ? ' copiado' : ''}
          </div>
        </div>
      </aside>

      <footer className="devsecops-footer">
        My Works App · Panel operativo
        {!supabaseConfigStatus.urlConfigured && ' · Supabase URL no configurada'}
      </footer>
    </div>
  );
}
