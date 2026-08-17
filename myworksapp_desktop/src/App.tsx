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
  UserCheck
} from 'lucide-react';
import { SupportWorkspace } from './components/SupportWorkspace';
import { ExecutiveWorkspace } from './components/ExecutiveWorkspace';
import { DevSecOpsWorkspace } from './components/DevSecOpsWorkspace';
import { HumanResourcesWorkspace } from './components/HumanResourcesWorkspace';
import { DesktopLoginScreen } from './components/DesktopLoginScreen';

export function App() {
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(true);
  const [userRole, setUserRole] = useState<'ADMIN' | 'SUPPORT' | 'DEVSECOPS'>('ADMIN');
  // 0: Soporte, 1: Ejecutivo/Admin, 2: DevSecOps & QA, 3: Recursos Humanos
  const [activeRoleWorkspace, setActiveRoleWorkspace] = useState<number>(1);

  const handleLogin = (role: 'ADMIN' | 'SUPPORT' | 'DEVSECOPS') => {
    setUserRole(role);
    setIsLoggedIn(true);
    if (role === 'SUPPORT') setActiveRoleWorkspace(0);
    else if (role === 'DEVSECOPS') setActiveRoleWorkspace(2);
    else setActiveRoleWorkspace(1);
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
  };

  if (!isLoggedIn) {
    return <DesktopLoginScreen onLogin={handleLogin} />;
  }

  return (
    <div className="desktop-layout">
      {/* 1. Sidebar de Escritorio con Selector de Workspace por Rol */}
      <aside className="sidebar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
          {/* Logo Idéntico a App Móvil: Casa + Herramienta */}
          <div style={{ position: 'relative', width: '38px', height: '38px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Home size={34} color="#FFFFFF" />
            <div style={{ position: 'absolute', bottom: '2px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Wrench size={14} color="#F0782A" />
            </div>
          </div>
          <div>
            <h2 style={{ fontSize: '15px', fontWeight: 800, color: '#FFFFFF', letterSpacing: '0.2px' }}>My Works App</h2>
            <span style={{ fontSize: '10px', color: '#F0782A', fontWeight: 800, backgroundColor: 'rgba(240,120,42,0.15)', padding: '2px 6px', borderRadius: '4px' }}>DESKTOP HUB v2.5</span>
          </div>
        </div>

        {/* Etiqueta de Workspace */}
        <div style={{ fontSize: '11px', fontWeight: 800, color: '#98989D', textTransform: 'uppercase', marginBottom: '12px', letterSpacing: '0.5px' }}>
          Paneles Disponibles:
        </div>

        {/* Selector de Navegación por Rol */}
        <div>
          {(userRole === 'ADMIN' || userRole === 'SUPPORT') && (
            <div 
              className={`sidebar-nav-item ${activeRoleWorkspace === 0 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(0)}
              style={{ justifyContent: 'space-between' }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <TicketCheck size={18} />
                <span>1. Soporte & Tickets</span>
              </div>
              <span style={{ backgroundColor: '#FF3B30', color: 'white', fontSize: '10px', fontWeight: 800, padding: '2px 6px', borderRadius: '10px' }}>2</span>
            </div>
          )}

          {userRole === 'ADMIN' && (
            <div 
              className={`sidebar-nav-item ${activeRoleWorkspace === 1 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(1)}
            >
              <Users size={18} />
              <span>2. Panel Ejecutivo</span>
            </div>
          )}

          {(userRole === 'ADMIN' || userRole === 'DEVSECOPS') && (
            <div 
              className={`sidebar-nav-item ${activeRoleWorkspace === 2 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(2)}
            >
              <Terminal size={18} />
              <span>3. DevSecOps & QA</span>
            </div>
          )}

          {userRole === 'ADMIN' && (
            <div 
              className={`sidebar-nav-item ${activeRoleWorkspace === 3 ? 'active' : ''}`}
              onClick={() => setActiveRoleWorkspace(3)}
            >
              <UserCheck size={18} />
              <span>4. Recursos Humanos (RRHH)</span>
            </div>
          )}
        </div>

        {/* Perfil del Operador & Cierre de Sesión */}
        <div style={{ marginTop: 'auto', paddingTop: '20px', borderTop: '1px solid rgba(255,255,255,0.08)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: userRole === 'ADMIN' ? '#F0782A' : userRole === 'SUPPORT' ? '#FF3B30' : '#007AFF', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: '12px' }}>
                {userRole === 'ADMIN' ? 'ADM' : userRole === 'SUPPORT' ? 'SOP' : 'DEV'}
              </div>
              <div>
                <div style={{ fontSize: '12px', fontWeight: 700, color: 'white' }}>
                  {userRole === 'ADMIN' ? 'Administrador General' : userRole === 'SUPPORT' ? 'Agente de Soporte' : 'DevSecOps Specialist'}
                </div>
                <div style={{ fontSize: '10px', color: '#34C759', fontWeight: 700 }}>● Sesión Activa</div>
              </div>
            </div>

            <button 
              onClick={handleLogout} 
              title="Cerrar Sesión Corporativa"
              style={{ background: 'rgba(255,59,48,0.15)', border: 'none', color: '#FF3B30', width: '30px', height: '30px', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      {/* 2. Área de Contenido Principal */}
      <main className="main-content">
        {/* Topbar de Escritorio */}
        <header className="topbar">
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <h1 style={{ fontSize: '18px', fontWeight: 800 }}>
              {activeRoleWorkspace === 0 && '🎧 Centro Completo de Soporte & Mediación de Disputas'}
              {activeRoleWorkspace === 1 && '👑 Panel Ejecutivo & Administración General'}
              {activeRoleWorkspace === 2 && '🛡️ DevSecOps, Auditoría RLS & QA completo'}
              {activeRoleWorkspace === 3 && '👥 Módulo de Recursos Humanos & Colaboradores'}
            </h1>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ position: 'relative', cursor: 'pointer' }}>
              <Bell size={20} color="#98989D" />
              <span style={{ position: 'absolute', top: '-2px', right: '-2px', width: '8px', height: '8px', backgroundColor: '#F0782A', borderRadius: '50%' }} />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', backgroundColor: 'rgba(255,255,255,0.05)', padding: '6px 12px', borderRadius: '20px', fontSize: '12px', fontWeight: 700 }}>
              <Shield size={14} color="#34C759" />
              <span>Modo Enterprise Protegido</span>
            </div>
          </div>
        </header>

        {/* 3. Renderizado del Workspace Activo por Categoría */}
        <div style={{ padding: '24px' }}>
          {activeRoleWorkspace === 0 && <SupportWorkspace />}
          {activeRoleWorkspace === 1 && <ExecutiveWorkspace />}
          {activeRoleWorkspace === 2 && <DevSecOpsWorkspace />}
          {activeRoleWorkspace === 3 && <HumanResourcesWorkspace />}
        </div>
      </main>
    </div>
  );
}

export default App;
