export type FilaBandeja = {
  prioridad?: string | null;
  asignado_a?: string | null;
  vence_en?: string | null;
};

const PESO: Record<string, number> = { alta: 0, media: 1, baja: 2 };

export function ordenarDisputas<T extends FilaBandeja>(filas: T[]): T[] {
  return [...filas].sort((a, b) => {
    const pesoA = PESO[a.prioridad ?? ''] ?? 3;
    const pesoB = PESO[b.prioridad ?? ''] ?? 3;
    if (pesoA !== pesoB) return pesoA - pesoB;
    return String(a.vence_en ?? '9999').localeCompare(String(b.vence_en ?? '9999'));
  });
}

export function filtrarDisputas<T extends FilaBandeja>(
  filas: T[],
  filtro: string,
  miId: string | null,
): T[] {
  if (filtro === 'todas') return filas;
  if (filtro === 'sin_asignar') return filas.filter((fila) => !fila.asignado_a);
  if (filtro === 'mias') return filas.filter((fila) => fila.asignado_a === miId);
  return filas.filter((fila) => fila.prioridad === filtro);
}

export function textoProcedencia(foto: {
  confianza?: string | null;
  tipo_evidencia?: string | null;
  distancia_metros?: number | null;
  duplicado?: boolean | null;
  origen_captura?: string | null;
}): string {
  const confianza = foto.confianza === 'confiable' ? 'Verificada' : 'No verificada';
  const distancia = foto.distancia_metros == null
    ? 'sin GPS'
    : `${Math.round(Number(foto.distancia_metros))} m del trabajo`;
  const duplicado = foto.duplicado ? 'Duplicada' : 'Sin duplicado';
  const tipo = foto.tipo_evidencia || 'sin tipo';
  const origen = foto.origen_captura || 'origen desconocido';
  return `${confianza} · ${tipo} · ${origen} · ${distancia} · ${duplicado}`;
}
