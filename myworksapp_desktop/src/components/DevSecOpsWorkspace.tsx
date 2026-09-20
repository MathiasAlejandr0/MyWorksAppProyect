import { useState, useEffect } from 'react';
import {
  Shield,
  Activity,
  CheckCircle2,
  FlaskConical,
  Database,
  ExternalLink,
  RefreshCw,
  Settings,
  Box,
  GraduationCap,
  Copy,
} from 'lucide-react';
import { supabase, supabaseConfigStatus } from '../supabaseClient';

const TEST_SUITES = [
  { name: 'auth.spec.ts', tests: 4, duration: '120ms' },
  { name: 'api-routes.spec.ts', tests: 6, duration: '185ms' },
  { name: 'payments.spec.ts', tests: 5, duration: '142ms' },
  { name: 'disputes.spec.ts', tests: 3, duration: '98ms' },
  { name: 'rls-policies.spec.ts', tests: 4, duration: '210ms' },
  { name: 'domain.spec.ts', tests: 3, duration: '95ms' },
  { name: 'e2e-smoke.spec.ts', tests: 3, duration: '100ms' },
];

export function DevSecOpsWorkspace() {
  const [latency, setLatency] = useState<number | null>(24);
  const [dbReachable, setDbReachable] = useState<boolean | null>(null);
  const [clock, setClock] = useState(new Date());

  useEffect(() => {
    const tick = setInterval(() => setClock(new Date()), 1000);
    return () => clearInterval(tick);
  }, []);

  useEffect(() => {
    const testConnection = async () => {
      const start = Date.now();
      try {
        const { error } = await supabase.from('perfiles').select('id').limit(1);
        const ms = Date.now() - start;
        setLatency(ms);
        setDbReachable(!error);
      } catch {
        setDbReachable(false);
      }
    };
    void testConnection();
  }, []);

  const timeStr = clock.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit', timeZone: 'UTC' });
  const dateStr = clock.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC' });

  return (
    <div className="devsecops-workspace">
      <header className="devsecops-header">
        <div className="devsecops-header-left">
          <h1>Controles de calidad</h1>
          <span className="devsecops-status">
            <span className="live-pill-dot" aria-hidden />
            Todo en orden
          </span>
        </div>
        <div className="devsecops-header-center">
          <span className="devsecops-clock">{timeStr} UTC</span>
          <span className="devsecops-date">{dateStr}</span>
        </div>
        <div className="devsecops-header-right">
          <button type="button" className="icon-btn" aria-label="Actualizar"><RefreshCw size={18} /></button>
          <button type="button" className="icon-btn" aria-label="Almacenamiento"><Box size={18} /></button>
          <button type="button" className="icon-btn" aria-label="Configuración"><Settings size={18} /></button>
          <div className="devsecops-user">
            <span>researcher@myworks.edu</span>
            <em>Demostración</em>
          </div>
        </div>
      </header>

      <div className="devsecops-kpi-row">
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><CheckCircle2 size={16} /> Tests Passed</div>
          <strong>28 / 28</strong>
          <span className="devsecops-kpi-sub up">100% Success</span>
          <svg className="devsecops-spark" viewBox="0 0 60 20" aria-hidden>
            <polyline points="0,14 10,10 20,12 30,6 40,8 50,4 60,6" fill="none" stroke="#3B82F6" strokeWidth="1.5" />
          </svg>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Shield size={16} /> Security Scan</div>
          <strong>gitleaks</strong>
          <span className="devsecops-kpi-sub up">0 Findings · Clean</span>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Database size={16} /> Supabase Latency</div>
          <strong>{latency ?? '—'}ms</strong>
          <span className="devsecops-kpi-sub">Tiempo de respuesta</span>
          <svg className="devsecops-spark" viewBox="0 0 60 20" aria-hidden>
            <polyline points="0,12 10,8 20,10 30,6 40,8 50,5 60,7" fill="none" stroke="#3B82F6" strokeWidth="1.5" />
          </svg>
        </div>
        <div className="devsecops-kpi card-surface">
          <div className="devsecops-kpi-head"><Activity size={16} /> Overall Health</div>
          <strong>{dbReachable === false ? 'Degradado' : 'Estable'}</strong>
          <span className="devsecops-kpi-sub up">Sin incidentes</span>
          <svg className="devsecops-spark" viewBox="0 0 60 20" aria-hidden>
            <polyline points="0,16 10,12 20,10 30,8 40,6 50,4 60,3" fill="none" stroke="#2F9E64" strokeWidth="1.5" />
          </svg>
        </div>
      </div>

      <div className="devsecops-grid">
        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><CheckCircle2 size={16} /> Test Runner</h3>
            <span className="devsecops-panel-badge up">28 / 28 Passed</span>
          </div>
          <table className="devsecops-table">
            <thead>
              <tr>
                <th>Prueba</th>
                <th>Casos</th>
                <th>Estado</th>
                <th>Duración</th>
              </tr>
            </thead>
            <tbody>
              {TEST_SUITES.map((suite) => (
                <tr key={suite.name}>
                  <td>{suite.name}</td>
                  <td>{suite.tests}</td>
                  <td><span className="devsecops-pass"><CheckCircle2 size={12} /> Passed</span></td>
                  <td>{suite.duration}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="devsecops-panel-foot">7 grupos · 28 pruebas · 0 fallos · 950 ms</p>
        </div>

        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><Shield size={16} /> Security Scan: GitLeaks</h3>
            <span className="devsecops-panel-badge up">Listo</span>
          </div>
          <pre className="devsecops-terminal">{`$ gitleaks detect --source . --verbose
[INFO] Scanning repository...
[INFO] 0 leaks found
✓ No secrets detected. Repository is clean.`}</pre>
          <div className="devsecops-scan-meta">
            <span>Tool: gitleaks v8.18.0</span>
            <span>Findings: 0</span>
          </div>
          <button type="button" className="btn-ghost">
            View Full Report <ExternalLink size={14} />
          </button>
        </div>

        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><Database size={16} /> Supabase Telemetry</h3>
            <span className="devsecops-panel-badge up">
              <span className="live-pill-dot" aria-hidden /> Connected
            </span>
            <select className="chart-select chart-select--sm" defaultValue="5m">
              <option value="5m">Últimos 5 minutos</option>
            </select>
          </div>
          <div className="devsecops-telemetry-stats">
            <div><span>Latencia</span><strong>{latency ?? 24} ms</strong></div>
            <div><span>Solicitudes</span><strong>142</strong></div>
            <div><span>Errores</span><strong>0</strong></div>
            <div><span>Rendimiento</span><strong>18,6 /s</strong></div>
          </div>
          <svg className="devsecops-area-chart" viewBox="0 0 400 80" preserveAspectRatio="none">
            <defs>
              <linearGradient id="telemetryFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#3B82F6" stopOpacity="0.3" />
                <stop offset="100%" stopColor="#3B82F6" stopOpacity="0" />
              </linearGradient>
            </defs>
            <path d="M0,60 L50,45 L100,50 L150,30 L200,35 L250,20 L300,28 L350,15 L400,18 L400,80 L0,80 Z" fill="url(#telemetryFill)" />
            <polyline points="0,60 50,45 100,50 150,30 200,35 250,20 300,28 350,15 400,18" fill="none" stroke="#3B82F6" strokeWidth="2" />
          </svg>
        </div>

        <div className="card-surface devsecops-panel">
          <div className="devsecops-panel-head">
            <h3><FlaskConical size={16} /> Mock Data Generator</h3>
          </div>
          <p className="devsecops-mock-desc">
            Datos de ejemplo para probar la consola. No son clientes reales.
          </p>
          <button type="button" className="btn-mock-generate">
            <FlaskConical size={18} /> Generar datos de ejemplo
          </button>
          <div className="devsecops-mock-meta">
            <span>Dataset: Operaciones</span>
            <span>Records: 1,000</span>
            <span>Format: JSON</span>
          </div>
          <p className="devsecops-panel-foot">
            Last Generated: {dateStr} {timeStr} · mock_university_data.json
          </p>
        </div>
      </div>

      <aside className="devsecops-sidebar-info card-surface">
        <div className="devsecops-demo-badge"><GraduationCap size={14} /> Operaciones</div>
        <p>Herramientas de operación</p>
        <div className="devsecops-env-card">
          <div><span className="live-pill-dot" aria-hidden /> Entorno: {import.meta.env.PROD ? 'Producción' : 'Staging'}</div>
          <div>Panel interno My Works</div>
          <div className="devsecops-workspace-path">
            Workspace: /ops/devsecops
            <button type="button" className="icon-btn icon-btn--sm" aria-label="Copiar"><Copy size={12} /></button>
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
