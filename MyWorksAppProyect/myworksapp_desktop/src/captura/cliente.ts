import { disputasCaptura, filasCaptura, muestraAnalitica } from '../features/premium/muestras';

type Fila = Record<string, unknown>;

function filasDe(tabla: string): Fila[] {
  if (tabla === 'trabajos') return filasCaptura('pedidos');
  if (tabla === 'calificaciones') return filasCaptura('resenas');
  if (tabla === 'trabajadores') return filasCaptura('profesionales');
  if (tabla === 'tickets_soporte') return filasCaptura('tickets');
  if (tabla === 'reportes') return filasCaptura('reportes');
  if (tabla === 'cobros_profesional') return filasCaptura('pagos');
  if (tabla === 'pagos') return filasCaptura('reembolsables');
  if (tabla === 'servicios') return filasCaptura('servicios');
  if (tabla === 'notificaciones') {
    return [{ id: 'not-1', titulo: 'Nuevo pedido', cuerpo: 'Tienes un pedido de prueba.', leido: 0, creado_en: '2026-11-18T12:00:00Z', tipo: 'pedido' }];
  }
  if (tabla === 'app_config') return [{ clave: 'demo_modo', valor: '0', actualizado_en: '2026-11-01T00:00:00Z' }];
  return [];
}

function rpc(nombre: string, args?: Record<string, unknown>): unknown {
  if (nombre === 'consola_premium_kpis') return muestraAnalitica(String(args?.p_seccion ?? 'inicio'));
  if (nombre === 'consola_premium_resenas') {
    const filtro = String(args?.p_filtro ?? 'todas');
    const todas = [
      {
        id: 'rev-1', puntaje: 5, comentario: 'Llegó puntual y dejó todo limpio', estado_revision: 'vigente',
        sentimiento: 'positivo', temas: ['puntualidad', 'limpieza'], alerta_grave: false, fuente: 'reglas_estrellas',
        creado_en: '2026-11-11T12:00:00Z', trabajador: 'Trabajador de prueba', id_trabajo: 'job-1', total: 2,
      },
      {
        id: 'rev-2', puntaje: 1, comentario: 'No llegó y hubo una amenaza', estado_revision: 'vigente',
        sentimiento: 'negativo', temas: ['no_llego', 'alerta_grave'], alerta_grave: true, fuente: 'reglas_estrellas',
        creado_en: '2026-11-19T12:00:00Z', trabajador: 'Trabajador de prueba', id_trabajo: 'job-3', total: 2,
      },
    ];
    return todas.filter((fila) => {
      if (filtro === 'positivas') return fila.sentimiento === 'positivo';
      if (filtro === 'negativas') return fila.sentimiento === 'negativo';
      if (filtro === 'marcadas') return fila.alerta_grave;
      return true;
    });
  }
  if (nombre === 'consola_disputas_abiertas') return disputasCaptura();
  if (nombre === 'consola_disputas_resueltas') return [];
  if (nombre === 'consola_resumen_periodo') {
    return {
      financiero: { gmv_clp: 860000, comision_clp: 43000, ticket_promedio_clp: 20000, csat: 4.4, n_resenas: 18 },
      colas: { disputas_abiertas: 3, verificaciones_en_revision: 2, pagos_retenidos: 1, reembolsos_pendientes: 0, tickets_abiertos: 1, errores_nuevos: 0 },
    };
  }
  if (nombre === 'consola_buscar') {
    return [{ tipo: 'pedido', id: 'job-1', ruta: '/pedidos/job-1', titulo: 'Pedido de prueba', detalle: 'Completado' }];
  }
  if (nombre === 'consola_listar_equipo') {
    return [{ id: '11111111-1111-1111-1111-111111111111', nombre: 'Admin de prueba', correo: 'admin.consola@local.test', rol: 'administrador', estado_cuenta: 'activo', creado_en: '2026-01-01', invitacion_pendiente: false }];
  }
  if (nombre === 'consola_listar_perfiles') return filasCaptura('usuarios');
  if (nombre === 'consola_seguridad_ciclo') {
    return {
      generado_en: '2026-11-22T15:00:00Z',
      umbrales: [],
      incidentes: [{ id: 'inc-1', resumen: 'Muchos intentos de ingreso', cuando: '2026-11-22T14:00:00Z', tipo: 'login', severidad: 'alta', estado: 'abierto' }],
      auditoria_auth: [],
      mfa: [],
      sesiones_consola: [],
      reportes_abuso: [],
      rls_sin_politica: [],
      servicio: { base: 'local', edge: 'sin desplegar en la captura' },
      turnstile: 'Sin registros en la captura.',
      logins_fallidos: 2,
      errores: 0,
      disputas_activas_ventana: 1,
      altas: 0,
      pagos_retenidos_viejos: 0,
    };
  }
  if (nombre === 'consola_estado_defensa') return { solo_lectura: false, bloqueo_total: false };
  if (nombre === 'consola_listar_respaldos' || nombre === 'consola_listar_pruebas') return [];
  return [];
}

export function clienteCaptura(): unknown {
  return {
    from(tabla: string) {
      const ops: Array<(rows: Fila[]) => Fila[]> = [];
      let head = false;
      const finish = (desde = 0, hasta = 49) => {
        let rows = filasDe(tabla);
        for (const op of ops) rows = op(rows);
        return { data: rows.slice(desde, hasta + 1), error: null, count: rows.length };
      };
      const api = {
        select(_cols?: string, opts?: { head?: boolean }) {
          head = Boolean(opts?.head);
          return api;
        },
        eq(col: string, val: unknown) {
          ops.push((rows) => rows.filter((row) => row[col] === val));
          return api;
        },
        in(col: string, vals: unknown[]) {
          ops.push((rows) => rows.filter((row) => vals.includes(row[col])));
          return api;
        },
        ilike(col: string, pattern: string) {
          const q = pattern.replaceAll('%', '').toLowerCase();
          ops.push((rows) => rows.filter((row) => String(row[col] ?? '').toLowerCase().includes(q)));
          return api;
        },
        or() { return api; },
        order() { return api; },
        limit() { return api; },
        range(desde: number, hasta: number) {
          return Promise.resolve(finish(desde, hasta));
        },
        maybeSingle() {
          return Promise.resolve({ data: finish().data[0] ?? null, error: null });
        },
        update() {
          return { eq: () => Promise.resolve({ data: null, error: null }) };
        },
        then(resolve: (value: unknown) => void, reject?: (reason: unknown) => void) {
          const result = finish();
          return Promise.resolve(head ? { count: result.count, data: null, error: null } : result).then(resolve, reject);
        },
      };
      return api;
    },
    rpc(nombre: string, args?: Record<string, unknown>) {
      return Promise.resolve({ data: rpc(nombre, args), error: null });
    },
    functions: {
      invoke: async (nombre: string) => ({
        data: null,
        error: { message: `Captura local: ${nombre} no se ejecutó.` },
      }),
    },
    channel() {
      const canal = {
        on() { return canal; },
        subscribe(callback?: (status: string) => void) {
          callback?.('SUBSCRIBED');
          return canal;
        },
      };
      return canal;
    },
    removeChannel() { return Promise.resolve('ok'); },
    auth: {
      getSession: async () => ({ data: { session: null }, error: null }),
      onAuthStateChange() {
        return { data: { subscription: { unsubscribe() {} } } };
      },
      signOut: async () => ({ error: null }),
      mfa: {
        listFactors: async () => ({ data: { totp: [] }, error: null }),
        getAuthenticatorAssuranceLevel: async () => ({ data: { currentLevel: 'aal2', nextLevel: 'aal2' }, error: null }),
        challenge: async () => ({ data: null, error: { message: 'captura' } }),
        verify: async () => ({ data: null, error: { message: 'captura' } }),
      },
    },
    storage: {
      from() {
        return { createSignedUrl: async () => ({ data: null, error: null }) };
      },
    },
  };
}
