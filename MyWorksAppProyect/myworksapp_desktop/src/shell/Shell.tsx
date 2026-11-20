import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { NavLink, useNavigate } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { consolePermissions, consoleRoleLabel } from '../authAccess';
import { useAuth } from '../context/auth-store';
import { idlePhase } from '../lib/idle';
import { applyTheme, savedTheme, sharedDeviceEnabled } from '../lib/session';
import { supabase } from '../supabaseClient';
import { Dialog } from '../ui/kit';
import { NAV } from './nav';

export function Shell({ children }: { children: ReactNode }) {
  const { profile, logout } = useAuth();
  const navigate = useNavigate();
  const permissions = consolePermissions(profile?.role ?? '');
  const [menu, setMenu] = useState(false);
  const [palette, setPalette] = useState(false);
  const [query, setQuery] = useState('');
  const [idle, setIdle] = useState<'active' | 'warning' | 'expired'>('active');
  const [theme, setTheme] = useState(savedTheme);

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
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        setPalette(true);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
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

  return (
    <div className="shell">
      <aside className="side">
        <NavLink to="/resumen" className="brand">
          <img src="/brand/mark.svg" alt="" />
          <strong>MyWorksApp</strong>
        </NavLink>
        {groups.map((group) => (
          <div key={group.group}>
            <div className="side-group">{group.group}</div>
            {group.items.map((item) => (
              <NavLink key={item.to} to={item.to} className={({ isActive }) => `side-link${isActive ? ' is-active' : ''}`}>
                <span>{item.label}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </aside>
      <div className="workspace">
        <header className="topbar">
          <button type="button" className="btn btn-secondary search" onClick={() => setPalette(true)}>
            Buscar personas, pedidos, pagos o disputas · Ctrl K
          </button>
          <button type="button" className="icon-btn" aria-label="Notificaciones" onClick={() => navigate('/notificaciones')}>
            {unread.data ? unread.data : '0'}
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
        <main className="content">{children}</main>
      </div>
      {palette ? (
        <Dialog title="Buscar" onClose={() => setPalette(false)}>
          <label className="field">
            <span>Nombre, correo, identificador o texto</span>
            <input autoFocus value={query} onChange={(event) => setQuery(event.target.value)} />
          </label>
          {search.isError ? <p>No se pudo buscar.</p> : null}
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
          {query.trim().length >= 2 && search.data?.length === 0 ? <p className="muted">Sin resultados.</p> : null}
        </Dialog>
      ) : null}
    </div>
  );
}
