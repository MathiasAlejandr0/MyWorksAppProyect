import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { NavLink, useNavigate } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import {
  Activity,
  AlertTriangle,
  BadgeCheck,
  BarChart3,
  Bell,
  Bug,
  ClipboardList,
  Home,
  Landmark,
  LifeBuoy,
  RefreshCw,
  Scale,
  ScrollText,
  Settings,
  Shield,
  Star,
  Tags,
  Users,
  Wallet,
  Wrench,
  type LucideIcon,
} from 'lucide-react';
import { consolePermissions, consoleRoleLabel } from '../authAccess';
import { useAuth } from '../context/auth-store';
import { idlePhase } from '../lib/idle';
import { applyTheme, savedTheme, setDensity, savedDensity, sharedDeviceEnabled } from '../lib/session';
import { supabase } from '../supabaseClient';
import { Dialog } from '../ui/kit';
import { NAV } from './nav';
import { PeriodoProvider, usePeriodo } from './periodo';

const ICONOS: Record<string, LucideIcon> = {
  Home,
  ClipboardList,
  Scale,
  Wallet,
  Star,
  Users,
  Wrench,
  BadgeCheck,
  LifeBuoy,
  Bell,
  Shield,
  BarChart3,
  ScrollText,
  Settings,
  Landmark,
  RefreshCw,
  AlertTriangle,
  Tags,
  Activity,
  Bug,
};

export function Shell({ children }: { children: ReactNode }) {
  return (
    <PeriodoProvider>
      <ShellFrame>{children}</ShellFrame>
    </PeriodoProvider>
  );
}

function ShellFrame({ children }: { children: ReactNode }) {
  const { profile, logout } = useAuth();
  const navigate = useNavigate();
  const { dias, fijarDias } = usePeriodo();
  const permissions = consolePermissions(profile?.role ?? '');
  const [menu, setMenu] = useState(false);
  const [palette, setPalette] = useState(false);
  const [query, setQuery] = useState('');
  const [idle, setIdle] = useState<'active' | 'warning' | 'expired'>('active');
  const [theme, setTheme] = useState(savedTheme);
  const [density, setDensityState] = useState(savedDensity);
  const [navOpen, setNavOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(localStorage.getItem('mwa-nav') === 'cerrada');
  const [vivo, setVivo] = useState(false);
  const letra = useRef('');

  useEffect(() => {
    let last = Date.now();
    const bump = () => {
      last = Date.now();
      setIdle('active');
    };
    const events = ['pointerdown', 'keydown'] as const;
    events.forEach((name) => window.addEventListener(name, bump));
    const timer = window.setInterval(() => {
      const phase = idlePhase(Date.now() - last);
      setIdle(phase);
      if (phase === 'expired') void logout();
    }, 15000);
    return () => {
      events.forEach((name) => window.removeEventListener(name, bump));
      window.clearInterval(timer);
    };
  }, [logout]);

  useEffect(() => {
    if (!sharedDeviceEnabled()) return;
    const close = () => { void logout(); };
    window.addEventListener('pagehide', close);
    return () => window.removeEventListener('pagehide', close);
  }, [logout]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      const escribe = target?.tagName === 'INPUT' || target?.tagName === 'TEXTAREA' || target?.isContentEditable;
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        setPalette(true);
        return;
      }
      if (escribe) return;
      if (event.key === '/') {
        event.preventDefault();
        const campo = document.querySelector<HTMLInputElement>('input[aria-label="Buscar en la tabla"]');
        if (campo) campo.focus();
        else setPalette(true);
        return;
      }
      if (event.key === 'Escape') {
        setPalette(false);
        return;
      }
      const tecla = event.key.toLowerCase();
      if (letra.current === 'g' && tecla === 'p') navigate('/pedidos');
      if (letra.current === 'g' && tecla === 'd') navigate('/disputas');
      letra.current = tecla === 'g' ? 'g' : '';
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [navigate]);

  useEffect(() => {
    const channel = supabase.channel('consola-presencia').subscribe((status) => {
      setVivo(status === 'SUBSCRIBED');
    });
    return () => { void supabase.removeChannel(channel); };
  }, []);

  const groups = useMemo(() => {
    const visible = NAV.filter((item) => item.allow(permissions));
    const order: string[] = [];
    for (const item of visible) if (!order.includes(item.group)) order.push(item.group);
    return order.map((group) => ({ group, items: visible.filter((item) => item.group === group) }));
  }, [permissions]);

  const search = useQuery({
    queryKey: ['buscar', query],
    enabled: palette && query.trim().length >= 2,
    queryFn: async () => {
      const { data, error } = await supabase.rpc('consola_buscar', { p_q: query.trim() });
      if (error) throw error;
      return data ?? [];
    },
  });

  const colas = useQuery({
    queryKey: ['badges', dias],
    queryFn: async () => {
      const hasta = new Date();
      const desde = new Date(hasta.getTime() - dias * 86_400_000);
      const { data, error } = await supabase.rpc('consola_resumen_periodo', {
        p_desde: desde.toISOString(),
        p_hasta: hasta.toISOString(),
      });
      if (error) throw error;
      const row = data as { colas?: Record<string, number | null> } | null;
      return row?.colas ?? {};
    },
  });

  const unread = useQuery({
    queryKey: ['notificaciones', profile?.id],
    enabled: Boolean(profile?.id),
    queryFn: async () => {
      const { count, error } = await supabase
        .from('notificaciones')
        .select('id', { count: 'exact', head: true })
        .eq('id_usuario', profile!.id)
        .eq('leido', 0);
      if (error) throw error;
      return count ?? 0;
    },
  });

  const badgeDe = (tipo?: 'disputas' | 'verificaciones' | 'seguridad') => {
    if (tipo === 'disputas') return colas.data?.disputas_abiertas ?? 0;
    if (tipo === 'verificaciones') return colas.data?.verificaciones_en_revision ?? 0;
    if (tipo === 'seguridad') return colas.data?.errores_nuevos ?? 0;
    return 0;
  };

  return (
    <div className={`shell${collapsed ? ' is-collapsed' : ''}`}>
      <a className="skip-link" href="#contenido">Saltar al contenido</a>
      <aside className={`side${navOpen ? ' is-open' : ''}`}>
        <NavLink to="/resumen" className="brand">
          <img src="/brand/mark.svg" alt="" />
          <strong>MyWorksApp</strong>
        </NavLink>
        <button
          type="button"
          className="btn btn-ghost"
          onClick={() => {
            const next = !collapsed;
            setCollapsed(next);
            localStorage.setItem('mwa-nav', next ? 'cerrada' : 'abierta');
          }}
        >
          {collapsed ? '»' : 'Contraer menú'}
        </button>
        {groups.map((group) => (
          <div key={group.group}>
            <div className="side-group">{group.group}</div>
            {group.items.map((item) => {
              const Icono = ICONOS[item.icon] ?? Home;
              const cuenta = badgeDe(item.badge);
              return (
                <NavLink key={item.to} to={item.to} className={({ isActive }) => `side-link${isActive ? ' is-active' : ''}`} onClick={() => setNavOpen(false)}>
                  <Icono size={16} aria-hidden />
                  <span>{item.label}</span>
                  {cuenta > 0 ? <span className="nav-badge">{cuenta}</span> : null}
                </NavLink>
              );
            })}
          </div>
        ))}
      </aside>
      <div className="workspace">
        <header className="topbar">
          <button type="button" className="icon-btn nav-toggle" aria-label="Abrir menú" aria-expanded={navOpen} onClick={() => setNavOpen((value) => !value)}>
            Menú
          </button>
          <button type="button" className="btn btn-secondary search" onClick={() => setPalette(true)}>
            Buscar clientes, trabajadores, pedidos o disputas · Ctrl K
          </button>
          <div className="row" role="group" aria-label="Rango de fechas">
            {[1, 7, 30, 90].map((value) => (
              <button key={value} type="button" className={`btn ${dias === value ? '' : 'btn-secondary'}`} onClick={() => fijarDias(value)}>
                {value === 1 ? '24 h' : `${value} d`}
              </button>
            ))}
          </div>
          <span className="live-dot" title={vivo ? 'Conectado en tiempo real' : 'Sin canal en tiempo real'} data-vivo={vivo ? 'si' : 'no'} />
          <button type="button" className="icon-btn" aria-label="Notificaciones" onClick={() => navigate('/notificaciones')}>
            <Bell size={16} aria-hidden /> {unread.data ? unread.data : '0'}
          </button>
          <div className="profile-slot">
            <button type="button" className="btn btn-secondary" onClick={() => setMenu((value) => !value)}>
              {profile?.name} · {consoleRoleLabel(profile?.role ?? '')}
            </button>
            {menu ? (
              <div className="menu" role="menu">
                <button type="button" className="btn btn-ghost" onClick={() => { setMenu(false); navigate('/cuenta'); }}>Mi cuenta</button>
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={() => {
                    const next = theme === 'dark' ? 'light' : 'dark';
                    setTheme(next);
                    applyTheme(next);
                  }}
                >
                  Tema {theme === 'dark' ? 'claro' : 'oscuro'}
                </button>
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={() => {
                    const next = density === 'comoda' ? 'compacta' : 'comoda';
                    setDensityState(next);
                    setDensity(next);
                  }}
                >
                  Densidad {density === 'comoda' ? 'compacta' : 'cómoda'}
                </button>
                <button type="button" className="btn btn-ghost" onClick={() => void logout()}>Cerrar sesión</button>
              </div>
            ) : null}
          </div>
        </header>
        {idle === 'warning' ? (
          <p className="warn-banner" role="status">
            La sesión se cerrará por inactividad en menos de 2 minutos. Mueve el cursor o usa el teclado para seguir.
          </p>
        ) : null}
        <main id="contenido" className="content">{children}</main>
      </div>
      {palette ? (
        <Dialog title="Buscar" onClose={() => setPalette(false)}>
          <label className="field">
            <span>Nombre, correo, identificador o texto</span>
            <input autoFocus value={query} onChange={(event) => setQuery(event.target.value)} />
          </label>
          {search.isError ? <p>No se pudo buscar. Revisa la conexión e inténtalo de nuevo.</p> : null}
          <ul className="timeline">
            {(search.data ?? []).map((hit) => (
              <li key={`${hit.tipo}-${hit.id}`}>
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={() => {
                    setPalette(false);
                    navigate(hit.ruta);
                  }}
                >
                  {hit.titulo} · {hit.detalle}
                </button>
              </li>
            ))}
          </ul>
          {query.trim().length >= 2 && search.data?.length === 0 ? <p className="muted">Sin resultados. Prueba con otro nombre o identificador.</p> : null}
        </Dialog>
      ) : null}
    </div>
  );
}
