-- Bitácora de la consola y RPC que la escriben.
-- No edita migraciones anteriores. No se aplica en remoto desde este cambio.
--
-- Inserción solo por registrar_auditoria() (bandera de sesión). No hay UPDATE
-- ni DELETE. La lectura de la tabla es solo para is_admin().

BEGIN;

DO $$
BEGIN
  CREATE TYPE public.accion_auditoria_consola AS ENUM (
    'liberar_pago',
    'devolver_pago',
    'liquidar',
    'resolver_disputa',
    'invitar_colaborador',
    'reenviar_invitacion',
    'revocar_invitacion',
    'cambiar_rol',
    'suspender_cuenta',
    'reactivar_cuenta',
    'aprobar_verificacion',
    'rechazar_verificacion',
    'pedir_correccion',
    'ocultar_resena',
    'restaurar_resena',
    'proponer_resena',
    'cerrar_sesion',
    'editar_ajuste',
    'editar_bandera',
    'aviso_masivo',
    'consultar_rut',
    'exportar_datos',
    'eliminar_datos',
    'sancionar_reporte',
    'descartar_reporte',
    'marcar_error_revisado',
    'nota_interna'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.auditoria_consola (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  id_actor uuid,
  rol_actor text,
  accion public.accion_auditoria_consola NOT NULL,
  entidad text NOT NULL,
  id_entidad text,
  antes jsonb,
  despues jsonb,
  motivo text,
  ip text,
  user_agent text
);

CREATE INDEX IF NOT EXISTS auditoria_consola_creado_idx
  ON public.auditoria_consola (creado_en DESC);
CREATE INDEX IF NOT EXISTS auditoria_consola_actor_idx
  ON public.auditoria_consola (id_actor, creado_en DESC);
CREATE INDEX IF NOT EXISTS auditoria_consola_entidad_idx
  ON public.auditoria_consola (entidad, id_entidad);

ALTER TABLE public.auditoria_consola ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.auditoria_consola FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.auditoria_consola TO authenticated, service_role;

DROP POLICY IF EXISTS auditoria_consola_select_admin ON public.auditoria_consola;
CREATE POLICY auditoria_consola_select_admin
  ON public.auditoria_consola
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));

CREATE OR REPLACE FUNCTION public.auditoria_consola_solo_rpc()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP <> 'INSERT' THEN
    RAISE EXCEPTION 'auditoria_consola es inmutable';
  END IF;
  IF current_setting('mwa.auditoria', true) IS DISTINCT FROM '1' THEN
    RAISE EXCEPTION 'solo registrar_auditoria puede insertar';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS auditoria_consola_solo_rpc ON public.auditoria_consola;
CREATE TRIGGER auditoria_consola_solo_rpc
  BEFORE INSERT OR UPDATE OR DELETE ON public.auditoria_consola
  FOR EACH ROW
  EXECUTE FUNCTION public.auditoria_consola_solo_rpc();

CREATE OR REPLACE FUNCTION public.registrar_auditoria(
  p_accion public.accion_auditoria_consola,
  p_entidad text,
  p_id_entidad text,
  p_antes jsonb,
  p_despues jsonb,
  p_motivo text,
  p_ip text DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_id_actor uuid DEFAULT NULL,
  p_rol_actor text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid;
  v_actor uuid;
  v_rol text;
BEGIN
  IF public.is_admin()
     OR (
       public.rol_consola() = 'soporte'
       AND p_accion IN ('nota_interna', 'proponer_resena')
     ) THEN
    v_actor := auth.uid();
    SELECT p.rol INTO v_rol FROM public.perfiles p WHERE p.id = v_actor;
  ELSIF coalesce(auth.role(), '') = 'service_role' THEN
    IF p_id_actor IS NULL THEN
      RAISE EXCEPTION 'actor requerido';
    END IF;
    SELECT p.id, p.rol INTO v_actor, v_rol
    FROM public.perfiles p
    WHERE p.id = p_id_actor
      AND p.rol = 'administrador'
      AND p.estado_cuenta IN ('activo', 'active');
    IF v_actor IS NULL THEN
      RAISE EXCEPTION 'actor no es administrador activo';
    END IF;
  ELSE
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_motivo IS NULL OR char_length(btrim(p_motivo)) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;

  PERFORM set_config('mwa.auditoria', '1', true);
  INSERT INTO public.auditoria_consola (
    id_actor, rol_actor, accion, entidad, id_entidad,
    antes, despues, motivo, ip, user_agent
  ) VALUES (
    v_actor,
    COALESCE(NULLIF(btrim(p_rol_actor), ''), v_rol),
    p_accion,
    left(btrim(p_entidad), 80),
    NULLIF(left(btrim(COALESCE(p_id_entidad, '')), 80), ''),
    p_antes,
    p_despues,
    left(btrim(p_motivo), 2000),
    NULLIF(left(COALESCE(p_ip, ''), 80), ''),
    NULLIF(left(COALESCE(p_user_agent, ''), 300), '')
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_auditoria(
  public.accion_auditoria_consola, text, text, jsonb, jsonb, text, text, text, uuid, text
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_auditoria(
  public.accion_auditoria_consola, text, text, jsonb, jsonb, text, text, text, uuid, text
) TO service_role;

-- Notas internas: las partes no las leen. Las notas ya existentes siguen visibles.
ALTER TABLE public.disputa_mensajes
  ADD COLUMN IF NOT EXISTS interna boolean NOT NULL DEFAULT false;

DROP POLICY IF EXISTS disputa_mensajes_select ON public.disputa_mensajes;
CREATE POLICY disputa_mensajes_select ON public.disputa_mensajes
  FOR SELECT TO authenticated
  USING (
    (
      NOT interna
      AND (
        (SELECT public.is_admin())
        OR (SELECT public.rol_consola()) IS NOT NULL
        OR EXISTS (
          SELECT 1 FROM public.disputas d
          WHERE d.id::text = disputa_mensajes.id_disputa::text
            AND public.es_parte_trabajo(d.id_trabajo::text)
        )
      )
    )
    OR (
      interna
      AND (SELECT public.rol_consola()) IN ('administrador', 'soporte')
    )
  );

CREATE OR REPLACE FUNCTION public.consola_nota_interna(p_id text, p_nota text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_rol text := public.rol_consola();
  v_nota text := left(btrim(COALESCE(p_nota, '')), 1000);
  v_row public.disputas%ROWTYPE;
BEGIN
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(v_nota) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT * INTO v_row FROM public.disputas WHERE id::text = btrim(p_id);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  INSERT INTO public.disputa_mensajes (id, id_disputa, id_autor, cuerpo, interna)
  VALUES (gen_random_uuid()::text, v_row.id, auth.uid(), v_nota, true);
  PERFORM public.registrar_auditoria(
    'nota_interna', 'disputas', v_row.id::text,
    NULL, jsonb_build_object('interna', true), v_nota, NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_nota_interna(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_nota_interna(text, text) TO authenticated;

-- Verificación: el rechazo exige nota (CU-29) y queda en la bitácora.
CREATE OR REPLACE FUNCTION public.fijar_verificacion_profesional(
  p_id_usuario uuid,
  p_estado text,
  p_nota text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_nota_antes text;
  v_accion public.accion_auditoria_consola;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Solo un administrador puede fijar la verificación';
  END IF;
  IF p_estado NOT IN ('pendiente', 'en_revision', 'verificado', 'rechazado') THEN
    RAISE EXCEPTION 'Estado de verificación inválido';
  END IF;
  IF p_estado = 'rechazado' AND char_length(btrim(COALESCE(p_nota, ''))) < 10 THEN
    RAISE EXCEPTION 'La nota de rechazo debe tener al menos 10 caracteres';
  END IF;
  SELECT estado_verificacion, nota_verificacion
    INTO v_antes, v_nota_antes
  FROM public.trabajadores
  WHERE id_usuario = p_id_usuario;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profesional no encontrado';
  END IF;
  PERFORM set_config('mwa.rpc_trabajador', '1', true);
  UPDATE public.trabajadores
  SET estado_verificacion = p_estado,
      nota_verificacion = CASE
        WHEN p_nota IS NULL THEN nota_verificacion
        ELSE left(p_nota, 4000)
      END
  WHERE id_usuario = p_id_usuario;
  v_accion := CASE p_estado
    WHEN 'verificado' THEN 'aprobar_verificacion'::public.accion_auditoria_consola
    WHEN 'rechazado' THEN 'rechazar_verificacion'::public.accion_auditoria_consola
    ELSE 'pedir_correccion'::public.accion_auditoria_consola
  END;
  PERFORM public.registrar_auditoria(
    v_accion,
    'trabajadores',
    p_id_usuario::text,
    jsonb_build_object('estado_verificacion', v_antes, 'nota_verificacion', v_nota_antes),
    jsonb_build_object('estado_verificacion', p_estado, 'nota_verificacion', left(COALESCE(p_nota, v_nota_antes), 4000)),
    CASE
      WHEN char_length(btrim(COALESCE(p_nota, ''))) >= 10 THEN btrim(p_nota)
      ELSE 'Cambio de verificación a ' || p_estado
    END,
    NULL, NULL, NULL, NULL
  );
END;
$$;

-- Resumen del período. Las cifras de dinero solo salen para is_admin().
-- No hay fecha_completado: no se cuenta «completados» por actualizado_en.
CREATE OR REPLACE FUNCTION public.consola_resumen_periodo(
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
  v_gmv bigint;
  v_comision bigint;
  v_ticket numeric;
  v_csat numeric;
  v_n_csat bigint;
  v_pendientes bigint;
  v_pagados bigint;
  v_reembolsos bigint;
  v_serie jsonb;
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
  v_admin := public.is_admin();

  IF v_admin THEN
    SELECT
      COALESCE(sum(round(p.monto))::bigint, 0),
      COALESCE(sum(public.comision_servicio_clp(p.monto)) FILTER (WHERE p.tipo_pago = 'principal'), 0)::bigint,
      avg(p.monto) FILTER (WHERE p.monto > 0)
    INTO v_gmv, v_comision, v_ticket
    FROM public.pagos p
    WHERE public.texto_a_timestamptz(p.creado_en) >= p_desde
      AND public.texto_a_timestamptz(p.creado_en) < p_hasta
      AND p.estado IN ('retenido', 'liberado');

    SELECT avg(c.puntaje), count(*)
    INTO v_csat, v_n_csat
    FROM public.calificaciones c
    WHERE public.texto_a_timestamptz(c.creado_en) >= p_desde
      AND public.texto_a_timestamptz(c.creado_en) < p_hasta
      AND c.estado_revision IS DISTINCT FROM 'excluida';

    SELECT COALESCE(sum(round(p.monto))::bigint, 0)
    INTO v_pendientes
    FROM public.pagos p
    WHERE p.estado = 'retenido';

    SELECT COALESCE(sum(l.monto_clp)::bigint, 0)
    INTO v_pagados
    FROM public.liquidaciones l
    WHERE l.creado_en >= p_desde AND l.creado_en < p_hasta;

    SELECT COALESCE(sum(round(p.monto))::bigint, 0)
    INTO v_reembolsos
    FROM public.pagos p
    WHERE p.estado = 'reembolsado'
      AND public.texto_a_timestamptz(p.reembolsado_en) >= p_desde
      AND public.texto_a_timestamptz(p.reembolsado_en) < p_hasta;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'dia', to_char(d::date, 'YYYY-MM-DD'),
      'gmv_clp', COALESCE(s.gmv, 0)
    ) ORDER BY d), '[]'::jsonb)
    INTO v_serie
    FROM generate_series(
      (p_desde AT TIME ZONE 'America/Santiago')::date,
      ((p_hasta - interval '1 second') AT TIME ZONE 'America/Santiago')::date,
      interval '1 day'
    ) AS d
    LEFT JOIN (
      SELECT (public.texto_a_timestamptz(p.creado_en) AT TIME ZONE 'America/Santiago')::date AS dia,
             sum(round(p.monto))::bigint AS gmv
      FROM public.pagos p
      WHERE public.texto_a_timestamptz(p.creado_en) >= p_desde
        AND public.texto_a_timestamptz(p.creado_en) < p_hasta
        AND p.estado IN ('retenido', 'liberado')
      GROUP BY 1
    ) s ON s.dia = d::date;
  END IF;

  RETURN jsonb_build_object(
    'rol', v_rol,
    'zona', 'America/Santiago',
    'desde', p_desde,
    'hasta', p_hasta,
    'financiero', CASE WHEN v_admin THEN jsonb_build_object(
      'gmv_clp', v_gmv,
      'comision_clp', v_comision,
      'ticket_promedio_clp', CASE WHEN v_ticket IS NULL THEN NULL ELSE round(v_ticket)::bigint END,
      'csat', v_csat,
      'n_resenas', v_n_csat,
      'payouts_pendientes_clp', v_pendientes,
      'payouts_pagados_clp', v_pagados,
      'reembolsos_clp', v_reembolsos,
      'serie_diaria', v_serie
    ) ELSE NULL END,
    'colas', jsonb_build_object(
      'disputas_abiertas', (
        SELECT count(*) FROM public.disputas d
        WHERE d.estado IN ('abierta', 'en_revision', 'requiere_humano', 'reembolso_pendiente')
      ),
      'verificaciones_en_revision', CASE WHEN v_admin THEN (
        SELECT count(*) FROM public.trabajadores t WHERE t.estado_verificacion = 'en_revision'
      ) ELSE NULL END,
      'pagos_retenidos', CASE WHEN v_admin THEN (
        SELECT count(*) FROM public.pagos p WHERE p.estado = 'retenido'
      ) ELSE NULL END,
      'reembolsos_pendientes', CASE WHEN v_admin THEN (
        SELECT count(*) FROM public.disputas d WHERE d.estado = 'reembolso_pendiente'
      ) ELSE NULL END,
      'tickets_abiertos', (
        SELECT count(*) FROM public.tickets_soporte t
        WHERE COALESCE(t.estado, 'pendiente') IS DISTINCT FROM 'resuelto'
      ),
      'errores_nuevos', CASE WHEN v_rol IN ('administrador', 'qa') THEN (
        SELECT count(*) FROM public.registros_error_app e WHERE e.estado = 'nuevo'
      ) ELSE NULL END
    )
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_resumen_periodo(timestamptz, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_resumen_periodo(timestamptz, timestamptz) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_listar_equipo()
RETURNS TABLE (
  id uuid,
  nombre text,
  correo text,
  rol text,
  estado_cuenta text,
  creado_en text,
  invitacion_pendiente boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT
    p.id,
    p.nombre,
    p.correo,
    p.rol,
    p.estado_cuenta,
    p.creado_en,
    COALESCE(u.invited_at IS NOT NULL AND u.email_confirmed_at IS NULL, false)
  FROM public.perfiles p
  LEFT JOIN auth.users u ON u.id = p.id
  WHERE p.rol IN ('administrador', 'soporte', 'qa')
  ORDER BY p.nombre;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_listar_equipo() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_equipo() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_cambiar_rol(
  p_id uuid,
  p_rol text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_estado text;
  v_admins integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_rol NOT IN ('administrador', 'soporte', 'qa') THEN
    RAISE EXCEPTION 'Rol no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT rol, estado_cuenta INTO v_antes, v_estado
  FROM public.perfiles WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  IF v_antes = 'administrador' AND p_rol IS DISTINCT FROM 'administrador'
     AND v_estado IN ('activo', 'active') THEN
    SELECT count(*) INTO v_admins
    FROM public.perfiles
    WHERE rol = 'administrador'
      AND estado_cuenta IN ('activo', 'active')
      AND id <> p_id;
    IF v_admins < 1 THEN
      RAISE EXCEPTION 'No se puede quitar el último administrador activo';
    END IF;
  END IF;
  UPDATE public.perfiles SET rol = p_rol WHERE id = p_id;
  PERFORM public.registrar_auditoria(
    'cambiar_rol', 'perfiles', p_id::text,
    jsonb_build_object('rol', v_antes),
    jsonb_build_object('rol', p_rol),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_cambiar_rol(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_cambiar_rol(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_fijar_estado_cuenta(
  p_id uuid,
  p_estado text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_rol text;
  v_admins integer;
  v_accion public.accion_auditoria_consola;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_estado NOT IN ('activo', 'suspendido') THEN
    RAISE EXCEPTION 'Estado no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_id = auth.uid() AND p_estado = 'suspendido' THEN
    RAISE EXCEPTION 'No puedes suspender tu propia sesión desde aquí';
  END IF;
  SELECT estado_cuenta, rol INTO v_antes, v_rol
  FROM public.perfiles WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  IF v_rol = 'administrador' AND p_estado = 'suspendido' AND v_antes IN ('activo', 'active') THEN
    SELECT count(*) INTO v_admins
    FROM public.perfiles
    WHERE rol = 'administrador'
      AND estado_cuenta IN ('activo', 'active')
      AND id <> p_id;
    IF v_admins < 1 THEN
      RAISE EXCEPTION 'No se puede suspender el último administrador activo';
    END IF;
  END IF;
  UPDATE public.perfiles SET estado_cuenta = p_estado WHERE id = p_id;
  v_accion := CASE WHEN p_estado = 'suspendido'
    THEN 'suspender_cuenta'::public.accion_auditoria_consola
    ELSE 'reactivar_cuenta'::public.accion_auditoria_consola
  END;
  PERFORM public.registrar_auditoria(
    v_accion, 'perfiles', p_id::text,
    jsonb_build_object('estado_cuenta', v_antes),
    jsonb_build_object('estado_cuenta', p_estado),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_fijar_estado_cuenta(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_fijar_estado_cuenta(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_cron_salud()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'cron'
AS $$
DECLARE
  v_rol text := public.rol_consola();
  v_jobs jsonb;
BEGIN
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'qa') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF to_regclass('cron.job_run_details') IS NULL OR to_regclass('cron.job') IS NULL THEN
    RETURN jsonb_build_object(
      'disponible', false,
      'jobs', '[]'::jsonb,
      'nota', 'pg_cron no está visible en esta base'
    );
  END IF;
  BEGIN
    SELECT COALESCE(jsonb_agg(row_to_json(x)), '[]'::jsonb) INTO v_jobs
    FROM (
      SELECT
        j.jobname,
        r.status,
        r.start_time,
        r.end_time,
        left(COALESCE(r.return_message, ''), 240) AS return_message
      FROM cron.job j
      LEFT JOIN LATERAL (
        SELECT status, start_time, end_time, return_message
        FROM cron.job_run_details d
        WHERE d.jobid = j.jobid
        ORDER BY d.start_time DESC
        LIMIT 1
      ) r ON true
      WHERE j.jobname IN (
        'mwa_webpay_reconcile',
        'mwa_expirar_pagos_abandonados',
        'mwa_resolver_soporte_automatico'
      )
    ) x;
  EXCEPTION
    WHEN insufficient_privilege OR undefined_table THEN
      RETURN jsonb_build_object(
        'disponible', false,
        'jobs', '[]'::jsonb,
        'nota', 'Sin permiso para leer el historial de pg_cron'
      );
  END;
  RETURN jsonb_build_object('disponible', true, 'jobs', COALESCE(v_jobs, '[]'::jsonb));
END;
$$;
REVOKE ALL ON FUNCTION public.consola_cron_salud() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_cron_salud() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_moderar_resena(
  p_id text,
  p_estado text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_accion public.accion_auditoria_consola;
  v_rol text := public.rol_consola();
BEGIN
  IF p_estado = 'en_revision' THEN
    IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte') THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
    v_accion := 'proponer_resena';
  ELSIF p_estado IN ('excluida', 'vigente') THEN
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
    v_accion := CASE WHEN p_estado = 'excluida'
      THEN 'ocultar_resena'::public.accion_auditoria_consola
      ELSE 'restaurar_resena'::public.accion_auditoria_consola
    END;
  ELSE
    RAISE EXCEPTION 'Estado no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT estado_revision INTO v_antes FROM public.calificaciones WHERE id::text = btrim(p_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reseña no encontrada';
  END IF;
  UPDATE public.calificaciones
  SET estado_revision = p_estado,
      motivo_revision = left(btrim(p_motivo), 500)
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    v_accion, 'calificaciones', btrim(p_id),
    jsonb_build_object('estado_revision', v_antes),
    jsonb_build_object('estado_revision', p_estado),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_moderar_resena(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_moderar_resena(text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_resolver_reporte(
  p_id text,
  p_estado text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
  v_accion public.accion_auditoria_consola;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_estado NOT IN ('revisado', 'resuelto', 'descartado') THEN
    RAISE EXCEPTION 'Estado no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT estado INTO v_antes FROM public.reportes WHERE id::text = btrim(p_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reporte no encontrado';
  END IF;
  UPDATE public.reportes SET estado = p_estado WHERE id::text = btrim(p_id);
  v_accion := CASE WHEN p_estado = 'descartado'
    THEN 'descartar_reporte'::public.accion_auditoria_consola
    ELSE 'sancionar_reporte'::public.accion_auditoria_consola
  END;
  PERFORM public.registrar_auditoria(
    v_accion, 'reportes', btrim(p_id),
    jsonb_build_object('estado', v_antes),
    jsonb_build_object('estado', p_estado),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_resolver_reporte(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_resolver_reporte(text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_marcar_error(p_id text, p_motivo text)
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
  SELECT estado INTO v_antes FROM public.registros_error_app WHERE id::text = btrim(p_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Error no encontrado';
  END IF;
  UPDATE public.registros_error_app SET estado = 'reconocido' WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'marcar_error_revisado', 'registros_error_app', btrim(p_id),
    jsonb_build_object('estado', v_antes),
    jsonb_build_object('estado', 'reconocido'),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_marcar_error(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_marcar_error(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_editar_config(
  p_clave text,
  p_valor text,
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
  IF p_clave IN ('admin_requiere_aal2', 'demo_modo') THEN
    RAISE EXCEPTION 'Esa clave es de solo lectura';
  END IF;
  IF p_clave NOT IN (
    'soporte_plazo_disputa_horas',
    'soporte_plazo_silencio_horas',
    'soporte_monto_max_auto',
    'soporte_reincidencia_max'
  ) THEN
    RAISE EXCEPTION 'Clave no editable desde la consola';
  END IF;
  IF p_valor IS NULL OR btrim(p_valor) = '' OR btrim(p_valor) !~ '^[0-9]+$' THEN
    RAISE EXCEPTION 'El valor debe ser un entero';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT valor INTO v_antes FROM public.app_config WHERE clave = p_clave FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Clave no encontrada';
  END IF;
  UPDATE public.app_config
  SET valor = btrim(p_valor), actualizado_en = now()
  WHERE clave = p_clave;
  PERFORM public.registrar_auditoria(
    'editar_ajuste', 'app_config', p_clave,
    jsonb_build_object('valor', v_antes),
    jsonb_build_object('valor', btrim(p_valor)),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_editar_config(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_editar_config(text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_editar_bandera(
  p_id text,
  p_habilitada integer,
  p_motivo text
) RETURNS void
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
  IF p_habilitada NOT IN (0, 1) THEN
    RAISE EXCEPTION 'Valor no permitido';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT habilitada INTO v_antes FROM public.banderas_funcionalidad WHERE id::text = btrim(p_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bandera no encontrada';
  END IF;
  UPDATE public.banderas_funcionalidad
  SET habilitada = p_habilitada, actualizado_en = now()::text
  WHERE id::text = btrim(p_id);
  PERFORM public.registrar_auditoria(
    'editar_bandera', 'banderas_funcionalidad', btrim(p_id),
    jsonb_build_object('habilitada', v_antes),
    jsonb_build_object('habilitada', p_habilitada),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_editar_bandera(text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_editar_bandera(text, integer, text) TO authenticated;

-- Búsqueda real para la paleta. Soporte y QA no reciben correos.
CREATE OR REPLACE FUNCTION public.consola_buscar(p_q text)
RETURNS TABLE (tipo text, id text, titulo text, detalle text, ruta text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_rol text := public.rol_consola();
  v_q text := left(btrim(COALESCE(p_q, '')), 80);
  v_admin boolean;
BEGIN
  IF v_rol IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(v_q) < 2 THEN
    RETURN;
  END IF;
  v_admin := public.is_admin();
  RETURN QUERY
  SELECT * FROM (
    SELECT
      'persona'::text,
      p.id::text,
      p.nombre,
      CASE
        WHEN v_admin THEN COALESCE(p.correo, p.rol)
        ELSE p.rol
      END,
      CASE
        WHEN p.rol = 'trabajador' THEN '/profesionales/' || p.id::text
        WHEN p.rol IN ('administrador', 'soporte', 'qa') AND v_admin THEN '/equipo'
        ELSE '/usuarios/' || p.id::text
      END
    FROM public.perfiles p
    WHERE p.nombre ILIKE '%' || v_q || '%'
       OR (v_admin AND p.correo ILIKE '%' || v_q || '%')
       OR p.id::text ILIKE v_q || '%'
    LIMIT 8
  ) personas
  UNION ALL
  SELECT * FROM (
    SELECT
      'pedido'::text,
      t.id::text,
      left(COALESCE(NULLIF(t.descripcion, ''), t.direccion, t.id::text), 80),
      t.estado,
      '/pedidos/' || t.id::text
    FROM public.trabajos t
    WHERE t.id::text ILIKE '%' || v_q || '%'
       OR t.descripcion ILIKE '%' || v_q || '%'
       OR t.direccion ILIKE '%' || v_q || '%'
    LIMIT 8
  ) pedidos
  UNION ALL
  SELECT * FROM (
    SELECT
      'pago'::text,
      pg.id::text,
      pg.estado,
      CASE WHEN v_admin THEN pg.id::text ELSE left(pg.id::text, 8) END,
      '/pagos/' || pg.id::text
    FROM public.pagos pg
    WHERE v_admin
      AND (pg.id::text ILIKE '%' || v_q || '%' OR COALESCE(pg.id_transaccion, '') ILIKE '%' || v_q || '%')
    LIMIT 8
  ) pagos
  UNION ALL
  SELECT * FROM (
    SELECT
      'disputa'::text,
      d.id::text,
      d.motivo,
      d.estado,
      '/disputas/' || d.id::text
    FROM public.disputas d
    WHERE d.id::text ILIKE '%' || v_q || '%'
       OR d.motivo ILIKE '%' || v_q || '%'
    LIMIT 8
  ) disputas;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_buscar(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_buscar(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_registrar_vista_sensible(
  p_entidad text,
  p_id text,
  p_motivo text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  PERFORM public.registrar_auditoria(
    'consultar_rut',
    left(btrim(p_entidad), 80),
    btrim(p_id),
    NULL,
    jsonb_build_object('visible', true),
    btrim(p_motivo),
    NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_registrar_vista_sensible(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_registrar_vista_sensible(text, text, text) TO authenticated;

-- Disputas ya cerradas. La política de la tabla solo deja leer al admin;
-- soporte y QA entran por aquí, igual que en la cola abierta.
CREATE OR REPLACE FUNCTION public.consola_disputas_resueltas()
RETURNS TABLE (
  id text,
  id_trabajo text,
  motivo text,
  descripcion text,
  estado text,
  resolucion text,
  resuelta_en text,
  creado_en text,
  nombre_cliente text,
  nombre_profesional text,
  monto_retenido numeric
)
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
  SELECT
    d.id::text,
    d.id_trabajo::text,
    d.motivo,
    d.descripcion,
    d.estado,
    d.resolucion,
    d.resuelta_en,
    d.creado_en::text,
    COALESCE(pc.nombre, 'Cliente'),
    COALESCE(pp.nombre, 'Profesional'),
    COALESCE((
      SELECT max(pg.monto)
      FROM public.pagos pg
      WHERE pg.id_trabajo = d.id_trabajo
        AND pg.estado IN ('liberado', 'reembolsado', 'retenido', 'autorizado')
    ), 0)
  FROM public.disputas d
  JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
  LEFT JOIN public.perfiles pc ON pc.id = t.id_usuario
  LEFT JOIN public.perfiles pp ON pp.id = t.id_trabajador
  WHERE d.estado = 'resuelta'
  ORDER BY d.resuelta_en DESC NULLS LAST
  LIMIT 200;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_disputas_resueltas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_disputas_resueltas() TO authenticated;

-- Revocar una invitación que todavía no aceptó. No existe otro RPC para esto.
CREATE OR REPLACE FUNCTION public.consola_revocar_invitacion(p_id uuid, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_rol text;
  v_estado text;
  v_invited timestamptz;
  v_confirmed timestamptz;
  v_admins integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(COALESCE(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  IF p_id = auth.uid() THEN
    RAISE EXCEPTION 'No puedes revocar tu propia cuenta desde aquí';
  END IF;
  SELECT p.rol, p.estado_cuenta INTO v_rol, v_estado
  FROM public.perfiles p WHERE p.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Persona no encontrada';
  END IF;
  IF v_rol NOT IN ('administrador', 'soporte', 'qa') THEN
    RAISE EXCEPTION 'No es una cuenta de la consola';
  END IF;
  SELECT u.invited_at, u.email_confirmed_at INTO v_invited, v_confirmed
  FROM auth.users u WHERE u.id = p_id;
  IF v_invited IS NULL OR v_confirmed IS NOT NULL THEN
    RAISE EXCEPTION 'La invitación ya fue aceptada';
  END IF;
  IF v_rol = 'administrador' AND v_estado IN ('activo', 'active') THEN
    SELECT count(*) INTO v_admins
    FROM public.perfiles
    WHERE rol = 'administrador'
      AND estado_cuenta IN ('activo', 'active')
      AND id <> p_id;
    IF v_admins < 1 THEN
      RAISE EXCEPTION 'No se puede quitar el último administrador activo';
    END IF;
  END IF;
  PERFORM public.registrar_auditoria(
    'revocar_invitacion', 'perfiles', p_id::text,
    jsonb_build_object('rol', v_rol, 'invitacion_pendiente', true),
    jsonb_build_object('revocada', true),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
  IF to_regclass('auth.sessions') IS NOT NULL THEN
    DELETE FROM auth.sessions WHERE user_id = p_id;
  END IF;
  IF to_regclass('auth.refresh_tokens') IS NOT NULL THEN
    EXECUTE 'DELETE FROM auth.refresh_tokens WHERE user_id::text = $1' USING p_id::text;
  END IF;
  DELETE FROM auth.users WHERE id = p_id;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_revocar_invitacion(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_revocar_invitacion(uuid, text) TO authenticated;

-- Cierra las sesiones de Auth de otra persona. No borra la cuenta.
CREATE OR REPLACE FUNCTION public.consola_cerrar_sesiones(p_id uuid, p_motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_rol text;
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
  SELECT p.rol INTO v_rol FROM public.perfiles p WHERE p.id = p_id;
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte', 'qa') THEN
    RAISE EXCEPTION 'No es una cuenta de la consola';
  END IF;
  IF to_regclass('auth.sessions') IS NULL AND to_regclass('auth.refresh_tokens') IS NULL THEN
    RAISE EXCEPTION 'No se puede cerrar la sesión desde la base';
  END IF;
  IF to_regclass('auth.sessions') IS NOT NULL THEN
    DELETE FROM auth.sessions WHERE user_id = p_id;
  END IF;
  IF to_regclass('auth.refresh_tokens') IS NOT NULL THEN
    EXECUTE 'DELETE FROM auth.refresh_tokens WHERE user_id::text = $1' USING p_id::text;
  END IF;
  PERFORM public.registrar_auditoria(
    'cerrar_sesion', 'perfiles', p_id::text,
    NULL,
    jsonb_build_object('sesiones', 'cerradas'),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;
REVOKE ALL ON FUNCTION public.consola_cerrar_sesiones(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_cerrar_sesiones(uuid, text) TO authenticated;

COMMIT;
