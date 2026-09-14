import { useState, useEffect } from 'react';
import { Terminal, Shield, Cpu, Activity, Play, Command, Database, CheckCircle2, AlertTriangle, RefreshCw } from 'lucide-react';
import { supabase, supabaseConfigStatus } from '../supabaseClient';

interface LogEntry {
  id: string;
  timestamp: string;
  type: 'INFO' | 'WARN' | 'SECURITY' | 'TEST';
  message: string;
}

interface TestCase {
  id: string;
  name: string;
  category: 'Flutter App' | 'Vite Web' | 'Supabase DB' | 'Service Worker';
  status: 'IDLE' | 'RUNNING' | 'PASSED' | 'FAILED';
  durationMs: number;
}

export function DevSecOpsWorkspace() {
  const [activeTab, setActiveTab] = useState<number>(1);
  const [latency, setLatency] = useState<number | null>(null);
  const [dbReachable, setDbReachable] = useState<boolean | null>(null);
  const [commandOpen, setCommandOpen] = useState(false);
  const [commandInput, setCommandInput] = useState('');
  const [isRunningAllTests, setIsRunningAllTests] = useState(false);

  const [logs, setLogs] = useState<LogEntry[]>([
    { id: '1', timestamp: new Date().toLocaleTimeString(), type: 'INFO', message: 'Cliente Supabase inicializado (sin exponer URL ni claves en UI).' },
    { id: '2', timestamp: new Date().toLocaleTimeString(), type: 'SECURITY', message: 'RLS: estado real se valida en el proyecto Supabase, no en esta consola demo.' },
    { id: '3', timestamp: new Date().toLocaleTimeString(), type: 'TEST', message: 'Suite QA local: simulación UI — no ejecuta tests reales del repo.' },
  ]);

  const [testCases, setTestCases] = useState<TestCase[]>([
    { id: '1', name: 'App móvil: smoke login (simulado)', category: 'Flutter App', status: 'IDLE', durationMs: 0 },
    { id: '2', name: 'App móvil: flujo trabajo (simulado)', category: 'Flutter App', status: 'IDLE', durationMs: 0 },
    { id: '3', name: 'Web: build TypeScript (simulado)', category: 'Vite Web', status: 'IDLE', durationMs: 0 },
    { id: '4', name: 'Supabase: ping perfiles (real)', category: 'Supabase DB', status: 'IDLE', durationMs: 0 },
    { id: '5', name: 'Service Worker: cache (simulado)', category: 'Service Worker', status: 'IDLE', durationMs: 0 },
  ]);

  useEffect(() => {
    const testConnection = async () => {
      const start = Date.now();
      try {
        const { error } = await supabase.from('perfiles').select('id').limit(1);
        setLatency(Date.now() - start);
        setDbReachable(!error);
        if (error) {
          setLogs((prev) => [
            { id: Date.now().toString(), timestamp: new Date().toLocaleTimeString(), type: 'WARN', message: 'Ping a perfiles falló (permisos, red o env).' },
            ...prev,
          ]);
        }
      } catch {
        setDbReachable(false);
        setLatency(null);
      }
    };
    void testConnection();
  }, []);

  const runAllTests = () => {
    setIsRunningAllTests(true);
    setTestCases((prev) => prev.map((tc) => ({ ...tc, status: 'RUNNING' })));

    setTimeout(() => {
      setTestCases((prev) =>
        prev.map((tc) => ({
          ...tc,
          status: tc.category === 'Supabase DB' && dbReachable === false ? 'FAILED' : 'PASSED',
          durationMs: tc.category === 'Supabase DB' ? latency ?? 40 : 80 + Math.floor(Math.random() * 120),
        })),
      );
      setIsRunningAllTests(false);
      setLogs((prev) => [
        {
          id: Date.now().toString(),
          timestamp: new Date().toLocaleTimeString(),
          type: 'TEST',
          message: 'Suite demo completada (simulación UI; no es CI real).',
        },
        ...prev,
      ]);
    }, 1200);
  };

  const generateMockData = (type: 'DISPUTES' | 'JOBS' | 'WORKERS') => {
    let msg = '';
    if (type === 'DISPUTES') msg = 'Simulación local: 5 disputas de ejemplo (no se escribió en Supabase).';
    else if (type === 'JOBS') msg = 'Simulación local: 10 solicitudes de ejemplo (no se escribió en Supabase).';
    else msg = 'Simulación local: 3 expedientes de ejemplo (sin PII real).';

    setLogs((prev) => [
      { id: Date.now().toString(), timestamp: new Date().toLocaleTimeString(), type: 'INFO', message: msg },
      ...prev,
    ]);
  };

  const runCommand = () => {
    if (!commandInput.trim()) return;
    const newLog: LogEntry = {
      id: Date.now().toString(),
      timestamp: new Date().toLocaleTimeString(),
      type: 'SECURITY',
      message: `Comando demo (no ejecuta shell): ${commandInput}`,
    };
    setLogs((prev) => [newLog, ...prev]);
    setCommandInput('');
    setCommandOpen(false);
  };

  const envOk = supabaseConfigStatus.urlConfigured && supabaseConfigStatus.anonKeyConfigured;
  const healthLabel =
    dbReachable === null ? 'Comprobando…' : dbReachable ? `Alcanzable${latency != null ? ` (${latency} ms)` : ''}` : 'No alcanzable';

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '24px', gap: '16px', flexWrap: 'wrap' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            <h1 style={{ fontSize: '22px', fontWeight: 900 }}>DevSecOps y estado técnico</h1>
            <span className="demo-badge">DEMO</span>
          </div>
          <p style={{ fontSize: '13.5px', color: '#98989D', marginTop: '4px' }}>
            Consola académica: ping real a Supabase cuando hay sesión; el resto es simulación local sin secretos en pantalla.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button onClick={() => setCommandOpen(true)} className="btn-action-secondary" style={{ fontSize: '12.5px' }}>
            <Command size={14} /> Paleta de comandos
          </button>
          <button onClick={runAllTests} disabled={isRunningAllTests} className="btn-action-primary" style={{ fontSize: '12.5px' }}>
            {isRunningAllTests ? <RefreshCw size={14} className="spin" /> : <Play size={14} />}
            {isRunningAllTests ? 'Ejecutando…' : 'Correr suite demo'}
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card-3d" style={{ border: `1px solid ${dbReachable ? 'rgba(52, 199, 89, 0.4)' : 'rgba(255, 149, 0, 0.4)'}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: dbReachable ? '#34C759' : '#FF9500', marginBottom: '8px' }}>
            <Activity size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>SUPABASE</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: 900 }}>{healthLabel}</div>
          <span style={{ fontSize: '11px', color: '#98989D' }}>Ping a tabla perfiles (sin revelar host)</span>
        </div>

        <div className="card-3d" style={{ border: '1px solid rgba(0, 122, 255, 0.4)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#007AFF', marginBottom: '8px' }}>
            <Shield size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>RLS</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: 900 }}>Revisar en proyecto</div>
          <span style={{ fontSize: '11px', color: '#98989D' }}>No se audita RLS desde esta UI demo</span>
        </div>

        <div className="card-3d" style={{ border: '1px solid rgba(240, 120, 42, 0.4)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#F0782A', marginBottom: '8px' }}>
            <Cpu size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>QA LOCAL</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: 900 }}>Simulación UI</div>
          <span style={{ fontSize: '11px', color: '#98989D' }}>No sustituye CI / tests del repositorio</span>
        </div>
      </div>

      <div className="sub-tabs-bar" style={{ marginBottom: '20px' }}>
        <div className={`sub-tab-item ${activeTab === 1 ? 'active' : ''}`} onClick={() => setActiveTab(1)}>
          <Play size={15} /> Test runner (demo)
        </div>
        <div className={`sub-tab-item ${activeTab === 2 ? 'active' : ''}`} onClick={() => setActiveTab(2)}>
          <Database size={15} /> Generador mock
        </div>
        <div className={`sub-tab-item ${activeTab === 0 ? 'active' : ''}`} onClick={() => setActiveTab(0)}>
          <Terminal size={15} /> Telemetría ({logs.length})
        </div>
        <div className={`sub-tab-item ${activeTab === 3 ? 'active' : ''}`} onClick={() => setActiveTab(3)}>
          <Shield size={15} /> Entorno
        </div>
      </div>

      {activeTab === 1 && (
        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', gap: '12px', flexWrap: 'wrap' }}>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Runner de pruebas (demostración)</h3>
              <p style={{ fontSize: '12px', color: '#98989D' }}>Simula estados PASSED/FAILED en UI. Solo el ping a perfiles refleja conectividad real.</p>
            </div>
            <button onClick={runAllTests} disabled={isRunningAllTests} className="btn-action-success" style={{ fontSize: '12px' }}>
              Ejecutar suite demo
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {testCases.map((tc) => (
              <div key={tc.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 16px', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)', gap: '12px', flexWrap: 'wrap' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <CheckCircle2 size={18} color={tc.status === 'FAILED' ? '#FF3B30' : tc.status === 'PASSED' ? '#34C759' : '#98989D'} />
                  <div>
                    <div style={{ fontSize: '13.5px', fontWeight: 700 }}>{tc.name}</div>
                    <span style={{ fontSize: '11px', color: '#98989D' }}>Categoría: {tc.category}</span>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '11px', color: '#98989D', fontFamily: 'monospace' }}>{tc.durationMs ? `${tc.durationMs}ms` : '—'}</span>
                  <span className={`badge ${tc.status === 'FAILED' ? 'badge-error' : tc.status === 'PASSED' ? 'badge-success' : 'badge-warning'}`} style={{ fontSize: '11px' }}>
                    {tc.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 2 && (
        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Generador de datos ficticios</h3>
            <span className="demo-badge">DEMO</span>
          </div>
          <p style={{ fontSize: '12.5px', color: '#98989D', marginBottom: '20px' }}>
            Solo escribe en el log local de esta pantalla. No inyecta filas en Supabase.
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
            <button onClick={() => generateMockData('DISPUTES')} className="btn-action-primary" style={{ padding: '16px', flexDirection: 'column', gap: '6px' }}>
              <AlertTriangle size={22} />
              <span>Simular 5 disputas</span>
            </button>

            <button onClick={() => generateMockData('JOBS')} className="btn-action-success" style={{ padding: '16px', flexDirection: 'column', gap: '6px' }}>
              <Activity size={22} />
              <span>Simular 10 solicitudes</span>
            </button>

            <button onClick={() => generateMockData('WORKERS')} className="btn-action-secondary" style={{ padding: '16px', flexDirection: 'column', gap: '6px', color: '#007AFF', borderColor: '#007AFF' }}>
              <Shield size={22} />
              <span>Simular 3 trabajadores</span>
            </button>
          </div>
        </div>
      )}

      {activeTab === 0 && (
        <div className="card-3d" style={{ backgroundColor: '#090D16', border: '1px solid #1E2A3B', padding: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', borderBottom: '1px solid #1E2A3B', paddingBottom: '12px', gap: '8px', flexWrap: 'wrap' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#F5F5F7' }}>
              <Terminal size={18} color="#F0782A" />
              <span style={{ fontSize: '14px', fontWeight: 800, fontFamily: 'monospace' }}>Eventos locales</span>
            </div>
            <span style={{ fontSize: '11px', color: '#98989D', fontWeight: 700 }}>Sin fragmentos de claves ni URL de proyecto</span>
          </div>

          <div style={{ fontFamily: 'monospace', fontSize: '12.5px', height: '240px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {logs.map((log) => (
              <div key={log.id} style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', color: log.type === 'SECURITY' ? '#007AFF' : log.type === 'TEST' ? '#34C759' : log.type === 'WARN' ? '#FF9500' : '#F0782A' }}>
                <span style={{ color: '#6E6E73' }}>[{log.timestamp}]</span>
                <span style={{ fontWeight: 800 }}>[{log.type}]</span>
                <span style={{ color: '#F5F5F7' }}>{log.message}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 3 && (
        <div className="card-3d">
          <h3 style={{ fontSize: '16px', fontWeight: 800, marginBottom: '6px' }}>Estado del entorno</h3>
          <p style={{ fontSize: '12.5px', color: '#98989D', marginBottom: '18px' }}>
            Solo estado alto nivel. Las claves y la URL del proyecto no se muestran en la UI.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <div style={{ padding: '12px 16px', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '13px', gap: '12px', flexWrap: 'wrap' }}>
              <span style={{ fontWeight: 700 }}>VITE_SUPABASE_URL</span>
              <span style={{ fontWeight: 800, color: supabaseConfigStatus.urlConfigured ? '#34C759' : '#FF3B30' }}>
                {supabaseConfigStatus.urlConfigured ? 'Configurada' : 'No configurada'}
              </span>
            </div>
            <div style={{ padding: '12px 16px', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '13px', gap: '12px', flexWrap: 'wrap' }}>
              <span style={{ fontWeight: 700 }}>VITE_SUPABASE_ANON_KEY</span>
              <span style={{ fontWeight: 800, color: supabaseConfigStatus.anonKeyConfigured ? '#34C759' : '#FF3B30' }}>
                {supabaseConfigStatus.anonKeyConfigured ? 'Configurada' : 'No configurada'}
              </span>
            </div>
            <div style={{ padding: '12px 16px', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '13px', gap: '12px', flexWrap: 'wrap' }}>
              <span style={{ fontWeight: 700 }}>Cliente listo</span>
              <span className={`badge ${envOk ? 'badge-success' : 'badge-error'}`}>
                {envOk ? 'Variables presentes' : 'Faltan variables .env'}
              </span>
            </div>
            <div style={{ padding: '12px 16px', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '13px', gap: '12px', flexWrap: 'wrap' }}>
              <span style={{ fontWeight: 700 }}>Row Level Security</span>
              <span className="badge badge-warning">Validar en Supabase Dashboard</span>
            </div>
          </div>
        </div>
      )}

      {commandOpen && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', paddingTop: '100px', zIndex: 999 }}>
          <div style={{ maxWidth: '520px', width: '100%', backgroundColor: '#121826', border: '1px solid #1E2A3B', borderRadius: '16px', padding: '20px', color: 'white', boxShadow: '0 20px 40px rgba(0,0,0,0.5)', margin: '0 16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px', borderBottom: '1px solid #1E2A3B', paddingBottom: '12px' }}>
              <Command size={18} color="#F0782A" />
              <input
                type="text"
                value={commandInput}
                onChange={(e) => setCommandInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && runCommand()}
                placeholder="Comando demo (solo log local)…"
                style={{ width: '100%', background: 'none', border: 'none', color: 'white', outline: 'none', fontSize: '14px', fontFamily: 'monospace' }}
                autoFocus
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button onClick={() => setCommandOpen(false)} style={{ background: 'none', border: 'none', color: '#98989D', cursor: 'pointer', fontSize: '12px' }}>Cancelar</button>
              <button onClick={runCommand} className="btn-action-primary" style={{ padding: '6px 14px', fontSize: '12px' }}>Registrar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
