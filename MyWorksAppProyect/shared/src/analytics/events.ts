export const EVENTOS_USO = {
  vioFicha: 'vio_ficha_profesional',
  eligioHora: 'eligio_hora_reserva',
  confirmoPedido: 'confirmo_pedido',
} as const;

export type NombreEventoUso = (typeof EVENTOS_USO)[keyof typeof EVENTOS_USO];

const NOMBRES = new Set<string>(Object.values(EVENTOS_USO));

export type FilaEventoAnalitica = {
  id: string;
  nombre_evento: NombreEventoUso;
  id_usuario: string | null;
  marca_tiempo: string;
  metadatos: string;
};

export function filaEventoAnalitica(
  nombre: NombreEventoUso,
  metadatos: Record<string, string>,
  idUsuario: string | null,
  ahora = new Date(),
  id = crypto.randomUUID(),
): FilaEventoAnalitica {
  if (!NOMBRES.has(nombre)) {
    throw new Error('evento no permitido');
  }
  return {
    id,
    nombre_evento: nombre,
    id_usuario: idUsuario,
    marca_tiempo: ahora.toISOString(),
    metadatos: JSON.stringify(metadatos),
  };
}

export function resumenResenasPublico(data: unknown): string | null {
  if (!data || typeof data !== 'object') return null;
  const resumen = (data as { resumen?: unknown }).resumen;
  if (typeof resumen !== 'string') return null;
  const texto = resumen.trim();
  return texto.length > 0 ? texto : null;
}

export type ProfesionalParecido = {
  id: string;
  nombre: string;
  profesion: string;
  calificacion: number | null;
};

function nota(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '' && Number.isFinite(Number(value))) {
    return Number(value);
  }
  return null;
}

export function listaProfesionalesParecidos(data: unknown): ProfesionalParecido[] {
  if (!Array.isArray(data)) return [];
  const vistos = new Set<string>();
  const salida: ProfesionalParecido[] = [];
  for (const item of data) {
    if (!item || typeof item !== 'object') continue;
    const row = item as Record<string, unknown>;
    const id = typeof row.id_usuario === 'string' ? row.id_usuario : '';
    if (!id || vistos.has(id)) continue;
    vistos.add(id);
    const nombre = typeof row.nombre === 'string' ? row.nombre.trim() : '';
    const profesion = typeof row.profesion === 'string' ? row.profesion.trim() : '';
    salida.push({
      id,
      nombre: nombre || 'Profesional',
      profesion: profesion || 'Oficio',
      calificacion: nota(row.calificacion),
    });
  }
  return salida;
}
