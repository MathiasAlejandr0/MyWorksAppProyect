-- Pruebas de comisión y de permisos de la consola en una base local.
-- Transacción con ROLLBACK. No apunta a producción.
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/permisos_consola_y_comision.sql

BEGIN;

-- 1) Comisión del servicio: 5 %, mínimo $1.000, nunca mayor que el pago.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      (NULL::numeric, 0), (0, 0), (-500, 0), (1, 1), (500, 500), (999, 999),
      (1000, 1000), (15000, 1000), (20000, 1000), (20010, 1001), (32000, 1600),
      (40000, 2000), (100000, 5000), (1234567, 61728)
    ) AS t(bruto, esperado)
  LOOP
    IF public.comision_servicio_clp(r.bruto) IS DISTINCT FROM r.esperado THEN
      RAISE EXCEPTION 'comision_servicio_clp(%) = %, se esperaba %',
        r.bruto, public.comision_servicio_clp(r.bruto), r.esperado;
    END IF;
    IF r.bruto > 0 AND public.comision_servicio_clp(r.bruto) > round(r.bruto) THEN
      RAISE EXCEPTION 'la comisión no puede superar el pago (%)', r.bruto;
    END IF;
  END LOOP;
END $$;

-- 2) anon no puede ejecutar ninguna función de consola o administración.
DO $$
DECLARE
  v_malas text;
BEGIN
  SELECT string_agg(p.oid::regprocedure::text, ', ')
  INTO v_malas
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND (p.proname LIKE 'consola\_%' OR p.proname LIKE 'admin\_%'
         OR p.proname IN ('fichas_sensibles_admin', 'fijar_verificacion_profesional',
                          'fijar_prioridad_trabajador'))
    AND has_function_privilege('anon', p.oid, 'execute');
  IF v_malas IS NOT NULL THEN
    RAISE EXCEPTION 'anon puede ejecutar: %', v_malas;
  END IF;
END $$;

-- 3) Un usuario autenticado que no es admin recibe error (o cero filas) en cada una.
CREATE TEMP TABLE _usuario_prueba ON COMMIT DROP AS
SELECT gen_random_uuid() AS id;
INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
SELECT id, 'authenticated', 'authenticated', 'permisos-' || id || '@prueba.test', now(), now()
FROM _usuario_prueba;
INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
SELECT id, 'Prueba permisos', 'permisos-' || id || '@prueba.test', 'usuario', 'activo',
  to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
FROM _usuario_prueba;
GRANT SELECT ON _usuario_prueba TO authenticated;

SELECT set_config(
  'request.jwt.claims',
  json_build_object('sub', (SELECT id FROM _usuario_prueba), 'role', 'authenticated')::text,
  true
);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  f record;
  v_args text;
  v_pasaron text[] := ARRAY[]::text[];
  v_total int := 0;
  v_filas bigint;
BEGIN
  FOR f IN
    SELECT p.oid, p.proname, p.proargtypes, p.proretset
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND (p.proname LIKE 'consola\_%' OR p.proname LIKE 'admin\_%'
           OR p.proname IN ('fichas_sensibles_admin', 'fijar_verificacion_profesional',
                            'fijar_prioridad_trabajador'))
      AND has_function_privilege('authenticated', p.oid, 'execute')
    ORDER BY p.proname
  LOOP
    v_total := v_total + 1;
    SELECT string_agg(format('NULL::%s', format_type(t, NULL)), ', ' ORDER BY ord)
    INTO v_args
    FROM unnest(f.proargtypes::oid[]) WITH ORDINALITY AS a(t, ord);
    BEGIN
      IF f.proretset THEN
        -- Las que devuelven filas pueden filtrar por is_admin(): basta con que no devuelvan nada.
        EXECUTE format('SELECT count(*) FROM public.%I(%s)', f.proname, COALESCE(v_args, ''))
        INTO v_filas;
        IF v_filas > 0 THEN
          v_pasaron := v_pasaron || f.oid::regprocedure::text;
        END IF;
      ELSE
        EXECUTE format('SELECT public.%I(%s)', f.proname, COALESCE(v_args, ''));
        v_pasaron := v_pasaron || f.oid::regprocedure::text;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Esperado: la función rechaza a quien no es admin.
      IF SQLERRM !~* '(admin|forbidden|permiso|autoriz|autentic|soporte)' THEN
        RAISE NOTICE 'revisar %: rechazó con "%"', f.oid::regprocedure, SQLERRM;
      END IF;
    END;
  END LOOP;
  IF v_total = 0 THEN
    RAISE EXCEPTION 'no se encontró ninguna función de consola';
  END IF;
  IF array_length(v_pasaron, 1) > 0 THEN
    RAISE EXCEPTION 'un no admin pudo ejecutar: %', array_to_string(v_pasaron, ', ');
  END IF;
  RAISE NOTICE 'OK: % funciones de consola rechazan a un usuario sin rol admin', v_total;
END $$;

-- 4) consola_moderar_resena valida el estado antes del rol: se prueba con estados válidos.
DO $$
DECLARE
  v_estado text;
BEGIN
  FOREACH v_estado IN ARRAY ARRAY['en_revision', 'excluida', 'vigente'] LOOP
    BEGIN
      PERFORM public.consola_moderar_resena('x', v_estado, 'motivo de prueba suficiente');
      RAISE EXCEPTION 'un no admin pudo moderar una reseña con estado %', v_estado;
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM <> 'forbidden' THEN
        RAISE EXCEPTION 'moderar reseña (%) rechazó con "%" y no con forbidden', v_estado, SQLERRM;
      END IF;
    END;
  END LOOP;
END $$;

RESET ROLE;
ROLLBACK;
