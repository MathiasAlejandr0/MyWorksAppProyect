-- Acciones de gestión y módulo de seguridad de la consola.
-- No aplicar en el proyecto remoto wxqrfcqifkfgawrnqmnj.
-- El cliente usa la anon key. Lo sensible lo leen funciones SECURITY DEFINER
-- que exigen rol de consola o administrador. No hay service role en el navegador.

BEGIN;

CREATE OR REPLACE FUNCTION public.enmascarar_correo(p_correo text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT CASE
    WHEN p_correo IS NULL OR position('@' IN btrim(p_correo)) = 0 THEN '***'
    ELSE left(split_part(btrim(p_correo), '@', 1), 1) || '***@' || split_part(btrim(p_correo), '@', 2)
  END;
$$;
REVOKE ALL ON FUNCTION public.enmascarar_correo(text) FROM PUBLIC, anon, authenticated;

-- Soporte y QA ven la cola de profesionales, reportes y tickets.
-- La fila de perfiles no se abre: el correo se queda detrás de un RPC sin correo.
DROP POLICY IF EXISTS trabajadores_select_consola ON public.trabajadores;
CREATE POLICY trabajadores_select_consola
  ON public.trabajadores
  FOR SELECT
  TO authenticated
  USING ((SELECT public.rol_consola()) IS NOT NULL);

DROP POLICY IF EXISTS reportes_select_consola ON public.reportes;
CREATE POLICY reportes_select_consola
  ON public.reportes
  FOR SELECT
  TO authenticated
  USING ((SELECT public.rol_consola()) IS NOT NULL);

DROP POLICY IF EXISTS tickets_soporte_select_consola ON public.tickets_soporte;
CREATE POLICY tickets_soporte_select_consola
  ON public.tickets_soporte
  FOR SELECT
  TO authenticated
  USING ((SELECT public.rol_consola()) IS NOT NULL);

CREATE TABLE IF NOT EXISTS public.ticket_mensajes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_ticket text NOT NULL REFERENCES public.tickets_soporte (id) ON DELETE CASCADE,
  id_autor uuid,
  cuerpo text NOT NULL CHECK (char_length(btrim(cuerpo)) BETWEEN 2 AND 2000),
  creado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ticket_mensajes_ticket_idx
  ON public.ticket_mensajes (id_ticket, creado_en);
ALTER TABLE public.ticket_mensajes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ticket_mensajes FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.ticket_mensajes TO authenticated;
DROP POLICY IF EXISTS ticket_mensajes_select_consola ON public.ticket_mensajes;
CREATE POLICY ticket_mensajes_select_consola
  ON public.ticket_mensajes
  FOR SELECT
  TO authenticated
  USING ((SELECT public.rol_consola()) IS NOT NULL);

CREATE TABLE IF NOT EXISTS public.eventos_acceso (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  tipo text NOT NULL CHECK (tipo IN ('login_fallido', 'mfa_fallido')),
  correo_enmascarado text NOT NULL
);
CREATE INDEX IF NOT EXISTS eventos_acceso_creado_idx
  ON public.eventos_acceso (creado_en DESC);
ALTER TABLE public.eventos_acceso ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.eventos_acceso FROM PUBLIC, anon, authenticated;

CREATE TABLE IF NOT EXISTS public.umbrales_seguridad (
  clave text PRIMARY KEY,
  valor integer NOT NULL CHECK (valor BETWEEN 0 AND 100000),
  ventana_minutos integer NOT NULL CHECK (ventana_minutos BETWEEN 1 AND 10080),
  descripcion text NOT NULL
);
ALTER TABLE public.umbrales_seguridad ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.umbrales_seguridad FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.umbrales_seguridad TO authenticated;
DROP POLICY IF EXISTS umbrales_seguridad_select_admin ON public.umbrales_seguridad;
CREATE POLICY umbrales_seguridad_select_admin
  ON public.umbrales_seguridad
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));

INSERT INTO public.umbrales_seguridad (clave, valor, ventana_minutos, descripcion)
VALUES
  ('logins_fallidos', 5, 15, 'Intentos de acceso fallidos'),
  ('errores_app', 10, 15, 'Errores nuevos de la app y de funciones'),
  ('disputas_nuevas', 8, 60, 'Disputas activas creadas en la ventana'),
  ('reportes_usuario', 3, 1440, 'Reportes contra la misma persona'),
  ('altas', 20, 60, 'Perfiles creados'),
  ('pagos_retenidos_viejos', 5, 10080, 'Pagos retenidos más viejos que la ventana')
ON CONFLICT (clave) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.incidentes_seguridad (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  tipo text NOT NULL,
  severidad text NOT NULL CHECK (severidad IN ('baja', 'media', 'alta')),
  resumen text NOT NULL,
  detalle jsonb NOT NULL DEFAULT '{}'::jsonb,
  estado text NOT NULL DEFAULT 'abierto' CHECK (estado IN ('abierto', 'reconocido')),
  id_usuario uuid
);
CREATE INDEX IF NOT EXISTS incidentes_seguridad_creado_idx
  ON public.incidentes_seguridad (creado_en DESC);
ALTER TABLE public.incidentes_seguridad ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.incidentes_seguridad FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.incidentes_seguridad TO authenticated;
DROP POLICY IF EXISTS incidentes_seguridad_select_admin ON public.incidentes_seguridad;
CREATE POLICY incidentes_seguridad_select_admin
  ON public.incidentes_seguridad
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));
ALTER TABLE public.incidentes_seguridad REPLICA IDENTITY FULL;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.incidentes_seguridad;
EXCEPTION
  WHEN undefined_object THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.registrar_evento_acceso(p_tipo text, p_correo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_tipo text := btrim(COALESCE(p_tipo, ''));
  v_n integer;
BEGIN
  IF v_tipo NOT IN ('login_fallido', 'mfa_fallido') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_tipo = 'mfa_fallido' AND auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT count(*) INTO v_n
  FROM public.eventos_acceso
  WHERE creado_en > now() - interval '1 hour';
  IF v_n >= 120 THEN
    RETURN;
  END IF;
  INSERT INTO public.eventos_acceso (tipo, correo_enmascarado)
  VALUES (v_tipo, public.enmascarar_correo(left(COALESCE(p_correo, ''), 180)));
END;
$$;
REVOKE ALL ON FUNCTION public.registrar_evento_acceso(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.registrar_evento_acceso(text, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_listar_perfiles(
  p_rol text,
  p_q text,
  p_offset integer,
  p_limite integer
)
RETURNS TABLE (
  id uuid,
  nombre text,
  rol text,
  estado_cuenta text,
  creado_en text,
  total bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_q text := left(replace(replace(btrim(COALESCE(p_q, '')), '%', ''), '_', ''), 60);
  v_off integer := GREATEST(COALESCE(p_offset, 0), 0);
  v_lim integer := LEAST(GREATEST(COALESCE(p_limite, 25), 1), 100);
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_rol IS NULL OR p_rol NOT IN ('usuario', 'trabajador', 'administrador', 'soporte', 'qa') THEN
    RAISE EXCEPTION 'rol no permitido';
  END IF;
  RETURN QUERY
  SELECT
    p.id,
    p.nombre,
    p.rol,
    p.estado_cuenta,
    p.creado_en,
    count(*) OVER ()
  FROM public.perfiles p
  WHERE p.rol = p_rol
    AND (v_q = '' OR p.nombre ILIKE '%' || v_q || '%')
  ORDER BY p.creado_en DESC
  LIMIT v_lim
  OFFSET v_off;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_listar_perfiles(text, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_perfiles(text, text, integer, integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_responder_ticket(
  p_id text,
  p_cuerpo text,
  p_cerrar boolean,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_rol text := public.rol_consola();
  v_estado text;
  v_nuevo text;
  v_cuerpo text := left(btrim(COALESCE(p_cuerpo, '')), 2000);
BEGIN
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(v_cuerpo) < 2 THEN
    RAISE EXCEPTION 'La respuesta es demasiado corta';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF COALESCE(p_cerrar, false) AND v_rol <> 'administrador' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT estado INTO v_estado
  FROM public.tickets_soporte
  WHERE id::text = btrim(p_id)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket no encontrado';
  END IF;
  v_nuevo := CASE WHEN COALESCE(p_cerrar, false) THEN 'resuelto' ELSE 'respondido' END;
  INSERT INTO public.ticket_mensajes (id_ticket, id_autor, cuerpo)
  VALUES (btrim(p_id), auth.uid(), v_cuerpo);
  UPDATE public.tickets_soporte
  SET estado = v_nuevo
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    CASE WHEN v_nuevo = 'resuelto'
      THEN 'resolver_ticket'::public.accion_auditoria_consola
      ELSE 'responder_ticket'::public.accion_auditoria_consola
    END,
    'tickets_soporte',
    btrim(p_id),
    jsonb_build_object('estado', v_estado),
    jsonb_build_object('estado', v_nuevo),
    btrim(p_motivo),
    NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_responder_ticket(text, text, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_responder_ticket(text, text, boolean, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_mensajes_ticket(p_id text)
RETURNS TABLE (id uuid, cuerpo text, creado_en timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT m.id, m.cuerpo, m.creado_en
  FROM public.ticket_mensajes m
  WHERE m.id_ticket = btrim(p_id)
  ORDER BY m.creado_en;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_mensajes_ticket(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_mensajes_ticket(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_fijar_servicio(
  p_id text,
  p_activo integer,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_activo NOT IN (0, 1) THEN
    RAISE EXCEPTION 'Valor no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT activo INTO v_antes
  FROM public.servicios
  WHERE id::text = btrim(p_id)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Servicio no encontrado';
  END IF;
  UPDATE public.servicios
  SET activo = p_activo
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'editar_servicio',
    'servicios',
    btrim(p_id),
    jsonb_build_object('activo', v_antes),
    jsonb_build_object('activo', p_activo),
    btrim(p_motivo),
    NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_fijar_servicio(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_fijar_servicio(text, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.abrir_incidente_seguridad(
  p_tipo text,
  p_severidad text,
  p_resumen text,
  p_detalle jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.incidentes_seguridad i
    WHERE i.tipo = p_tipo
      AND i.estado = 'abierto'
      AND i.creado_en > now() - interval '1 hour'
  ) THEN
    RETURN;
  END IF;
  INSERT INTO public.incidentes_seguridad (tipo, severidad, resumen, detalle)
  VALUES (
    left(btrim(p_tipo), 80),
    p_severidad,
    left(btrim(p_resumen), 300),
    COALESCE(p_detalle, '{}'::jsonb)
  );
END;
$$;
REVOKE ALL ON FUNCTION public.abrir_incidente_seguridad(text, text, text, jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.consola_seguridad_vivo()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_logins integer := 0;
  v_extra integer := 0;
  v_ventana_login integer := 15;
  v_umbral_login integer := 5;
  v_errores integer := 0;
  v_ventana_err integer := 15;
  v_umbral_err integer := 10;
  v_disputas integer := 0;
  v_ventana_dis integer := 60;
  v_umbral_dis integer := 8;
  v_altas integer := 0;
  v_ventana_altas integer := 60;
  v_umbral_altas integer := 20;
  v_viejos integer := 0;
  v_umbral_viejos integer := 5;
  v_ventana_viejos integer := 10080;
  v_umbral_reportes integer := 3;
  v_auth jsonb := '[]'::jsonb;
  v_mfa jsonb := '[]'::jsonb;
  v_sesiones jsonb := '[]'::jsonb;
  v_reportes jsonb := '[]'::jsonb;
  v_rls jsonb := '[]'::jsonb;
  v_incidentes jsonb := '[]'::jsonb;
  v_umbrales jsonb := '[]'::jsonb;
  v_turnstile text := 'Sin registros de Turnstile en la base.';
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT valor, ventana_minutos INTO v_umbral_login, v_ventana_login
  FROM public.umbrales_seguridad WHERE clave = 'logins_fallidos';
  SELECT valor, ventana_minutos INTO v_umbral_err, v_ventana_err
  FROM public.umbrales_seguridad WHERE clave = 'errores_app';
  SELECT valor, ventana_minutos INTO v_umbral_dis, v_ventana_dis
  FROM public.umbrales_seguridad WHERE clave = 'disputas_nuevas';
  SELECT valor, ventana_minutos INTO v_umbral_altas, v_ventana_altas
  FROM public.umbrales_seguridad WHERE clave = 'altas';
  SELECT valor, ventana_minutos INTO v_umbral_viejos, v_ventana_viejos
  FROM public.umbrales_seguridad WHERE clave = 'pagos_retenidos_viejos';
  SELECT valor INTO v_umbral_reportes
  FROM public.umbrales_seguridad WHERE clave = 'reportes_usuario';

  SELECT count(*) INTO v_logins
  FROM public.eventos_acceso e
  WHERE e.tipo = 'login_fallido'
    AND e.creado_en > now() - make_interval(mins => v_ventana_login);

  IF to_regclass('auth.audit_log_entries') IS NOT NULL THEN
    BEGIN
      EXECUTE $q$
        SELECT count(*)::int
        FROM auth.audit_log_entries a
        WHERE a.created_at > now() - make_interval(mins => $1)
          AND (
            coalesce(a.payload->>'action', '') IN ('user_login_failed', 'login_failed')
            OR (
              coalesce(a.payload->>'action', '') = 'login'
              AND (a.payload ? 'error' OR coalesce(a.payload->>'level', '') = 'error')
            )
          )
      $q$ INTO v_extra USING v_ventana_login;
      v_logins := v_logins + COALESCE(v_extra, 0);
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
    BEGIN
      EXECUTE $q$
        SELECT coalesce(jsonb_agg(jsonb_build_object(
          'cuando', s.created_at,
          'accion', s.accion,
          'correo', public.enmascarar_correo(s.correo),
          'ip', left(coalesce(s.ip, ''), 64)
        ) ORDER BY s.created_at DESC), '[]'::jsonb)
        FROM (
          SELECT
            a.created_at,
            coalesce(a.payload->>'action', '') AS accion,
            coalesce(a.payload->>'actor_username', a.payload->>'actor_name', '') AS correo,
            a.ip_address::text AS ip
          FROM auth.audit_log_entries a
          WHERE a.created_at > now() - interval '24 hours'
          ORDER BY a.created_at DESC
          LIMIT 30
        ) s
      $q$ INTO v_auth;
    EXCEPTION WHEN OTHERS THEN
      v_auth := '[]'::jsonb;
    END;
  END IF;

  IF to_regclass('auth.mfa_factors') IS NOT NULL THEN
    BEGIN
      EXECUTE $q$
        SELECT coalesce(jsonb_agg(jsonb_build_object(
          'tipo', f.factor_type,
          'estado', f.status,
          'cuando', f.updated_at,
          'usuario', f.user_id
        ) ORDER BY f.updated_at DESC), '[]'::jsonb)
        FROM (
          SELECT factor_type, status, updated_at, user_id
          FROM auth.mfa_factors
          WHERE updated_at > now() - interval '24 hours'
          ORDER BY updated_at DESC
          LIMIT 20
        ) f
      $q$ INTO v_mfa;
    EXCEPTION WHEN OTHERS THEN
      v_mfa := '[]'::jsonb;
    END;
  END IF;

  IF to_regclass('auth.sessions') IS NOT NULL THEN
    BEGIN
      EXECUTE $q$
        SELECT coalesce(jsonb_agg(jsonb_build_object(
          'nombre', s.nombre,
          'rol', s.rol,
          'cuando', s.created_at,
          'aal', s.aal,
          'usuario', s.user_id
        ) ORDER BY s.created_at DESC), '[]'::jsonb)
        FROM (
          SELECT p.nombre, p.rol, ses.created_at, ses.aal, ses.user_id
          FROM auth.sessions ses
          JOIN public.perfiles p ON p.id = ses.user_id
          WHERE p.rol IN ('administrador', 'soporte', 'qa')
            AND ses.created_at > now() - interval '24 hours'
          ORDER BY ses.created_at DESC
          LIMIT 20
        ) s
      $q$ INTO v_sesiones;
    EXCEPTION WHEN OTHERS THEN
      v_sesiones := '[]'::jsonb;
    END;
  END IF;

  SELECT count(*) INTO v_errores
  FROM public.registros_error_app e
  WHERE public.texto_a_timestamptz(e.creado_en::text) > now() - make_interval(mins => v_ventana_err);

  SELECT count(*) INTO v_disputas
  FROM public.disputas d
  WHERE public.disputa_esta_activa(d.estado)
    AND public.texto_a_timestamptz(d.creado_en::text) > now() - make_interval(mins => v_ventana_dis);

  SELECT count(*) INTO v_altas
  FROM public.perfiles p
  WHERE public.texto_a_timestamptz(p.creado_en::text) > now() - make_interval(mins => v_ventana_altas);

  SELECT count(*) INTO v_viejos
  FROM public.pagos p
  WHERE p.estado = 'retenido'
    AND public.texto_a_timestamptz(p.creado_en::text) < now() - make_interval(mins => v_ventana_viejos);

  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'usuario', g.id_usuario_reportado,
    'cantidad', g.n
  )), '[]'::jsonb)
  INTO v_reportes
  FROM (
    SELECT r.id_usuario_reportado, count(*) AS n
    FROM public.reportes r
    WHERE public.texto_a_timestamptz(r.creado_en::text) > now() - interval '1 day'
    GROUP BY r.id_usuario_reportado
    HAVING count(*) >= v_umbral_reportes
    ORDER BY count(*) DESC
    LIMIT 20
  ) g;

  SELECT coalesce(jsonb_agg(t.nombre), '[]'::jsonb)
  INTO v_rls
  FROM (
    SELECT n.nspname || '.' || c.relname AS nombre
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relrowsecurity
      AND NOT EXISTS (
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname = 'public' AND p.tablename = c.relname
      )
    ORDER BY 1
    LIMIT 20
  ) t;

  IF to_regclass('public.eventos_turnstile') IS NOT NULL
     OR EXISTS (
       SELECT 1 FROM public.app_config WHERE clave ILIKE '%turnstile%'
     ) THEN
    v_turnstile := 'Hay una clave de Turnstile en la configuración. El secreto no se muestra aquí.';
  END IF;

  IF v_logins >= v_umbral_login THEN
    PERFORM public.abrir_incidente_seguridad(
      'logins_fallidos', 'alta',
      format('%s accesos fallidos en %s min', v_logins, v_ventana_login),
      jsonb_build_object('cantidad', v_logins, 'umbral', v_umbral_login)
    );
  END IF;
  IF v_errores >= v_umbral_err THEN
    PERFORM public.abrir_incidente_seguridad(
      'errores_app', 'media',
      format('%s errores en %s min', v_errores, v_ventana_err),
      jsonb_build_object('cantidad', v_errores, 'umbral', v_umbral_err)
    );
  END IF;
  IF v_disputas >= v_umbral_dis THEN
    PERFORM public.abrir_incidente_seguridad(
      'disputas_nuevas', 'media',
      format('%s disputas activas en la ventana', v_disputas),
      jsonb_build_object('cantidad', v_disputas, 'umbral', v_umbral_dis)
    );
  END IF;
  IF v_altas >= v_umbral_altas THEN
    PERFORM public.abrir_incidente_seguridad(
      'altas', 'media',
      format('%s altas en %s min', v_altas, v_ventana_altas),
      jsonb_build_object('cantidad', v_altas, 'umbral', v_umbral_altas)
    );
  END IF;
  IF v_viejos >= v_umbral_viejos THEN
    PERFORM public.abrir_incidente_seguridad(
      'pagos_retenidos_viejos', 'alta',
      format('%s pagos retenidos superan la ventana', v_viejos),
      jsonb_build_object('cantidad', v_viejos, 'umbral', v_umbral_viejos)
    );
  END IF;
  IF jsonb_array_length(v_reportes) > 0 THEN
    PERFORM public.abrir_incidente_seguridad(
      'abuso_reportes', 'alta',
      'Hay personas con más reportes que el umbral',
      jsonb_build_object('personas', v_reportes)
    );
  END IF;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'clave', u.clave, 'valor', u.valor, 'ventana_minutos', u.ventana_minutos, 'descripcion', u.descripcion
  ) ORDER BY u.clave), '[]'::jsonb)
  INTO v_umbrales
  FROM public.umbrales_seguridad u;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id, 'cuando', i.creado_en, 'tipo', i.tipo, 'severidad', i.severidad,
    'resumen', i.resumen, 'estado', i.estado
  ) ORDER BY i.creado_en DESC), '[]'::jsonb)
  INTO v_incidentes
  FROM (
    SELECT * FROM public.incidentes_seguridad
    ORDER BY creado_en DESC
    LIMIT 30
  ) i;

  RETURN jsonb_build_object(
    'generado_en', now(),
    'logins_fallidos', v_logins,
    'errores', v_errores,
    'disputas_activas_ventana', v_disputas,
    'altas', v_altas,
    'pagos_retenidos_viejos', v_viejos,
    'auditoria_auth', v_auth,
    'mfa', v_mfa,
    'sesiones_consola', v_sesiones,
    'reportes_abuso', v_reportes,
    'rls_sin_politica', v_rls,
    'turnstile', v_turnstile,
    'servicio', jsonb_build_object(
      'base', 'ok',
      'edge', 'El plan gratis no expone la latencia de las Edge Functions. Los fallos que llegan a registros_error_app se cuentan arriba.'
    ),
    'umbrales', v_umbrales,
    'incidentes', v_incidentes
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_seguridad_vivo() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_seguridad_vivo() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_seguridad_usuario(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_perfil public.perfiles%ROWTYPE;
  v_reportes integer := 0;
  v_errores integer := 0;
  v_sesiones integer := 0;
  v_eventos jsonb := '[]'::jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT * INTO v_perfil FROM public.perfiles WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  SELECT count(*) INTO v_reportes
  FROM public.reportes r
  WHERE r.id_usuario_reportado = p_id;
  SELECT count(*) INTO v_errores
  FROM public.registros_error_app e
  WHERE e.id_usuario::text = p_id::text;
  IF to_regclass('auth.sessions') IS NOT NULL THEN
    BEGIN
      EXECUTE 'SELECT count(*) FROM auth.sessions WHERE user_id = $1' INTO v_sesiones USING p_id;
    EXCEPTION WHEN OTHERS THEN
      v_sesiones := 0;
    END;
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'cuando', e.creado_en, 'tipo', e.tipo, 'correo', e.correo_enmascarado
  ) ORDER BY e.creado_en DESC), '[]'::jsonb)
  INTO v_eventos
  FROM (
    SELECT creado_en, tipo, correo_enmascarado
    FROM public.eventos_acceso
    WHERE correo_enmascarado = public.enmascarar_correo(v_perfil.correo)
    ORDER BY creado_en DESC
    LIMIT 20
  ) e;
  RETURN jsonb_build_object(
    'id', v_perfil.id,
    'nombre', v_perfil.nombre,
    'rol', v_perfil.rol,
    'estado_cuenta', v_perfil.estado_cuenta,
    'correo', public.enmascarar_correo(v_perfil.correo),
    'reportes', v_reportes,
    'errores', v_errores,
    'sesiones_abiertas', v_sesiones,
    'eventos', v_eventos
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_seguridad_usuario(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_seguridad_usuario(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_cerrar_sesion_persona(p_id uuid, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_id = auth.uid() THEN
    RAISE EXCEPTION 'Cierra tu sesión desde Mi cuenta';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.perfiles WHERE id = p_id) THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  IF to_regclass('auth.sessions') IS NOT NULL THEN
    DELETE FROM auth.sessions WHERE user_id = p_id;
  END IF;
  IF to_regclass('auth.refresh_tokens') IS NOT NULL THEN
    EXECUTE 'DELETE FROM auth.refresh_tokens WHERE user_id::text = $1' USING p_id::text;
  END IF;
  PERFORM public.registrar_auditoria(
    'cerrar_sesion', 'perfiles', p_id::text,
    NULL, jsonb_build_object('sesiones', 'cerradas'),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_cerrar_sesion_persona(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_cerrar_sesion_persona(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_forzar_reset(p_id uuid, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_id = auth.uid() THEN
    RAISE EXCEPTION 'No puedes forzarte el reset desde aquí';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.perfiles WHERE id = p_id) THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  UPDATE auth.users
  SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('requiere_reset', true)
  WHERE id = p_id;
  IF to_regclass('auth.sessions') IS NOT NULL THEN
    DELETE FROM auth.sessions WHERE user_id = p_id;
  END IF;
  IF to_regclass('auth.refresh_tokens') IS NOT NULL THEN
    EXECUTE 'DELETE FROM auth.refresh_tokens WHERE user_id::text = $1' USING p_id::text;
  END IF;
  PERFORM public.registrar_auditoria(
    'forzar_reset', 'perfiles', p_id::text,
    NULL, jsonb_build_object('requiere_reset', true, 'sesiones', 'cerradas'),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_forzar_reset(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_forzar_reset(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_bloquear_cuenta(
  p_id uuid,
  p_bloquear boolean,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_antes text;
  v_rol text;
  v_admins integer;
  v_estado text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_id = auth.uid() AND p_bloquear THEN
    RAISE EXCEPTION 'No puedes bloquear tu propia cuenta';
  END IF;
  SELECT estado_cuenta, rol INTO v_antes, v_rol
  FROM public.perfiles WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  v_estado := CASE WHEN p_bloquear THEN 'suspendido' ELSE 'activo' END;
  IF v_rol = 'administrador' AND p_bloquear AND v_antes IN ('activo', 'active') THEN
    SELECT count(*) INTO v_admins
    FROM public.perfiles
    WHERE rol = 'administrador'
      AND estado_cuenta IN ('activo', 'active')
      AND id <> p_id;
    IF v_admins < 1 THEN
      RAISE EXCEPTION 'No se puede suspender el último administrador activo';
    END IF;
  END IF;
  UPDATE public.perfiles SET estado_cuenta = v_estado WHERE id = p_id;
  UPDATE auth.users
  SET banned_until = CASE
        WHEN p_bloquear THEN now() + interval '100 years'
        ELSE NULL
      END
  WHERE id = p_id;
  IF p_bloquear THEN
    IF to_regclass('auth.sessions') IS NOT NULL THEN
      DELETE FROM auth.sessions WHERE user_id = p_id;
    END IF;
    IF to_regclass('auth.refresh_tokens') IS NOT NULL THEN
      EXECUTE 'DELETE FROM auth.refresh_tokens WHERE user_id::text = $1' USING p_id::text;
    END IF;
  END IF;
  PERFORM public.registrar_auditoria(
    CASE WHEN p_bloquear
      THEN 'bloquear_cuenta'::public.accion_auditoria_consola
      ELSE 'reactivar_cuenta'::public.accion_auditoria_consola
    END,
    'perfiles', p_id::text,
    jsonb_build_object('estado_cuenta', v_antes),
    jsonb_build_object('estado_cuenta', v_estado, 'bloqueado', p_bloquear),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_bloquear_cuenta(uuid, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_bloquear_cuenta(uuid, boolean, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_editar_umbral(
  p_clave text,
  p_valor integer,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_valor IS NULL OR p_valor < 0 OR p_valor > 100000 THEN
    RAISE EXCEPTION 'Valor no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT valor INTO v_antes
  FROM public.umbrales_seguridad
  WHERE clave = btrim(p_clave)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Umbral no encontrado';
  END IF;
  UPDATE public.umbrales_seguridad
  SET valor = p_valor
  WHERE clave = btrim(p_clave);
  PERFORM public.registrar_auditoria(
    'umbral_seguridad', 'umbrales_seguridad', btrim(p_clave),
    jsonb_build_object('valor', v_antes),
    jsonb_build_object('valor', p_valor),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_editar_umbral(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_editar_umbral(text, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_reconocer_incidente(p_id uuid, p_motivo text)
RETURNS void
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
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT estado INTO v_antes
  FROM public.incidentes_seguridad
  WHERE id = p_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Incidente no encontrado';
  END IF;
  UPDATE public.incidentes_seguridad
  SET estado = 'reconocido'
  WHERE id = p_id;
  PERFORM public.registrar_auditoria(
    'reconocer_incidente', 'incidentes_seguridad', p_id::text,
    jsonb_build_object('estado', v_antes),
    jsonb_build_object('estado', 'reconocido'),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_reconocer_incidente(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_reconocer_incidente(uuid, text) TO authenticated;

COMMIT;
