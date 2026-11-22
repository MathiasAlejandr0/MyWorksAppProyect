-- Fase 4: reglas de fraude que abren incidentes. No bloquean cuentas ni pagos.
-- Se integran con incidentes_seguridad y umbrales_seguridad.
-- Isolation Forest solo escribe si la bandera está activa.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

BEGIN;

INSERT INTO public.umbrales_seguridad (clave, valor, ventana_minutos, descripcion)
VALUES
  ('rafaga_resenas', 5, 60, 'Reseñas del mismo usuario en la ventana'),
  ('cuentas_misma_huella', 4, 1440, 'Cuentas distintas con el mismo dispositivo'),
  ('disputas_serie', 3, 1440, 'Disputas abiertas por la misma persona'),
  ('banco_antes_retiro', 1, 1440, 'Horas tras cambiar la cuenta y pedir un retiro')
ON CONFLICT (clave) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.ia_banderas (
  clave text PRIMARY KEY,
  activa boolean NOT NULL DEFAULT false,
  nota text NOT NULL
);

ALTER TABLE public.ia_banderas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_banderas FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.ia_banderas TO authenticated;

DROP POLICY IF EXISTS ia_banderas_select_admin ON public.ia_banderas;
CREATE POLICY ia_banderas_select_admin
  ON public.ia_banderas
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_admin()));

INSERT INTO public.ia_banderas (clave, activa, nota)
VALUES (
  'anomalias_isolation_forest',
  false,
  'Con pocos eventos el job no escribe alertas. Las reglas SQL siguen activas.'
)
ON CONFLICT (clave) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.ia_huellas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.perfiles (id) ON DELETE CASCADE,
  device_hash text NOT NULL CHECK (char_length(device_hash) BETWEEN 16 AND 128),
  ip_hash text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ia_huellas_device_idx
  ON public.ia_huellas (device_hash, created_at DESC);

ALTER TABLE public.ia_huellas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_huellas FROM PUBLIC, anon, authenticated;
GRANT INSERT ON public.ia_huellas TO authenticated;
GRANT SELECT ON public.ia_huellas TO service_role;

DROP POLICY IF EXISTS ia_huellas_insert_propio ON public.ia_huellas;
CREATE POLICY ia_huellas_insert_propio
  ON public.ia_huellas
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.ia_cambios_banco (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.perfiles (id) ON DELETE CASCADE,
  creado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ia_cambios_banco ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ia_cambios_banco FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.ia_registrar_huella(p_device_hash text, p_ip_hash text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
DECLARE
  v_device text := left(btrim(coalesce(p_device_hash, '')), 128);
BEGIN
  IF auth.uid() IS NULL OR v_device !~ '^[a-f0-9]{16,128}$' THEN
    RETURN;
  END IF;
  INSERT INTO public.ia_huellas (user_id, device_hash, ip_hash)
  VALUES (
    auth.uid(),
    v_device,
    NULLIF(left(btrim(coalesce(p_ip_hash, '')), 128), '')
  );
EXCEPTION
  WHEN others THEN
    RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.ia_registrar_huella(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ia_registrar_huella(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.cuentas_bancarias_marcar_cambio()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.numero_cuenta IS NOT DISTINCT FROM OLD.numero_cuenta THEN
    RETURN NEW;
  END IF;
  INSERT INTO public.ia_cambios_banco (user_id) VALUES (NEW.id_usuario);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS cuentas_bancarias_marcar_cambio ON public.cuentas_bancarias;
CREATE TRIGGER cuentas_bancarias_marcar_cambio
  AFTER INSERT OR UPDATE OF numero_cuenta ON public.cuentas_bancarias
  FOR EACH ROW
  EXECUTE FUNCTION public.cuentas_bancarias_marcar_cambio();

CREATE OR REPLACE FUNCTION privado.insertar_incidente_ia(
  p_tipo text,
  p_severidad text,
  p_resumen text,
  p_detalle jsonb,
  p_usuario uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF p_severidad NOT IN ('baja', 'media', 'alta') THEN
    RETURN;
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
  INSERT INTO public.incidentes_seguridad (tipo, severidad, resumen, detalle, id_usuario)
  VALUES (
    left(btrim(p_tipo), 80),
    p_severidad,
    left(btrim(p_resumen), 300),
    COALESCE(p_detalle, '{}'::jsonb),
    p_usuario
  );
END;
$$;

REVOKE ALL ON FUNCTION privado.insertar_incidente_ia(text, text, text, jsonb, uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.evaluar_alertas_ia()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_n integer := 0;
  v_umbral integer;
  v_ventana integer;
  v_fila record;
BEGIN
  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'rafaga_resenas';
  FOR v_fila IN
    SELECT c.id_usuario, count(*) AS n
    FROM public.calificaciones c
    WHERE privado.texto_a_timestamptz(c.creado_en) > now() - make_interval(mins => COALESCE(v_ventana, 60))
      AND c.id_usuario IS NOT NULL
    GROUP BY c.id_usuario
    HAVING count(*) >= COALESCE(v_umbral, 5)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_rafaga_resenas', 'media',
      format('%s reseñas en la ventana', v_fila.n),
      jsonb_build_object('usuario', v_fila.id_usuario, 'cantidad', v_fila.n, 'propuesta', true),
      v_fila.id_usuario
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'cuentas_misma_huella';
  FOR v_fila IN
    SELECT h.device_hash, count(DISTINCT h.user_id) AS n
    FROM public.ia_huellas h
    WHERE h.created_at > now() - make_interval(mins => COALESCE(v_ventana, 1440))
    GROUP BY h.device_hash
    HAVING count(DISTINCT h.user_id) >= COALESCE(v_umbral, 4)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_misma_huella', 'alta',
      format('%s cuentas con el mismo dispositivo', v_fila.n),
      jsonb_build_object('device_hash', left(v_fila.device_hash, 12), 'cantidad', v_fila.n, 'propuesta', true),
      NULL
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'logins_fallidos';
  FOR v_fila IN
    SELECT e.correo_enmascarado, count(*) AS n
    FROM public.eventos_acceso e
    WHERE e.tipo = 'login_fallido'
      AND e.creado_en > now() - make_interval(mins => COALESCE(v_ventana, 15))
    GROUP BY e.correo_enmascarado
    HAVING count(*) >= COALESCE(v_umbral, 5)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_login_fallido', 'alta',
      format('%s accesos fallidos del mismo correo', v_fila.n),
      jsonb_build_object('correo', v_fila.correo_enmascarado, 'cantidad', v_fila.n, 'propuesta', true),
      NULL
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'disputas_serie';
  FOR v_fila IN
    SELECT d.abierta_por, count(*) AS n
    FROM public.disputas d
    WHERE privado.texto_a_timestamptz(d.creado_en) > now() - make_interval(mins => COALESCE(v_ventana, 1440))
    GROUP BY d.abierta_por
    HAVING count(*) >= COALESCE(v_umbral, 3)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_disputas_serie', 'media',
      format('%s disputas de la misma persona', v_fila.n),
      jsonb_build_object('usuario', v_fila.abierta_por, 'cantidad', v_fila.n, 'propuesta', true),
      v_fila.abierta_por
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'banco_antes_retiro';
  FOR v_fila IN
    SELECT b.user_id
    FROM public.ia_cambios_banco b
    JOIN public.liquidaciones l ON l.id_trabajador = b.user_id::text
    WHERE b.creado_en > now() - interval '7 days'
      AND privado.texto_a_timestamptz(l.creado_en) > b.creado_en
      AND privado.texto_a_timestamptz(l.creado_en) < b.creado_en + make_interval(mins => COALESCE(v_ventana, 1440))
      AND l.estado_transferencia IN ('pendiente', 'transferido')
    LIMIT 1
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_banco_retiro', 'alta',
      'Cambió la cuenta bancaria y hubo un retiro en la ventana',
      jsonb_build_object('usuario', v_fila.user_id, 'propuesta', true, 'bloquea', false),
      v_fila.user_id
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.evaluar_alertas_ia() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.evaluar_alertas_ia() TO service_role;

CREATE OR REPLACE FUNCTION public.registrar_alerta_anomalia(
  p_usuario uuid,
  p_score numeric,
  p_detalle jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_activa boolean := false;
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  SELECT activa INTO v_activa
  FROM public.ia_banderas
  WHERE clave = 'anomalias_isolation_forest';
  IF COALESCE(v_activa, false) IS NOT TRUE THEN
    RETURN;
  END IF;
  IF p_score IS NULL OR p_score < 0.65 OR p_score > 1 THEN
    RETURN;
  END IF;
  PERFORM privado.insertar_incidente_ia(
    'ia_anomalia', 'media',
    format('Puntaje de anomalía %s', round(p_score, 2)),
    COALESCE(p_detalle, '{}'::jsonb) || jsonb_build_object('score', round(p_score, 3), 'propuesta', true),
    p_usuario
  );
END;
$$;

REVOKE ALL ON FUNCTION public.registrar_alerta_anomalia(uuid, numeric, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_alerta_anomalia(uuid, numeric, jsonb) TO service_role;

CREATE OR REPLACE FUNCTION public.consola_alertas_ia()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  PERFORM public.evaluar_alertas_ia();
  RETURN jsonb_build_object(
    'bandera', COALESCE((
      SELECT activa FROM public.ia_banderas WHERE clave = 'anomalias_isolation_forest'
    ), false),
    'alertas', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', i.id,
        'cuando', i.creado_en,
        'tipo', i.tipo,
        'severidad', i.severidad,
        'resumen', i.resumen,
        'detalle', i.detalle,
        'estado', i.estado,
        'usuario', i.id_usuario
      ) ORDER BY i.creado_en DESC)
      FROM (
        SELECT *
        FROM public.incidentes_seguridad
        WHERE tipo LIKE 'ia_%'
        ORDER BY creado_en DESC
        LIMIT 40
      ) i
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_alertas_ia() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_alertas_ia() TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_fijar_bandera_ia(
  p_clave text,
  p_activa boolean,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes boolean;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF char_length(btrim(coalesce(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT activa INTO v_antes
  FROM public.ia_banderas
  WHERE clave = btrim(p_clave)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bandera no encontrada';
  END IF;
  UPDATE public.ia_banderas
  SET activa = COALESCE(p_activa, false)
  WHERE clave = btrim(p_clave);
  PERFORM public.registrar_auditoria(
    'editar_bandera', 'ia_banderas', btrim(p_clave),
    jsonb_build_object('activa', v_antes),
    jsonb_build_object('activa', COALESCE(p_activa, false)),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_fijar_bandera_ia(text, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_fijar_bandera_ia(text, boolean, text) TO authenticated;

DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ia_evaluar_alertas') THEN
      PERFORM cron.unschedule('ia_evaluar_alertas');
    END IF;
    PERFORM cron.schedule(
      'ia_evaluar_alertas',
      '*/15 * * * *',
      'SELECT public.evaluar_alertas_ia();'
    );
  ELSE
    RAISE NOTICE 'Sin pg_cron. Programa SELECT public.evaluar_alertas_ia(); cada 15 minutos.';
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'No se programaron las alertas de IA: %', SQLERRM;
END;
$cron$;

COMMIT;
