/** Reglas de sentimiento compartidas con la función SQL consola_premium_clasificar. */

export type Sentimiento = 'positivo' | 'neutro' | 'negativo' | 'sin_dato';

export interface Clasificacion {
  sentimiento: Sentimiento;
  temas: string[];
  alertaGrave: boolean;
  fuente: 'reglas_estrellas';
}

const TEMAS: Array<{ id: string; patron: RegExp }> = [
  { id: 'puntualidad', patron: /puntual|a tiempo|r[aá]pido|en hora/i },
  { id: 'limpieza', patron: /limpi/i },
  { id: 'precio', patron: /precio|barat|car[oa]|cobr/i },
  { id: 'trato', patron: /trato|amable|respet|educad/i },
  { id: 'atraso', patron: /atras|demor|tard/i },
  { id: 'calidad', patron: /calidad|mal hecho|defect|chapuz/i },
  { id: 'no_llego', patron: /no lleg|no vino|no se present|no asist/i },
];

const GRAVE = /golpe|agres|amenaz|robo|hurt|dañ|dan[oó]|acoso/i;

export function clasificarComentario(puntaje: number | null | undefined, texto: string | null | undefined): Clasificacion {
  let sentimiento: Sentimiento = 'sin_dato';
  if (puntaje != null && !Number.isNaN(puntaje)) {
    if (puntaje >= 4) sentimiento = 'positivo';
    else if (puntaje <= 2) sentimiento = 'negativo';
    else sentimiento = 'neutro';
  }
  const cuerpo = texto ?? '';
  const temas = TEMAS.filter((tema) => tema.patron.test(cuerpo)).map((tema) => tema.id);
  const alertaGrave = GRAVE.test(cuerpo);
  if (alertaGrave) temas.push('alerta_grave');
  return { sentimiento, temas, alertaGrave, fuente: 'reglas_estrellas' };
}

export function variacion(actual: number | null, anterior: number | null): number | null {
  if (actual == null || anterior == null) return null;
  if (anterior === 0) return actual === 0 ? 0 : null;
  return ((actual - anterior) / Math.abs(anterior)) * 100;
}

export function etiquetaTema(id: string): string {
  const nombres: Record<string, string> = {
    puntualidad: 'Puntualidad',
    limpieza: 'Limpieza',
    precio: 'Precio',
    trato: 'Trato',
    atraso: 'Atraso',
    calidad: 'Calidad',
    no_llego: 'No llegó',
    alerta_grave: 'Alerta grave',
  };
  return nombres[id] ?? id;
}

/** Quita RUT, teléfono y correo antes de cualquier texto que salga de la consola. */
export function redactar(texto: string): string {
  return texto
    .replace(/\b\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]\b/g, '[dato]')
    .replace(/\b(?:\+?56\s?)?9\s?\d{4}\s?\d{4}\b/g, '[dato]')
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[dato]');
}

export interface ValorSerie {
  nombre: string;
  valor: number;
}

export interface PuntoSerie {
  x: string;
  valores: ValorSerie[];
}

export interface SerieAnalitica {
  id: string;
  titulo: string;
  tipo: 'linea' | 'barra' | 'area' | 'embudo';
  ayuda: string;
  puntos: PuntoSerie[];
}

export interface KpiAnalitico {
  id: string;
  etiqueta: string;
  valor: number | null;
  unidad: 'numero' | 'clp' | 'porcentaje' | 'estrellas' | 'horas';
  ayuda: string;
  filtro?: string | null;
}

export interface FilaDesglose {
  etiqueta: string;
  valor: number;
  filtro?: string | null;
}

export interface DesgloseAnalitico {
  id: string;
  titulo: string;
  filas: FilaDesglose[];
}

export interface Atencion {
  etiqueta: string;
  valor: number;
  ruta: string;
  detalle: string;
}

export interface Analitica {
  seccion: string;
  fuente: string;
  sin_movimiento: boolean;
  sin_permiso?: boolean;
  nota?: string | null;
  kpis: KpiAnalitico[];
  series: SerieAnalitica[];
  desgloses: DesgloseAnalitico[];
  atencion: Atencion[];
}

export function rango(dias: number, ahora = new Date()): { desde: string; hasta: string; anteriorDesde: string; anteriorHasta: string } {
  const seguro = [1, 7, 30, 90].includes(dias) ? dias : 7;
  const hasta = ahora;
  const desde = new Date(hasta.getTime() - seguro * 86_400_000);
  const anteriorHasta = new Date(desde.getTime());
  const anteriorDesde = new Date(anteriorHasta.getTime() - seguro * 86_400_000);
  return {
    desde: desde.toISOString(),
    hasta: hasta.toISOString(),
    anteriorDesde: anteriorDesde.toISOString(),
    anteriorHasta: anteriorHasta.toISOString(),
  };
}

export function comoAnalitica(value: unknown): Analitica | null {
  if (!value || typeof value !== 'object') return null;
  const row = value as Partial<Analitica>;
  if (!Array.isArray(row.kpis) || !Array.isArray(row.series)) return null;
  return {
    seccion: String(row.seccion ?? ''),
    fuente: String(row.fuente ?? 'sql'),
    sin_movimiento: Boolean(row.sin_movimiento),
    sin_permiso: Boolean(row.sin_permiso),
    nota: row.nota ?? null,
    kpis: row.kpis,
    series: row.series,
    desgloses: Array.isArray(row.desgloses) ? row.desgloses : [],
    atencion: Array.isArray(row.atencion) ? row.atencion : [],
  };
}

/** Ventana visible de una tabla virtual. Se prueba con 10.000 filas. */
export function ventanaVirtual(scrollTop: number, altoVista: number, altoFila: number, total: number, extra = 4): { inicio: number; fin: number } {
  const fila = Math.max(1, altoFila);
  const inicio = Math.max(0, Math.floor(scrollTop / fila) - extra);
  const fin = Math.min(total, Math.ceil((scrollTop + altoVista) / fila) + extra);
  return { inicio, fin };
}
