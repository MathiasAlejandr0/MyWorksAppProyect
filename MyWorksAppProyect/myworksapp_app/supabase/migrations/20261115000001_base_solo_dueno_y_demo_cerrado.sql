-- La base del profesional deja de salir exacta para cualquier sesión.
-- Solo el dueño la lee, por mi_ficha_propia. El catálogo redondea a ~1 km
-- para el resto, incluido un cliente autenticado. El cobro sigue leyendo
-- la tabla con service_role.
--
-- listar_cuentas_demo_acceso deja de ser ejecutable por anon y authenticated.
-- El login de la app usa la lista local de demo_credentials.dart.
-- Idempotente.

BEGIN;

CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(p_categoria text DEFAULT NULL::text, p_zona text DEFAULT NULL::text, p_cursor_calificacion numeric DEFAULT NULL::numeric, p_cursor_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 20)
 RETURNS TABLE(id_usuario uuid, profesion text, descripcion text, calificacion numeric, tarifa_visita numeric, categoria_servicio text, zona_trabajo text, nombre text, ruta_foto_perfil text, latitud_base double precision, longitud_base double precision, radio_servicio_km numeric, origen_base text, trabajos_completados integer, score_listado numeric, prioridad_manual integer, radio_urbano_km numeric, tarifa_fuera_radio_clp integer, es_elite boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    t.id_usuario,
    t.profesion,
    t.descripcion,
    t.calificacion,
    t.tarifa_visita,
    t.categoria_servicio,
    t.zona_trabajo,
    p.nombre,
    p.ruta_foto_perfil,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.latitud_base
      ELSE round(t.latitud_base::numeric, 2)::double precision
    END AS latitud_base,
    CASE
      WHEN auth.uid() IS NOT NULL AND auth.uid() = t.id_usuario
        THEN t.longitud_base
      ELSE round(t.longitud_base::numeric, 2)::double precision
    END AS longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    t.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    t.es_elite
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND (COALESCE(t.calificacion, 0) = 0 OR t.calificacion >= 3)
    AND (
      p_categoria IS NULL
      OR btrim(p_categoria) = ''
      OR t.categoria_servicio = p_categoria
    )
    AND (
      p_zona IS NULL
      OR btrim(p_zona) = ''
      OR t.zona_trabajo ILIKE
        ('%' || replace(replace(btrim(p_zona), '%', ''), '_', '') || '%')
    )
    AND (
      p_cursor_id IS NULL
      OR COALESCE(t.score_listado, 0) < COALESCE(p_cursor_calificacion, 0)
      OR (
        COALESCE(t.score_listado, 0) = COALESCE(p_cursor_calificacion, 0)
        AND t.id_usuario > p_cursor_id
      )
    )
  ORDER BY COALESCE(t.score_listado, 0) DESC, t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40);
$function$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated, service_role;

REVOKE SELECT ON TABLE public.trabajadores FROM anon, authenticated;
GRANT SELECT (
  id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita,
  categoria_servicio, niveles_precio, conteo_rechazos, servicios_personalizados,
  precios_configurados, zona_trabajo, estado_verificacion, radio_servicio_km,
  origen_base, score_listado, ranking_actualizado_en, radio_urbano_km,
  tarifa_fuera_radio_clp, trabajos_completados, es_elite
) ON public.trabajadores TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.mi_ficha_propia()
RETURNS TABLE (
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric,
  origen_base text,
  estado_verificacion text,
  nota_verificacion text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    t.latitud_base,
    t.longitud_base,
    t.radio_servicio_km,
    t.origen_base,
    t.estado_verificacion,
    t.nota_verificacion
  FROM public.trabajadores t
  WHERE t.id_usuario = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.mi_ficha_propia() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mi_ficha_propia() TO authenticated;

REVOKE ALL ON FUNCTION public.listar_cuentas_demo_acceso() FROM PUBLIC, anon, authenticated;

-- El detalle y la cotización leen la base ya redondeada. El dueño sigue
-- usando mi_ficha_propia. El admin lee nota y coordenada exacta por
-- fichas_sensibles_admin, no por un SELECT abierto.
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
    AND t.estado_verificacion = 'verificado';
$$;

REVOKE ALL ON FUNCTION public.base_publica_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.base_publica_profesional(uuid) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.fichas_sensibles_admin()
RETURNS TABLE (
  id_usuario uuid,
  latitud_base double precision,
  longitud_base double precision,
  nota_verificacion text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT t.id_usuario, t.latitud_base, t.longitud_base, t.nota_verificacion
  FROM public.trabajadores t
  WHERE public.is_admin();
$$;

REVOKE ALL ON FUNCTION public.fichas_sensibles_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fichas_sensibles_admin() TO authenticated;

COMMIT;
