import type { LucideIcon } from 'lucide-react';
import {
  Activity,
  Bell,
  Bug,
  ClipboardList,
  Gavel,
  Home,
  Landmark,
  LayoutGrid,
  LifeBuoy,
  LineChart,
  Receipt,
  ScrollText,
  Settings,
  Shield,
  Star,
  Undo2,
  UserCog,
  Users,
  Wallet,
  Wrench,
} from 'lucide-react';
import type { ConsolePermissions } from '../authAccess';

export interface NavItem {
  to: string;
  label: string;
  group: string;
  icon: LucideIcon;
  allow: (permissions: ConsolePermissions) => boolean;
}

/**
 * Orden del trabajo real: el pedido, la disputa y el soporte;
 * después las personas; después el dinero en el orden en que se mueve
 * (cobro, conciliación, liquidación, reembolso, resumen);
 * al final el contenido, la empresa y el sistema.
 */
export const NAV: NavItem[] = [
  { to: '/resumen', label: 'Inicio', group: 'Inicio', icon: Home, allow: () => true },
  { to: '/pedidos', label: 'Pedidos', group: 'Operación', icon: ClipboardList, allow: (p) => p.viewOrders },
  { to: '/disputas', label: 'Disputas', group: 'Operación', icon: Gavel, allow: (p) => p.supportQueue },
  { to: '/tickets', label: 'Tickets de soporte', group: 'Operación', icon: LifeBuoy, allow: (p) => p.supportQueue },
  { to: '/reportes', label: 'Reportes y abuso', group: 'Operación', icon: Shield, allow: (p) => p.viewPeople },
  { to: '/usuarios', label: 'Clientes', group: 'Personas', icon: Users, allow: (p) => p.viewPeople },
  { to: '/profesionales', label: 'Profesionales', group: 'Personas', icon: Wrench, allow: (p) => p.viewPeople },
  { to: '/pagos', label: 'Pagos y escrow', group: 'Dinero', icon: Wallet, allow: (p) => p.viewMoney },
  { to: '/conciliacion', label: 'Conciliación Transbank', group: 'Dinero', icon: Receipt, allow: (p) => p.viewMoney },
  { to: '/liquidaciones', label: 'Liquidaciones', group: 'Dinero', icon: Landmark, allow: (p) => p.viewMoney },
  { to: '/reembolsos', label: 'Reembolsos', group: 'Dinero', icon: Undo2, allow: (p) => p.viewMoney },
  { to: '/finanzas', label: 'Finanzas', group: 'Dinero', icon: LineChart, allow: (p) => p.executive },
  { to: '/resenas', label: 'Reseñas', group: 'Contenido', icon: Star, allow: (p) => p.viewPeople },
  { to: '/catalogo', label: 'Catálogo', group: 'Contenido', icon: LayoutGrid, allow: (p) => p.manageCatalog },
  { to: '/notificaciones', label: 'Notificaciones', group: 'Contenido', icon: Bell, allow: () => true },
  { to: '/equipo', label: 'Equipo y roles', group: 'Empresa', icon: UserCog, allow: (p) => p.people },
  { to: '/auditoria', label: 'Auditoría', group: 'Empresa', icon: ScrollText, allow: (p) => p.viewAudit },
  { to: '/ajustes', label: 'Ajustes', group: 'Empresa', icon: Settings, allow: (p) => p.manageCatalog },
  { to: '/salud', label: 'Salud y monitoreo', group: 'Sistema', icon: Activity, allow: (p) => p.security },
  { to: '/errores', label: 'Errores de la app', group: 'Sistema', icon: Bug, allow: (p) => p.viewErrors },
];
