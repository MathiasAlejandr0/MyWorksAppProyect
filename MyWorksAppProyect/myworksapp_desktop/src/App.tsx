import { useEffect } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router';
import { DesktopLoginScreen } from './components/DesktopLoginScreen';
import { InvitePasswordScreen } from './components/InvitePasswordScreen';
import { AdminMfaGate } from './components/AdminMfaGate';
import { useAuth } from './context/auth-store';
import {
  AjustesPage,
  AuditoriaPage,
  CatalogoPage,
  ConciliacionPage,
  CuentaPage,
  DisputasPage,
  EquipoPage,
  ErroresPage,
  FinanzasPage,
  LiquidacionesPage,
  NotificacionesPage,
  PagosPage,
  PedidosPage,
  ProfesionalesPage,
  ReembolsosPage,
  ReportesPage,
  ResenasPage,
  ResumenPage,
  SaludPage,
  TicketsPage,
  UsuariosPage,
} from './features/screens';
import { isTauriRuntime } from './lib/redirect';
import { supabase, supabaseConfigStatus } from './supabaseClient';
import { Shell } from './shell/Shell';
import { RouteErrorBoundary } from './ui/boundary';
import { EmptyState } from './ui/kit';

function Gate() {
  const { profile, loading, needsMfa, mustSetPassword, finishPasswordSetup, logout } = useAuth();
  if (!supabaseConfigStatus.urlConfigured || !supabaseConfigStatus.anonKeyConfigured) {
    return <EmptyState title="Faltan las variables de Supabase" detail="Define VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY antes de abrir la consola." />;
  }
  if (loading) return <p className="muted">Cargando sesión…</p>;
  if (mustSetPassword) return <InvitePasswordScreen onSubmit={finishPasswordSetup} onCancel={logout} />;
  if (needsMfa) return <AdminMfaGate />;
  if (!profile) return <DesktopLoginScreen />;
  return (
    <Shell>
      <RouteErrorBoundary>
        <Routes>
          <Route path="/" element={<Navigate to="/resumen" replace />} />
          <Route path="/resumen" element={<ResumenPage />} />
          <Route path="/pedidos" element={<PedidosPage />} />
          <Route path="/pedidos/:id" element={<PedidosPage />} />
          <Route path="/disputas" element={<DisputasPage />} />
          <Route path="/tickets" element={<TicketsPage />} />
          <Route path="/reportes" element={<ReportesPage />} />
          <Route path="/usuarios" element={<UsuariosPage />} />
          <Route path="/usuarios/:id" element={<UsuariosPage />} />
          <Route path="/profesionales" element={<ProfesionalesPage />} />
          <Route path="/profesionales/:id" element={<ProfesionalesPage />} />
          <Route path="/pagos" element={<PagosPage />} />
          <Route path="/pagos/:id" element={<PagosPage />} />
          <Route path="/liquidaciones" element={<LiquidacionesPage />} />
          <Route path="/reembolsos" element={<ReembolsosPage />} />
          <Route path="/conciliacion" element={<ConciliacionPage />} />
          <Route path="/finanzas" element={<FinanzasPage />} />
          <Route path="/resenas" element={<ResenasPage />} />
          <Route path="/catalogo" element={<CatalogoPage />} />
          <Route path="/notificaciones" element={<NotificacionesPage />} />
          <Route path="/equipo" element={<EquipoPage />} />
          <Route path="/auditoria" element={<AuditoriaPage />} />
          <Route path="/ajustes" element={<AjustesPage />} />
          <Route path="/salud" element={<SaludPage />} />
          <Route path="/errores" element={<ErroresPage />} />
          <Route path="/cuenta" element={<CuentaPage />} />
          <Route path="*" element={<EmptyState title="Esta ruta no existe." />} />
        </Routes>
      </RouteErrorBoundary>
    </Shell>
  );
}

export default function App() {
  useEffect(() => {
    if (!isTauriRuntime()) return;
    void import('@tauri-apps/plugin-deep-link').then(async ({ onOpenUrl, getCurrent }) => {
      const handle = async (urls: string[]) => {
        const target = urls[0];
        if (!target) return;
        const url = new URL(target);
        const code = url.searchParams.get('code');
        if (code) await supabaseAuthExchange(code);
      };
      const current = await getCurrent();
      if (current?.length) await handle(current);
      await onOpenUrl((urls) => { void handle(urls); });
    }).catch(() => {
      // La versión web no tiene el plugin.
    });
  }, []);
  return (
    <BrowserRouter>
      <Gate />
    </BrowserRouter>
  );
}

async function supabaseAuthExchange(code: string): Promise<void> {
  await supabase.auth.exchangeCodeForSession(code);
}
