import type { ConsoleRole } from '@myworksapp/shared';

/** Roles que pueden entrar a la consola de escritorio (BD ES). */
export const CONSOLE_ROLES: readonly ConsoleRole[] = ['administrador', 'soporte', 'qa'];

/** Permisos mínimos por rol. El servidor (RLS, RPC y Edge Functions) los vuelve a validar. */
export interface ConsolePermissions {
  /** Panel ejecutivo, métricas y pagos. */
  executive: boolean;
  /** Ver la cola de disputas. */
  supportQueue: boolean;
  /** Ver fotos de evidencia. */
  disputeEvidence: boolean;
  /** Dejar notas internas en una disputa. */
  disputeNotes: boolean;
  /** Liberar o devolver el pago retenido. */
  resolveDisputes: boolean;
  /** Controles de calidad y seguridad (solo lectura). */
  security: boolean;
  /** Invitaciones y equipo (RRHH). */
  people: boolean;
}

const NONE: ConsolePermissions = {
  executive: false,
  supportQueue: false,
  disputeEvidence: false,
  disputeNotes: false,
  resolveDisputes: false,
  security: false,
  people: false,
};

export function isConsoleRole(role: string): role is ConsoleRole {
  return (CONSOLE_ROLES as readonly string[]).includes(role);
}

/** Entran administrador, soporte y QA. Usuarios y profesionales no. */
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
      };
    case 'soporte':
      return { ...NONE, supportQueue: true, disputeEvidence: true, disputeNotes: true };
    case 'qa':
      return { ...NONE, supportQueue: true, security: true };
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
      return 'QA (solo lectura)';
    default:
      return 'Sin acceso';
  }
}

export const CONSOLE_ACCESS_DENIED =
  'Esta consola es para el equipo de MyWorksApp (administración, soporte o QA).';
