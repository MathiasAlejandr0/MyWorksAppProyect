export const PAGE_SIZE = 25;
export const MAX_EXPORT_PAGES = 400;

export interface PageResult<T> {
  rows: T[];
  total: number;
}

export interface OrderSpec {
  column: string;
  ascending: boolean;
  tie: string;
}

/** Orden estable: la columna de desempate es única, así range() no repite ni salta filas. */
export const LIST_ORDERS = {
  trabajos: { column: 'creado_en', ascending: false, tie: 'id' },
  tickets_soporte: { column: 'creado_en', ascending: false, tie: 'id' },
  reportes: { column: 'creado_en', ascending: false, tie: 'id' },
  calificaciones: { column: 'creado_en', ascending: false, tie: 'id' },
  servicios: { column: 'nombre', ascending: true, tie: 'id' },
  registros_error_app: { column: 'creado_en', ascending: false, tie: 'id' },
  perfiles: { column: 'creado_en', ascending: false, tie: 'id' },
  trabajadores: { column: 'calificacion', ascending: false, tie: 'id_usuario' },
  cobros_profesional: { column: 'creado_en', ascending: false, tie: 'id_pago' },
  pagos: { column: 'reembolsado_en', ascending: false, tie: 'id' },
  auditoria_consola: { column: 'creado_en', ascending: false, tie: 'id' },
} as const satisfies Record<string, OrderSpec>;

export type ListedTable = keyof typeof LIST_ORDERS;

export function listOrder(table: ListedTable): OrderSpec {
  return LIST_ORDERS[table];
}

export interface PageQuery {
  order: (
    column: string,
    options?: { ascending?: boolean; nullsFirst?: boolean },
  ) => PageQuery;
  range: (from: number, to: number) => PromiseLike<{
    data: unknown;
    error: { message: string } | null;
    count: number | null;
  }>;
}

export function fetchOrderedPage(
  request: PageQuery,
  table: ListedTable,
  page: number,
  pageSize = PAGE_SIZE,
): PromiseLike<{
  data: unknown;
  error: { message: string } | null;
  count: number | null;
}> {
  const spec = listOrder(table);
  let ordered = request.order(spec.column, {
    ascending: spec.ascending,
    nullsFirst: false,
  });
  if (spec.tie !== spec.column) {
    ordered = ordered.order(spec.tie, { ascending: true });
  }
  const start = page * pageSize;
  return ordered.range(start, start + pageSize - 1);
}

/** Quita comodines y la coma que separa filtros de PostgREST. */
export function cleanSearch(value: string): string {
  return value.replace(/[%_*,]/g, '').trim().slice(0, 60);
}

/** Filtro `or` de supabase-js. El asterisco es el comodín de ilike. */
export function orIlike(columns: readonly string[], raw: string): string | null {
  const q = cleanSearch(raw);
  if (!q || columns.length === 0) return null;
  return columns.map((column) => `${column}.ilike.*${q}*`).join(',');
}

const PAYMENT_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function paymentFilter(raw: string): { or: string | null; paymentId: string | null } {
  const q = cleanSearch(raw);
  if (!q) return { or: null, paymentId: null };
  if (PAYMENT_UUID.test(q)) return { or: null, paymentId: q };
  return { or: orIlike(['estado_pago', 'tipo_pago'], q), paymentId: null };
}

export function refundFilter(raw: string): string | null {
  const q = cleanSearch(raw);
  if (!q) return null;
  if (/^\d+$/.test(q)) return `id.ilike.*${q}*,monto.eq.${q}`;
  return `id.ilike.*${q}*`;
}

/**
 * Recorre la lista de a una página hasta cubrir `total` o una página corta.
 * Sirve para exportar el filtro completo, no solo la página visible.
 */
export async function collectPages<T>(
  load: (page: number) => Promise<PageResult<T>>,
  pageSize = PAGE_SIZE,
  maxPages = MAX_EXPORT_PAGES,
): Promise<T[]> {
  const all: T[] = [];
  let total = Number.POSITIVE_INFINITY;
  const limit = Math.max(1, maxPages);
  for (let page = 0; page < limit && all.length < total; page += 1) {
    const result = await load(page);
    const reported = Number(result.total);
    if (Number.isFinite(reported) && reported >= 0) total = reported;
    const rows = result.rows ?? [];
    if (rows.length === 0) break;
    all.push(...rows);
    if (rows.length < pageSize) break;
  }
  if (Number.isFinite(total) && all.length > total) return all.slice(0, total);
  return all;
}
