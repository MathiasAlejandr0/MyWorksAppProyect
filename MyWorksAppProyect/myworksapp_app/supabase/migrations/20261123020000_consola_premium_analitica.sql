-- Analítica de la consola premium. Los KPI se calculan aquí, no en el cliente.
-- No aplicar en el proyecto remoto wxqrfcqifkfgawrnqmnj.
-- El sentimiento de reseñas usa estrellas y reglas de texto. La fuente queda
-- marcada como reglas_estrellas. No sale RUT ni correo en el resultado.

BEGIN;

ALTER TABLE public.disputas
  ADD COLUMN IF NOT EXISTS prioridad text,
  ADD COLUMN IF NOT EXISTS asignado_a uuid;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'disputas_prioridad_chk') THEN
    ALTER TABLE public.disputas
      ADD CONSTRAINT disputas_prioridad_chk
      CHECK (prioridad IS NULL OR prioridad IN ('alta', 'media', 'baja'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'disputas_asignado_a_fkey') THEN
    ALTER TABLE public.disputas
      ADD CONSTRAINT disputas_asignado_a_fkey
      FOREIGN KEY (asignado_a) REFERENCES public.perfiles (id);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.consola_premium_clasificar(
  p_puntaje numeric,
  p_texto text
) RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_texto text := lower(coalesce(p_texto, ''));
  v_sentimiento text := 'sin_dato';
  v_temas jsonb := '[]'::jsonb;
  v_grave boolean := false;
BEGIN
  IF p_puntaje IS NOT NULL THEN
    IF p_puntaje >= 4 THEN
      v_sentimiento := 'positivo';
    ELSIF p_puntaje <= 2 THEN
      v_sentimiento := 'negativo';
    ELSE
      v_sentimiento := 'neutro';
    END IF;
  END IF;
  IF v_texto ~ 'puntual|a tiempo|rápido|rapido|en hora' THEN
    v_temas := v_temas || jsonb_build_array('puntualidad');
  END IF;
  IF v_texto ~ 'limpi' THEN
    v_temas := v_temas || jsonb_build_array('limpieza');
  END IF;
  IF v_texto ~ 'precio|barat|car[oa]|cobr' THEN
    v_temas := v_temas || jsonb_build_array('precio');
  END IF;
  IF v_texto ~ 'trato|amable|respet|educad' THEN
    v_temas := v_temas || jsonb_build_array('trato');
  END IF;
  IF v_texto ~ 'atras|demor|tard' THEN
    v_temas := v_temas || jsonb_build_array('atraso');
  END IF;
  IF v_texto ~ 'calidad|mal hecho|defect|chapuz' THEN
    v_temas := v_temas || jsonb_build_array('calidad');
  END IF;
  IF v_texto ~ 'no lleg|no vino|no se present|no asist' THEN
    v_temas := v_temas || jsonb_build_array('no_llego');
  END IF;
  IF v_texto ~ 'golpe|agres|amenaz|robo|hurt|dañ|dano|daño|acoso' THEN
    v_grave := true;
    v_temas := v_temas || jsonb_build_array('alerta_grave');
  END IF;
  RETURN jsonb_build_object(
    'sentimiento', v_sentimiento,
    'temas', v_temas,
    'alerta_grave', v_grave,
    'fuente', 'reglas_estrellas'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_clasificar(numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_clasificar(numeric, text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_premium_item(
  p_id text,
  p_etiqueta text,
  p_valor numeric,
  p_unidad text,
  p_ayuda text,
  p_filtro text DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT jsonb_build_object(
    'id', p_id,
    'etiqueta', p_etiqueta,
    'valor', CASE WHEN p_valor IS NULL THEN NULL ELSE round(p_valor, 2) END,
    'unidad', p_unidad,
    'ayuda', p_ayuda,
    'filtro', p_filtro
  );
$$;

REVOKE ALL ON FUNCTION public.consola_premium_item(text, text, numeric, text, text, text) FROM PUBLIC, anon;

CREATE OR REPLACE FUNCTION public.consola_premium_kpis(
  p_seccion text,
  p_desde timestamptz,
  p_hasta timestamptz
) RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_rol text := public.rol_consola();
  v_admin boolean;
  v_sec text := lower(btrim(coalesce(p_seccion, '')));
  v_kpis jsonb := '[]'::jsonb;
  v_series jsonb := '[]'::jsonb;
  v_desgloses jsonb := '[]'::jsonb;
  v_atencion jsonb := '[]'::jsonb;
  v_nota text := NULL;
  v_sin boolean := false;
  v_n bigint;
  v_n2 bigint;
  v_monto numeric;
  v_monto2 numeric;
  v_prom numeric;
  v_puntos jsonb;
BEGIN
  IF v_rol IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_desde IS NULL OR p_hasta IS NULL OR p_hasta <= p_desde THEN
    RAISE EXCEPTION 'rango invalido';
  END IF;
  IF p_hasta - p_desde > interval '400 days' THEN
    RAISE EXCEPTION 'rango demasiado amplio';
  END IF;
  IF v_sec NOT IN (
    'inicio', 'pedidos', 'disputas', 'resenas', 'clientes', 'trabajadores',
    'verificaciones', 'pagos', 'soporte', 'notificaciones', 'seguridad',
    'reportes', 'auditoria', 'configuracion'
  ) THEN
    RAISE EXCEPTION 'seccion desconocida';
  END IF;

  v_admin := public.is_admin();

  IF v_sec IN ('inicio', 'reportes') THEN
    SELECT count(*) INTO v_n
    FROM public.trabajos t
    WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta;
    SELECT count(*) INTO v_n2
    FROM public.trabajos t
    WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      AND t.estado = 'completado';
    v_kpis := v_kpis || jsonb_build_array(
      public.consola_premium_item('pedidos', 'Pedidos del período', v_n, 'numero', 'Pedidos creados en el rango, hora de Santiago.', NULL),
      public.consola_premium_item('completados', 'Pedidos completados', v_n2, 'numero', 'Creados en el período y que hoy están completados. La base no guarda la fecha de término.', 'completado'),
      public.consola_premium_item(
        'finalizacion',
        'Tasa de finalización',
        CASE WHEN v_n = 0 THEN NULL ELSE round(100.0 * v_n2 / v_n, 1) END,
        'porcentaje',
        'Completados dividido por los pedidos creados en el período.',
        NULL
      )
    );
    IF v_admin THEN
      SELECT COALESCE(sum(round(p.monto)), 0), COALESCE(sum(public.comision_servicio_clp(p.monto)) FILTER (WHERE p.tipo_pago = 'principal'), 0)
      INTO v_monto, v_monto2
      FROM public.pagos p
      WHERE public.texto_a_timestamptz(p.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
        AND p.estado IN ('retenido', 'liberado');
      SELECT avg(c.puntaje) INTO v_prom
      FROM public.calificaciones c
      WHERE public.texto_a_timestamptz(c.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
        AND c.estado_revision IS DISTINCT FROM 'excluida';
      v_kpis := v_kpis || jsonb_build_array(
        public.consola_premium_item('gmv', 'Ingresos del período', v_monto, 'clp', 'Suma de pagos retenidos o liberados. No incluye reembolsos.', NULL),
        public.consola_premium_item('comision', 'Comisión ganada', v_monto2, 'clp', 'Comisión de los pagos principales del período, con la regla vigente de la base.', NULL),
        public.consola_premium_item('csat', 'Satisfacción promedio', v_prom, 'estrellas', 'Promedio de estrellas de reseñas visibles del período.', NULL)
      );
    ELSE
      v_nota := 'Tu rol ve la operación y no los montos.';
    END IF;
    SELECT count(*) INTO v_n FROM public.disputas d WHERE public.disputa_esta_activa(d.estado);
    v_kpis := v_kpis || jsonb_build_array(
      public.consola_premium_item('disputas', 'Disputas abiertas', v_n, 'numero', 'Incluye abierta, en revisión, requiere una persona y reembolso pendiente.', 'abiertas')
    );
    v_sin := (SELECT count(*) FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta) = 0;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', to_char(d::date, 'DD mon'),
      'valores', jsonb_build_array(
        jsonb_build_object('nombre', 'Pedidos', 'valor', COALESCE(s.n, 0)),
        jsonb_build_object('nombre', 'Completados', 'valor', COALESCE(s.c, 0))
      )
    ) ORDER BY d), '[]'::jsonb)
    INTO v_series
    FROM generate_series(
      (p_desde AT TIME ZONE 'America/Santiago')::date,
      ((p_hasta - interval '1 second') AT TIME ZONE 'America/Santiago')::date,
      interval '1 day'
    ) AS d
    LEFT JOIN (
      SELECT (public.texto_a_timestamptz(t.creado_en::text) AT TIME ZONE 'America/Santiago')::date AS dia,
             count(*) AS n,
             count(*) FILTER (WHERE t.estado = 'completado') AS c
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      GROUP BY 1
    ) s ON s.dia = d::date;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'pedidos_dia',
      'titulo', 'Pedidos por día',
      'tipo', 'linea',
      'ayuda', 'Pedidos creados cada día del período. La línea de completados usa el estado actual.',
      'puntos', v_series
    ));

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', paso.nombre,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Pedidos', 'valor', paso.n))
    ) ORDER BY paso.orden), '[]'::jsonb)
    INTO v_puntos
    FROM (
      SELECT 1 AS orden, 'Solicitud' AS nombre, count(*) AS n
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      UNION ALL
      SELECT 2, 'Cotización', count(*)
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND t.estado IN ('cotizacion_seleccionada', 'esperando_pago', 'aceptado', 'en_camino', 'en_curso', 'esperando_aprobacion_cliente', 'pausado_orden_cambio', 'completado')
      UNION ALL
      SELECT 3, 'Aceptado', count(*)
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND t.estado IN ('aceptado', 'en_camino', 'en_curso', 'esperando_aprobacion_cliente', 'pausado_orden_cambio', 'completado')
      UNION ALL
      SELECT 4, 'Completado', count(*)
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND t.estado = 'completado'
      UNION ALL
      SELECT 5, 'Pagado', count(DISTINCT t.id)
      FROM public.trabajos t
      JOIN public.pagos p ON p.id_trabajo = t.id
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND p.estado IN ('retenido', 'liberado')
      UNION ALL
      SELECT 6, 'Reseñado', count(DISTINCT t.id)
      FROM public.trabajos t
      JOIN public.calificaciones c ON c.id_trabajo = t.id
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND c.estado_revision IS DISTINCT FROM 'excluida'
    ) paso;
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'embudo',
      'titulo', 'Embudo del pedido',
      'tipo', 'embudo',
      'ayuda', 'Cada paso cuenta pedidos creados en el período que hoy llegaron al menos hasta ahí.',
      'puntos', v_puntos
    ));

    SELECT COALESCE(jsonb_agg(jsonb_build_object('etiqueta', fila.nombre, 'valor', fila.n) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_desgloses
    FROM (
      SELECT COALESCE(c.nombre, 'Sin comuna') AS nombre, count(*) AS n
      FROM public.trabajos t
      LEFT JOIN public.comunas c ON c.id = t.id_comuna
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      GROUP BY 1
      ORDER BY count(*) DESC
      LIMIT 8
    ) fila;
    v_desgloses := jsonb_build_array(jsonb_build_object(
      'id', 'comunas',
      'titulo', 'Dónde se pidió',
      'filas', v_desgloses
    ));

    v_atencion := jsonb_build_array(
      jsonb_build_object(
        'etiqueta', 'Disputas abiertas',
        'valor', (SELECT count(*) FROM public.disputas d WHERE public.disputa_esta_activa(d.estado)),
        'ruta', '/disputas',
        'detalle', 'Incluye abierta y en revisión.'
      ),
      jsonb_build_object(
        'etiqueta', 'Verificaciones por revisar',
        'valor', (SELECT count(*) FROM public.trabajadores w WHERE w.estado_verificacion IN ('pendiente', 'en_revision')),
        'ruta', '/verificaciones',
        'detalle', 'Documentos que todavía no están aprobados.'
      )
    );
    IF v_admin THEN
      v_atencion := v_atencion || jsonb_build_array(jsonb_build_object(
        'etiqueta', 'Pagos fallidos',
        'valor', (
          SELECT count(*) FROM public.pagos p
          WHERE p.estado = 'fallido'
            AND public.texto_a_timestamptz(p.creado_en::text) >= p_desde
            AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
        ),
        'ruta', '/pagos',
        'detalle', 'Pagos del período que quedaron fallidos.'
      ));
    END IF;
  ELSIF v_sec = 'pedidos' THEN
    SELECT
      count(*),
      count(*) FILTER (WHERE t.estado IN ('aceptado', 'en_camino', 'en_curso', 'esperando_aprobacion_cliente', 'pausado_orden_cambio')),
      count(*) FILTER (WHERE t.estado = 'completado'),
      count(*) FILTER (WHERE t.estado IN ('cancelado', 'expirado', 'no_asistio'))
    INTO v_n, v_n2, v_monto, v_monto2
    FROM public.trabajos t
    WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta;
    v_sin := v_n = 0;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('total', 'Pedidos totales', v_n, 'numero', 'Creados en el período.', NULL),
      public.consola_premium_item('curso', 'En curso', v_n2, 'numero', 'Aceptados, en camino, en curso o esperando conformidad.', 'en_curso'),
      public.consola_premium_item('completados', 'Completados', v_monto, 'numero', 'Creados en el período y completados. No hay fecha de término en la base.', 'completado'),
      public.consola_premium_item('cancelados', 'Cancelados', CASE WHEN v_n = 0 THEN NULL ELSE round(100.0 * v_monto2 / v_n, 1) END, 'porcentaje', 'Porcentaje cancelado, expirado o no asistió.', 'cancelado')
    );
    IF v_admin THEN
      SELECT avg(p.monto) INTO v_prom
      FROM public.pagos p
      JOIN public.trabajos t ON t.id = p.id_trabajo
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
        AND p.estado IN ('retenido', 'liberado')
        AND p.monto > 0;
      v_kpis := v_kpis || jsonb_build_array(
        public.consola_premium_item('ticket', 'Ticket promedio', v_prom, 'clp', 'Promedio de pagos retenidos o liberados de esos pedidos.', NULL)
      );
    END IF;
    v_kpis := v_kpis || jsonb_build_array(
      public.consola_premium_item('aceptacion', 'Tiempo hasta aceptación', NULL, 'horas', 'La base no guarda la hora en que el trabajador aceptó. No se inventa.', NULL),
      public.consola_premium_item('termino', 'Tiempo hasta completar', NULL, 'horas', 'La base no guarda la fecha de término. No se usa la última edición como si fuera el cierre.', NULL)
    );
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.estado,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Pedidos', 'valor', fila.n))
    ) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_series
    FROM (
      SELECT t.estado, count(*) AS n
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      GROUP BY t.estado
    ) fila;
    v_series := jsonb_build_array(
      jsonb_build_object('id', 'estados', 'titulo', 'Pedidos por estado', 'tipo', 'barra', 'ayuda', 'Estado actual de los pedidos creados en el período.', 'puntos', v_series)
    );
    SELECT COALESCE(jsonb_agg(jsonb_build_object('etiqueta', left(fila.motivo, 48), 'valor', fila.n) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_desgloses
    FROM (
      SELECT c.motivo, count(*) AS n
      FROM public.cancelaciones_trabajo c
      WHERE public.texto_a_timestamptz(c.cancelado_en::text) >= p_desde
        AND public.texto_a_timestamptz(c.cancelado_en::text) < p_hasta
      GROUP BY c.motivo
      ORDER BY count(*) DESC
      LIMIT 8
    ) fila;
    v_desgloses := jsonb_build_array(jsonb_build_object(
      'id', 'cancelaciones',
      'titulo', 'Por qué se canceló',
      'filas', v_desgloses
    ));
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.etiqueta,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Pedidos', 'valor', fila.n))
    ) ORDER BY fila.orden), '[]'::jsonb)
    INTO v_puntos
    FROM (
      SELECT
        extract(dow FROM public.texto_a_timestamptz(t.creado_en::text) AT TIME ZONE 'America/Santiago')::int AS orden,
        to_char(public.texto_a_timestamptz(t.creado_en::text) AT TIME ZONE 'America/Santiago', 'Dy') AS etiqueta,
        count(*) AS n
      FROM public.trabajos t
      WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      GROUP BY 1, 2
    ) fila;
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'semana',
      'titulo', 'Qué día se pide más',
      'tipo', 'barra',
      'ayuda', 'Pedidos agrupados por día de la semana, hora de Santiago.',
      'puntos', COALESCE(v_puntos, '[]'::jsonb)
    ));
  ELSIF v_sec = 'disputas' THEN
    SELECT
      count(*) FILTER (WHERE public.disputa_esta_activa(d.estado)),
      count(*) FILTER (WHERE d.estado = 'en_revision'),
      count(*) FILTER (WHERE d.estado = 'resuelta' AND public.texto_a_timestamptz(d.resuelta_en::text) >= p_desde AND public.texto_a_timestamptz(d.resuelta_en::text) < p_hasta)
    INTO v_n, v_n2, v_monto
    FROM public.disputas d;
    SELECT count(*) INTO v_monto2 FROM public.trabajos t
    WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('abiertas', 'Abiertas', v_n, 'numero', 'Disputas que siguen activas, incluidas abierta y en revisión.', 'abiertas'),
      public.consola_premium_item('revision', 'En revisión', v_n2, 'numero', 'Casos marcados en revisión.', 'en_revision'),
      public.consola_premium_item('resueltas', 'Resueltas en el período', v_monto, 'numero', 'Cerradas dentro del rango.', 'resuelta'),
      public.consola_premium_item(
        'tasa',
        'Tasa de disputa',
        CASE WHEN v_monto2 = 0 THEN NULL ELSE round(100.0 * (
          SELECT count(*) FROM public.disputas d
          WHERE public.texto_a_timestamptz(d.creado_en::text) >= p_desde
            AND public.texto_a_timestamptz(d.creado_en::text) < p_hasta
        ) / v_monto2, 1) END,
        'porcentaje',
        'Disputas creadas en el período dividido por pedidos creados.',
        NULL
      )
    );
    SELECT count(*) FILTER (WHERE d.resuelta_en IS NOT NULL AND d.vence_en IS NOT NULL AND public.texto_a_timestamptz(d.resuelta_en::text) <= d.vence_en),
           count(*) FILTER (WHERE d.estado = 'resuelta' AND d.vence_en IS NOT NULL)
    INTO v_n, v_n2
    FROM public.disputas d
    WHERE d.estado = 'resuelta'
      AND public.texto_a_timestamptz(d.resuelta_en::text) >= p_desde
      AND public.texto_a_timestamptz(d.resuelta_en::text) < p_hasta;
    v_kpis := v_kpis || jsonb_build_array(
      public.consola_premium_item('sla', 'Dentro del plazo', CASE WHEN v_n2 = 0 THEN NULL ELSE round(100.0 * v_n / v_n2, 1) END, 'porcentaje', 'Resueltas antes de la fecha de vencimiento.', NULL),
      public.consola_premium_item('horas', 'Horas promedio de resolución', (
        SELECT round(avg(extract(epoch FROM (public.texto_a_timestamptz(d.resuelta_en::text) - public.texto_a_timestamptz(d.creado_en::text))) / 3600.0), 1)
        FROM public.disputas d
        WHERE d.estado = 'resuelta'
          AND public.texto_a_timestamptz(d.resuelta_en::text) >= p_desde
          AND public.texto_a_timestamptz(d.resuelta_en::text) < p_hasta
      ), 'horas', 'Desde que se abrió hasta que se resolvió.', NULL)
    );
    IF v_admin THEN
      SELECT COALESCE(sum(p.monto), 0) INTO v_prom
      FROM public.disputas d
      JOIN public.pagos p ON p.id_trabajo = d.id_trabajo
      WHERE public.disputa_esta_activa(d.estado)
        AND p.estado IN ('retenido', 'autorizado', 'pendiente');
      v_kpis := v_kpis || jsonb_build_array(
        public.consola_premium_item('monto', 'Plata en disputa', v_prom, 'clp', 'Suma de pagos todavía retenidos en casos abiertos.', NULL)
      );
    END IF;
    v_sin := (SELECT count(*) FROM public.disputas) = 0;
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.motivo,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Casos', 'valor', fila.n))
    ) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_series
    FROM (
      SELECT d.motivo, count(*) AS n
      FROM public.disputas d
      WHERE public.texto_a_timestamptz(d.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(d.creado_en::text) < p_hasta
      GROUP BY d.motivo
      ORDER BY count(*) DESC
      LIMIT 8
    ) fila;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'motivos', 'titulo', 'Motivos', 'tipo', 'barra',
      'ayuda', 'Por qué se abrió el caso en el período.', 'puntos', v_series
    ));
    SELECT COALESCE(jsonb_agg(jsonb_build_object('etiqueta', fila.estado, 'valor', fila.n, 'filtro', fila.estado)), '[]'::jsonb)
    INTO v_desgloses
    FROM (
      SELECT d.estado, count(*) AS n FROM public.disputas d GROUP BY d.estado
    ) fila;
    v_desgloses := jsonb_build_array(jsonb_build_object('id', 'estados', 'titulo', 'Casos por estado', 'filas', v_desgloses));
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'resultado',
      'titulo', 'Cómo terminaron',
      'tipo', 'barra',
      'ayuda', 'Resoluciones escritas en el período, agrupadas por las primeras palabras.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', left(fila.resolucion, 32),
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Casos', 'valor', fila.n))
        ))
        FROM (
          SELECT COALESCE(NULLIF(left(d.resolucion, 32), ''), 'Sin texto') AS resolucion, count(*) AS n
          FROM public.disputas d
          WHERE d.estado = 'resuelta'
            AND public.texto_a_timestamptz(d.resuelta_en::text) >= p_desde
            AND public.texto_a_timestamptz(d.resuelta_en::text) < p_hasta
          GROUP BY 1
          ORDER BY count(*) DESC
          LIMIT 6
        ) fila
      ), '[]'::jsonb)
    ));
  ELSIF v_sec = 'resenas' THEN
    SELECT
      count(*),
      avg(c.puntaje),
      count(*) FILTER (WHERE c.puntaje >= 4),
      count(*) FILTER (WHERE c.puntaje <= 2)
    INTO v_n, v_prom, v_n2, v_monto
    FROM public.calificaciones c
    WHERE public.texto_a_timestamptz(c.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
      AND c.estado_revision IS DISTINCT FROM 'excluida';
    v_sin := v_n = 0;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('promedio', 'Calificación promedio', v_prom, 'estrellas', 'Promedio de reseñas visibles del período.', NULL),
      public.consola_premium_item('total', 'Total de reseñas', v_n, 'numero', 'Reseñas visibles creadas en el período.', NULL),
      public.consola_premium_item('positivas', 'Positivas', CASE WHEN v_n = 0 THEN NULL ELSE round(100.0 * v_n2 / v_n, 1) END, 'porcentaje', '4 o 5 estrellas. La clasificación de respaldo usa esta regla.', 'positivas'),
      public.consola_premium_item('negativas', 'Negativas', CASE WHEN v_n = 0 THEN NULL ELSE round(100.0 * v_monto / v_n, 1) END, 'porcentaje', '1 o 2 estrellas.', 'negativas'),
      public.consola_premium_item('csat', 'Satisfacción', CASE WHEN v_prom IS NULL THEN NULL ELSE round(100.0 * v_prom / 5, 1) END, 'porcentaje', 'El promedio de estrellas llevado a una escala de 0 a 100.', NULL),
      public.consola_premium_item('respuesta', 'Tasa de respuesta', NULL, 'porcentaje', 'La base no guarda una respuesta pública a la reseña. No se inventa el porcentaje.', 'sin_responder')
    );
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.dia,
      'valores', jsonb_build_array(
        jsonb_build_object('nombre', 'Positivas', 'valor', fila.pos),
        jsonb_build_object('nombre', 'Neutras', 'valor', fila.neu),
        jsonb_build_object('nombre', 'Negativas', 'valor', fila.neg)
      )
    ) ORDER BY fila.dia), '[]'::jsonb)
    INTO v_series
    FROM (
      SELECT to_char((public.texto_a_timestamptz(c.creado_en::text) AT TIME ZONE 'America/Santiago')::date, 'YYYY-MM-DD') AS dia,
             count(*) FILTER (WHERE c.puntaje >= 4) AS pos,
             count(*) FILTER (WHERE c.puntaje = 3) AS neu,
             count(*) FILTER (WHERE c.puntaje <= 2) AS neg
      FROM public.calificaciones c
      WHERE public.texto_a_timestamptz(c.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
        AND c.estado_revision IS DISTINCT FROM 'excluida'
      GROUP BY 1
    ) fila;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'sentimiento',
      'titulo', 'Positivas, neutras y negativas',
      'tipo', 'area',
      'ayuda', 'Clasificación por estrellas. La fuente es reglas_estrellas mientras no haya una función de IA en este entorno.',
      'puntos', v_series
    ));
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.estrellas::text,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Reseñas', 'valor', fila.n))
    ) ORDER BY fila.estrellas), '[]'::jsonb)
    INTO v_puntos
    FROM (
      SELECT g.estrellas, count(c.id) AS n
      FROM generate_series(1, 5) AS g(estrellas)
      LEFT JOIN public.calificaciones c
        ON c.puntaje = g.estrellas
       AND public.texto_a_timestamptz(c.creado_en::text) >= p_desde
       AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
       AND c.estado_revision IS DISTINCT FROM 'excluida'
      GROUP BY g.estrellas
    ) fila;
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'estrellas',
      'titulo', 'Distribución de estrellas',
      'tipo', 'barra',
      'ayuda', 'Cuántas reseñas hay en cada nota.',
      'puntos', COALESCE(v_puntos, '[]'::jsonb)
    ));
    SELECT COALESCE(jsonb_agg(jsonb_build_object('etiqueta', fila.tema, 'valor', fila.n, 'filtro', fila.tema) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_desgloses
    FROM (
      SELECT tema.tema, count(*) AS n
      FROM public.calificaciones c
      CROSS JOIN LATERAL jsonb_array_elements_text(public.consola_premium_clasificar(c.puntaje, c.comentario) -> 'temas') AS tema(tema)
      WHERE public.texto_a_timestamptz(c.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
        AND c.estado_revision IS DISTINCT FROM 'excluida'
      GROUP BY tema.tema
    ) fila;
    v_desgloses := jsonb_build_array(jsonb_build_object(
      'id', 'temas',
      'titulo', 'Temas en los comentarios',
      'filas', v_desgloses
    ));
    v_nota := 'Fuente del sentimiento: reglas_estrellas. Una función de IA, si existe, solo puede proponer.';
  ELSIF v_sec = 'clientes' THEN
    SELECT count(*) INTO v_n FROM public.perfiles p WHERE p.rol = 'usuario';
    SELECT count(*) INTO v_n2 FROM public.perfiles p
    WHERE p.rol = 'usuario'
      AND public.texto_a_timestamptz(p.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta;
    SELECT count(DISTINCT t.id_usuario) INTO v_monto
    FROM public.trabajos t
    WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_hasta - interval '30 days'
      AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('total', 'Clientes', v_n, 'numero', 'Personas con rol de cliente.', NULL),
      public.consola_premium_item('nuevos', 'Nuevos en el período', v_n2, 'numero', 'Cuentas de cliente creadas en el rango.', NULL),
      public.consola_premium_item('activos', 'Activos en 30 días', v_monto, 'numero', 'Clientes distintos que pidieron en los 30 días hasta el fin del rango.', NULL),
      public.consola_premium_item('disputas', 'Clientes con disputas', (
        SELECT count(DISTINCT t.id_usuario)
        FROM public.disputas d
        JOIN public.trabajos t ON t.id = d.id_trabajo
        WHERE public.texto_a_timestamptz(d.creado_en::text) >= p_desde
          AND public.texto_a_timestamptz(d.creado_en::text) < p_hasta
      ), 'numero', 'Clientes distintos con un caso abierto o cerrado en el período.', NULL),
      public.consola_premium_item('retencion', 'Clientes que volvieron', NULL, 'porcentaje', 'No hay una cohorte cerrada en la base. No se inventa la retención a 30 o 90 días.', NULL)
    );
    v_sin := v_n = 0;
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', to_char(d::date, 'DD mon'),
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Altas', 'valor', COALESCE(s.n, 0)))
    ) ORDER BY d), '[]'::jsonb)
    INTO v_series
    FROM generate_series(
      (p_desde AT TIME ZONE 'America/Santiago')::date,
      ((p_hasta - interval '1 second') AT TIME ZONE 'America/Santiago')::date,
      interval '1 day'
    ) AS d
    LEFT JOIN (
      SELECT (public.texto_a_timestamptz(p.creado_en::text) AT TIME ZONE 'America/Santiago')::date AS dia, count(*) AS n
      FROM public.perfiles p
      WHERE p.rol = 'usuario'
        AND public.texto_a_timestamptz(p.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
      GROUP BY 1
    ) s ON s.dia = d::date;
    v_series := jsonb_build_array(
      jsonb_build_object('id', 'altas', 'titulo', 'Clientes nuevos', 'tipo', 'linea', 'ayuda', 'Cuentas creadas por día.', 'puntos', v_series),
      jsonb_build_object('id', 'frecuencia', 'titulo', 'Cuántas veces pidieron', 'tipo', 'barra', 'ayuda', 'Clientes según cuántos pedidos tienen en el período.', 'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.veces::text || ' pedidos',
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Clientes', 'valor', fila.n))
        ))
        FROM (
          SELECT veces, count(*) AS n FROM (
            SELECT count(*) AS veces
            FROM public.trabajos t
            WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
              AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
            GROUP BY t.id_usuario
          ) g GROUP BY veces
        ) fila
      ), '[]'::jsonb))
    );
    v_desgloses := '[]'::jsonb;
  ELSIF v_sec = 'trabajadores' THEN
    SELECT
      count(*) FILTER (WHERE w.estado_verificacion = 'verificado'),
      count(*),
      avg(w.calificacion)
    INTO v_n, v_n2, v_prom
    FROM public.trabajadores w;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('activos', 'Verificados', v_n, 'numero', 'Trabajadores con verificación aprobada.', 'verificado'),
      public.consola_premium_item('total', 'En la base', v_n2, 'numero', 'Fichas de trabajador, en cualquier estado.', NULL),
      public.consola_premium_item('porcentaje', 'Porcentaje verificado', CASE WHEN v_n2 = 0 THEN NULL ELSE round(100.0 * v_n / v_n2, 1) END, 'porcentaje', 'Verificados sobre el total de fichas.', NULL),
      public.consola_premium_item('nota', 'Calificación promedio', v_prom, 'estrellas', 'Promedio guardado en la ficha del trabajador.', NULL)
    );
    v_sin := v_n2 = 0;
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'x', fila.profesion,
      'valores', jsonb_build_array(jsonb_build_object('nombre', 'Trabajadores', 'valor', fila.n))
    ) ORDER BY fila.n DESC), '[]'::jsonb)
    INTO v_series
    FROM (
      SELECT COALESCE(NULLIF(w.profesion, ''), 'Sin oficio') AS profesion, count(*) AS n
      FROM public.trabajadores w
      GROUP BY 1
      ORDER BY count(*) DESC
      LIMIT 8
    ) fila;
    v_series := jsonb_build_array(
      jsonb_build_object('id', 'oficio', 'titulo', 'Oferta por oficio', 'tipo', 'barra', 'ayuda', 'Cuántos trabajadores hay en cada oficio.', 'puntos', v_series),
      jsonb_build_object('id', 'verificacion', 'titulo', 'Estado de verificación', 'tipo', 'barra', 'ayuda', 'Cómo está la cola de documentos.', 'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Personas', 'valor', fila.n))
        ))
        FROM (
          SELECT w.estado_verificacion AS estado, count(*) AS n
          FROM public.trabajadores w
          GROUP BY w.estado_verificacion
        ) fila
      ), '[]'::jsonb))
    );
    v_desgloses := '[]'::jsonb;
  ELSIF v_sec = 'verificaciones' THEN
    SELECT
      count(*) FILTER (WHERE w.estado_verificacion IN ('pendiente', 'en_revision')),
      count(*) FILTER (WHERE w.estado_verificacion = 'verificado'),
      count(*) FILTER (WHERE w.estado_verificacion = 'rechazado')
    INTO v_n, v_n2, v_monto
    FROM public.trabajadores w;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('pendientes', 'Por revisar', v_n, 'numero', 'Pendientes o en revisión.', 'en_revision'),
      public.consola_premium_item('aprobados', 'Aprobados', CASE WHEN (v_n2 + v_monto) = 0 THEN NULL ELSE round(100.0 * v_n2 / (v_n2 + v_monto), 1) END, 'porcentaje', 'Aprobados sobre aprobados más rechazados.', 'verificado'),
      public.consola_premium_item('tiempo', 'Horas de revisión', NULL, 'horas', 'La ficha no guarda el minuto en que empezó la revisión. No se calcula un promedio inventado.', NULL)
    );
    v_sin := v_n = 0 AND v_n2 = 0;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'cola',
      'titulo', 'Cola de documentos',
      'tipo', 'barra',
      'ayuda', 'Estado actual de las verificaciones.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Personas', 'valor', fila.n))
        ))
        FROM (
          SELECT w.estado_verificacion AS estado, count(*) AS n
          FROM public.trabajadores w
          GROUP BY w.estado_verificacion
        ) fila
      ), '[]'::jsonb)
    ), jsonb_build_object(
      'id', 'resultado',
      'titulo', 'Aprobados y rechazados',
      'tipo', 'barra',
      'ayuda', 'Resultado acumulado de la verificación.',
      'puntos', jsonb_build_array(
        jsonb_build_object('x', 'Por revisar', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Personas', 'valor', v_n))),
        jsonb_build_object('x', 'Aprobados', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Personas', 'valor', v_n2))),
        jsonb_build_object('x', 'Rechazados', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Personas', 'valor', v_monto)))
      )
    ));
    v_desgloses := '[]'::jsonb;
    v_nota := 'La sugerencia de la IA, si la función existe, se muestra como propuesta. La persona aprueba o rechaza.';
  ELSIF v_sec = 'pagos' THEN
    IF NOT v_admin THEN
      v_nota := 'Tu rol no ve los montos.';
    ELSE
      SELECT COALESCE(sum(round(p.monto)), 0) INTO v_monto
      FROM public.pagos p
      WHERE public.texto_a_timestamptz(p.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
        AND p.estado IN ('retenido', 'liberado');
      SELECT COALESCE(sum(public.comision_servicio_clp(p.monto)), 0) INTO v_monto2
      FROM public.pagos p
      WHERE public.texto_a_timestamptz(p.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
        AND p.tipo_pago = 'principal'
        AND p.estado IN ('retenido', 'liberado');
      SELECT COALESCE(sum(round(p.monto)), 0) INTO v_n FROM public.pagos p WHERE p.estado = 'retenido';
      SELECT COALESCE(sum(round(p.monto)), 0) INTO v_n2
      FROM public.pagos p
      WHERE p.estado = 'reembolsado'
        AND public.texto_a_timestamptz(COALESCE(p.reembolsado_en, p.creado_en)::text) >= p_desde
        AND public.texto_a_timestamptz(COALESCE(p.reembolsado_en, p.creado_en)::text) < p_hasta;
      SELECT count(*) INTO v_prom FROM public.pagos p
      WHERE p.estado = 'fallido'
        AND public.texto_a_timestamptz(p.creado_en::text) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta;
      v_kpis := jsonb_build_array(
        public.consola_premium_item('gmv', 'Ingresos', v_monto, 'clp', 'Pagos retenidos o liberados del período.', NULL),
        public.consola_premium_item('comision', 'Comisión', v_monto2, 'clp', 'Comisión de los pagos principales.', NULL),
        public.consola_premium_item('pendiente', 'Plata pendiente de pagar', v_n, 'clp', 'Pagos que siguen retenidos, aunque sean de otro período.', NULL),
        public.consola_premium_item('reembolsos', 'Reembolsos', v_n2, 'clp', 'Dinero devuelto en el período.', NULL),
        public.consola_premium_item('fallidos', 'Pagos fallidos', v_prom, 'numero', 'Intentos que quedaron fallidos.', 'fallido')
      );
      v_sin := v_monto = 0 AND v_prom = 0;
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'x', to_char(d::date, 'DD mon'),
        'valores', jsonb_build_array(jsonb_build_object('nombre', 'Ingresos', 'valor', COALESCE(s.monto, 0)))
      ) ORDER BY d), '[]'::jsonb)
      INTO v_series
      FROM generate_series(
        (p_desde AT TIME ZONE 'America/Santiago')::date,
        ((p_hasta - interval '1 second') AT TIME ZONE 'America/Santiago')::date,
        interval '1 day'
      ) AS d
      LEFT JOIN (
        SELECT (public.texto_a_timestamptz(p.creado_en::text) AT TIME ZONE 'America/Santiago')::date AS dia,
               sum(round(p.monto)) AS monto
        FROM public.pagos p
        WHERE p.estado IN ('retenido', 'liberado')
          AND public.texto_a_timestamptz(p.creado_en::text) >= p_desde
          AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
        GROUP BY 1
      ) s ON s.dia = d::date;
      v_series := jsonb_build_array(
        jsonb_build_object('id', 'ingresos', 'titulo', 'Ingresos por día', 'tipo', 'linea', 'ayuda', 'Pagos retenidos o liberados.', 'puntos', v_series),
        jsonb_build_object('id', 'estados', 'titulo', 'Pagos por estado', 'tipo', 'barra', 'ayuda', 'Cantidad de pagos del período en cada estado.', 'puntos', COALESCE((
          SELECT jsonb_agg(jsonb_build_object(
            'x', fila.estado,
            'valores', jsonb_build_array(jsonb_build_object('nombre', 'Pagos', 'valor', fila.n))
          ))
          FROM (
            SELECT p.estado, count(*) AS n
            FROM public.pagos p
            WHERE public.texto_a_timestamptz(p.creado_en::text) >= p_desde
              AND public.texto_a_timestamptz(p.creado_en::text) < p_hasta
            GROUP BY p.estado
          ) fila
        ), '[]'::jsonb))
      );
    END IF;
    v_desgloses := '[]'::jsonb;
    v_nota := COALESCE(v_nota, 'Cualquier movimiento de dinero usa las funciones webpay ya existentes y pide confirmación fuerte. Esta pantalla no cobra sola.');
  ELSIF v_sec = 'soporte' THEN
    SELECT
      count(*) FILTER (WHERE COALESCE(t.estado, 'pendiente') IS DISTINCT FROM 'resuelto'),
      count(*) FILTER (WHERE t.estado = 'resuelto')
    INTO v_n, v_n2
    FROM public.tickets_soporte t;
    SELECT count(*) INTO v_monto FROM public.reportes r WHERE r.estado = 'pendiente';
    v_kpis := jsonb_build_array(
      public.consola_premium_item('abiertos', 'Tickets sin cerrar', v_n, 'numero', 'Tickets que no están resueltos.', NULL),
      public.consola_premium_item('resueltos', 'Tickets resueltos', v_n2, 'numero', 'Tickets marcados como resueltos.', NULL),
      public.consola_premium_item('reportes', 'Reportes por ver', v_monto, 'numero', 'Reportes de abuso todavía pendientes.', NULL),
      public.consola_premium_item('primera', 'Primera respuesta', (
        SELECT round(avg(extract(epoch FROM (m.minimo - public.texto_a_timestamptz(t.creado_en::text))) / 3600.0), 1)
        FROM public.tickets_soporte t
        JOIN (
          SELECT id_ticket, min(creado_en) AS minimo
          FROM public.ticket_mensajes
          GROUP BY id_ticket
        ) m ON m.id_ticket = t.id
        WHERE public.texto_a_timestamptz(t.creado_en::text) >= p_desde
          AND public.texto_a_timestamptz(t.creado_en::text) < p_hasta
      ), 'horas', 'Horas entre el ticket y el primer mensaje del hilo, en el período.', NULL)
    );
    v_sin := v_n = 0 AND v_monto = 0;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'tickets',
      'titulo', 'Tickets por estado',
      'tipo', 'barra',
      'ayuda', 'Estado actual de la bandeja.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Tickets', 'valor', fila.n))
        ))
        FROM (
          SELECT COALESCE(t.estado, 'pendiente') AS estado, count(*) AS n
          FROM public.tickets_soporte t
          GROUP BY 1
        ) fila
      ), '[]'::jsonb)
    ));
    v_desgloses := jsonb_build_array(jsonb_build_object(
      'id', 'moderacion',
      'titulo', 'Cola de moderación',
      'filas', jsonb_build_array(jsonb_build_object(
        'etiqueta', 'La cola de la función moderar-mensaje no está en esta base',
        'valor', 0
      ))
    ));
    v_nota := 'Si la función moderar-mensaje no responde, la bandeja lo dice y no inventa mensajes marcados.';
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'reportes',
      'titulo', 'Reportes por estado',
      'tipo', 'barra',
      'ayuda', 'Abuso informado por las personas.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Reportes', 'valor', fila.n))
        ))
        FROM (
          SELECT r.estado, count(*) AS n
          FROM public.reportes r
          GROUP BY r.estado
        ) fila
      ), '[]'::jsonb)
    ));
  ELSIF v_sec = 'notificaciones' THEN
    SELECT count(*), count(*) FILTER (WHERE n.leido = 0)
    INTO v_n, v_n2
    FROM public.notificaciones n
    WHERE public.texto_a_timestamptz(n.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(n.creado_en::text) < p_hasta;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('enviadas', 'Avisos del período', v_n, 'numero', 'Filas de notificación creadas en el rango.', NULL),
      public.consola_premium_item('sin_leer', 'Sin leer', v_n2, 'numero', 'Avisos del período que siguen sin marcar como leídos.', NULL),
      public.consola_premium_item('apertura', 'Apertura del push', NULL, 'porcentaje', 'La base marca leído dentro de la app. No guarda la apertura del aviso del sistema.', NULL)
    );
    v_sin := v_n = 0;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'tipos',
      'titulo', 'Avisos por tipo',
      'tipo', 'barra',
      'ayuda', 'Tipos de notificación del período.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.tipo,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Avisos', 'valor', fila.n))
        ))
        FROM (
          SELECT n.tipo, count(*) AS n
          FROM public.notificaciones n
          WHERE public.texto_a_timestamptz(n.creado_en::text) >= p_desde
            AND public.texto_a_timestamptz(n.creado_en::text) < p_hasta
          GROUP BY n.tipo
        ) fila
      ), '[]'::jsonb)
    ));
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'lectura',
      'titulo', 'Leídos y sin leer',
      'tipo', 'barra',
      'ayuda', 'Dentro de la app, no del sistema operativo.',
      'puntos', jsonb_build_array(
        jsonb_build_object('x', 'Sin leer', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Avisos', 'valor', v_n2))),
        jsonb_build_object('x', 'Leídos', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Avisos', 'valor', GREATEST(v_n - v_n2, 0))))
      )
    ));
    v_desgloses := '[]'::jsonb;
  ELSIF v_sec = 'seguridad' THEN
    IF NOT v_admin THEN
      v_nota := 'El detalle de seguridad es solo para administración.';
    ELSE
      SELECT
        count(*) FILTER (WHERE i.estado = 'abierto' AND i.severidad = 'alta'),
        count(*) FILTER (WHERE i.estado = 'abierto' AND i.severidad = 'media'),
        count(*) FILTER (WHERE i.estado = 'abierto' AND i.severidad = 'baja')
      INTO v_n, v_n2, v_monto
      FROM public.incidentes_seguridad i;
      SELECT count(*) INTO v_prom
      FROM public.eventos_acceso e
      WHERE e.tipo = 'login_fallido'
        AND e.creado_en >= p_desde
        AND e.creado_en < p_hasta;
      v_kpis := jsonb_build_array(
        public.consola_premium_item('alta', 'Alertas altas', v_n, 'numero', 'Incidentes abiertos de severidad alta.', NULL),
        public.consola_premium_item('media', 'Alertas medias', v_n2, 'numero', 'Incidentes abiertos de severidad media.', NULL),
        public.consola_premium_item('baja', 'Alertas bajas', v_monto, 'numero', 'Incidentes abiertos de severidad baja.', NULL),
        public.consola_premium_item('fallidos', 'Inicios fallidos', v_prom, 'numero', 'Eventos login_fallido de la consola en el período.', NULL)
      );
      v_sin := v_n = 0 AND v_prom = 0;
      v_series := jsonb_build_array(
        jsonb_build_object('id', 'severidad', 'titulo', 'Alertas abiertas', 'tipo', 'barra', 'ayuda', 'Incidentes que siguen abiertos.', 'puntos', jsonb_build_array(
          jsonb_build_object('x', 'Alta', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Alertas', 'valor', v_n))),
          jsonb_build_object('x', 'Media', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Alertas', 'valor', v_n2))),
          jsonb_build_object('x', 'Baja', 'valores', jsonb_build_array(jsonb_build_object('nombre', 'Alertas', 'valor', v_monto)))
        )),
        jsonb_build_object('id', 'tipos', 'titulo', 'Tipos de incidente', 'tipo', 'barra', 'ayuda', 'Historial del período por tipo.', 'puntos', COALESCE((
          SELECT jsonb_agg(jsonb_build_object(
            'x', fila.tipo,
            'valores', jsonb_build_array(jsonb_build_object('nombre', 'Incidentes', 'valor', fila.n))
          ))
          FROM (
            SELECT i.tipo, count(*) AS n
            FROM public.incidentes_seguridad i
            WHERE i.creado_en >= p_desde AND i.creado_en < p_hasta
            GROUP BY i.tipo
          ) fila
        ), '[]'::jsonb))
      );
    END IF;
    v_desgloses := '[]'::jsonb;
  ELSIF v_sec = 'auditoria' THEN
    SELECT count(*) INTO v_n
    FROM public.auditoria_consola a
    WHERE a.creado_en >= p_desde AND a.creado_en < p_hasta;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('eventos', 'Hechos registrados', v_n, 'numero', 'Filas de la bitácora en el período. No se pueden borrar desde la consola.', NULL),
      public.consola_premium_item('personas', 'Personas que actuaron', (
        SELECT count(DISTINCT a.id_actor) FROM public.auditoria_consola a
        WHERE a.creado_en >= p_desde AND a.creado_en < p_hasta
      ), 'numero', 'Actores distintos de la bitácora. El identificador no se muestra en el gráfico.', NULL),
      public.consola_premium_item('acciones', 'Tipos de acción', (
        SELECT count(DISTINCT a.accion) FROM public.auditoria_consola a
        WHERE a.creado_en >= p_desde AND a.creado_en < p_hasta
      ), 'numero', 'Cuántas clases de acción distintas quedaron registradas.', NULL),
      public.consola_premium_item('borrado', 'Filas borradas', 0, 'numero', 'La bitácora no se borra desde la consola.', NULL)
    );
    v_sin := v_n = 0;
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'acciones',
      'titulo', 'Qué se hizo',
      'tipo', 'barra',
      'ayuda', 'Acciones de la bitácora en el período.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.accion,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Hechos', 'valor', fila.n))
        ) ORDER BY fila.n DESC)
        FROM (
          SELECT a.accion::text AS accion, count(*) AS n
          FROM public.auditoria_consola a
          WHERE a.creado_en >= p_desde AND a.creado_en < p_hasta
          GROUP BY a.accion
        ) fila
      ), '[]'::jsonb)
    ));
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'roles',
      'titulo', 'Quién actuó',
      'tipo', 'barra',
      'ayuda', 'Rol de quien hizo la acción.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.rol,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Hechos', 'valor', fila.n))
        ))
        FROM (
          SELECT COALESCE(a.rol_actor, 'sin rol') AS rol, count(*) AS n
          FROM public.auditoria_consola a
          WHERE a.creado_en >= p_desde AND a.creado_en < p_hasta
          GROUP BY a.rol_actor
        ) fila
      ), '[]'::jsonb)
    ));
    v_desgloses := '[]'::jsonb;
  ELSIF v_sec = 'configuracion' THEN
    SELECT count(*) INTO v_n FROM public.app_config;
    SELECT count(*) INTO v_n2 FROM public.comunas c WHERE c.activa = 1;
    v_kpis := jsonb_build_array(
      public.consola_premium_item('ajustes', 'Ajustes guardados', v_n, 'numero', 'Claves de app_config que la administración puede leer.', NULL),
      public.consola_premium_item('comunas', 'Comunas habilitadas', v_n2, 'numero', 'Comunas marcadas como activas.', NULL)
    );
    v_series := jsonb_build_array(jsonb_build_object(
      'id', 'banderas',
      'titulo', 'Interruptores',
      'tipo', 'barra',
      'ayuda', 'Banderas de funcionalidad.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Banderas', 'valor', fila.n))
        ))
        FROM (
          SELECT CASE WHEN b.habilitada = 1 THEN 'Activas' ELSE 'Apagadas' END AS estado, count(*) AS n
          FROM public.banderas_funcionalidad b
          GROUP BY 1
        ) fila
      ), '[]'::jsonb)
    ));
    v_series := v_series || jsonb_build_array(jsonb_build_object(
      'id', 'servicios',
      'titulo', 'Servicios del catálogo',
      'tipo', 'barra',
      'ayuda', 'Servicios activos e inactivos.',
      'puntos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'x', fila.estado,
          'valores', jsonb_build_array(jsonb_build_object('nombre', 'Servicios', 'valor', fila.n))
        ))
        FROM (
          SELECT CASE WHEN s.activo = 1 THEN 'Activos' ELSE 'Inactivos' END AS estado, count(*) AS n
          FROM public.servicios s
          GROUP BY 1
        ) fila
      ), '[]'::jsonb)
    ));
    v_desgloses := '[]'::jsonb;
    v_nota := 'La lectura de app_config sigue limitada a administración con la política de is_admin().';
  END IF;

  RETURN jsonb_build_object(
    'seccion', v_sec,
    'fuente', 'sql',
    'sin_movimiento', v_sin,
    'sin_permiso', false,
    'nota', v_nota,
    'kpis', v_kpis,
    'series', v_series,
    'desgloses', v_desgloses,
    'atencion', v_atencion
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_kpis(text, timestamptz, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_kpis(text, timestamptz, timestamptz) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_premium_resenas(
  p_desde timestamptz,
  p_hasta timestamptz,
  p_filtro text,
  p_tema text,
  p_offset integer,
  p_limite integer
) RETURNS TABLE (
  id text,
  puntaje numeric,
  comentario text,
  estado_revision text,
  sentimiento text,
  temas jsonb,
  alerta_grave boolean,
  fuente text,
  creado_en text,
  trabajador text,
  id_trabajo text,
  total bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_limite integer := LEAST(GREATEST(COALESCE(p_limite, 25), 1), 100);
  v_offset integer := GREATEST(COALESCE(p_offset, 0), 0);
  v_filtro text := lower(btrim(COALESCE(p_filtro, 'todas')));
  v_tema text := NULLIF(lower(btrim(COALESCE(p_tema, ''))), '');
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_hasta <= p_desde OR p_hasta - p_desde > interval '400 days' THEN
    RAISE EXCEPTION 'rango invalido';
  END IF;
  RETURN QUERY
  WITH base AS (
    SELECT
      c.id,
      c.puntaje,
      c.comentario,
      c.estado_revision,
      c.creado_en,
      c.id_trabajo,
      c.id_calificado,
      public.consola_premium_clasificar(c.puntaje, c.comentario) AS clase
    FROM public.calificaciones c
    WHERE public.texto_a_timestamptz(c.creado_en::text) >= p_desde
      AND public.texto_a_timestamptz(c.creado_en::text) < p_hasta
  ),
  filtrada AS (
    SELECT * FROM base b
    WHERE (
      v_filtro = 'todas'
      OR (v_filtro = 'positivas' AND b.clase ->> 'sentimiento' = 'positivo')
      OR (v_filtro = 'negativas' AND b.clase ->> 'sentimiento' = 'negativo')
      OR (v_filtro = 'sin_responder' AND b.estado_revision = 'vigente')
      OR (v_filtro = 'marcadas' AND (b.estado_revision = 'en_revision' OR (b.clase ->> 'alerta_grave')::boolean))
    )
    AND (
      v_tema IS NULL
      OR b.clase -> 'temas' ? v_tema
    )
  )
  SELECT
    f.id::text,
    f.puntaje::numeric,
    left(f.comentario, 600),
    f.estado_revision,
    f.clase ->> 'sentimiento',
    f.clase -> 'temas',
    (f.clase ->> 'alerta_grave')::boolean,
    f.clase ->> 'fuente',
    f.creado_en::text,
    COALESCE(p.nombre, 'Trabajador'),
    f.id_trabajo::text,
    count(*) OVER ()
  FROM filtrada f
  LEFT JOIN public.perfiles p ON p.id = f.id_calificado
  ORDER BY public.texto_a_timestamptz(f.creado_en::text) DESC
  OFFSET v_offset
  LIMIT v_limite;
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_resenas(timestamptz, timestamptz, text, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_resenas(timestamptz, timestamptz, text, text, integer, integer) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_premium_prioridad_disputa(
  p_id text,
  p_prioridad text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_prioridad NOT IN ('alta', 'media', 'baja') THEN
    RAISE EXCEPTION 'prioridad no permitida';
  END IF;
  SELECT prioridad INTO v_antes FROM public.disputas WHERE id::text = btrim(p_id);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  UPDATE public.disputas SET prioridad = p_prioridad, actualizado_en = now()
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'prioridad_disputa', 'disputas', btrim(p_id),
    jsonb_build_object('prioridad', v_antes),
    jsonb_build_object('prioridad', p_prioridad),
    p_motivo, NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_prioridad_disputa(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_prioridad_disputa(text, text, text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_premium_asignar_disputa(
  p_id text,
  p_asignado uuid,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_asignado IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.perfiles p
    WHERE p.id = p_asignado AND p.rol IN ('administrador', 'soporte')
  ) THEN
    RAISE EXCEPTION 'esa persona no pertenece al equipo';
  END IF;
  SELECT asignado_a INTO v_antes FROM public.disputas WHERE id::text = btrim(p_id);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  UPDATE public.disputas SET asignado_a = p_asignado, actualizado_en = now()
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'asignar_disputa', 'disputas', btrim(p_id),
    jsonb_build_object('asignado_a', v_antes),
    jsonb_build_object('asignado_a', p_asignado),
    p_motivo, NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_asignar_disputa(text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_asignar_disputa(text, uuid, text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_premium_reasignar_pedido(
  p_id text,
  p_trabajador uuid,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes uuid;
  v_estado text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.trabajadores w
    JOIN public.perfiles p ON p.id = w.id_usuario
    WHERE w.id_usuario = p_trabajador
      AND w.estado_verificacion = 'verificado'
      AND p.estado_cuenta IN ('activo', 'active')
  ) THEN
    RAISE EXCEPTION 'el trabajador no está verificado';
  END IF;
  SELECT id_trabajador, estado INTO v_antes, v_estado
  FROM public.trabajos WHERE id::text = btrim(p_id);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido no encontrado';
  END IF;
  IF v_estado IN ('completado', 'cancelado', 'expirado') THEN
    RAISE EXCEPTION 'ese pedido ya está cerrado';
  END IF;
  UPDATE public.trabajos
  SET id_trabajador = p_trabajador, actualizado_en = now()
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'reasignar_pedido', 'trabajos', btrim(p_id),
    jsonb_build_object('id_trabajador', v_antes),
    jsonb_build_object('id_trabajador', p_trabajador),
    p_motivo, NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_premium_reasignar_pedido(text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_premium_reasignar_pedido(text, uuid, text) TO authenticated, service_role;

-- Vista de lectura. Respeta RLS (security_invoker). La consola usa el RPC.
CREATE OR REPLACE VIEW public.consola_premium_resenas_base
WITH (security_invoker = true) AS
SELECT
  c.id,
  c.puntaje,
  left(c.comentario, 600) AS comentario,
  c.estado_revision,
  c.creado_en,
  c.id_trabajo,
  (public.consola_premium_clasificar(c.puntaje, c.comentario) ->> 'sentimiento') AS sentimiento,
  (public.consola_premium_clasificar(c.puntaje, c.comentario) -> 'temas') AS temas,
  (public.consola_premium_clasificar(c.puntaje, c.comentario) ->> 'fuente') AS fuente
FROM public.calificaciones c;

REVOKE ALL ON public.consola_premium_resenas_base FROM PUBLIC, anon;
GRANT SELECT ON public.consola_premium_resenas_base TO authenticated;

COMMIT;
