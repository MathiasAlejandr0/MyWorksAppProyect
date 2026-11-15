-- La base del profesional (latitud_base/longitud_base) suele ser su casa.
-- Hasta ahora listar_profesionales_catalogo la devolvía exacta a anon
-- (cualquiera sin cuenta podía sacar la ubicación de todos los
-- profesionales verificados).
--
-- 1. Misma firma y mismas filas; sin sesión (auth.uid() IS NULL) las
--    coordenadas salen redondeadas a 2 decimales (~1 km). Alcanza para el
--    mapa y la distancia aproximada del catálogo público. El cobro real lo
--    calculan las Edge Functions con service_role sobre la tabla.
-- 2. Defensa en profundidad: anon tenía SELECT de tabla completa sobre
--    trabajadores (hoy sin política RLS para anon, o sea 0 filas). Se
--    cambia por SELECT por columna, sin base, nota de verificación ni
--    desglose del ranking.
--
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
    -- anon: ~1 km (2 decimales). Con sesión: la base exacta.
    CASE WHEN auth.uid() IS NULL
      THEN round(t.latitud_base::numeric, 2)::double precision
      ELSE t.latitud_base END AS latitud_base,
    CASE WHEN auth.uid() IS NULL
      THEN round(t.longitud_base::numeric, 2)::double precision
      ELSE t.longitud_base END AS longitud_base,
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

REVOKE SELECT ON public.trabajadores FROM anon;
GRANT SELECT (
  id_usuario, profesion, descripcion, calificacion, disponible, tarifa_visita,
  categoria_servicio, niveles_precio, conteo_rechazos, servicios_personalizados,
  precios_configurados, zona_trabajo, estado_verificacion, radio_servicio_km,
  origen_base, score_listado, ranking_actualizado_en, radio_urbano_km,
  tarifa_fuera_radio_clp, trabajos_completados, es_elite
) ON public.trabajadores TO anon;

COMMIT;
