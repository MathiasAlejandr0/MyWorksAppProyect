-- =============================================================================
-- DEMO / TEST. No es una migración. NO correr en producción.
--
-- Respalda a los 8 profesionales de seed_puerto_montt.sql con trabajos
-- completados, pagos liberados y reseñas de cliente. Así la nota y el
-- contador quedan iguales en búsqueda, perfil y seguimiento aunque
-- refrescar_calificacion_trabajador y trabajos_contar_completados vuelvan
-- a calcularlos.
--
-- Orden, en el SQL Editor:
--   1. scripts/demo/seed_demo.sql          (clientes Camila y Andrés)
--   2. scripts/demo/seed_puerto_montt.sql  (las 8 fichas)
--   3. este script
-- seed_demo.sql borra todo id LIKE 'demo-%'. Si se vuelve a correr, hay que
-- repetir este script el mismo mes de la grabación: las fechas son relativas
-- a now() en America/Santiago.
-- Reejecutar es seguro: solo borra y recrea filas demo-pm-*.
--
-- Mateo Oyarzo: puntajes [5,5,5,5,5,5,5,4], promedio 4.875.
-- El trigger guarda round(4.875, 2) = 4.88. La pantalla muestra 4.9 y 8 trabajos.
-- 3 pagos liberados el mes anterior y 5 este mes, todos por su tarifa
-- → la tarjeta de ganancias dice +67% vs. mes anterior.
--
-- GMV del panel ejecutivo (pendiente de decisión de Mathias):
-- cada pago queda `liberado` y el panel suma retenido + liberado + autorizado
-- por creado_en. Con las tarifas de la ficha son $1.227.000 en total
-- (Mateo 256.000, Elsa 228.000, Bruno 81.000, Nora 120.000, Iván 234.000,
-- Sofía 40.000, Clemente 100.000, Rosa 168.000).
-- De eso, $773.000 cae en el mes de Santiago en curso y $454.000 en el anterior.
-- Un rango de 30 días los incluye casi todo el mes; uno de 7 días, en general, no.
-- Este archivo no se ejecuta solo: hay que correrlo a mano en la base de demo.
-- =============================================================================

BEGIN;
SET LOCAL TIME ZONE 'UTC';

DO $hist$
DECLARE
  v_tz text := 'America/Santiago';
  v_month_start timestamp;
  v_prev timestamptz;
  v_curr timestamptz;
  v_mateo uuid;
  v_msg text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_timezone_names WHERE name = v_tz) THEN
    RAISE EXCEPTION 'Falta el huso America/Santiago en la base.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'calificaciones'
      AND column_name = 'direccion'
  ) THEN
    RAISE EXCEPTION 'Falta calificaciones.direccion. Aplica la calificación bidireccional antes.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'pagos'
      AND column_name = 'liberado_en'
  ) THEN
    RAISE EXCEPTION 'Falta pagos.liberado_en. Sin esa fecha la tarjeta no puede comparar meses.';
  END IF;

  v_month_start := date_trunc('month', timezone(v_tz, now()));
  v_prev := timezone(v_tz, v_month_start - interval '10 days');
  v_curr := timezone(v_tz, v_month_start + interval '15 hours');

  CREATE TEMP TABLE pm_hist (
    slug text PRIMARY KEY,
    email text NOT NULL,
    categoria text NOT NULL,
    n_anterior int NOT NULL,
    puntajes int[] NOT NULL,
    comentarios text[]
  ) ON COMMIT DROP;

  INSERT INTO pm_hist (slug, email, categoria, n_anterior, puntajes, comentarios) VALUES
    (
      'mateo', 'mateo.oyarzo@demo.myworksapp.cl', 'plomeria', 3,
      ARRAY[5,5,5,5,5,5,5,4],
      ARRAY[
        'Cambió la llave del lavaplatos y dejó todo seco.',
        'El calefont volvió a encender a la primera.',
        'Encontró la fuga bajo el piso y la selló bien.',
        'Cambió el flexible del lavamanos sin ensuciar.',
        'Destapó el desagüe de la tina en una sola visita.',
        'La llave de la cocina quedó firme y sin goteras.',
        'Revisó la presión y ajustó la válvula del calefont.',
        'Llegó a la hora. La gotera del baño quedó resuelta.'
      ]
    ),
    ('elsa', 'elsa.caicheo@demo.myworksapp.cl', 'electricidad', 2, ARRAY[5,5,5,5,5,4], NULL),
    ('bruno', 'bruno.levio@demo.myworksapp.cl', 'pintura', 1, ARRAY[5,4,4], NULL),
    ('nora', 'nora.huenchun@demo.myworksapp.cl', 'construccion', 2, ARRAY[4,4,3,3], NULL),
    ('ivan', 'ivan.barria@demo.myworksapp.cl', 'jardineria', 3, ARRAY[5,5,5,5,5,5,5,5,4], NULL),
    ('sofia', 'sofia.alvarado@demo.myworksapp.cl', 'limpieza', 1, ARRAY[3,2], NULL),
    ('clemente', 'clemente.navarro@demo.myworksapp.cl', 'cerrajeria', 1, ARRAY[4,4,4,4], NULL),
    ('rosa', 'rosa.millalonco@demo.myworksapp.cl', 'soporte_tecnico', 3, ARRAY[5,5,5,5,5,4,4], NULL);

  CREATE TEMP TABLE pm_esperado (
    slug text PRIMARY KEY,
    nota numeric NOT NULL,
    hechos int NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO pm_esperado (slug, nota, hechos) VALUES
    ('mateo', 4.88, 8),
    ('elsa', 4.83, 6),
    ('bruno', 4.33, 3),
    ('nora', 3.50, 4),
    ('ivan', 4.89, 9),
    ('sofia', 2.50, 2),
    ('clemente', 4.00, 4),
    ('rosa', 4.71, 7);

  IF EXISTS (
    SELECT 1
    FROM pm_hist h
    JOIN pm_esperado e ON e.slug = h.slug
    WHERE cardinality(h.puntajes) IS DISTINCT FROM e.hechos
       OR h.n_anterior < 1
       OR h.n_anterior >= cardinality(h.puntajes)
       OR round((SELECT avg(s) FROM unnest(h.puntajes) AS s)::numeric, 2) IS DISTINCT FROM e.nota
       OR EXISTS (SELECT 1 FROM unnest(h.puntajes) AS s WHERE s < 1 OR s > 5)
  ) THEN
    RAISE EXCEPTION 'Los puntajes no cierran con la nota o el contador esperado.';
  END IF;

  CREATE TEMP TABLE pm_quien (
    slug text PRIMARY KEY,
    uid uuid NOT NULL,
    tarifa int NOT NULL,
    profesion text NOT NULL,
    zona text NOT NULL,
    lat float8,
    lng float8
  ) ON COMMIT DROP;

  INSERT INTO pm_quien (slug, uid, tarifa, profesion, zona, lat, lng)
  SELECT
    h.slug,
    p.id,
    round(t.tarifa_visita)::int,
    t.profesion,
    t.zona_trabajo,
    t.latitud_base,
    t.longitud_base
  FROM pm_hist h
  JOIN public.perfiles p ON lower(p.correo) = h.email
  JOIN public.trabajadores t ON t.id_usuario = p.id;

  IF (SELECT count(*) FROM pm_quien) <> 8 THEN
    RAISE EXCEPTION 'Faltan fichas de Puerto Montt. Corre scripts/demo/seed_puerto_montt.sql antes.';
  END IF;

  IF EXISTS (SELECT 1 FROM pm_quien WHERE tarifa <= 0) THEN
    RAISE EXCEPTION 'Hay una ficha con tarifa 0. El pago liberado no sumaría GMV ni crecimiento.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.perfiles WHERE lower(correo) = 'camila.soto@demo.myworksapp.cl'
  ) OR NOT EXISTS (
    SELECT 1 FROM public.perfiles WHERE lower(correo) = 'andres.pizarro@demo.myworksapp.cl'
  ) THEN
    RAISE EXCEPTION 'Faltan los clientes demo. Corre scripts/demo/seed_demo.sql antes.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM (SELECT DISTINCT categoria FROM pm_hist) c
    WHERE NOT EXISTS (
      SELECT 1
      FROM public.servicios s
      WHERE s.categoria = c.categoria
        AND COALESCE(s.activo, 0) = 1
    )
  ) THEN
    RAISE EXCEPTION 'Falta un servicio activo. Corre scripts/demo/seed_demo.sql antes.';
  END IF;

  IF to_regclass('public.senales_resena') IS NOT NULL THEN
    DELETE FROM public.senales_resena WHERE id_calificacion LIKE 'demo-pm-nota-%';
  END IF;
  IF to_regclass('public.ubicacion_en_vivo') IS NOT NULL THEN
    DELETE FROM public.ubicacion_en_vivo WHERE id_trabajo LIKE 'demo-pm-job-%';
  END IF;
  IF to_regclass('public.liquidaciones') IS NOT NULL THEN
    DELETE FROM public.liquidaciones
    WHERE id LIKE 'demo-pm-liq-%'
       OR id_pago LIKE 'demo-pm-pago-%'
       OR id_trabajo LIKE 'demo-pm-job-%';
  END IF;
  IF to_regclass('public.calificaciones_cliente') IS NOT NULL THEN
    DELETE FROM public.calificaciones_cliente WHERE id_trabajo LIKE 'demo-pm-job-%';
  END IF;
  IF to_regclass('public.fotos_trabajo') IS NOT NULL THEN
    DELETE FROM public.fotos_trabajo WHERE id_trabajo LIKE 'demo-pm-job-%';
  END IF;
  DELETE FROM public.mensajes WHERE id_trabajo LIKE 'demo-pm-job-%';
  DELETE FROM public.disputas WHERE id_trabajo LIKE 'demo-pm-job-%';
  DELETE FROM public.notificaciones WHERE id LIKE 'demo-pm-%' OR id_relacionado LIKE 'demo-pm-job-%';
  DELETE FROM public.calificaciones WHERE id LIKE 'demo-pm-nota-%' OR id_trabajo LIKE 'demo-pm-job-%';
  DELETE FROM public.pagos WHERE id LIKE 'demo-pm-pago-%' OR id_trabajo LIKE 'demo-pm-job-%';
  DELETE FROM public.trabajos WHERE id LIKE 'demo-pm-job-%';

  INSERT INTO public.trabajos (
    id, id_usuario, id_trabajador, id_servicio, estado, estado_pago, direccion,
    descripcion, latitud, longitud, modalidad_cobro, creado_en, actualizado_en
  )
  SELECT
    'demo-pm-job-' || h.slug || '-' || g.ord,
    (
      SELECT id FROM public.perfiles
      WHERE lower(correo) = CASE WHEN g.ord % 2 = 0
        THEN 'camila.soto@demo.myworksapp.cl'
        ELSE 'andres.pizarro@demo.myworksapp.cl' END
      LIMIT 1
    ),
    q.uid,
    (
      SELECT s.id FROM public.servicios s
      WHERE s.categoria = h.categoria AND COALESCE(s.activo, 0) = 1
      ORDER BY s.creado_en NULLS LAST
      LIMIT 1
    ),
    'completado',
    'liberado',
    'Visita en ' || COALESCE(q.zona, 'Puerto Montt'),
    COALESCE(
      h.comentarios[g.ord::int],
      'Visita de ' || q.profesion || ' en ' || COALESCE(q.zona, 'Puerto Montt')
        || ', número ' || g.ord || '. El cliente dejó constancia del trabajo.'
    ),
    q.lat,
    q.lng,
    'precio_fijo',
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  FROM pm_hist h
  JOIN pm_quien q ON q.slug = h.slug
  JOIN LATERAL unnest(h.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN g.ord <= h.n_anterior THEN v_prev + (g.ord * interval '1 hour')
      WHEN v_curr + (g.ord * interval '1 hour') < now() THEN v_curr + (g.ord * interval '1 hour')
      ELSE now() - interval '1 minute'
    END AS v_inst
  ) instante;

  INSERT INTO public.pagos (
    id, id_trabajo, monto, moneda, estado, tipo_pago, metodo_pago,
    creado_en, actualizado_en, liberado_en
  )
  SELECT
    'demo-pm-pago-' || h.slug || '-' || g.ord,
    'demo-pm-job-' || h.slug || '-' || g.ord,
    q.tarifa,
    'CLP',
    'liberado',
    'principal',
    'webpay',
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  FROM pm_hist h
  JOIN pm_quien q ON q.slug = h.slug
  JOIN LATERAL unnest(h.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN g.ord <= h.n_anterior THEN v_prev + (g.ord * interval '1 hour')
      WHEN v_curr + (g.ord * interval '1 hour') < now() THEN v_curr + (g.ord * interval '1 hour')
      ELSE now() - interval '1 minute'
    END AS v_inst
  ) instante;

  INSERT INTO public.calificaciones (
    id, id_trabajo, id_usuario, id_calificado, direccion, puntaje, comentario, creado_en
  )
  SELECT
    'demo-pm-nota-' || h.slug || '-' || g.ord,
    'demo-pm-job-' || h.slug || '-' || g.ord,
    (
      SELECT id FROM public.perfiles
      WHERE lower(correo) = CASE WHEN g.ord % 2 = 0
        THEN 'camila.soto@demo.myworksapp.cl'
        ELSE 'andres.pizarro@demo.myworksapp.cl' END
      LIMIT 1
    ),
    q.uid,
    'cliente_a_trabajador',
    g.puntaje,
    COALESCE(
      h.comentarios[g.ord::int],
      'Visita de ' || q.profesion || ' en ' || COALESCE(q.zona, 'Puerto Montt')
        || ', número ' || g.ord || '. El cliente dejó constancia del trabajo.'
    ),
    to_char(v_inst AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
  FROM pm_hist h
  JOIN pm_quien q ON q.slug = h.slug
  JOIN LATERAL unnest(h.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN g.ord <= h.n_anterior THEN v_prev + (g.ord * interval '1 hour')
      WHEN v_curr + (g.ord * interval '1 hour') < now() THEN v_curr + (g.ord * interval '1 hour')
      ELSE now() - interval '1 minute'
    END AS v_inst
  ) instante;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'calificaciones'
      AND column_name = 'estado_revision'
  ) THEN
    UPDATE public.calificaciones
    SET estado_revision = 'vigente',
        peso_confianza = 1,
        motivo_revision = NULL
    WHERE id LIKE 'demo-pm-nota-%';
  END IF;

  IF to_regclass('public.senales_resena') IS NOT NULL THEN
    DELETE FROM public.senales_resena WHERE id_calificacion LIKE 'demo-pm-nota-%';
  END IF;

  IF to_regclass('public.liquidaciones') IS NOT NULL THEN
    INSERT INTO public.liquidaciones (
      id, id_pago, id_trabajo, id_trabajador, monto_clp,
      proveedor, referencia_transferencia, notas, id_operador, creado_en
    )
    SELECT
      'demo-pm-liq-' || h.slug || '-' || g.ord,
      'demo-pm-pago-' || h.slug || '-' || g.ord,
      'demo-pm-job-' || h.slug || '-' || g.ord,
      q.uid::text,
      q.tarifa,
      'conformidad',
      'CONFORME-' || left(replace('demo-pm-job-' || h.slug || '-' || g.ord, '-', ''), 16),
      'Pago de la demo liberado al recibir conforme',
      (
        SELECT id::text FROM public.perfiles
        WHERE lower(correo) = CASE WHEN g.ord % 2 = 0
          THEN 'camila.soto@demo.myworksapp.cl'
          ELSE 'andres.pizarro@demo.myworksapp.cl' END
        LIMIT 1
      ),
      v_inst
    FROM pm_hist h
    JOIN pm_quien q ON q.slug = h.slug
    JOIN LATERAL unnest(h.puntajes) WITH ORDINALITY AS g(puntaje, ord) ON true
    CROSS JOIN LATERAL (
      SELECT CASE
        WHEN g.ord <= h.n_anterior THEN v_prev + (g.ord * interval '1 hour')
        WHEN v_curr + (g.ord * interval '1 hour') < now() THEN v_curr + (g.ord * interval '1 hour')
        ELSE now() - interval '1 minute'
      END AS v_inst
    ) instante;
  END IF;

  -- El contador de la ficha ya venía escrito a mano. El trigger de trabajos
  -- suma encima al insertar. Acá se deja igual a los trabajos completados reales.
  UPDATE public.trabajadores w
  SET trabajos_completados = src.n
  FROM (
    SELECT j.id_trabajador, count(*)::int AS n
    FROM public.trabajos j
    WHERE j.estado = 'completado'
      AND j.id_trabajador IN (SELECT uid FROM pm_quien)
    GROUP BY j.id_trabajador
  ) src
  WHERE w.id_usuario = src.id_trabajador;

  -- Misma fórmula que refrescar_calificacion_trabajador (promedio a 2 decimales,
  -- solo cliente → profesional).
  UPDATE public.trabajadores w
  SET calificacion = src.promedio
  FROM (
    SELECT
      t.id_trabajador AS id_usuario,
      round(avg(c.puntaje)::numeric, 2) AS promedio
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    WHERE t.id_trabajador IN (SELECT uid FROM pm_quien)
      AND c.direccion = 'cliente_a_trabajador'
    GROUP BY t.id_trabajador
  ) src
  WHERE w.id_usuario = src.id_usuario;

  SELECT string_agg(
    e.slug || ' quedó ' || round(w.calificacion::numeric, 2) || '/' || w.trabajos_completados
      || ' y se esperaba ' || e.nota || '/' || e.hechos,
    '; '
  )
  INTO v_msg
  FROM pm_esperado e
  JOIN pm_quien q ON q.slug = e.slug
  JOIN public.trabajadores w ON w.id_usuario = q.uid
  WHERE round(w.calificacion::numeric, 2) IS DISTINCT FROM e.nota
     OR w.trabajos_completados IS DISTINCT FROM e.hechos;

  IF v_msg IS NOT NULL THEN
    RAISE EXCEPTION 'Nota o contador distinto al historial (¿hay trabajos ajenos a demo-pm-?): %', v_msg;
  END IF;

  SELECT uid INTO v_mateo FROM pm_quien WHERE slug = 'mateo';

  IF (
    SELECT count(*)
    FROM public.pagos p
    JOIN public.trabajos t ON t.id = p.id_trabajo
    WHERE t.id_trabajador = v_mateo
      AND p.id LIKE 'demo-pm-pago-%'
      AND p.estado = 'liberado'
      AND timezone(v_tz, p.liberado_en::timestamptz) >= v_month_start
      AND timezone(v_tz, p.liberado_en::timestamptz) < v_month_start + interval '1 month'
  ) IS DISTINCT FROM 5
  OR (
    SELECT count(*)
    FROM public.pagos p
    JOIN public.trabajos t ON t.id = p.id_trabajo
    WHERE t.id_trabajador = v_mateo
      AND p.id LIKE 'demo-pm-pago-%'
      AND p.estado = 'liberado'
      AND timezone(v_tz, p.liberado_en::timestamptz) >= v_month_start - interval '1 month'
      AND timezone(v_tz, p.liberado_en::timestamptz) < v_month_start
  ) IS DISTINCT FROM 3 THEN
    RAISE EXCEPTION 'Mateo debe tener 3 liberaciones el mes anterior y 5 este mes (Santiago), para el +67%% de la tarjeta.';
  END IF;

  IF to_regprocedure('public.refrescar_ranking_todos()') IS NOT NULL THEN
    PERFORM public.refrescar_ranking_todos();
  END IF;
END
$hist$;

COMMIT;
