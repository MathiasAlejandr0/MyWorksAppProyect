-- Pruebas de seguridad, modo defensa y respaldos lógicos de la consola.
-- No aplicar en el proyecto remoto. El navegador no recibe service role:
-- todo pasa por RPC SECURITY DEFINER que exige administrador.

BEGIN;

INSERT INTO public.app_config (clave, valor)
VALUES
  ('defensa_bloqueo', '0'),
  ('defensa_solo_lectura', '0'),
  ('defensa_pausar_pagos', '0'),
  ('defensa_pausar_registros', '0'),
  ('defensa_automatica', '0')
ON CONFLICT (clave) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.pruebas_seguridad (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  tipo text NOT NULL,
  origen text NOT NULL DEFAULT 'servidor' CHECK (origen IN ('servidor', 'navegador')),
  resultado text NOT NULL CHECK (resultado IN ('ok', 'aviso', 'fallo')),
  severidad text NOT NULL CHECK (severidad IN ('baja', 'media', 'alta')),
  resumen text NOT NULL,
  recomendacion text NOT NULL,
  detalle jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS pruebas_seguridad_creado_idx
  ON public.pruebas_seguridad (creado_en DESC);
ALTER TABLE public.pruebas_seguridad ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pruebas_seguridad FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.pruebas_seguridad TO authenticated;
DROP POLICY IF EXISTS pruebas_seguridad_select_admin ON public.pruebas_seguridad;
CREATE POLICY pruebas_seguridad_select_admin
  ON public.pruebas_seguridad
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

CREATE TABLE IF NOT EXISTS public.bloqueos_ip (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  ip text NOT NULL,
  hasta timestamptz,
  motivo text NOT NULL,
  activo boolean NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS bloqueos_ip_activos_idx ON public.bloqueos_ip (ip) WHERE activo;
ALTER TABLE public.bloqueos_ip ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.bloqueos_ip FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.bloqueos_ip TO authenticated;
DROP POLICY IF EXISTS bloqueos_ip_select_admin ON public.bloqueos_ip;
CREATE POLICY bloqueos_ip_select_admin
  ON public.bloqueos_ip
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

CREATE TABLE IF NOT EXISTS public.respaldos_consola (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  tamano_bytes integer NOT NULL CHECK (tamano_bytes >= 0),
  sha256 text NOT NULL,
  tablas text[] NOT NULL,
  estado text NOT NULL DEFAULT 'listo' CHECK (estado IN ('listo', 'restaurado')),
  contenido text NOT NULL
);
CREATE INDEX IF NOT EXISTS respaldos_consola_creado_idx
  ON public.respaldos_consola (creado_en DESC);
ALTER TABLE public.respaldos_consola ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.respaldos_consola FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.respaldos_consola TO service_role;

DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NOT NULL THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('respaldos-consola', 'respaldos-consola', false)
    ON CONFLICT (id) DO NOTHING;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

CREATE OR REPLACE FUNCTION public.defensa_activa(p_claves text[])
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.app_config c
    WHERE c.clave = ANY (p_claves) AND c.valor = '1'
  );
$$;
REVOKE ALL ON FUNCTION public.defensa_activa(text[]) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.rechazar_si_pagos_pausados()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('mwa.defensa_bypass', true) = '1' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF coalesce(auth.role(), '') = '' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF public.defensa_activa(ARRAY['defensa_bloqueo', 'defensa_solo_lectura', 'defensa_pausar_pagos']) THEN
    RAISE EXCEPTION 'operaciones de pago pausadas';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;
DROP TRIGGER IF EXISTS pagos_defensa ON public.pagos;
CREATE TRIGGER pagos_defensa
  BEFORE INSERT OR UPDATE OR DELETE ON public.pagos
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_pagos_pausados();

CREATE OR REPLACE FUNCTION public.rechazar_si_registros_pausados()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('mwa.defensa_bypass', true) = '1' THEN
    RETURN NEW;
  END IF;
  IF coalesce(auth.role(), '') = '' THEN
    RETURN NEW;
  END IF;
  IF public.defensa_activa(ARRAY['defensa_bloqueo', 'defensa_pausar_registros']) THEN
    RAISE EXCEPTION 'registros pausados';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS perfiles_defensa_altas ON public.perfiles;
CREATE TRIGGER perfiles_defensa_altas
  BEFORE INSERT ON public.perfiles
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_registros_pausados();

CREATE OR REPLACE FUNCTION public.rechazar_si_solo_lectura()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('mwa.defensa_bypass', true) = '1' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF coalesce(auth.role(), '') = '' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF public.defensa_activa(ARRAY['defensa_bloqueo', 'defensa_solo_lectura']) THEN
    RAISE EXCEPTION 'modo solo lectura';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS disputas_solo_lectura ON public.disputas;
CREATE TRIGGER disputas_solo_lectura
  BEFORE INSERT OR UPDATE OR DELETE ON public.disputas
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_solo_lectura();
DROP TRIGGER IF EXISTS servicios_solo_lectura ON public.servicios;
CREATE TRIGGER servicios_solo_lectura
  BEFORE UPDATE OR DELETE ON public.servicios
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_solo_lectura();
DROP TRIGGER IF EXISTS reportes_solo_lectura ON public.reportes;
CREATE TRIGGER reportes_solo_lectura
  BEFORE UPDATE OR DELETE ON public.reportes
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_solo_lectura();
DROP TRIGGER IF EXISTS tickets_solo_lectura ON public.tickets_soporte;
CREATE TRIGGER tickets_solo_lectura
  BEFORE UPDATE OR DELETE ON public.tickets_soporte
  FOR EACH ROW EXECUTE FUNCTION public.rechazar_si_solo_lectura();

CREATE OR REPLACE FUNCTION public.app_config_defensa_protegida()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('mwa.defensa_bypass', true) = '1' THEN
    RETURN NEW;
  END IF;
  IF coalesce(auth.role(), '') <> '' AND (
    NEW.clave LIKE 'defensa_%'
    OR public.defensa_activa(ARRAY['defensa_bloqueo', 'defensa_solo_lectura'])
  ) THEN
    RAISE EXCEPTION 'Esa clave se cambia desde Seguridad';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS app_config_defensa_protegida ON public.app_config;
CREATE TRIGGER app_config_defensa_protegida
  BEFORE UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION public.app_config_defensa_protegida();

CREATE OR REPLACE FUNCTION public.consola_estado_defensa()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v jsonb := '{}'::jsonb;
  r record;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  FOR r IN
    SELECT clave, valor FROM public.app_config
    WHERE clave IN (
      'defensa_bloqueo', 'defensa_solo_lectura', 'defensa_pausar_pagos',
      'defensa_pausar_registros', 'defensa_automatica'
    )
  LOOP
    v := v || jsonb_build_object(r.clave, r.valor = '1');
  END LOOP;
  RETURN v || jsonb_build_object(
    'ips', (
      SELECT coalesce(jsonb_agg(jsonb_build_object(
        'id', b.id, 'ip', b.ip, 'hasta', b.hasta, 'motivo', b.motivo
      ) ORDER BY b.creado_en DESC), '[]'::jsonb)
      FROM public.bloqueos_ip b
      WHERE b.activo AND (b.hasta IS NULL OR b.hasta > now())
    )
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_estado_defensa() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_estado_defensa() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_fijar_defensa(
  p_clave text,
  p_activo boolean,
  p_frase text,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_valor text := CASE WHEN p_activo THEN '1' ELSE '0' END;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_clave NOT IN (
    'defensa_bloqueo', 'defensa_solo_lectura', 'defensa_pausar_pagos',
    'defensa_pausar_registros', 'defensa_automatica'
  ) THEN
    RAISE EXCEPTION 'Clave no permitida';
  END IF;
  IF p_frase IS DISTINCT FROM (CASE WHEN p_activo THEN 'BLOQUEAR' ELSE 'LIBERAR' END) THEN
    RAISE EXCEPTION 'confirmacion invalida';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  PERFORM set_config('mwa.defensa_bypass', '1', true);
  SELECT valor INTO v_antes FROM public.app_config WHERE clave = p_clave FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO public.app_config (clave, valor) VALUES (p_clave, v_valor);
  ELSE
    UPDATE public.app_config
    SET valor = v_valor, actualizado_en = now()
    WHERE clave = p_clave;
  END IF;
  IF p_clave = 'defensa_bloqueo' AND p_activo THEN
    UPDATE public.app_config
    SET valor = '1', actualizado_en = now()
    WHERE clave IN ('defensa_solo_lectura', 'defensa_pausar_pagos', 'defensa_pausar_registros');
  END IF;
  IF p_clave = 'defensa_bloqueo' AND NOT p_activo THEN
    UPDATE public.app_config
    SET valor = '0', actualizado_en = now()
    WHERE clave IN ('defensa_solo_lectura', 'defensa_pausar_pagos', 'defensa_pausar_registros');
  END IF;
  PERFORM public.registrar_auditoria(
    CASE WHEN p_activo
      THEN 'activar_defensa'::public.accion_auditoria_consola
      ELSE 'desactivar_defensa'::public.accion_auditoria_consola
    END,
    'app_config', p_clave,
    jsonb_build_object('valor', v_antes),
    jsonb_build_object('valor', v_valor),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_fijar_defensa(text, boolean, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_fijar_defensa(text, boolean, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.aplicar_defensa_automatica()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RETURN;
  END IF;
  IF NOT public.defensa_activa(ARRAY['defensa_automatica']) THEN
    RETURN;
  END IF;
  IF public.defensa_activa(ARRAY['defensa_bloqueo']) THEN
    RETURN;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.incidentes_seguridad
    WHERE severidad = 'alta' AND estado = 'abierto'
      AND creado_en > now() - interval '10 minutes'
  ) THEN
    RETURN;
  END IF;
  PERFORM set_config('mwa.defensa_bypass', '1', true);
  UPDATE public.app_config
  SET valor = '1', actualizado_en = now()
  WHERE clave IN (
    'defensa_bloqueo', 'defensa_solo_lectura', 'defensa_pausar_pagos', 'defensa_pausar_registros'
  );
  PERFORM public.registrar_auditoria(
    'activar_defensa', 'app_config', 'defensa_bloqueo',
    jsonb_build_object('valor', '0'),
    jsonb_build_object('valor', '1', 'origen', 'umbral'),
    'Umbral de seguridad superado: modo bloqueo automatico',
    NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.aplicar_defensa_automatica() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_seguridad_ciclo()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v jsonb;
BEGIN
  v := public.consola_seguridad_vivo();
  PERFORM public.aplicar_defensa_automatica();
  RETURN v || jsonb_build_object('defensa', public.consola_estado_defensa());
END;
$$;
REVOKE ALL ON FUNCTION public.consola_seguridad_ciclo() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_seguridad_ciclo() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_bloquear_ip(
  p_ip text,
  p_horas integer,
  p_frase text,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_ip inet;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_frase IS DISTINCT FROM 'BLOQUEAR' THEN
    RAISE EXCEPTION 'confirmacion invalida';
  END IF;
  IF p_horas IS NULL OR p_horas < 1 OR p_horas > 720 THEN
    RAISE EXCEPTION 'Plazo no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  BEGIN
    v_ip := btrim(p_ip)::inet;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'IP no valida';
  END;
  INSERT INTO public.bloqueos_ip (ip, hasta, motivo)
  VALUES (v_ip::text, now() + make_interval(hours => p_horas), btrim(p_motivo));
  PERFORM public.registrar_auditoria(
    'bloquear_ip', 'bloqueos_ip', v_ip::text,
    NULL, jsonb_build_object('horas', p_horas),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_bloquear_ip(text, integer, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_bloquear_ip(text, integer, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_desbloquear_ip(p_id uuid, p_frase text, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_ip text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_frase IS DISTINCT FROM 'LIBERAR' THEN
    RAISE EXCEPTION 'confirmacion invalida';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  UPDATE public.bloqueos_ip
  SET activo = false
  WHERE id = p_id AND activo
  RETURNING ip INTO v_ip;
  IF v_ip IS NULL THEN
    RAISE EXCEPTION 'Bloqueo no encontrado';
  END IF;
  PERFORM public.registrar_auditoria(
    'desbloquear_ip', 'bloqueos_ip', v_ip,
    jsonb_build_object('activo', true),
    jsonb_build_object('activo', false),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_desbloquear_ip(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_desbloquear_ip(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.acceso_ip_permitida(p_ip text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_ip text;
BEGIN
  BEGIN
    v_ip := btrim(COALESCE(p_ip, ''))::inet::text;
  EXCEPTION WHEN OTHERS THEN
    RETURN true;
  END;
  RETURN NOT EXISTS (
    SELECT 1 FROM public.bloqueos_ip b
    WHERE b.activo AND b.ip = v_ip AND (b.hasta IS NULL OR b.hasta > now())
  );
END;
$$;
REVOKE ALL ON FUNCTION public.acceso_ip_permitida(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.acceso_ip_permitida(text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.guardar_prueba_seguridad(
  p_tipo text,
  p_origen text,
  p_resultado text,
  p_severidad text,
  p_resumen text,
  p_recomendacion text,
  p_detalle jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_resultado NOT IN ('ok', 'aviso', 'fallo') OR p_severidad NOT IN ('baja', 'media', 'alta') THEN
    RAISE EXCEPTION 'Resultado no permitido';
  END IF;
  IF p_origen NOT IN ('servidor', 'navegador') THEN
    RAISE EXCEPTION 'Origen no permitido';
  END IF;
  INSERT INTO public.pruebas_seguridad (tipo, origen, resultado, severidad, resumen, recomendacion, detalle)
  VALUES (
    left(btrim(p_tipo), 80),
    p_origen,
    p_resultado,
    p_severidad,
    left(btrim(p_resumen), 400),
    left(btrim(p_recomendacion), 600),
    COALESCE(p_detalle, '{}'::jsonb)
  )
  RETURNING id INTO v_id;
  PERFORM public.registrar_auditoria(
    'ejecutar_prueba', 'pruebas_seguridad', v_id::text,
    NULL,
    jsonb_build_object('tipo', p_tipo, 'resultado', p_resultado, 'severidad', p_severidad),
    'Prueba de seguridad de la consola',
    NULL, NULL, NULL, NULL
  );
  RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.guardar_prueba_seguridad(text, text, text, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_guardar_prueba(
  p_tipo text,
  p_resultado text,
  p_severidad text,
  p_resumen text,
  p_recomendacion text,
  p_detalle jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF p_tipo NOT IN ('cors', 'secretos_cliente') THEN
    RAISE EXCEPTION 'Esa prueba se calcula en el servidor';
  END IF;
  RETURN public.guardar_prueba_seguridad(
    p_tipo, 'navegador', p_resultado, p_severidad, p_resumen, p_recomendacion, p_detalle
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_guardar_prueba(text, text, text, text, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_guardar_prueba(text, text, text, text, text, jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_ejecutar_prueba(p_tipo text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_tipo text := btrim(COALESCE(p_tipo, ''));
  v_resultado text := 'ok';
  v_severidad text := 'baja';
  v_resumen text;
  v_recomendacion text;
  v_detalle jsonb := '{}'::jsonb;
  v_n integer := 0;
  v_umbral integer := 5;
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_tipo = 'rls' THEN
    SELECT coalesce(jsonb_build_object(
      'sin_rls', coalesce((
        SELECT jsonb_agg(n.nspname || '.' || c.relname ORDER BY c.relname)
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity
      ), '[]'::jsonb),
      'politica_abierta', coalesce((
        SELECT jsonb_agg(jsonb_build_object('tabla', p.tablename, 'politica', p.policyname, 'rol', p.roles) ORDER BY p.tablename)
        FROM pg_policies p
        WHERE p.schemaname = 'public'
          AND (p.roles && ARRAY['anon', 'authenticated', 'public']::name[] OR p.roles = '{public}'::name[])
          AND (
            replace(lower(coalesce(p.qual, '')), ' ', '') IN ('true', '(true)')
            OR replace(lower(coalesce(p.with_check, '')), ' ', '') IN ('true', '(true)')
          )
      ), '[]'::jsonb)
    ), '{}'::jsonb) INTO v_detalle;
    v_n := jsonb_array_length(v_detalle->'sin_rls') + jsonb_array_length(v_detalle->'politica_abierta');
    IF jsonb_array_length(v_detalle->'sin_rls') > 0 THEN
      v_resultado := 'fallo'; v_severidad := 'alta';
      v_resumen := 'Hay tablas public sin RLS.';
      v_recomendacion := 'Activa RLS y una politica explicita antes de exponer la tabla.';
    ELSIF jsonb_array_length(v_detalle->'politica_abierta') > 0 THEN
      v_resultado := 'aviso'; v_severidad := 'media';
      v_resumen := 'Hay politicas USING true para anon o authenticated.';
      v_recomendacion := 'Revisa si esa lectura publica es intencional. Si no, cierrala.';
    ELSE
      v_resumen := 'No hay tablas public sin RLS ni politicas abiertas en este corte.';
      v_recomendacion := 'Vuelve a correrla despues de cada migracion.';
    END IF;

  ELSIF v_tipo = 'advisors' THEN
    SELECT coalesce(jsonb_agg(n.nspname || '.' || p.proname ORDER BY p.proname), '[]'::jsonb)
    INTO v_detalle
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND NOT EXISTS (
        SELECT 1 FROM unnest(coalesce(p.proconfig, ARRAY[]::text[])) cfg
        WHERE cfg LIKE 'search_path=%'
      );
    v_detalle := jsonb_build_object('definer_sin_search_path', coalesce(v_detalle, '[]'::jsonb));
    IF jsonb_array_length(v_detalle->'definer_sin_search_path') > 0 THEN
      v_resultado := 'aviso'; v_severidad := 'media';
      v_resumen := 'Hay funciones SECURITY DEFINER sin search_path fijo.';
      v_recomendacion := 'Fija search_path en esas funciones para evitar secuestro de objetos.';
    ELSE
      v_resumen := 'Las funciones SECURITY DEFINER revisadas fijan search_path.';
      v_recomendacion := 'Manten el search_path en cada funcion nueva.';
    END IF;

  ELSIF v_tipo = 'funciones_sin_auth' THEN
    v_detalle := jsonb_build_array(
      'definir-clave-invitado', 'guest-checkout', 'oneclick-handoff', 'oneclick-return',
      'send-push', 'soporte-automatico', 'webpay-commit', 'webpay-handoff', 'webpay-reconcile'
    );
    v_resultado := 'aviso'; v_severidad := 'baja';
    v_resumen := 'Esas Edge Functions estan con verify_jwt en falso a proposito.';
    v_recomendacion := 'Cada una debe validar un secreto, firma o token propio. No agregues otra sin esa revision.';

  ELSIF v_tipo = 'fuerza_bruta' THEN
    SELECT valor INTO v_umbral FROM public.umbrales_seguridad WHERE clave = 'logins_fallidos';
    SELECT count(*) INTO v_n
    FROM public.eventos_acceso
    WHERE tipo = 'login_fallido' AND creado_en > now() - interval '15 minutes';
    v_detalle := jsonb_build_object('intentos', v_n, 'umbral', v_umbral, 'ventana_minutos', 15);
    IF v_n >= COALESCE(v_umbral, 5) THEN
      v_resultado := 'fallo'; v_severidad := 'alta';
      v_resumen := format('%s intentos fallidos en 15 minutos.', v_n);
      v_recomendacion := 'Activa el modo bloqueo o bloquea la IP si el origen se repite.';
    ELSE
      v_resumen := format('%s intentos fallidos, bajo el umbral %s.', v_n, COALESCE(v_umbral, 5));
      v_recomendacion := 'No hace falta bloquear. El conteo no prueba contrasenas.';
    END IF;

  ELSIF v_tipo = 'salud' THEN
    SELECT count(*) INTO v_n
    FROM public.registros_error_app
    WHERE public.texto_a_timestamptz(creado_en::text) > now() - interval '1 hour';
    v_detalle := jsonb_build_object('errores_ultima_hora', v_n, 'base', 'ok');
    IF v_n >= 10 THEN
      v_resultado := 'aviso'; v_severidad := 'media';
      v_resumen := format('La base responde. Hay %s errores de app en la ultima hora.', v_n);
      v_recomendacion := 'Revisa Errores de la app antes de tratarlo como incidente.';
    ELSE
      v_resumen := 'La base responde y los errores recientes estan bajo el umbral.';
      v_recomendacion := 'Las Edge Functions no publican latencia en el plan gratis.';
    END IF;

  ELSE
    RAISE EXCEPTION 'Prueba no conocida';
  END IF;

  v_id := public.guardar_prueba_seguridad(
    v_tipo, 'servidor', v_resultado, v_severidad, v_resumen, v_recomendacion, v_detalle
  );
  RETURN jsonb_build_object(
    'id', v_id, 'tipo', v_tipo, 'resultado', v_resultado, 'severidad', v_severidad,
    'resumen', v_resumen, 'recomendacion', v_recomendacion, 'detalle', v_detalle
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_ejecutar_prueba(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_ejecutar_prueba(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_listar_pruebas()
RETURNS TABLE (
  id uuid,
  creado_en timestamptz,
  tipo text,
  origen text,
  resultado text,
  severidad text,
  resumen text,
  recomendacion text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT p.id, p.creado_en, p.tipo, p.origen, p.resultado, p.severidad, p.resumen, p.recomendacion
  FROM public.pruebas_seguridad p
  ORDER BY p.creado_en DESC
  LIMIT 20;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_listar_pruebas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_pruebas() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_crear_respaldo(p_motivo text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_payload text;
  v_hash text;
  v_bytes integer;
  v_id uuid;
  v_total bigint;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT jsonb_build_object(
    'version', 1,
    'creado_en', now(),
    'app_config', coalesce((SELECT jsonb_agg(to_jsonb(c) - 'actualizado_en') FROM public.app_config c), '[]'::jsonb),
    'umbrales_seguridad', coalesce((SELECT jsonb_agg(to_jsonb(u)) FROM public.umbrales_seguridad u), '[]'::jsonb),
    'banderas_funcionalidad', coalesce((SELECT jsonb_agg(to_jsonb(b)) FROM public.banderas_funcionalidad b), '[]'::jsonb),
    'servicios', coalesce((
      SELECT jsonb_agg(jsonb_build_object('id', s.id, 'nombre', s.nombre, 'categoria', s.categoria, 'activo', s.activo))
      FROM public.servicios s
    ), '[]'::jsonb)
  )::text INTO v_payload;
  v_bytes := octet_length(v_payload);
  IF v_bytes > 8000000 THEN
    RAISE EXCEPTION 'El respaldo supera 8 MB';
  END IF;
  v_hash := encode(extensions.digest(convert_to(v_payload, 'utf8'), 'sha256'::text), 'hex');
  INSERT INTO public.respaldos_consola (tamano_bytes, sha256, tablas, contenido)
  VALUES (
    v_bytes, v_hash,
    ARRAY['app_config', 'umbrales_seguridad', 'banderas_funcionalidad', 'servicios'],
    v_payload
  )
  RETURNING id INTO v_id;

  DELETE FROM public.respaldos_consola
  WHERE id IN (
    SELECT id FROM public.respaldos_consola
    ORDER BY creado_en DESC
    OFFSET 5
  );
  SELECT coalesce(sum(tamano_bytes), 0) INTO v_total FROM public.respaldos_consola;
  WHILE v_total > 40000000 LOOP
    DELETE FROM public.respaldos_consola
    WHERE id = (SELECT id FROM public.respaldos_consola ORDER BY creado_en ASC LIMIT 1);
    SELECT coalesce(sum(tamano_bytes), 0) INTO v_total FROM public.respaldos_consola;
  END LOOP;

  PERFORM public.registrar_auditoria(
    'crear_respaldo', 'respaldos_consola', v_id::text,
    NULL, jsonb_build_object('bytes', v_bytes, 'sha256', v_hash),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
  RETURN jsonb_build_object('id', v_id, 'tamano_bytes', v_bytes, 'sha256', v_hash);
END;
$$;
REVOKE ALL ON FUNCTION public.consola_crear_respaldo(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_crear_respaldo(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_listar_respaldos()
RETURNS TABLE (id uuid, creado_en timestamptz, tamano_bytes integer, sha256 text, tablas text[], estado text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT r.id, r.creado_en, r.tamano_bytes, r.sha256, r.tablas, r.estado
  FROM public.respaldos_consola r
  ORDER BY r.creado_en DESC
  LIMIT 20;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_listar_respaldos() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_respaldos() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_verificar_respaldo(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_contenido text;
  v_hash text;
  v_guardado text;
  v_ok boolean;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT contenido, sha256 INTO v_contenido, v_guardado
  FROM public.respaldos_consola WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Respaldo no encontrado';
  END IF;
  v_hash := encode(extensions.digest(convert_to(v_contenido, 'utf8'), 'sha256'::text), 'hex');
  v_ok := v_hash = v_guardado;
  RETURN jsonb_build_object('ok', v_ok, 'sha256', v_guardado, 'calculado', v_hash);
END;
$$;
REVOKE ALL ON FUNCTION public.consola_verificar_respaldo(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_verificar_respaldo(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_restaurar_respaldo(
  p_id uuid,
  p_frase text,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_contenido text;
  v_guardado text;
  v_hash text;
  v_json jsonb;
  r record;
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
  SELECT contenido, sha256 INTO v_contenido, v_guardado
  FROM public.respaldos_consola WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Respaldo no encontrado';
  END IF;
  v_hash := encode(extensions.digest(convert_to(v_contenido, 'utf8'), 'sha256'::text), 'hex');
  IF v_hash IS DISTINCT FROM v_guardado THEN
    RAISE EXCEPTION 'El respaldo no coincide con su hash';
  END IF;
  v_json := v_contenido::jsonb;
  PERFORM set_config('mwa.defensa_bypass', '1', true);

  FOR r IN
    SELECT * FROM jsonb_to_recordset(COALESCE(v_json->'app_config', '[]'::jsonb))
      AS x(clave text, valor text)
  LOOP
    INSERT INTO public.app_config (clave, valor)
    VALUES (r.clave, r.valor)
    ON CONFLICT (clave) DO UPDATE SET valor = EXCLUDED.valor, actualizado_en = now();
  END LOOP;

  FOR r IN
    SELECT * FROM jsonb_to_recordset(COALESCE(v_json->'umbrales_seguridad', '[]'::jsonb))
      AS x(clave text, valor integer, ventana_minutos integer, descripcion text)
  LOOP
    INSERT INTO public.umbrales_seguridad (clave, valor, ventana_minutos, descripcion)
    VALUES (r.clave, r.valor, r.ventana_minutos, r.descripcion)
    ON CONFLICT (clave) DO UPDATE
      SET valor = EXCLUDED.valor, ventana_minutos = EXCLUDED.ventana_minutos, descripcion = EXCLUDED.descripcion;
  END LOOP;

  FOR r IN
    SELECT * FROM jsonb_to_recordset(COALESCE(v_json->'servicios', '[]'::jsonb))
      AS x(id text, activo integer)
  LOOP
    UPDATE public.servicios SET activo = r.activo WHERE id::text = r.id;
  END LOOP;

  FOR r IN
    SELECT * FROM jsonb_to_recordset(COALESCE(v_json->'banderas_funcionalidad', '[]'::jsonb))
      AS x(id text, habilitada integer)
  LOOP
    UPDATE public.banderas_funcionalidad
    SET habilitada = r.habilitada
    WHERE id::text = r.id;
  END LOOP;

  UPDATE public.respaldos_consola SET estado = 'restaurado' WHERE id = p_id;
  PERFORM public.registrar_auditoria(
    'restaurar_respaldo', 'respaldos_consola', p_id::text,
    NULL, jsonb_build_object('sha256', v_guardado),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_restaurar_respaldo(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_restaurar_respaldo(uuid, text, text) TO authenticated;

COMMIT;
