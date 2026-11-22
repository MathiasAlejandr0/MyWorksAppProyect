/** Lógica pura de IA. La misma clasificación vive en clasificar_mensaje (SQL). */

export const TIPOS_EVENTO = [
  "busqueda",
  "vista_perfil",
  "click",
  "contratacion",
  "cancelacion",
  "disputa",
  "resena",
] as const;

export type TipoEvento = (typeof TIPOS_EVENTO)[number];

export const CATEGORIAS_IA = [
  "ensamblaje",
  "electricidad",
  "plomeria",
  "gasfiteria",
  "limpieza",
  "pintura",
  "jardineria",
  "cerrajeria",
  "construccion",
  "soporte_tecnico",
  "mudanza",
  "climatizacion",
] as const;

export type CategoriaIa = (typeof CATEGORIAS_IA)[number];

const CLAVES_SENSIBLES = [
  "rut",
  "correo",
  "email",
  "telefono",
  "password",
  "clave",
  "numero_cuenta",
  "rut_titular",
  "nombre_titular",
];

export function sanitizarMetadata(metadata: Record<string, unknown> | null | undefined): Record<string, unknown> {
  const limpio: Record<string, unknown> = {};
  for (const [clave, valor] of Object.entries(metadata ?? {})) {
    if (CLAVES_SENSIBLES.includes(clave)) continue;
    if (typeof valor === "string") limpio[clave] = valor.slice(0, 180);
    else if (typeof valor === "number" || typeof valor === "boolean") limpio[clave] = valor;
  }
  return limpio;
}

export function enmascararParaExterno(texto: string): string {
  return texto
    .replace(/\b\d{1,2}\.\d{3}\.\d{3}-[\dkK]\b/g, "RUT oculto")
    .replace(/\b\d{7,8}-[\dkK]\b/g, "RUT oculto")
    .replace(/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/gi, "correo oculto")
    .replace(/(?:^|[^\d])(?:\+?56[\s.-]*)?9(?:[\s.-]?\d){8}(?!\d)/g, " telefono oculto");
}

export type MotivoModeracion =
  | "limpio"
  | "telefono"
  | "correo"
  | "banco"
  | "fuera"
  | "insulto"
  | "dudoso";

export function clasificarMensaje(texto: string): MotivoModeracion {
  const v = texto.trim();
  if (!v) return "limpio";
  if (/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i.test(v)) return "correo";
  if (/(?:^|[^\d])(?:\+?56[\s.-]*)?9(?:[\s.-]?\d){8}(?!\d)/.test(v)) return "telefono";
  if (/cuenta\s+(corriente|vista|rut|de\s+ahorro)|n[uú]mero\s+de\s+cuenta/i.test(v)) return "banco";
  if (/p[aá]game\s+por\s+fuera|pago\s+por\s+fuera|por\s+fuera\s+de\s+la\s+app|sin\s+pasar\s+por\s+la\s+app/i.test(v)) {
    return "fuera";
  }
  if (/\b(weon|weón|aweonao|aweona|conchetumare|conchesumadre|ctm|qliao|imbecil|imbécil|idiota)\b|saco\s+de\s+wea/i.test(v)) {
    return "insulto";
  }
  if (/escribeme|mi\s+n[uú]mero|por\s+interno|te\s+paso\s+el\s+dato|[0-9]{5,7}/i.test(v)) return "dudoso";
  return "limpio";
}

export interface SugerenciaSolicitud {
  categoria: CategoriaIa;
  urgencia: "baja" | "media" | "alta";
  precio_min_clp: number;
  precio_max_clp: number;
  preguntas: string[];
  aviso: string;
}

export const AVISO_SUGERENCIA =
  "Sugerencia de la IA. No reserva ni cobra: tú confirmas el pedido.";

const PRECIOS: Record<CategoriaIa, [number, number]> = {
  ensamblaje: [25000, 45000],
  electricidad: [30000, 70000],
  plomeria: [30000, 80000],
  gasfiteria: [30000, 80000],
  limpieza: [20000, 45000],
  pintura: [40000, 120000],
  jardineria: [25000, 60000],
  cerrajeria: [25000, 55000],
  construccion: [50000, 180000],
  soporte_tecnico: [20000, 50000],
  mudanza: [40000, 120000],
  climatizacion: [35000, 90000],
};

export function sugerenciaDesdeTexto(texto: string): SugerenciaSolicitud {
  const limpio = enmascararParaExterno(texto).toLowerCase();
  let categoria: CategoriaIa = "gasfiteria";
  if (/enchufe|luz|eléctric|electric|tablero|automático/.test(limpio)) categoria = "electricidad";
  else if (/llave|fuga|cañer|gasfiter|plomer|agua/.test(limpio)) categoria = "gasfiteria";
  else if (/pint/.test(limpio)) categoria = "pintura";
  else if (/jard[ií]n|pasto|poda/.test(limpio)) categoria = "jardineria";
  else if (/mudanza|camion|caja/.test(limpio)) categoria = "mudanza";
  else if (/comput|wifi|notebook|windows/.test(limpio)) categoria = "soporte_tecnico";
  else if (/aire|split|calefont|climat/.test(limpio)) categoria = "climatizacion";
  else if (/cerradura|llave trabada|chapa/.test(limpio)) categoria = "cerrajeria";
  else if (/armar|mueble|escritorio/.test(limpio)) categoria = "ensamblaje";
  else if (/limpieza|aseo/.test(limpio)) categoria = "limpieza";
  else if (/muro|radier|obra/.test(limpio)) categoria = "construccion";
  const urgencia = /hoy|urgente|inunda|sin agua|sin luz|ahora/.test(limpio)
    ? "alta"
    : /semana|cuando pueda/.test(limpio)
      ? "baja"
      : "media";
  const [min, max] = PRECIOS[categoria];
  const factor = urgencia === "alta" ? 1.15 : 1;
  const preguntas = [
    "¿En qué comuna está el trabajo?",
    "¿Es casa, departamento o local?",
  ];
  if (!/comuna|puerto montt|santiago|ñuñoa|valdivia/.test(limpio)) {
    preguntas.unshift("¿En qué comuna hay que ir?");
  }
  return validarSugerencia({
    categoria,
    urgencia,
    precio_min_clp: Math.round(min * factor),
    precio_max_clp: Math.round(max * factor),
    preguntas: preguntas.slice(0, 3),
    aviso: AVISO_SUGERENCIA,
  })!;
}

export function validarSugerencia(raw: unknown): SugerenciaSolicitud | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as Record<string, unknown>;
  const categoria = row.categoria;
  const urgencia = row.urgencia;
  const min = Number(row.precio_min_clp);
  const max = Number(row.precio_max_clp);
  if (!(CATEGORIAS_IA as readonly string[]).includes(String(categoria))) return null;
  if (urgencia !== "baja" && urgencia !== "media" && urgencia !== "alta") return null;
  if (!Number.isInteger(min) || !Number.isInteger(max) || min < 5000 || max > 500000 || min > max) return null;
  if (!Array.isArray(row.preguntas) || row.preguntas.length > 4) return null;
  const preguntas = row.preguntas
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length >= 8 && item.length <= 160)
    .slice(0, 4);
  return {
    categoria: categoria as CategoriaIa,
    urgencia,
    precio_min_clp: min,
    precio_max_clp: max,
    preguntas,
    aviso: AVISO_SUGERENCIA,
  };
}

export function redactarPerfil(texto: string): string {
  const base = enmascararParaExterno(texto).replace(/\s+/g, " ").trim();
  if (base.length < 8) return "";
  const cuerpo = base.charAt(0).toUpperCase() + base.slice(1);
  const cerrado = /[.!?]$/.test(cuerpo) ? cuerpo : `${cuerpo}.`;
  return `Trabajo con orden y dejo el lugar limpio. ${cerrado}`.slice(0, 1200);
}

export function resumirResenas(comentarios: string[]): string {
  const limpios = comentarios
    .map((item) => enmascararParaExterno(item).replace(/\s+/g, " ").trim())
    .filter((item) => item.length >= 4)
    .slice(0, 12);
  if (limpios.length === 0) return "";
  const muestra = limpios.slice(0, 3).join(" ");
  return `Resumen de ${limpios.length} reseñas: ${muestra}`.slice(0, 600);
}

export interface PesosBusqueda {
  similitud: number;
  cercania: number;
  nota: number;
  confiabilidad: number;
}

export const PESOS_BUSQUEDA: PesosBusqueda = {
  similitud: 0.45,
  cercania: 0.25,
  nota: 0.2,
  confiabilidad: 0.1,
};

export function puntajeHibrido(input: {
  similitud: number;
  distanciaKm: number | null;
  calificacion: number;
  nCalificaciones: number;
  tasaCancelacion: number;
  disputas: number;
  horasRespuesta: number | null;
  pesos?: PesosBusqueda;
}): number {
  const pesos = input.pesos ?? PESOS_BUSQUEDA;
  const sim = Math.max(0, Math.min(1, input.similitud));
  const cerca = input.distanciaKm == null ? 0.5 : 1 / (1 + input.distanciaKm / 5);
  const nota = input.nCalificaciones <= 0 ? 0.4 : Math.min(input.calificacion, 5) / 5;
  const conf = Math.max(
    0,
    1
      - Math.min(input.tasaCancelacion, 1) * 0.5
      - Math.min(input.disputas, 5) * 0.05
      - ((input.horasRespuesta ?? 0) > 24 ? 0.1 : 0),
  );
  const total = pesos.similitud * sim + pesos.cercania * cerca + pesos.nota * nota + pesos.confiabilidad * conf;
  return Math.round(total * 10000) / 10000;
}

export interface SugerenciaDocumento {
  legible: boolean;
  tipo: "carnet" | "certificado" | "otro";
  nombre_coincide: boolean | null;
  confianza: number;
  nota: string;
}

export function validarSugerenciaDocumento(raw: unknown): SugerenciaDocumento | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as Record<string, unknown>;
  const tipo = row.tipo;
  if (tipo !== "carnet" && tipo !== "certificado" && tipo !== "otro") return null;
  if (typeof row.legible !== "boolean") return null;
  const confianza = Number(row.confianza);
  if (!Number.isFinite(confianza) || confianza < 0 || confianza > 1) return null;
  const coincide = row.nombre_coincide;
  if (coincide !== null && coincide !== true && coincide !== false) return null;
  const nota = enmascararParaExterno(String(row.nota ?? "")).slice(0, 400);
  return {
    legible: row.legible,
    tipo,
    nombre_coincide: coincide as boolean | null,
    confianza: Math.round(confianza * 100) / 100,
    nota,
  };
}

export function parsearJsonModelo(texto: string): unknown {
  const limpio = texto.trim().replace(/^```json\s*/i, "").replace(/```$/g, "").trim();
  const inicio = limpio.indexOf("{");
  const fin = limpio.lastIndexOf("}");
  if (inicio < 0 || fin <= inicio) return null;
  try {
    return JSON.parse(limpio.slice(inicio, fin + 1));
  } catch {
    return null;
  }
}
