const ETIQUETA: Record<string, string> = {
  cuenta_nueva: 'Cuenta nueva',
  duplicado_texto: 'Texto duplicado',
  granja_cinco_estrellas: 'Muchas notas máximas',
  rafaga: 'Ráfaga',
  auto_resena: 'Autorreseña',
  sin_trabajo_valido: 'Sin trabajo válido',
};

export function etiquetaSenal(tipo: string): string {
  return ETIQUETA[tipo] ?? tipo;
}

export type SenalResenaFila = {
  id_calificacion: string;
  tipo_senal: string;
  comentario: string | null;
  estado_revision: string | null;
  puntaje_resena: number | null;
  nombre_trabajador: string | null;
  nombre_cliente: string | null;
  detalle: string | null;
  creado_en: string;
};

export type ResenaDudosa = {
  idCalificacion: string;
  senales: string[];
  comentario: string | null;
  estadoRevision: string;
  puntaje: number | null;
  profesional: string;
  cliente: string;
  detalle: string | null;
  creadoEn: string;
};

export function agruparSenalesResena(filas: SenalResenaFila[]): ResenaDudosa[] {
  const grupos = new Map<string, ResenaDudosa>();
  for (const fila of filas) {
    const id = fila.id_calificacion;
    const etiqueta = etiquetaSenal(fila.tipo_senal);
    const previa = grupos.get(id);
    if (!previa) {
      grupos.set(id, {
        idCalificacion: id,
        senales: [etiqueta],
        comentario: fila.comentario,
        estadoRevision: fila.estado_revision ?? 'vigente',
        puntaje: fila.puntaje_resena,
        profesional: fila.nombre_trabajador?.trim() || 'Profesional',
        cliente: fila.nombre_cliente?.trim() || 'Cliente',
        detalle: fila.detalle,
        creadoEn: fila.creado_en,
      });
      continue;
    }
    if (!previa.senales.includes(etiqueta)) previa.senales.push(etiqueta);
  }
  return [...grupos.values()];
}
