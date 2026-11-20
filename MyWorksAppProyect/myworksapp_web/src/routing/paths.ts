export type AppView =
  | 'landing'
  | 'categories'
  | 'search'
  | 'tracking'
  | 'paid'
  | 'profile'
  | 'account'
  | 'trabaja'
  | 'aviso'
  | 'terminos'
  | 'privacidad'
  | 'notfound';

function clean(pathname: string): string {
  if (pathname.length > 1 && pathname.endsWith('/')) return pathname.slice(0, -1);
  return pathname || '/';
}

export function viewFromPath(pathname: string): AppView {
  const path = clean(pathname);
  if (path === '/' || path === '/encuesta') return 'landing';
  if (path === '/servicios') return 'categories';
  if (path.startsWith('/servicios/')) return 'search';
  if (path.startsWith('/profesional/')) return 'profile';
  if (path.startsWith('/pedido/')) return 'tracking';
  if (path === '/pago/retorno') return 'paid';
  if (path === '/cuenta') return 'account';
  if (path === '/trabaja') return 'trabaja';
  if (path === '/aviso-legal') return 'aviso';
  if (path === '/terminos') return 'terminos';
  if (path === '/privacidad') return 'privacidad';
  return 'notfound';
}

export function categoryFromPath(pathname: string): string | null {
  const match = clean(pathname).match(/^\/servicios\/([^/]+)$/);
  return match ? decodeURIComponent(match[1]) : null;
}

export function recordIdFromPath(pathname: string, prefix: 'profesional' | 'pedido'): string | null {
  const match = clean(pathname).match(new RegExp(`^/${prefix}/([^/]+)$`));
  return match ? decodeURIComponent(match[1]) : null;
}

export function pathForView(
  view: AppView,
  ctx: { category?: string | null; jobId?: string | null } = {},
): string {
  if (view === 'landing') return '/';
  if (view === 'categories') return '/servicios';
  if (view === 'search') {
    return ctx.category ? `/servicios/${encodeURIComponent(ctx.category)}` : '/servicios';
  }
  if (view === 'tracking') {
    return ctx.jobId ? `/pedido/${encodeURIComponent(ctx.jobId)}` : '/';
  }
  if (view === 'paid') return '/pago/retorno';
  if (view === 'account') return '/cuenta';
  if (view === 'trabaja') return '/trabaja';
  if (view === 'aviso') return '/aviso-legal';
  if (view === 'terminos') return '/terminos';
  if (view === 'privacidad') return '/privacidad';
  return '/no-existe';
}
