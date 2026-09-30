-- Afirmaciones de la migración 20261008000005.
-- Corre en una transacción que hace ROLLBACK: no deja filas de prueba.
-- Si algo falla, el bloque DO lanza y no aparece la línea OK.
-- Aplicar antes la migración. Luego este archivo en el SQL Editor.

BEGIN;

DO $$
DECLARE
  v_def text;
  v_insert text;
  v_quote text;
BEGIN
  IF has_column_privilege('authenticated', 'public.pagos', 'token_tbk', 'SELECT')
     OR has_column_privilege('anon', 'public.pagos', 'token_tbk', 'SELECT')
     OR has_column_privilege('authenticated', 'public.pagos', 'url_tbk', 'SELECT')
     OR has_column_privilege('authenticated', 'public.pagos', 'id_transaccion', 'SELECT')
  THEN
    RAISE EXCEPTION 'authenticated o anon todavía leen token_tbk, url_tbk o id_transaccion';
  END IF;

  IF has_table_privilege('anon', 'public.trabajadores', 'SELECT') THEN
    RAISE EXCEPTION 'anon todavía puede leer la tabla trabajadores';
  END IF;

  IF has_column_privilege('authenticated', 'public.trabajadores', 'calificacion', 'UPDATE')
     OR has_column_privilege('anon', 'public.trabajadores', 'calificacion', 'UPDATE')
     OR has_column_privilege('authenticated', 'public.trabajadores', 'estado_verificacion', 'UPDATE')
  THEN
    RAISE EXCEPTION 'el cliente todavía puede actualizar calificación o verificación';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'calificaciones_trabajo_usuario_uidx'
  ) THEN
    RAISE EXCEPTION 'falta el único (id_trabajo, id_usuario) en calificaciones';
  END IF;

  SELECT pg_get_functiondef('public.crear_intencion_pago(text, numeric, text)'::regprocedure)
  INTO v_def;
  IF v_def IS NULL OR position('monto_esperado_trabajo' in v_def) = 0 THEN
    RAISE EXCEPTION 'crear_intencion_pago no usa el monto del servidor';
  END IF;

  SELECT pg_get_functiondef('public.monto_esperado_trabajo(public.trabajos)'::regprocedure)
  INTO v_def;
  IF position('id_cotizacion_seleccionada' in v_def) = 0
     OR position('tarifa_visita' in v_def) = 0 THEN
    RAISE EXCEPTION 'el monto esperado no ata la cotización elegida ni la tarifa';
  END IF;

  SELECT pg_get_functiondef('public.listar_profesionales_catalogo(text, text, numeric, uuid, integer)'::regprocedure)
  INTO v_def;
  IF position('round(' in v_def) = 0 THEN
    RAISE EXCEPTION 'el catálogo no redondea coordenadas';
  END IF;
  IF position('nota_verificacion' in v_def) > 0 THEN
    RAISE EXCEPTION 'el catálogo devuelve nota_verificacion';
  END IF;

  SELECT pg_get_expr(p.polwithcheck, p.polrelid)
  INTO v_insert
  FROM pg_policy p
  JOIN pg_class c ON c.oid = p.polrelid
  WHERE c.relname = 'trabajos'
    AND p.polname = 'trabajos_insert';
  IF v_insert IS NULL
     OR (
       position('verificado' in v_insert) = 0
       AND position('trabajador_reservable' in v_insert) = 0
     ) THEN
    RAISE EXCEPTION 'trabajos_insert no exige un profesional verificado';
  END IF;
  IF position('trabajador_reservable' in v_insert) > 0 THEN
    SELECT pg_get_functiondef('public.trabajador_reservable(uuid)'::regprocedure)
    INTO v_def;
    IF position('verificado' in v_def) = 0 THEN
      RAISE EXCEPTION 'trabajador_reservable no exige un profesional verificado';
    END IF;
  END IF;
  IF position('pendiente' in v_insert) > 0
     AND position('id_trabajador IS NULL' in v_insert) = 0 THEN
    RAISE EXCEPTION 'trabajos_insert deja crear pendiente con profesional';
  END IF;

  SELECT pg_get_expr(p.polwithcheck, p.polrelid)
  INTO v_quote
  FROM pg_policy p
  JOIN pg_class c ON c.oid = p.polrelid
  WHERE c.relname = 'propuestas_cotizacion'
    AND p.polname = 'propuestas_insert';
  IF v_quote IS NULL OR position('es_rol_trabajador' in v_quote) = 0 THEN
    RAISE EXCEPTION 'el cliente todavía puede insertar cotizaciones';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = 'propuestas_cotizacion'
      AND p.polname = 'propuestas_all'
  ) THEN
    RAISE EXCEPTION 'sigue la política propuestas_all';
  END IF;

  SELECT pg_get_functiondef('public.is_admin()'::regprocedure) INTO v_def;
  IF position('administrador' in v_def) = 0 OR position('aal' in v_def) = 0 THEN
    RAISE EXCEPTION 'is_admin no exige rol administrador ni contempla aal2';
  END IF;

  SELECT pg_get_functiondef('public.listar_cuentas_demo_acceso()'::regprocedure) INTO v_def;
  IF position('demo_modo' in v_def) = 0 THEN
    RAISE EXCEPTION 'el selector demo no mira demo_modo';
  END IF;
END $$;

ROLLBACK;

SELECT 'RLS 20261009 ok' AS resultado;
