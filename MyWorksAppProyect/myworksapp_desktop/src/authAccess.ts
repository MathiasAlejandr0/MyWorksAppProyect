import type { ConsoleRole } from '@myworksapp/shared';

/** Roles que pueden entrar a la consola de escritorio (BD ES). */
export const CONSOLE_ROLES: readonly ConsoleRole[] = ['administrador', 'soporte', 'qa'];

/**
 * Permisos de la interfaz. El servidor (RLS, RPC y Edge Functions) los vuelve a validar.
 * Soporte ve personas y pedidos con datos sensibles enmascarados.
 */
export interface ConsolePermissions {
  /** KPI financieros de inicio y finanzas. */
  executive: boolean;
  supportQueue: boolean;
  disputeEvidence: boolean;
  disputeNotes: boolean;
  resolveDisputes: boolean;
  /** Salud del sistema, solo lectura. */
  security: boolean;
  /** Equipo, invitaciones y roles. */
  people: boolean;
  viewPeople: boolean;
  verifyPeople: boolean;
  viewOrders: boolean;
  interveneOrders: boolean;
  replyTickets: boolean;
  viewMoney: boolean;
  moderateReviews: boolean;
  proposeReviews: boolean;
  manageCatalog: boolean;
  viewErrors: boolean;
  viewAudit: boolean;
}

const NONE: ConsolePermissions = {
  executive: false,
  supportQueue: false,
  disputeEvidence: false,
  disputeNotes: false,
  resolveDisputes: false,
  security: false,
  people: false,
  viewPeople: false,
  verifyPeople: false,
  viewOrders: false,
  interveneOrders: false,
  replyTickets: false,
  viewMoney: false,
  moderateReviews: false,
  proposeReviews: false,
  manageCatalog: false,
  viewErrors: false,
  viewAudit: false,
};

export function isConsoleRole(role: string): role is ConsoleRole {
  return (CONSOLE_ROLES as readonly string[]).includes(role);
}

export function canAccessDesktopHub(role: string): boolean {
  return isConsoleRole(role);
}

export function consolePermissions(role: string): ConsolePermissions {
  switch (role) {
    case 'administrador':
      return {
        executive: true,
        supportQueue: true,
        disputeEvidence: true,
        disputeNotes: true,
        resolveDisputes: true,
        security: true,
        people: true,
        viewPeople: true,
        verifyPeople: true,
        viewOrders: true,
        interveneOrders: true,
        replyTickets: true,
        viewMoney: true,
        moderateReviews: true,
        proposeReviews: true,
        manageCatalog: true,
        viewErrors: true,
        viewAudit: true,
      };
    case 'soporte':
      return {
        ...NONE,
        supportQueue: true,
        disputeEvidence: true,
        disputeNotes: true,
        viewPeople: true,
        viewOrders: true,
        replyTickets: true,
        proposeReviews: true,
      };
    case 'qa':
      return {
        ...NONE,
        supportQueue: true,
        security: true,
        viewPeople: true,
        viewOrders: true,
        viewErrors: true,
      };
    default:
      return NONE;
  }
}

export function consoleRoleLabel(role: string): string {
  switch (role) {
    case 'administrador':
      return 'Administración';
    case 'soporte':
      return 'Soporte';
    case 'qa':
      return 'QA';
    default:
      return 'Sin acceso';
  }
}

export const CONSOLE_ACCESS_DENIED =
  'Esta consola es para el equipo de MyWorksApp (administración, soporte o QA).';

/** Matriz usada por las pruebas. true = la interfaz muestra la acción. */
export const PERMISSION_MATRIX: Record<ConsoleRole, ConsolePermissions> = {
  administrador: consolePermissions('administrador'),
  soporte: consolePermissions('soporte'),
  qa: consolePermissions('qa'),
};
