import { useState, lazy, Suspense } from 'react';
import {
  LayoutGrid,
  Headset,
  Shield,
  Users,
  Bell,
  LogOut,
  UserCheck,
  SlidersHorizontal,
  Database,
  ChevronDown,
} from 'lucide-react';
import { ExecutiveWorkspace } from './components/ExecutiveWorkspace';
import { DesktopLoginScreen } from './components/DesktopLoginScreen';
import { SessionLoadingShell } from './components/LoadingState';
import { useAuth } from './context/AuthContext';

const SupportWorkspace = lazy(() =>
  import('./components/SupportWorkspace').then((m) => ({
    default: m.SupportWorkspace,
  })),
);
const DevSecOpsWorkspace = lazy(() =>
  import('./components/DevSecOpsWorkspace').then((m) => ({
    default: m.DevSecOpsWorkspace,
  })),
);
const HumanResourcesWorkspace = lazy(() =>
  import('./components/HumanResourcesWorkspace').then((m) => ({
    default: m.HumanResourcesWorkspace,
  })),
);

const NAV_ITEMS = [
  { id: 0, label: 'Panel ejecutivo', icon: LayoutGrid },
  { id: 1, label: 'Soporte y disputas', icon: Headset },
  { id: 2, label: 'DevSecOps', icon: Shield },
  { id: 3, label: 'RRHH', icon: Users },
] as const;

export function App() {
  const { profile, loading, logout } = useAuth();
  const [activeRoleWorkspace, setActiveRoleWorkspace] = useState<number>(0);

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
    .map((part: string) => part[0]?.toUpperCase() ?? '')
    .join('') || 'AD';

  return (
    <div className="desktop-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-icon" aria-hidden>
            <img src="/brand/mark.svg" alt="" width={28} height={28} />
          </div>
          <div>
            <h2 className="sidebar-brand-name">My Works App</h2>
            <span className="sidebar-brand-subtitle">Operación</span>
          </div>
        </div>

        <nav className="sidebar-nav" aria-label="Operaciones">
          {NAV_ITEMS.map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              type="button"
              className={`sidebar-nav-item${activeRoleWorkspace === id ? ' active' : ''}`}
              onClick={() => setActiveRoleWorkspace(id)}
            >
              <Icon size={18} strokeWidth={2} />
              <span>{label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-profile">
            <div className="sidebar-profile-avatar">{initials}</div>
            <div className="sidebar-profile-info">
              <div className="sidebar-profile-name">{profile.name}</div>
              <div className="sidebar-profile-role">Administración</div>
            </div>
            <ChevronDown size={16} className="sidebar-profile-chevron" aria-hidden />
          </div>
          <button type="button" className="sidebar-profile-btn">
            <UserCheck size={14} /> Ver perfil completo
          </button>
          <button
            type="button"
            className="sidebar-logout-btn"
            onClick={() => void logout()}
            title="Cerrar sesión"
          >
            <LogOut size={14} /> Cerrar sesión
          </button>
        </div>
      </aside>

      <main className="main-content">
        <div className={`workspace-pad page-enter${activeRoleWorkspace === 1 ? ' workspace-pad--flush' : ''}`}>
          <Suspense fallback={<SessionLoadingShell />}>
          {activeRoleWorkspace === 0 && (
            <ExecutiveWorkspace
              headerActions={(
                <div className="shell-actions">
                  <div className="live-pill">
                    <Database size={14} />
                    <span className="live-pill-dot" aria-hidden />
                    Supabase LIVE
                    <svg className="live-pill-wave" viewBox="0 0 24 12" aria-hidden>
                      <polyline points="0,8 4,4 8,8 12,2 16,6 20,3 24,6" fill="none" stroke="currentColor" strokeWidth="1.5" />
                    </svg>
                  </div>
                  <span className="shell-divider" aria-hidden />
                  <button type="button" className="icon-btn" aria-label="Notificaciones">
                    <Bell size={20} />
                  </button>
                  <button type="button" className="icon-btn" aria-label="Ajustes">
                    <SlidersHorizontal size={20} />
                  </button>
                </div>
              )}
            />
          )}
          {activeRoleWorkspace === 1 && <SupportWorkspace adminId={profile.id} />}
          {activeRoleWorkspace === 2 && <DevSecOpsWorkspace />}
          {activeRoleWorkspace === 3 && <HumanResourcesWorkspace />}
          </Suspense>
        </div>
      </main>
    </div>
  );
}

export default App;
