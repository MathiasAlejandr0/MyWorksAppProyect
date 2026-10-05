-- Afirmaciones de 20261008000009, 20261008000010 y del REVOKE extra de anon.
-- 000007 y 000008 ya están en vivo. Este archivo no las vuelve a aplicar.
-- Corre en una transacción que hace ROLLBACK: no deja filas de prueba.
-- Si algo falla, el bloque DO lanza y no aparece la línea OK.
-- Aplicar antes 20261008000009, 20261008000010 y:
--   REVOKE INSERT, DELETE, TRUNCATE ON TABLE public.trabajadores FROM anon;

BEGIN;

DO $$
DECLARE
  v_def text;
  v_cfg text;
BEGIN
  SELECT pg_get_functiondef(
    'public.listar_profesionales_catalogo(text, text, numeric, uuid, integer)'::regprocedure
  ) INTO v_def;
  IF position('estado_verificacion' in v_def) = 0
     OR position('verificado' in v_def) = 0 THEN
    RAISE EXCEPTION 'el catálogo no filtra estado_verificacion = verificado';
  END IF;
  IF position('trabajos_completados' in v_def) = 0
     OR position('completado' in v_def) = 0 THEN
    RAISE EXCEPTION 'el catálogo no cuenta trabajos completados';
  END IF;

  SELECT pg_get_functiondef('public.categorias_con_disponibles()'::regprocedure)
  INTO v_def;
  IF position('estado_verificacion' in v_def) = 0 THEN
    RAISE EXCEPTION 'categorias_con_disponibles no exige verificación';
  END IF;

  SELECT pg_get_functiondef('public.crear_intencion_pago(text, numeric, text)'::regprocedure)
  INTO v_def;
  IF position('FOR UPDATE' in v_def) = 0 THEN
    RAISE EXCEPTION 'crear_intencion_pago no bloquea la fila del trabajo';
  END IF;

  SELECT pg_get_functiondef(
    'public.crear_intencion_pago_servicio(text, text, numeric)'::regprocedure
  ) INTO v_def;
  IF position('FOR UPDATE' in v_def) = 0 THEN
    RAISE EXCEPTION 'crear_intencion_pago_servicio no bloquea la fila del trabajo';
  END IF;

  SELECT pg_get_functiondef('public.trabajador_reservable(uuid)'::regprocedure)
  INTO v_def;
  IF position('verificado' in v_def) = 0
     OR position('precios_configurados' in v_def) = 0 THEN
    RAISE EXCEPTION 'trabajador_reservable no exige verificado y precios';
  END IF;

  SELECT array_to_string(p.proconfig, ',')
  INTO v_cfg
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'texto_a_timestamptz';
  IF v_cfg IS NULL OR position('search_path' in v_cfg) = 0 THEN
    RAISE EXCEPTION 'texto_a_timestamptz no fija search_path';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name = 'trabajadores'
      AND grantee IN ('anon', 'authenticated')
      AND privilege_type = 'UPDATE'
  ) THEN
    RAISE EXCEPTION 'anon o authenticated conservan UPDATE de tabla en trabajadores';
  END IF;

  IF has_table_privilege('anon', 'public.trabajadores', 'INSERT')
     OR has_table_privilege('anon', 'public.trabajadores', 'DELETE')
     OR has_table_privilege('anon', 'public.trabajadores', 'TRUNCATE')
  THEN
    RAISE EXCEPTION 'anon conserva INSERT, DELETE o TRUNCATE en trabajadores';
  END IF;

  SELECT pg_get_functiondef('public.monto_esperado_trabajo(public.trabajos)'::regprocedure)
  INTO v_def;
  IF position('no está verificado' in v_def) = 0 THEN
    RAISE EXCEPTION 'monto_esperado no distingue un profesional sin verificar';
  END IF;
  IF position('niveles_precio' in v_def) = 0 THEN
    RAISE EXCEPTION 'monto_esperado no lee la tarifa publicada';
  END IF;

  IF has_table_privilege('anon', 'public.trabajadores', 'REFERENCES')
     OR has_table_privilege('anon', 'public.trabajadores', 'TRIGGER')
  THEN
    RAISE EXCEPTION 'anon conserva REFERENCES o TRIGGER en trabajadores';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.column_privileges
    WHERE table_schema = 'public'
      AND table_name = 'trabajadores'
      AND grantee = 'authenticated'
      AND privilege_type = 'UPDATE'
      AND column_name IN (
        'calificacion',
        'conteo_rechazos',
        'estado_verificacion',
        'nota_verificacion'
      )
  ) THEN
    RAISE EXCEPTION 'authenticated puede actualizar calificación o verificación';
  END IF;
END $$;

ROLLBACK;

SELECT 'RLS 20261011 ok' AS resultado;
