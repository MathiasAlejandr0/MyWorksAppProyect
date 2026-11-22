export interface AlertaIa {
  id: string;
  cuando: string;
  tipo: string;
  severidad: string;
  resumen: string;
  detalle: string;
  estado: string;
  usuario: string;
}

export interface MarcaModeracion {
  id: string;
  idMensaje: string;
  motivo: string;
  detalle: string;
  estado: string;
  veredicto: string;
  cuando: string;
  extracto: string;
}

function fila(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" ? value as Record<string, unknown> : {};
}

function texto(value: unknown): string {
  if (value == null || value === "") return "";
  return String(value);
}

export function esAlertaIa(tipo: string): boolean {
  return tipo.startsWith("ia_");
}

export function leerAlertasIa(data: unknown): { bandera: boolean; alertas: AlertaIa[] } {
  const root = fila(data);
  const lista = Array.isArray(root.alertas) ? root.alertas : [];
  return {
    bandera: root.bandera === true,
    alertas: lista.map((item) => {
      const row = fila(item);
      return {
        id: texto(row.id),
        cuando: texto(row.cuando),
        tipo: texto(row.tipo),
        severidad: texto(row.severidad) || "media",
        resumen: texto(row.resumen),
        detalle: row.detalle == null ? "" : JSON.stringify(row.detalle),
        estado: texto(row.estado),
        usuario: texto(row.usuario),
      };
    }).filter((item) => esAlertaIa(item.tipo)),
  };
}

export function leerModeracion(data: unknown): MarcaModeracion[] {
  const lista = Array.isArray(data) ? data : [];
  return lista.map((item) => {
    const row = fila(item);
    return {
      id: texto(row.id),
      idMensaje: texto(row.id_mensaje),
      motivo: texto(row.motivo),
      detalle: texto(row.detalle),
      estado: texto(row.estado),
      veredicto: texto(row.veredicto_llm),
      cuando: texto(row.cuando),
      extracto: texto(row.extracto),
    };
  });
}

export function resumenSugerencia(valor: unknown): string {
  if (!valor || typeof valor !== "object") return "";
  const row = valor as Record<string, unknown>;
  const tipo = texto(row.tipo) || "documento";
  const nota = texto(row.nota);
  return `Sugerencia de la IA sobre un ${tipo}. ${nota} La aprobación sigue siendo humana.`.trim();
}
