-- La oferta del profesional (precios, servicios extra y oficios) vive solo en
-- sus tablas hijas: trabajador_precios, trabajador_servicios_extra y
-- trabajador_servicios. Se eliminan el trigger de sincronización, las
-- columnas jsonb niveles_precio y servicios_personalizados, categoria_servicio
-- y id_region (la región se obtiene desde comunas).

-- 1) Antes de borrar nada, completar las tablas hijas con lo que solo estaba
--    en las columnas (16 cuentas demo sin hijas y todos los oficios).
INSERT INTO public.trabajador_servicios (id_trabajador, categoria_servicio)
SELECT t.id_usuario, t.categoria_servicio
FROM public.trabajadores t
WHERE t.categoria_servicio IS NOT NULL AND btrim(t.categoria_servicio) <> ''
ON CONFLICT DO NOTHING;

INSERT INTO public.trabajador_precios (id_usuario, codigo, monto_clp)
SELECT t.id_usuario, e.key, round(e.value::numeric)
FROM public.trabajadores t
CROSS JOIN LATERAL jsonb_each_text(
  CASE WHEN jsonb_typeof(COALESCE(t.niveles_precio, '{}'::jsonb)) = 'object'
       THEN COALESCE(t.niveles_precio, '{}'::jsonb) ELSE '{}'::jsonb END
) AS e(key, value)
WHERE e.value ~ '^[0-9]+(\.[0-9]+)?$'
ON CONFLICT (id_usuario, codigo) DO NOTHING;

INSERT INTO public.trabajador_servicios_extra (id, id_usuario, titulo, subtitulo, monto_clp, unidad)
SELECT COALESCE(NULLIF(elem->>'id', ''), gen_random_uuid()::text),
       t.id_usuario,
       COALESCE(elem->>'title', ''),
       COALESCE(elem->>'subtitle', ''),
       round(COALESCE(NULLIF(elem->>'priceClp', '')::numeric, 0)),
       CASE WHEN elem->>'unit' = 'perSqm' THEN 'por_m2' ELSE 'fijo' END
FROM public.trabajadores t
CROSS JOIN LATERAL jsonb_array_elements(
  CASE WHEN jsonb_typeof(COALESCE(t.servicios_personalizados, '[]'::jsonb)) = 'array'
       THEN COALESCE(t.servicios_personalizados, '[]'::jsonb) ELSE '[]'::jsonb END
) AS elem
WHERE COALESCE(elem->>'title', '') <> ''
ON CONFLICT (id_usuario, id) DO NOTHING;

-- 2) trabajador_servicios cuelga del profesional (no solo del perfil).
ALTER TABLE public.trabajador_servicios
  DROP CONSTRAINT IF EXISTS "worker_services_workerId_fkey";
ALTER TABLE public.trabajador_servicios
  ADD CONSTRAINT trabajador_servicios_id_trabajador_fkey
  FOREIGN KEY (id_trabajador) REFERENCES public.trabajadores (id_usuario) ON DELETE CASCADE;

-- 3) Lectura de precios y servicios extra: la misma regla que la ficha del
--    profesional (quien puede ver la ficha ve su oferta); escribe solo el dueño.
DROP POLICY IF EXISTS trabajador_precios_propio ON public.trabajador_precios;
CREATE POLICY trabajador_precios_select ON public.trabajador_precios
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.trabajadores t WHERE t.id_usuario = trabajador_precios.id_usuario));
CREATE POLICY trabajador_precios_insert ON public.trabajador_precios
  FOR INSERT TO authenticated WITH CHECK (id_usuario = (SELECT auth.uid()));
CREATE POLICY trabajador_precios_update ON public.trabajador_precios
  FOR UPDATE TO authenticated
  USING (id_usuario = (SELECT auth.uid())) WITH CHECK (id_usuario = (SELECT auth.uid()));
CREATE POLICY trabajador_precios_delete ON public.trabajador_precios
  FOR DELETE TO authenticated USING (id_usuario = (SELECT auth.uid()));

DROP POLICY IF EXISTS trabajador_servicios_extra_propio ON public.trabajador_servicios_extra;
CREATE POLICY trabajador_servicios_extra_select ON public.trabajador_servicios_extra
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.trabajadores t WHERE t.id_usuario = trabajador_servicios_extra.id_usuario));
CREATE POLICY trabajador_servicios_extra_insert ON public.trabajador_servicios_extra
  FOR INSERT TO authenticated WITH CHECK (id_usuario = (SELECT auth.uid()));
CREATE POLICY trabajador_servicios_extra_update ON public.trabajador_servicios_extra
  FOR UPDATE TO authenticated
  USING (id_usuario = (SELECT auth.uid())) WITH CHECK (id_usuario = (SELECT auth.uid()));
CREATE POLICY trabajador_servicios_extra_delete ON public.trabajador_servicios_extra
  FOR DELETE TO authenticated USING (id_usuario = (SELECT auth.uid()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.trabajador_servicios_extra TO authenticated;

-- 4) Funciones que leían las columnas.
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
    AND t.estado_verificacion = 'verificado';
$function$;

CREATE OR REPLACE FUNCTION public.listar_cuentas_demo_acceso()
 RETURNS TABLE(id uuid, nombre text, correo text, rol text, profesion text, categoria_servicio text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT p.id, p.nombre, p.correo, p.rol, t.profesion,
         (SELECT min(s.categoria_servicio) FROM public.trabajador_servicios s WHERE s.id_trabajador = t.id_usuario)
  FROM public.perfiles p
  JOIN public.trabajadores t ON t.id_usuario = p.id
  WHERE COALESCE((SELECT c.valor FROM public.app_config c WHERE c.clave = 'demo_modo'), '0') = '1'
    AND p.rol = 'trabajador'
    AND p.correo ILIKE '%@demo.myworksapp.cl';
$function$;

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
    s.calificacion,
    t.tarifa_visita,
    c.categoria,
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
    s.trabajos_completados,
    t.score_listado,
    t.prioridad_manual,
    t.radio_urbano_km,
    t.tarifa_fuera_radio_clp,
    s.es_elite
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  JOIN LATERAL public.stats_profesional(t.id_usuario) AS s ON true
  LEFT JOIN LATERAL (
    SELECT min(ts.categoria_servicio) AS categoria
    FROM public.trabajador_servicios ts
    WHERE ts.id_trabajador = t.id_usuario
      AND (p_categoria IS NULL OR btrim(p_categoria) = '' OR ts.categoria_servicio = p_categoria)
  ) c ON true
  WHERE COALESCE(t.disponible, 0) = 1
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

CREATE OR REPLACE FUNCTION public.monto_esperado_trabajo(p_job trabajos)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_expected numeric;
  v_worker public.trabajadores%ROWTYPE;
  v_rol text;
  v_estado text;
  v_meta jsonb;
  v_tier text;
  v_rate numeric;
  v_m2 numeric;
  v_unit text;
  v_traslado integer;
BEGIN
  IF p_job.id_cotizacion_seleccionada IS NOT NULL
     OR COALESCE(p_job.modalidad_cobro, '') IN ('cotizacion_abierta', 'cotizacion') THEN
    IF p_job.id_cotizacion_seleccionada IS NULL OR p_job.id_trabajador IS NULL THEN
      RAISE EXCEPTION 'No hay cotizacion seleccionada para este trabajo';
    END IF;
    SELECT c.monto_total_clp INTO v_expected
    FROM public.propuestas_cotizacion c
    WHERE c.id::text = p_job.id_cotizacion_seleccionada::text
      AND c.id_trabajador::text = p_job.id_trabajador::text
      AND c.id_trabajo::text = p_job.id::text
      AND c.estado IN ('seleccionada', 'aceptada');
  ELSE
    SELECT w.* INTO v_worker FROM public.trabajadores w
    WHERE w.id_usuario::text = p_job.id_trabajador::text;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No hay tarifa/cotizacion para validar el monto';
    END IF;
    IF COALESCE(v_worker.estado_verificacion, '') <> 'verificado' THEN
      RAISE EXCEPTION 'Este profesional todavia no esta verificado para cobrar';
    END IF;
    SELECT p.rol, p.estado_cuenta INTO v_rol, v_estado
    FROM public.perfiles p WHERE p.id = v_worker.id_usuario;
    IF COALESCE(v_worker.disponible, 0) <> 1
       OR COALESCE(v_worker.precios_configurados, 0) <> 1
       OR v_rol IS DISTINCT FROM 'trabajador'
       OR v_estado NOT IN ('activo', 'active') THEN
      RAISE EXCEPTION 'Este profesional no esta disponible para cobrar';
    END IF;
    BEGIN
      IF p_job.metadatos_servicio IS NOT NULL AND btrim(p_job.metadatos_servicio) <> '' THEN
        v_meta := p_job.metadatos_servicio::jsonb;
      END IF;
    EXCEPTION WHEN others THEN v_meta := NULL;
    END;
    IF v_meta IS NOT NULL AND v_meta->>'request_type' = 'worker_tier_invitation' THEN
      v_tier := v_meta->>'worker_tier_id';
      v_unit := COALESCE(v_meta->>'worker_tier_unit', '');
      SELECT pr.monto_clp INTO v_rate
      FROM public.trabajador_precios pr
      WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = v_tier;
      IF v_rate IS NULL AND v_tier = 'construction_large_project' THEN
        SELECT pr.monto_clp INTO v_rate FROM public.trabajador_precios pr
        WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = 'construction_per_sqm';
      ELSIF v_rate IS NULL AND v_tier = 'electrical_large_project' THEN
        SELECT pr.monto_clp INTO v_rate FROM public.trabajador_precios pr
        WHERE pr.id_usuario = v_worker.id_usuario AND pr.codigo = 'electrical_per_sqm';
      END IF;
      IF v_rate IS NULL THEN
        SELECT ex.monto_clp INTO v_rate
        FROM public.trabajador_servicios_extra ex
        WHERE ex.id_usuario = v_worker.id_usuario AND ex.id = v_tier
        LIMIT 1;
      END IF;
      IF v_rate IS NULL OR v_rate <= 0 THEN
        RAISE EXCEPTION 'Este profesional no publico esa tarifa';
      END IF;
      v_m2 := NULLIF(v_meta->>'worker_tier_square_meters', '')::numeric;
      IF v_unit = 'perSqm' AND COALESCE(v_m2, 0) > 0 THEN
        v_expected := v_rate * v_m2;
      ELSE
        v_expected := v_rate;
      END IF;
    ELSE
      v_expected := v_worker.tarifa_visita;
    END IF;
    v_traslado := public.recargo_traslado_clp(
      v_worker.latitud_base, v_worker.longitud_base,
      p_job.latitud, p_job.longitud, v_worker.radio_servicio_km);
    v_expected := v_expected + COALESCE(v_traslado, 0);
  END IF;
  IF v_expected IS NULL OR v_expected <= 0 THEN
    RAISE EXCEPTION 'No hay tarifa/cotizacion para validar el monto';
  END IF;
  RETURN v_expected;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fijar_geo_trabajador()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_slug text;
  v_comuna public.comunas%ROWTYPE;
BEGIN
  IF NEW.zona_trabajo IS NULL OR length(trim(NEW.zona_trabajo)) = 0 THEN
    RETURN NEW;
  END IF;

  v_slug := public.slug_geo(NEW.zona_trabajo);

  IF NEW.zona_trabajo ILIKE '%(todas)%' THEN
    NEW.id_comuna := NULL;
    RETURN NEW;
  END IF;

  SELECT * INTO v_comuna
  FROM public.comunas
  WHERE id = v_slug OR public.slug_geo(nombre) = v_slug
  LIMIT 1;

  IF FOUND THEN
    NEW.id_comuna := v_comuna.id;
  END IF;
  RETURN NEW;
END;
$function$;

-- 5) Quitar la sincronización y las columnas.
DROP TRIGGER IF EXISTS trabajadores_explotar_oferta ON public.trabajadores;
DROP FUNCTION IF EXISTS public.explotar_oferta_trabajador();

ALTER TABLE public.trabajadores
  DROP COLUMN niveles_precio,
  DROP COLUMN servicios_personalizados,
  DROP COLUMN categoria_servicio,
  DROP COLUMN id_region;
