import { useState } from 'react';
import {
  TicketCheck,
  Users,
  Shield,
  Home,
  Wrench,
  Terminal,
  Bell,
  LogOut,
  UserCheck,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';
import { SupportWorkspace } from './components/SupportWorkspace';
import { ExecutiveWorkspace } from './components/ExecutiveWorkspace';
import { DevSecOpsWorkspace } from './components/DevSecOpsWorkspace';
import { HumanResourcesWorkspace } from './components/HumanResourcesWorkspace';
import { DesktopLoginScreen } from './components/DesktopLoginScreen';
import { SessionLoadingShell } from './components/LoadingState';
import { useAuth } from './context/AuthContext';

export function App() {
  const { profile, loading, logout } = useAuth();
  /** 0 = ejecutivo (landing ops), 1 = soporte, 2/3 = demos */
  const [activeRoleWorkspace, setActiveRoleWorkspace] = useState<number>(0);
  const [demosOpen, setDemosOpen] = useState(false);

  if (loading) {
    return <SessionLoadingShell />;
  }

  if (!profile) {
    return <DesktopLoginScreen />;
  }

  const initials = profile.name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('') || 'AD';

  const isDemoWorkspace = activeRoleWorkspace >= 2;

  return (
    <div className="desktop-layout">
      <aside className="sidebar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
          <div style={{ position: 'relative', width: '38px', height: '38px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Home size={34} color="#FFFFFF" />
            <div style={{ position: 'absolute', bottom: '2px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Wrench size={14} color="#F0782A" />
            </div>
          </div>
          <div>
            <h2 style={{ fontSize: '15px', fontWeight: 800, color: '#FFFFFF', letterSpacing: '0.2px' }}>My Works App</h2>
            <span style={{ fontSize: '10px', color: '#F0782A', fontWeight: 800, backgroundColor: 'rgba(240,120,42,0.15)', padding: '2px 6px', borderRadius: '4px' }}>
              Consola ops
            </span>
          </div>
        </div>

        <div style={{ fontSize: '11px', fontWeight: 800, color: '#98989D', textTransform: 'uppercase', marginBottom: '12px', letterSpacing: '0.5px' }}>
          Operaciones
        </div>

        <div>
          <div
            className={`sidebar-nav-item ${activeRoleWorkspace === 0 ? 'active' : ''}`}
            onClick={() => setActiveRoleWorkspace(0)}
          >
            <Users size={18} />
            <span>Panel ejecutivo</span>
          </div>

          <div
            className={`sidebar-nav-item ${activeRoleWorkspace === 1 ? 'active' : ''}`}
            onClick={() => setActiveRoleWorkspace(1)}
            style={{ justifyContent: 'space-between' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <TicketCheck size={18} />
              <span>Soporte y disputas</span>
            </div>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setDemosOpen((v) => !v)}
          style={{
            marginTop: 20,
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'transparent',
            border: 'none',
            color: '#98989D',
            fontSize: 11,
            fontWeight: 800,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            cursor: 'pointer',
            padding: '4px 2px',
          }}
        >
          <span>Herramientas de demostración</span>
          {demosOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
        </button>

        {demosOpen && (
          <div style={{ marginTop: 8 }}>
            <div
              className={`sidebar-nav-item ${activeRoleWorkspace === 2 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(2)}
            >
              <Terminal size={18} />
              <span>DevSecOps</span>
            </div>

            <div
              className={`sidebar-nav-item ${activeRoleWorkspace === 3 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(3)}
            >
              <UserCheck size={18} />
              <span>RRHH</span>
            </div>
          </div>
        )}

        <div style={{ marginTop: 'auto', paddingTop: '20px', borderTop: '1px solid rgba(255,255,255,0.08)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', minWidth: 0 }}>
              <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: '#F0782A', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: '12px', flexShrink: 0 }}>
                {initials}
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: 'white', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{profile.name}</div>
                <div style={{ fontSize: '10px', color: '#34C759', fontWeight: 700 }}>administrador</div>
              </div>
            </div>

            <button
              onClick={() => void logout()}
              title="Cerrar sesión"
              style={{ background: 'rgba(255,59,48,0.15)', border: 'none', color: '#FF3B30', width: '30px', height: '30px', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', minWidth: 0 }}>
            <h1 style={{ fontSize: '17px', fontWeight: 800, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {activeRoleWorkspace === 0 && 'Panel ejecutivo'}
              {activeRoleWorkspace === 1 && 'Centro de soporte y disputas'}
              {activeRoleWorkspace === 2 && 'DevSecOps (demo académica)'}
              {activeRoleWorkspace === 3 && 'RRHH (demo académica)'}
            </h1>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexShrink: 0 }}>
            <div style={{ position: 'relative', cursor: 'default' }} title="Sin bandeja en vivo aún">
              <Bell size={20} color="#98989D" />
            </div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                backgroundColor: isDemoWorkspace ? 'rgba(240,120,42,0.12)' : 'rgba(52,199,89,0.12)',
                padding: '6px 12px',
                borderRadius: '8px',
                fontSize: '11px',
                fontWeight: 700,
                color: isDemoWorkspace ? '#F0782A' : '#34C759',
              }}
            >
              <Shield size={14} color={isDemoWorkspace ? '#F0782A' : '#34C759'} />
              <span>{isDemoWorkspace ? 'Modo demostración académica' : 'Datos en vivo (Supabase)'}</span>
            </div>
          </div>
        </header>

        <div className="workspace-pad page-enter">
          {activeRoleWorkspace === 0 && <ExecutiveWorkspace />}
          {activeRoleWorkspace === 1 && <SupportWorkspace adminId={profile.id} />}
          {activeRoleWorkspace === 2 && <DevSecOpsWorkspace />}
          {activeRoleWorkspace === 3 && <HumanResourcesWorkspace />}
        </div>
      </main>
    </div>
  );
}

export default App;
