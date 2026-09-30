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
import { InvitePasswordScreen } from './components/InvitePasswordScreen';
import { AdminMfaGate } from './components/AdminMfaGate';
import { SessionLoadingShell } from './components/LoadingState';
import { AdminInboxPanel } from './components/AdminInboxPanel';
import { useAuth } from './context/AuthContext';
import { supabaseConfigStatus } from './supabaseClient';

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
  { id: 2, label: 'Seguridad', icon: Shield },
  { id: 3, label: 'RRHH', icon: Users },
] as const;

export function App() {
  const { profile, loading, logout, needsMfa, mustSetPassword, finishPasswordSetup } = useAuth();
  const [activeRoleWorkspace, setActiveRoleWorkspace] = useState<number>(0);
  const [showProfile, setShowProfile] = useState(false);
  const [showInbox, setShowInbox] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  if (loading) {
    return <SessionLoadingShell />;
  }

  if (mustSetPassword) {
    return (
      <InvitePasswordScreen
        onSubmit={finishPasswordSetup}
        onCancel={logout}
      />
    );
  }

  if (needsMfa) {
    return <AdminMfaGate />;
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
          <button type="button" className="sidebar-profile-btn" onClick={() => setShowProfile(true)}>
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
                  <button type="button" className="icon-btn" aria-label="Notificaciones" onClick={() => setShowInbox(true)}>
                    <Bell size={20} />
                  </button>
                  <button type="button" className="icon-btn" aria-label="Ajustes" onClick={() => setShowSettings(true)}>
                    <SlidersHorizontal size={20} />
                  </button>
                </div>
              )}
            />
          )}
          {activeRoleWorkspace === 1 && <SupportWorkspace adminId={profile.id} />}
          {activeRoleWorkspace === 2 && <DevSecOpsWorkspace operatorEmail={profile.email} />}
          {activeRoleWorkspace === 3 && (
            <HumanResourcesWorkspace onOpenNotifications={() => setShowInbox(true)} />
          )}
          </Suspense>
        </div>
      </main>
      {showInbox && (
        <AdminInboxPanel userId={profile.id} onClose={() => setShowInbox(false)} />
      )}
      {showSettings && (
        <div
          role="presentation"
          onClick={() => setShowSettings(false)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(8, 16, 32, 0.55)',
            display: 'grid',
            placeItems: 'center',
            zIndex: 40,
          }}
        >
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-settings-title"
            onClick={(event) => event.stopPropagation()}
            style={{
              background: '#0B1F3A',
              color: '#fff',
              padding: 24,
              borderRadius: 16,
              minWidth: 320,
              maxWidth: 460,
            }}
          >
            <h2 id="admin-settings-title" style={{ margin: '0 0 8px' }}>Ajustes de la sesión</h2>
            <p style={{ margin: '0 0 4px' }}>{profile.email}</p>
            <p style={{ margin: '0 0 8px' }}>Rol: {profile.role}</p>
            <p style={{ margin: '0 0 16px' }}>
              Supabase: {supabaseConfigStatus.urlConfigured ? 'URL configurada' : 'falta VITE_SUPABASE_URL'}.
              {' '}
              Clave publicable: {supabaseConfigStatus.anonKeyConfigured ? 'configurada' : 'falta VITE_SUPABASE_ANON_KEY'}.
            </p>
            <button type="button" className="sidebar-logout-btn" onClick={() => setShowSettings(false)}>
              Cerrar
            </button>
          </div>
        </div>
      )}
      {showProfile && (
        <div
          role="presentation"
          onClick={() => setShowProfile(false)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(8, 16, 32, 0.55)',
            display: 'grid',
            placeItems: 'center',
            zIndex: 40,
          }}
        >
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-profile-title"
            onClick={(event) => event.stopPropagation()}
            style={{
              background: '#0B1F3A',
              color: '#fff',
              padding: 24,
              borderRadius: 16,
              minWidth: 320,
              maxWidth: 420,
            }}
          >
            <h2 id="admin-profile-title" style={{ margin: '0 0 8px' }}>{profile.name}</h2>
            <p style={{ margin: '0 0 4px' }}>{profile.email}</p>
            <p style={{ margin: '0 0 16px', opacity: 0.8 }}>Rol: {profile.role}</p>
            <button type="button" className="sidebar-logout-btn" onClick={() => setShowProfile(false)}>
              Cerrar
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
