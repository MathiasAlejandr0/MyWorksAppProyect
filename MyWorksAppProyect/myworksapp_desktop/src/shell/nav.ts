import type { ConsolePermissions } from '../authAccess';

export interface NavItem {
  to: string;
  label: string;
  group: string;
  icon: string;
  badge?: 'disputas' | 'verificaciones' | 'seguridad';
  allow: (permissions: ConsolePermissions) => boolean;
}

export const NAV: NavItem[] = [
  { to: '/resumen', label: 'Inicio', group: 'General', icon: 'Home', allow: () => true },
  { to: '/pedidos', label: 'Pedidos', group: 'Operación', icon: 'ClipboardList', allow: (p) => p.viewOrders },
  { to: '/disputas', label: 'Disputas', group: 'Operación', icon: 'Scale', badge: 'disputas', allow: (p) => p.supportQueue },
  { to: '/pagos', label: 'Pagos y comisiones', group: 'Operación', icon: 'Wallet', allow: (p) => p.viewMoney },
  { to: '/resenas', label: 'Reseñas', group: 'Operación', icon: 'Star', allow: (p) => p.viewPeople },
  { to: '/usuarios', label: 'Clientes', group: 'Personas', icon: 'Users', allow: (p) => p.viewPeople },
  { to: '/profesionales', label: 'Trabajadores', group: 'Personas', icon: 'Wrench', allow: (p) => p.viewPeople },
  { to: '/verificaciones', label: 'Verificaciones', group: 'Personas', icon: 'BadgeCheck', badge: 'verificaciones', allow: (p) => p.viewPeople },
  { to: '/tickets', label: 'Soporte y moderación', group: 'Comunicación', icon: 'LifeBuoy', allow: (p) => p.supportQueue },
  { to: '/notificaciones', label: 'Notificaciones', group: 'Comunicación', icon: 'Bell', allow: () => true },
  { to: '/seguridad', label: 'Seguridad', group: 'Control', icon: 'Shield', badge: 'seguridad', allow: (p) => p.people },
  { to: '/informes', label: 'Reportes', group: 'Control', icon: 'BarChart3', allow: (p) => p.executive },
  { to: '/auditoria', label: 'Auditoría', group: 'Control', icon: 'ScrollText', allow: (p) => p.viewAudit },
  { to: '/ajustes', label: 'Configuración', group: 'Control', icon: 'Settings', allow: (p) => p.manageCatalog },
  { to: '/liquidaciones', label: 'Liquidaciones', group: 'Operación', icon: 'Landmark', allow: (p) => p.viewMoney },
  { to: '/reembolsos', label: 'Reembolsos', group: 'Operación', icon: 'RefreshCw', allow: (p) => p.viewMoney },
  { to: '/conciliacion', label: 'Conciliación', group: 'Operación', icon: 'Scale', allow: (p) => p.viewMoney },
  { to: '/finanzas', label: 'Finanzas', group: 'Operación', icon: 'BarChart3', allow: (p) => p.executive },
  { to: '/reportes', label: 'Reportes de abuso', group: 'Comunicación', icon: 'AlertTriangle', allow: (p) => p.viewPeople },
  { to: '/catalogo', label: 'Catálogo', group: 'Control', icon: 'Tags', allow: (p) => p.manageCatalog },
  { to: '/equipo', label: 'Equipo y roles', group: 'Control', icon: 'Users', allow: (p) => p.people },
  { to: '/salud', label: 'Salud del servicio', group: 'Control', icon: 'Activity', allow: (p) => p.security },
  { to: '/errores', label: 'Errores de la app', group: 'Control', icon: 'Bug', allow: (p) => p.viewErrors },
  { to: '/sistema-diseno', label: 'Sistema de diseño', group: 'General', icon: 'Tags', allow: () => true },
];
