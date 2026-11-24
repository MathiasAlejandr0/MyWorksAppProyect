const CLP = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
  maximumFractionDigits: 0,
});

export function formatClp(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) return '—';
  return CLP.format(Math.round(value));
}

const DATE_TIME = new Intl.DateTimeFormat('es-CL', {
  timeZone: 'America/Santiago',
  dateStyle: 'short',
  timeStyle: 'short',
});

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return `${DATE_TIME.format(date)} CLT`;
}

const LABELS: Record<string, string> = {
  pendiente: 'Pendiente',
  respondido: 'Respondido',
  autorizado: 'Autorizado',
  retenido: 'Retenido',
  liberado: 'Liberado',
  reembolsado: 'Reembolsado',
  anulado: 'Anulado',
  fallido: 'Fallido',
  pagado_por_confirmar: 'Pagado por confirmar',
  ninguno: 'Sin pago',
  abierta: 'Abierta',
  en_revision: 'En revisión',
  requiere_humano: 'Requiere una persona',
  reembolso_pendiente: 'Reembolso pendiente',
  resuelta: 'Resuelta',
  verificado: 'Verificado',
  rechazado: 'Rechazado',
  activo: 'Activo',
  suspendido: 'Suspendido',
  bloqueado: 'Bloqueado',
  eliminado: 'Eliminado',
  usuario: 'Cliente',
  trabajador: 'Profesional',
  administrador: 'Administración',
  soporte: 'Soporte',
  qa: 'QA',
  principal: 'Pago principal',
  orden_cambio: 'Orden de cambio',
  vigente: 'Visible',
  excluida: 'Oculta',
  nuevo: 'Nuevo',
  reconocido: 'Revisado',
  resuelto: 'Resuelto',
  ignorado: 'Ignorado',
  descartado: 'Descartado',
  revisado: 'Revisado',
  aceptado: 'Aceptado',
  en_camino: 'En camino',
  en_curso: 'En curso',
  completado: 'Completado',
  cancelado: 'Cancelado',
  expirado: 'Expirado',
  no_asistio: 'No asistió',
  esperando_pago: 'Esperando pago',
  esperando_cotizaciones: 'Esperando cotizaciones',
  cotizacion_seleccionada: 'Cotización elegida',
  esperando_aprobacion_cliente: 'Esperando conformidad',
  pausado_orden_cambio: 'Pausado por orden de cambio',
  reembolsar: 'Devolver el pago',
  liberar: 'Liberar al profesional',
  manual: 'Transferencia manual',
  khipu: 'Khipu',
  fintoc: 'Fintoc',
};

export function statusLabel(value: string | null | undefined): string {
  if (!value) return 'Sin estado';
  return LABELS[value] ?? 'Estado no reconocido';
}

export function maskId(value: string | null | undefined): string {
  if (!value) return '—';
  if (value.length <= 8) return value;
  return `${value.slice(0, 4)}…${value.slice(-4)}`;
}

export function maskRut(value: string): string {
  const digits = value.replace(/\s/g, '');
  if (digits.length < 6) return '••••';
  return `${digits.slice(0, 2)}••••${digits.slice(-2)}`;
}

export function shortId(value: string): string {
  return value.length <= 8 ? value : value.slice(0, 8);
}
