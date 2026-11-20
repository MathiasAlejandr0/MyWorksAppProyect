-- Oculta las cuentas demo del catálogo público y bloquea reservarlas o
-- cobrarles cuando app_config.demo_modo no es '1'.
-- Dominios demo: @demo.myworksapp.cl y @demo.com.
-- Con demo_modo = '1' el catálogo las sigue mostrando (la web pone el aviso
-- «Datos de demostración»). No cambia comisiones ni funciones de pago.
-- No está aplicada: Mathias la revisa y la corre cuando lo decida.

BEGIN;

CREATE OR REPLACE FUNCTION public.correo_es_demo(p_correo text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(split_part(coalesce(p_correo, ''), '@', 2))
    IN ('demo.myworksapp.cl', 'demo.com');
$$;

COMMENT ON FUNCTION public.correo_es_demo(text) IS
  'true si el dominio del correo es demo.myworksapp.cl o demo.com.';

CREATE OR REPLACE FUNCTION public.demo_modo_activo()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT coalesce((SELECT c.valor FROM public.app_config c WHERE c.clave = 'demo_modo'), '0') = '1';
$$;

REVOKE ALL ON FUNCTION public.demo_modo_activo() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.demo_modo_activo() TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.demo_modo_activo() IS
  'true solo cuando app_config.demo_modo vale 1. No expone el resto de la configuración.';

CREATE OR REPLACE FUNCTION public.catalogo_muestra_profesional(p_es_demo boolean)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT NOT coalesce(p_es_demo, false) OR public.demo_modo_activo();
$$;

REVOKE ALL ON FUNCTION public.catalogo_muestra_profesional(boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.catalogo_muestra_profesional(boolean) TO anon, authenticated, service_role;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS es_demo boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.trabajadores.es_demo IS
  'true si el correo del perfil es de un dominio demo. El titular no puede cambiarla.';

CREATE OR REPLACE FUNCTION public.profesional_bloqueado_por_demo(p_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trabajadores t
    WHERE t.id_usuario = p_id
      AND coalesce(t.es_demo, false)
      AND NOT public.demo_modo_activo()
  );
$$;

REVOKE ALL ON FUNCTION public.profesional_bloqueado_por_demo(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.profesional_bloqueado_por_demo(uuid) TO anon, authenticated, service_role;

UPDATE public.trabajadores t
SET es_demo = public.correo_es_demo(p.correo)
FROM public.perfiles p
WHERE p.id = t.id_usuario;

-- La columna nueva no entra en el GRANT UPDATE por columna ya existente.
-- El trigger impide que un UPDATE posterior la borre o la invente.
CREATE OR REPLACE FUNCTION public.trabajadores_fijar_es_demo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF coalesce(current_setting('mwa.marcar_demo', true), '') = '1' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.es_demo := public.correo_es_demo(
      (SELECT p.correo FROM public.perfiles p WHERE p.id = NEW.id_usuario)
    );
    RETURN NEW;
  END IF;
  NEW.es_demo := OLD.es_demo;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_fijar_es_demo ON public.trabajadores;
CREATE TRIGGER trabajadores_fijar_es_demo
  BEFORE INSERT OR UPDATE ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajadores_fijar_es_demo();

CREATE OR REPLACE FUNCTION public.perfiles_sincronizar_demo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.correo IS NOT DISTINCT FROM OLD.correo THEN
    RETURN NEW;
  END IF;
  PERFORM set_config('mwa.marcar_demo', '1', true);
  UPDATE public.trabajadores
  SET es_demo = public.correo_es_demo(NEW.correo)
  WHERE id_usuario = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS perfiles_sincronizar_demo ON public.perfiles;
CREATE TRIGGER perfiles_sincronizar_demo
  AFTER INSERT OR UPDATE OF correo ON public.perfiles
  FOR EACH ROW
  EXECUTE FUNCTION public.perfiles_sincronizar_demo();

-- Catálogo público: misma firma y el mismo orden que
-- 20261117215659. Solo se agrega el filtro de demo.
CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL,
  p_zona text DEFAULT NULL,
  p_cursor_calificacion numeric DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit integer DEFAULT 20,
  p_latitud double precision DEFAULT NULL,
  p_longitud double precision DEFAULT NULL,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  id_usuario uuid,
  profesion text,
  descripcion text,
  calificacion numeric,
  tarifa_visita numeric,
  categoria_servicio text,
  zona_trabajo text,
  nombre text,
  ruta_foto_perfil text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric,
  origen_base text,
  trabajos_completados integer,
  score_listado numeric,
  prioridad_manual integer,
  radio_urbano_km numeric,
  tarifa_fuera_radio_clp integer,
  es_elite boolean,
  distancia_km double precision
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT
    t.id_usuario,
    t.profesion,
    t.descripcion,
    s.calificacion,
    t.tarifa_visita,
    c.categoria,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.latitud_base
      ELSE g.lat_pub
    END AS latitud_base,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.longitud_base
      ELSE g.lng_pub
    END AS longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    s.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    s.es_elite,
    d.km AS distancia_km
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  JOIN LATERAL public.stats_profesional(t.id_usuario) AS s ON true
  CROSS JOIN LATERAL (
    SELECT public.catalogo_muestra_profesional(t.es_demo) AS visible
  ) vis
  LEFT JOIN LATERAL (
    SELECT min(ts.categoria_servicio) AS categoria
    FROM public.trabajador_servicios ts
    WHERE ts.id_trabajador = t.id_usuario
      AND (p_categoria IS NULL OR btrim(p_categoria) = '' OR ts.categoria_servicio = p_categoria)
  ) c ON true
  CROSS JOIN LATERAL (
    SELECT
      round(t.latitud_base::numeric, 2)::double precision AS lat_pub,
      round(t.longitud_base::numeric, 2)::double precision AS lng_pub
  ) g
  CROSS JOIN LATERAL (
    SELECT CASE
      WHEN p_latitud IS NULL OR p_longitud IS NULL
        OR g.lat_pub IS NULL OR g.lng_pub IS NULL
        THEN NULL::double precision
      ELSE 6371 * 2 * atan2(
        sqrt(h.a), sqrt(1 - h.a)
      )
    END AS km
    FROM (
      SELECT
        power(sin(radians(g.lat_pub - p_latitud) / 2), 2)
        + cos(radians(p_latitud)) * cos(radians(g.lat_pub))
          * power(sin(radians(g.lng_pub - p_longitud) / 2), 2) AS a
    ) h
  ) d
  WHERE vis.visible
    AND COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (s.n_calificaciones = 0 OR COALESCE(s.calificacion, 0) >= 3)
    AND (
      p_categoria IS NULL
      OR btrim(p_categoria) = ''
      OR c.categoria IS NOT NULL
    )
    AND (
      p_zona IS NULL
      OR btrim(p_zona) = ''
      OR t.zona_trabajo ILIKE
        ('%' || replace(replace(btrim(p_zona), '%', ''), '_', '') || '%')
    )
  ORDER BY
    floor(d.km) ASC NULLS LAST,
    CASE WHEN COALESCE(s.n_calificaciones, 0) > 0 THEN COALESCE(s.calificacion, 0) ELSE 0 END DESC,
    NULLIF(t.tarifa_visita, 0) ASC NULLS LAST,
    t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$;

COMMENT ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) IS
  'Catálogo público. Con demo_modo distinto de 1 omite es_demo. Orden único: banda de 1 km, nota, tarifa (0 o NULL al final), id. p_cursor_* se ignoran; paginar con p_offset.';

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer, double precision, double precision, integer) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.categorias_con_disponibles()
RETURNS SETOF text
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT DISTINCT s.categoria_servicio
  FROM public.trabajadores t
  JOIN public.trabajador_servicios s ON s.id_trabajador = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND public.catalogo_muestra_profesional(t.es_demo);
$function$;

CREATE OR REPLACE FUNCTION public.base_publica_profesional(p_id uuid)
RETURNS TABLE (
  latitud_base double precision,
  longitud_base double precision
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    round(t.latitud_base::numeric, 2)::double precision,
    round(t.longitud_base::numeric, 2)::double precision
  FROM public.trabajadores t
  WHERE t.id_usuario = p_id
    AND COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND public.catalogo_muestra_profesional(t.es_demo);
$$;

REVOKE ALL ON FUNCTION public.base_publica_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.base_publica_profesional(uuid) TO anon, authenticated, service_role;

-- Un SELECT directo a trabajadores no debe listar demos con demo_modo = 0.
-- El dueño y un administrador siguen viendo su fila. service_role no pasa por RLS.
DROP POLICY IF EXISTS trabajadores_ocultar_demo ON public.trabajadores;
CREATE POLICY trabajadores_ocultar_demo
  ON public.trabajadores
  AS RESTRICTIVE
  FOR SELECT
  TO anon, authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
    OR public.catalogo_muestra_profesional(es_demo)
  );

CREATE OR REPLACE FUNCTION public.trabajos_bloquear_demo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.id_trabajador IS NOT NULL
     AND public.profesional_bloqueado_por_demo(NEW.id_trabajador)
     AND (TG_OP = 'INSERT' OR NEW.id_trabajador IS DISTINCT FROM OLD.id_trabajador)
  THEN
    RAISE EXCEPTION 'Este profesional no está disponible para reservar'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajos_bloquear_demo ON public.trabajos;
CREATE TRIGGER trabajos_bloquear_demo
  BEFORE INSERT OR UPDATE OF id_trabajador ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_bloquear_demo();

CREATE OR REPLACE FUNCTION public.pagos_bloquear_demo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_worker uuid;
BEGIN
  SELECT j.id_trabajador INTO v_worker
  FROM public.trabajos j
  WHERE j.id = NEW.id_trabajo;
  IF v_worker IS NOT NULL AND public.profesional_bloqueado_por_demo(v_worker) THEN
    RAISE EXCEPTION 'No se puede cobrar a este profesional'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pagos_bloquear_demo ON public.pagos;
CREATE TRIGGER pagos_bloquear_demo
  BEFORE INSERT ON public.pagos
  FOR EACH ROW
  EXECUTE FUNCTION public.pagos_bloquear_demo();

COMMIT;
