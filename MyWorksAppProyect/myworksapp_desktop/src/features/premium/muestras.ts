import type { Analitica, PuntoSerie } from './modelo';

function dias(nombres: string[][]): PuntoSerie[] {
  return ['16 nov', '17 nov', '18 nov', '19 nov', '20 nov', '21 nov'].map((x, index) => ({
    x,
    valores: nombres.map(([nombre], serie) => ({ nombre, valor: Number(nombres[serie][index + 1] ?? 0) })),
  }));
}

function base(seccion: string, kpis: Analitica['kpis'], series: Analitica['series'], extra: Partial<Analitica> = {}): Analitica {
  return {
    seccion,
    fuente: 'muestra_local',
    sin_movimiento: false,
    nota: 'Muestra local de desarrollo. No es producción y no mueve dinero.',
    kpis,
    series,
    desgloses: extra.desgloses ?? [],
    atencion: extra.atencion ?? [],
  };
}

export function muestraAnalitica(seccion: string, factor = 1): Analitica {
  const f = (valor: number) => Math.round(valor * factor);
  if (seccion === 'resenas') {
    return base(seccion, [
      { id: 'promedio', etiqueta: 'Calificación promedio', valor: 4.2 * factor, unidad: 'estrellas', ayuda: 'Promedio de estrellas del período.', filtro: null },
      { id: 'total', etiqueta: 'Total de reseñas', valor: f(18), unidad: 'numero', ayuda: 'Reseñas visibles.', filtro: null },
      { id: 'positivas', etiqueta: 'Positivas', valor: f(72), unidad: 'porcentaje', ayuda: '4 o 5 estrellas.', filtro: 'positivas' },
      { id: 'negativas', etiqueta: 'Negativas', valor: f(16), unidad: 'porcentaje', ayuda: '1 o 2 estrellas.', filtro: 'negativas' },
      { id: 'csat', etiqueta: 'Satisfacción', valor: f(84), unidad: 'porcentaje', ayuda: 'Promedio llevado a 0-100.', filtro: null },
      { id: 'respuesta', etiqueta: 'Tasa de respuesta', valor: null, unidad: 'porcentaje', ayuda: 'La base no guarda respuesta pública.', filtro: 'sin_responder' },
    ], [
      {
        id: 'sentimiento',
        titulo: 'Positivas, neutras y negativas',
        tipo: 'area',
        ayuda: 'Fuente: reglas_estrellas en la muestra.',
        puntos: dias([
          ['Positivas', '4', '5', '6', '3', '7', '5'],
          ['Neutras', '1', '1', '0', '2', '1', '1'],
          ['Negativas', '1', '0', '2', '1', '0', '1'],
        ]),
      },
      {
        id: 'estrellas',
        titulo: 'Distribución de estrellas',
        tipo: 'barra',
        ayuda: 'Cuántas reseñas hay en cada nota.',
        puntos: [1, 2, 3, 4, 5].map((estrella) => ({
          x: String(estrella),
          valores: [{ nombre: 'Reseñas', valor: f([2, 1, 2, 6, 7][estrella - 1]) }],
        })),
      },
    ], {
      desgloses: [{
        id: 'temas',
        titulo: 'Temas en los comentarios',
        filas: [
          { etiqueta: 'Puntualidad', valor: f(8), filtro: 'puntualidad' },
          { etiqueta: 'Limpieza', valor: f(5), filtro: 'limpieza' },
          { etiqueta: 'Atraso', valor: f(3), filtro: 'atraso' },
          { etiqueta: 'No llegó', valor: f(2), filtro: 'no_llego' },
        ],
      }],
    });
  }
  return base(seccion, [
    { id: 'a', etiqueta: 'Pedidos del período', valor: f(42), unidad: 'numero', ayuda: 'Creados en el rango.', filtro: null },
    { id: 'b', etiqueta: 'Completados', valor: f(28), unidad: 'numero', ayuda: 'Estado actual completado.', filtro: 'completado' },
    { id: 'c', etiqueta: 'Ingresos del período', valor: f(860000), unidad: 'clp', ayuda: 'Pagos retenidos o liberados.', filtro: null },
    { id: 'd', etiqueta: 'Disputas abiertas', valor: f(3), unidad: 'numero', ayuda: 'Incluye abierta y en revisión.', filtro: 'abiertas' },
    { id: 'e', etiqueta: 'Satisfacción promedio', valor: 4.4, unidad: 'estrellas', ayuda: 'Promedio de reseñas.', filtro: null },
  ], [
    {
      id: 'linea',
      titulo: 'Movimiento del período',
      tipo: 'linea',
      ayuda: 'Serie de muestra para revisar la pantalla.',
      puntos: dias([['Pedidos', '4', '6', '5', '8', '7', '9'], ['Completados', '2', '3', '4', '5', '4', '6']]),
    },
    {
      id: 'embudo',
      titulo: 'Embudo',
      tipo: 'embudo',
      ayuda: 'De la solicitud a la reseña.',
      puntos: ['Solicitud', 'Cotización', 'Aceptado', 'Completado', 'Pagado', 'Reseñado'].map((x, index) => ({
        x,
        valores: [{ nombre: 'Pedidos', valor: f(40 - index * 5) }],
      })),
    },
  ], {
    atencion: seccion === 'inicio' ? [
      { etiqueta: 'Disputas abiertas', valor: f(3), ruta: '/disputas', detalle: 'Incluye abierta y en revisión.' },
      { etiqueta: 'Verificaciones por revisar', valor: f(2), ruta: '/verificaciones', detalle: 'Documentos pendientes.' },
    ] : [],
    desgloses: [{
      id: 'comunas',
      titulo: 'Dónde se pidió',
      filas: [
        { etiqueta: 'Puerto Montt', valor: f(18), filtro: null },
        { etiqueta: 'Puerto Varas', valor: f(9), filtro: null },
      ],
    }],
  });
}

export function filasCaptura(clave: string): Array<Record<string, unknown> & { id: string }> {
  if (clave === 'pedidos' || clave === 'trabajos') {
    return [
      { id: 'job-1', estado: 'completado', direccion: 'Calle de prueba 10', creado_en: '2026-11-10T15:00:00Z', id_usuario: 'cliente' },
      { id: 'job-2', estado: 'en_curso', direccion: 'Calle de prueba 20', creado_en: '2026-11-18T15:00:00Z', id_usuario: 'cliente' },
    ];
  }
  if (clave === 'resenas' || clave === 'calificaciones') {
    return [
      { id: 'rev-1', puntaje: 5, estado_revision: 'vigente', comentario: 'Llegó puntual y dejó todo limpio', creado_en: '2026-11-11T12:00:00Z' },
      { id: 'rev-2', puntaje: 1, estado_revision: 'vigente', comentario: 'No llegó y hubo una amenaza', creado_en: '2026-11-19T12:00:00Z' },
    ];
  }
  if (clave === 'usuarios') {
    return [{ id: '22222222-2222-2222-2222-222222222222', nombre: 'Cliente de prueba', rol: 'usuario', estado_cuenta: 'activo', creado_en: '2026-11-01T12:00:00Z', total: 1 }];
  }
  if (clave === 'profesionales') {
    return [{ id: '33333333-3333-3333-3333-333333333333', id_usuario: '33333333-3333-3333-3333-333333333333', profesion: 'Gasfitería', estado_verificacion: 'en_revision', calificacion: 4.5 }];
  }
  if (clave === 'tickets') {
    return [{ id: 'tic-1', asunto: 'Ayuda con el pago', estado: 'pendiente', nombre_cliente: 'Cliente de prueba', nombre_trabajador: 'Trabajador de prueba', creado_en: '2026-11-15T12:00:00Z' }];
  }
  if (clave === 'reportes') {
    return [{ id: 'rep-1', motivo: 'Abuso de prueba', estado: 'pendiente', creado_en: '2026-11-16T12:00:00Z' }];
  }
  if (clave === 'pagos') {
    return [{ id: 'pay-2', id_pago: 'pay-2', estado_pago: 'retenido', tipo_pago: 'principal', bruto_clp: 15000, comision_clp: 1000, neto_clp: 14000, creado_en: '2026-11-18T16:00:00Z' }];
  }
  if (clave === 'reembolsables') {
    return [{ id: 'pay-2', estado: 'retenido', monto: 15000, id_trabajo: 'job-2' }];
  }
  if (clave === 'servicios') {
    return [{ id: 'gas', nombre: 'Gasfitería', categoria: 'Hogar', activo: 1 }];
  }
  if (clave === 'errores') {
    return [{ id: 'err-1', mensaje: 'Falla de prueba', estado: 'nuevo', creado_en: '2026-11-20T12:00:00Z' }];
  }
  return [{ id: 'fila-1', nombre: 'Sin filas de muestra para esta tabla', estado: 'pendiente' }];
}

export function disputasCaptura() {
  return [
    {
      id: 'dis-1',
      id_trabajo: 'job-3',
      motivo: 'Trabajo incompleto',
      descripcion: 'El trabajo quedó a medias.',
      estado: 'abierta',
      decision_sugerida: 'reembolsar',
      motivo_regla: 'El trabajador no llegó.',
      vence_en: '2026-11-24T15:00:00Z',
      creado_en: '2026-11-19T13:00:00Z',
      nombre_cliente: 'Cliente de prueba',
      nombre_profesional: 'Trabajador de prueba',
      monto_retenido: 15000,
      resolucion: null,
      resuelta_en: null,
      prioridad: 'alta',
    },
  ];
}
