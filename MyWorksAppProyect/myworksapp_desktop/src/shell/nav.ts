import type { ConsolePermissions } from '../authAccess';

export interface NavItem {
  to: string;
  label: string;
  group: string;
  allow: (permissions: ConsolePermissions) => boolean;
}

export const NAV: NavItem[] = [
  { to: '/resumen', label: 'Inicio', group: 'Inicio', allow: () => true },
  { to: '/pedidos', label: 'Pedidos', group: 'Operación', allow: (p) => p.viewOrders },
  { to: '/disputas', label: 'Disputas', group: 'Operación', allow: (p) => p.supportQueue },
  { to: '/tickets', label: 'Tickets de soporte', group: 'Operación', allow: (p) => p.supportQueue },
  { to: '/reportes', label: 'Reportes y abuso', group: 'Operación', allow: (p) => p.viewPeople },
  { to: '/usuarios', label: 'Clientes', group: 'Personas', allow: (p) => p.viewPeople },
  { to: '/profesionales', label: 'Profesionales', group: 'Personas', allow: (p) => p.viewPeople },
  { to: '/pagos', label: 'Pagos y escrow', group: 'Dinero', allow: (p) => p.viewMoney },
  { to: '/liquidaciones', label: 'Liquidaciones', group: 'Dinero', allow: (p) => p.viewMoney },
  { to: '/reembolsos', label: 'Reembolsos', group: 'Dinero', allow: (p) => p.viewMoney },
  { to: '/conciliacion', label: 'Conciliación Transbank', group: 'Dinero', allow: (p) => p.viewMoney },
  { to: '/finanzas', label: 'Finanzas', group: 'Dinero', allow: (p) => p.executive },
  { to: '/resenas', label: 'Reseñas', group: 'Contenido', allow: (p) => p.viewPeople },
  { to: '/catalogo', label: 'Catálogo', group: 'Contenido', allow: (p) => p.manageCatalog },
  { to: '/notificaciones', label: 'Notificaciones', group: 'Contenido', allow: () => true },
  { to: '/equipo', label: 'Equipo y roles', group: 'Empresa', allow: (p) => p.people },
  { to: '/auditoria', label: 'Auditoría', group: 'Empresa', allow: (p) => p.viewAudit },
  { to: '/ajustes', label: 'Ajustes', group: 'Empresa', allow: (p) => p.manageCatalog },
  { to: '/seguridad', label: 'Seguridad', group: 'Sistema', allow: (p) => p.people },
  { to: '/salud', label: 'Salud y monitoreo', group: 'Sistema', allow: (p) => p.security },
  { to: '/errores', label: 'Errores de la app', group: 'Sistema', allow: (p) => p.viewErrors },
];
