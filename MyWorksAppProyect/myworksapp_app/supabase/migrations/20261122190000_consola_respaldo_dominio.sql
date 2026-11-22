-- Respaldo lógico del negocio (no solo configuración).
-- No aplicar en el proyecto remoto. El archivo gzip lo sube la Edge
-- Function con la service role. El cron no llama a producción: la URL
-- sale de app_config y, si está vacía, el job no hace nada.

BEGIN;

ALTER TABLE public.respaldos_consola ALTER COLUMN contenido DROP NOT NULL;
ALTER TABLE public.respaldos_consola ADD COLUMN IF NOT EXISTS filas jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.respaldos_consola ADD COLUMN IF NOT EXISTS ruta text;
ALTER TABLE public.respaldos_consola ADD COLUMN IF NOT EXISTS origen text NOT NULL DEFAULT 'manual';

INSERT INTO public.app_config (clave, valor)
VALUES ('respaldo_funcion_url', '')
ON CONFLICT (clave) DO NOTHING;

CREATE OR REPLACE FUNCTION public.consola_tablas_dominio()
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT ARRAY[
    'paises', 'regiones', 'comunas', 'categorias_servicio', 'servicios',
    'perfiles', 'trabajadores', 'trabajador_servicios', 'trabajador_precios',
    'trabajador_horarios', 'trabajador_horas_publicadas', 'trabajador_servicios_extra',
    'portafolio_trabajador', 'verificacion_eventos',
    'trabajos', 'cancelaciones_trabajo', 'reprogramaciones_trabajo', 'acuerdos_trabajo',
    'propuestas_cotizacion', 'propuesta_cotizacion_items', 'ordenes_cambio',
    'pagos', 'liquidaciones', 'cuentas_bancarias',
    'disputas', 'disputa_mensajes',
    'tickets_soporte', 'ticket_mensajes',
    'calificaciones', 'calificaciones_cliente', 'senales_resena',
    'notificaciones', 'mensajes', 'reportes', 'consentimientos_usuario',
    'app_config', 'banderas_funcionalidad', 'umbrales_seguridad',
    'auditoria_consola'
  ];
$$;
REVOKE ALL ON FUNCTION public.consola_tablas_dominio() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_columnas_secretas(p_tabla text)
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE p_tabla
    WHEN 'pagos' THEN ARRAY['token_tbk', 'url_tbk', 'alta_jti', 'alta_nonce_hash']
    ELSE ARRAY[]::text[]
  END;
$$;
REVOKE ALL ON FUNCTION public.consola_columnas_secretas(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_exportar_dominio()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_tabla text;
  v_cols text;
  v_filas jsonb;
  v_datos jsonb := '{}'::jsonb;
  v_conteos jsonb := '{}'::jsonb;
BEGIN
  IF NOT public.is_admin() AND coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  FOREACH v_tabla IN ARRAY public.consola_tablas_dominio() LOOP
    IF to_regclass('public.' || v_tabla) IS NULL THEN
      CONTINUE;
    END IF;
    SELECT string_agg(quote_ident(c.column_name), ', ' ORDER BY c.ordinal_position)
    INTO v_cols
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = v_tabla
      AND c.is_generated = 'NEVER'
      AND c.column_name <> ALL (public.consola_columnas_secretas(v_tabla));
    IF v_cols IS NULL THEN
      CONTINUE;
    END IF;
    EXECUTE format(
      'SELECT coalesce(jsonb_agg(to_jsonb(t)), ''[]''::jsonb) FROM (SELECT %s FROM public.%I) t',
      v_cols, v_tabla
    ) INTO v_filas;
    v_datos := v_datos || jsonb_build_object(v_tabla, v_filas);
    v_conteos := v_conteos || jsonb_build_object(v_tabla, jsonb_array_length(v_filas));
  END LOOP;
  RETURN jsonb_build_object('version', 2, 'tablas', v_datos, 'conteos', v_conteos);
END;
$$;
REVOKE ALL ON FUNCTION public.consola_exportar_dominio() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_exportar_dominio() TO service_role;

CREATE OR REPLACE FUNCTION public.consola_registrar_respaldo(
  p_sha text,
  p_bytes integer,
  p_ruta text,
  p_filas jsonb,
  p_origen text,
  p_motivo text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid;
  v_uso bigint;
  v_rutas jsonb := '[]'::jsonb;
  v_limite bigint := 1073741824;
  v_tope bigint := 900 * 1024 * 1024;
  r record;
BEGIN
  IF NOT public.is_admin() AND coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_origen IS DISTINCT FROM 'cron' AND char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_sha IS NULL OR p_bytes IS NULL OR p_bytes < 1 OR p_ruta IS NULL THEN
    RAISE EXCEPTION 'Respaldo incompleto';
  END IF;
  INSERT INTO public.respaldos_consola (tamano_bytes, sha256, tablas, filas, ruta, origen, contenido)
  VALUES (
    p_bytes,
    p_sha,
    COALESCE((SELECT array_agg(k) FROM jsonb_object_keys(COALESCE(p_filas, '{}'::jsonb)) k), ARRAY[]::text[]),
    COALESCE(p_filas, '{}'::jsonb),
    p_ruta,
    CASE WHEN p_origen = 'cron' THEN 'cron' ELSE 'manual' END,
    NULL
  )
  RETURNING id INTO v_id;

  SELECT coalesce(sum(tamano_bytes), 0) INTO v_uso FROM public.respaldos_consola;
  WHILE v_uso > v_tope OR (SELECT count(*) FROM public.respaldos_consola) > 24 LOOP
    SELECT id, ruta, tamano_bytes INTO r
    FROM public.respaldos_consola
    ORDER BY creado_en ASC
    LIMIT 1;
    EXIT WHEN r.id IS NULL OR r.id = v_id;
    v_rutas := v_rutas || jsonb_build_array(r.ruta);
    DELETE FROM public.respaldos_consola WHERE id = r.id;
    v_uso := v_uso - coalesce(r.tamano_bytes, 0);
  END LOOP;

  IF public.is_admin() THEN
    PERFORM public.registrar_auditoria(
      'crear_respaldo', 'respaldos_consola', v_id::text,
      NULL,
      jsonb_build_object('bytes', p_bytes, 'sha256', p_sha, 'origen', p_origen),
      COALESCE(NULLIF(btrim(p_motivo), ''), 'Respaldo programado del dominio'),
      NULL, NULL, NULL, NULL
    );
  END IF;
  RETURN jsonb_build_object(
    'id', v_id,
    'tamano_bytes', p_bytes,
    'sha256', p_sha,
    'ruta', p_ruta,
    'borrar', v_rutas,
    'uso_bytes', (SELECT coalesce(sum(tamano_bytes), 0) FROM public.respaldos_consola),
    'limite_bytes', v_limite
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_registrar_respaldo(text, integer, text, jsonb, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_registrar_respaldo(text, integer, text, jsonb, text, text) TO authenticated, service_role;

DROP FUNCTION IF EXISTS public.consola_listar_respaldos();
CREATE FUNCTION public.consola_listar_respaldos()
RETURNS TABLE (
  id uuid,
  creado_en timestamptz,
  tamano_bytes integer,
  sha256 text,
  tablas text[],
  filas jsonb,
  ruta text,
  origen text,
  estado text,
  uso_bytes bigint,
  limite_bytes bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uso bigint;
  v_limite bigint := 1073741824;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT coalesce(sum(r.tamano_bytes), 0) INTO v_uso FROM public.respaldos_consola r;
  RETURN QUERY
  SELECT
    r.id, r.creado_en, r.tamano_bytes, r.sha256, r.tablas, r.filas, r.ruta, r.origen, r.estado,
    v_uso, v_limite
  FROM public.respaldos_consola r
  ORDER BY r.creado_en DESC
  LIMIT 24;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_listar_respaldos() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_respaldos() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_restaurar_dominio(
  p_payload jsonb,
  p_frase text,
  p_motivo text,
  p_tablas text[] DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_tabla text;
  v_cols text;
  v_filas jsonb;
  v_orden text[] := public.consola_tablas_dominio();
  v_elegidas text[];
  v_despues jsonb := '{}'::jsonb;
  v_n integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_frase IS DISTINCT FROM 'RESTAURAR' THEN
    RAISE EXCEPTION 'confirmacion invalida';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF COALESCE((p_payload->>'version')::int, 0) <> 2 OR jsonb_typeof(p_payload->'tablas') IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'Respaldo no compatible';
  END IF;
  IF p_tablas IS NULL OR cardinality(p_tablas) = 0 THEN
    SELECT coalesce(array_agg(k), ARRAY[]::text[]) INTO v_elegidas
    FROM jsonb_object_keys(p_payload->'tablas') k
    WHERE k = ANY (v_orden);
  ELSE
    SELECT coalesce(array_agg(t), ARRAY[]::text[]) INTO v_elegidas
    FROM unnest(p_tablas) t
    WHERE t = ANY (v_orden) AND (p_payload->'tablas') ? t;
  END IF;
  IF cardinality(v_elegidas) = 0 THEN
    RAISE EXCEPTION 'No hay tablas para restaurar';
  END IF;

  PERFORM set_config('mwa.defensa_bypass', '1', true);

  FOR v_tabla IN
    SELECT u FROM unnest(v_orden) WITH ORDINALITY AS x(u, n)
    WHERE u = ANY (v_elegidas)
    ORDER BY n DESC
  LOOP
    IF to_regclass('public.' || v_tabla) IS NULL THEN
      CONTINUE;
    END IF;
    EXECUTE format('ALTER TABLE public.%I DISABLE TRIGGER USER', v_tabla);
    EXECUTE format('DELETE FROM public.%I WHERE true', v_tabla);
  END LOOP;

  FOR v_tabla IN
    SELECT u FROM unnest(v_orden) WITH ORDINALITY AS x(u, n)
    WHERE u = ANY (v_elegidas)
    ORDER BY n
  LOOP
    IF to_regclass('public.' || v_tabla) IS NULL THEN
      CONTINUE;
    END IF;
    v_filas := p_payload->'tablas'->v_tabla;
    IF v_filas IS NULL OR jsonb_array_length(v_filas) = 0 THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER USER', v_tabla);
      v_despues := v_despues || jsonb_build_object(v_tabla, 0);
      CONTINUE;
    END IF;
    SELECT string_agg(quote_ident(c.column_name), ', ' ORDER BY c.ordinal_position)
    INTO v_cols
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = v_tabla
      AND c.is_generated = 'NEVER'
      AND c.column_name <> ALL (public.consola_columnas_secretas(v_tabla));
    EXECUTE format(
      'INSERT INTO public.%I (%s) SELECT %s FROM jsonb_populate_recordset(NULL::public.%I, $1) s',
      v_tabla, v_cols, v_cols, v_tabla
    ) USING v_filas;
    EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER USER', v_tabla);
    EXECUTE format('SELECT count(*) FROM public.%I', v_tabla) INTO v_n;
    v_despues := v_despues || jsonb_build_object(v_tabla, v_n);
  END LOOP;

  PERFORM public.registrar_auditoria(
    'restaurar_respaldo', 'respaldos_consola', NULL,
    NULL,
    jsonb_build_object('tablas', v_elegidas, 'conteos', v_despues),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
  RETURN jsonb_build_object('conteos', v_despues);
END;
$$;
REVOKE ALL ON FUNCTION public.consola_restaurar_dominio(jsonb, text, text, text[]) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.consola_restaurar_dominio(jsonb, text, text, text[]) TO authenticated;

DO $$
DECLARE
  r record;
BEGIN
  IF to_regclass('cron.job') IS NULL THEN
    BEGIN
      CREATE EXTENSION IF NOT EXISTS pg_cron;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'pg_cron no se pudo crear: %', SQLERRM;
    END;
  END IF;
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_net no se pudo crear: %', SQLERRM;
  END;
  IF to_regclass('cron.job') IS NULL THEN
    RETURN;
  END IF;
  FOR r IN SELECT jobid FROM cron.job WHERE jobname = 'mwa_respaldo_dominio' LOOP
    PERFORM cron.unschedule(r.jobid);
  END LOOP;
  PERFORM cron.schedule(
    'mwa_respaldo_dominio',
    '0 7 * * *',
    $cmd$
    SELECT net.http_post(
      url := (SELECT c.valor FROM public.app_config c WHERE c.clave = 'respaldo_funcion_url'),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-respaldo-secret', coalesce((
          SELECT s.decrypted_secret
          FROM vault.decrypted_secrets s
          WHERE s.name = 'mwa_respaldo_cron_secret'
          LIMIT 1
        ), '')
      ),
      body := '{"accion":"crear","origen":"cron"}'::jsonb,
      timeout_milliseconds := 120000
    )
    WHERE coalesce((SELECT c.valor FROM public.app_config c WHERE c.clave = 'respaldo_funcion_url'), '') <> '';
    $cmd$
  );
END $$;

COMMIT;
