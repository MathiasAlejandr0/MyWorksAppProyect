-- Ubicación base del profesional y GPS en vivo del pedido.
-- El cliente del trabajo y un administrador leen el punto en vivo.
-- El profesional lo publica solo con la app en primer plano, vía RPC.

BEGIN;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS latitud_base double precision,
  ADD COLUMN IF NOT EXISTS longitud_base double precision,
  ADD COLUMN IF NOT EXISTS radio_servicio_km numeric NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS origen_base text;

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_base_lat_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_base_lat_chk
  CHECK (latitud_base IS NULL OR latitud_base BETWEEN -90 AND 90);

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_base_lng_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_base_lng_chk
  CHECK (longitud_base IS NULL OR longitud_base BETWEEN -180 AND 180);

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_radio_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_radio_chk
  CHECK (radio_servicio_km BETWEEN 1 AND 80);

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_origen_base_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_origen_base_chk
  CHECK (origen_base IS NULL OR origen_base IN ('mapa', 'comuna'));

COMMENT ON COLUMN public.trabajadores.latitud_base IS
  'Latitud de la base de servicio. origen_base=comuna es el centro de la comuna declarada; mapa la fijó el profesional.';
COMMENT ON COLUMN public.trabajadores.radio_servicio_km IS
  'Radio máximo de matching en kilómetros desde la base.';

-- Centros públicos de comuna, solo si aún no hay coordenada.
-- Una zona que nombra varias comunas usa el nombre más largo.
UPDATE public.trabajadores AS t
SET
  latitud_base = m.lat,
  longitud_base = m.lng,
  origen_base = 'comuna'
FROM (
  SELECT DISTINCT ON (t2.id_usuario)
    t2.id_usuario,
    c.lat,
    c.lng
  FROM public.trabajadores t2
  JOIN (
    VALUES
      ('las condes', -33.4172::float8, -70.5476::float8),
      ('lo barnechea', -33.3515, -70.5160),
      ('providencia', -33.4314, -70.6093),
      ('nunoa', -33.4569, -70.5978),
      ('vitacura', -33.3905, -70.5735),
      ('la reina', -33.4453, -70.5414),
      ('penalolen', -33.4860, -70.5440),
      ('la florida', -33.5225, -70.5980),
      ('puente alto', -33.6103, -70.5756),
      ('maipu', -33.5111, -70.7580),
      ('pudahuel', -33.4410, -70.7560),
      ('quilicura', -33.3600, -70.7300),
      ('recoleta', -33.4100, -70.6400),
      ('independencia', -33.4170, -70.6650),
      ('estacion central', -33.4510, -70.6790),
      ('san miguel', -33.4960, -70.6510),
      ('la cisterna', -33.5290, -70.6630),
      ('san bernardo', -33.5920, -70.6990),
      ('vina del mar', -33.0245, -71.5518),
      ('valparaiso', -33.0472, -71.6127),
      ('concepcion', -36.8201, -73.0444),
      ('santiago', -33.4489, -70.6693)
  ) AS c(nombre, lat, lng)
    ON lower(translate(coalesce(t2.zona_trabajo, ''), 'áéíóúñÁÉÍÓÚÑ', 'aeiounAEIOUN'))
      LIKE '%' || c.nombre || '%'
  WHERE t2.latitud_base IS NULL
    AND t2.zona_trabajo IS NOT NULL
  ORDER BY t2.id_usuario, length(c.nombre) DESC
) AS m
WHERE t.id_usuario = m.id_usuario;

CREATE INDEX IF NOT EXISTS trabajadores_base_geo_idx
  ON public.trabajadores (latitud_base, longitud_base)
  WHERE latitud_base IS NOT NULL AND longitud_base IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.ubicacion_en_vivo (
  id_trabajo text PRIMARY KEY REFERENCES public.trabajos(id) ON DELETE CASCADE,
  id_trabajador uuid NOT NULL,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  precision_metros double precision,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ubicacion_lat_chk CHECK (latitud BETWEEN -90 AND 90),
  CONSTRAINT ubicacion_lng_chk CHECK (longitud BETWEEN -180 AND 180)
);

ALTER TABLE public.ubicacion_en_vivo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ubicacion_select_cliente_admin ON public.ubicacion_en_vivo;
CREATE POLICY ubicacion_select_cliente_admin ON public.ubicacion_en_vivo
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.trabajos t
      WHERE t.id::text = ubicacion_en_vivo.id_trabajo
        AND t.id_usuario = (select auth.uid())
    )
  );

GRANT SELECT ON public.ubicacion_en_vivo TO authenticated;
REVOKE ALL ON public.ubicacion_en_vivo FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.ubicacion_en_vivo FROM authenticated;

CREATE OR REPLACE FUNCTION public.publicar_ubicacion_trabajo(
  p_trabajo_id text,
  p_lat double precision,
  p_lng double precision,
  p_precision double precision DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_estado text;
  v_worker uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;
  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat < -90 OR p_lat > 90
     OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'coordenadas invalidas';
  END IF;

  SELECT estado::text, id_trabajador
    INTO v_estado, v_worker
  FROM public.trabajos
  WHERE id::text = p_trabajo_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_worker IS NULL OR v_worker <> auth.uid() THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;
  IF v_estado NOT IN ('en_camino', 'en_curso') THEN
    RAISE EXCEPTION 'el gps solo se publica en camino o en curso';
  END IF;

  INSERT INTO public.ubicacion_en_vivo (
    id_trabajo, id_trabajador, latitud, longitud, precision_metros, actualizado_en
  ) VALUES (
    p_trabajo_id, auth.uid(), p_lat, p_lng, p_precision, now()
  )
  ON CONFLICT (id_trabajo) DO UPDATE SET
    id_trabajador = EXCLUDED.id_trabajador,
    latitud = EXCLUDED.latitud,
    longitud = EXCLUDED.longitud,
    precision_metros = EXCLUDED.precision_metros,
    actualizado_en = now();
END;
$$;

REVOKE ALL ON FUNCTION public.publicar_ubicacion_trabajo(text, double precision, double precision, double precision) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publicar_ubicacion_trabajo(text, double precision, double precision, double precision) TO authenticated;

CREATE OR REPLACE FUNCTION public.borrar_gps_si_trabajo_cerrado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.estado IS DISTINCT FROM OLD.estado
     AND NEW.estado::text NOT IN ('en_camino', 'en_curso') THEN
    DELETE FROM public.ubicacion_en_vivo WHERE id_trabajo = NEW.id::text;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.borrar_gps_si_trabajo_cerrado() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_borrar_gps ON public.trabajos;
CREATE TRIGGER trabajos_borrar_gps
  AFTER UPDATE OF estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.borrar_gps_si_trabajo_cerrado();

-- Catálogo público: coordenadas reales, sin correo.
DROP FUNCTION IF EXISTS public.listar_profesionales_catalogo(text, text, numeric, uuid, integer);

CREATE FUNCTION public.listar_profesionales_catalogo(
  p_categoria text DEFAULT NULL,
  p_zona text DEFAULT NULL,
  p_cursor_calificacion numeric DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
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
  origen_base text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
    t.latitud_base,
    t.longitud_base,
    t.radio_servicio_km,
    t.origen_base
  FROM public.trabajadores t
  LEFT JOIN public.perfiles p ON p.id = t.id_usuario
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
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
      OR COALESCE(t.calificacion, 0) < COALESCE(p_cursor_calificacion, 0)
      OR (
        COALESCE(t.calificacion, 0) = COALESCE(p_cursor_calificacion, 0)
        AND t.id_usuario > p_cursor_id
      )
    )
  ORDER BY COALESCE(t.calificacion, 0) DESC, t.id_usuario ASC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 40);
$$;

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(text, text, numeric, uuid, integer) TO anon, authenticated;

-- Misma matriz que 20260930000001 (ya aplicada) y solo se suman
-- aceptado -> en_camino y en_camino -> en_curso.
-- Se mantiene esperando_pago -> pendiente (el hold deja el trabajo pendiente)
-- y en_curso -> esperando_aprobacion_cliente (la conformidad no es un completado directo).
CREATE OR REPLACE FUNCTION public.transicion_trabajo_permitida(
  p_desde text,
  p_hacia text,
  p_modalidad text DEFAULT 'legado'
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_mode text := COALESCE(NULLIF(trim(p_modalidad), ''), 'legado');
BEGIN
  IF p_desde IS NULL OR p_hacia IS NULL OR p_desde = p_hacia THEN
    RETURN false;
  END IF;

  IF p_desde IN ('completado', 'cancelado', 'expirado', 'no_asistio') THEN
    RETURN false;
  END IF;

  IF p_hacia = 'cancelado' AND p_desde NOT IN ('completado', 'cancelado') THEN
    RETURN true;
  END IF;

  CASE v_mode
    WHEN 'precio_fijo', 'bloque_horas' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_pago', 'pendiente'),
        ('pendiente', 'aceptado'),
        ('aceptado', 'en_camino'),
        ('aceptado', 'en_curso'),
        ('en_camino', 'en_curso'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    WHEN 'cotizacion_abierta' THEN
      RETURN (p_desde, p_hacia) IN (
        ('esperando_cotizaciones', 'cotizacion_seleccionada'),
        ('esperando_cotizaciones', 'expirado'),
        ('cotizacion_seleccionada', 'esperando_pago'),
        ('esperando_pago', 'pendiente'),
        ('pendiente', 'aceptado'),
        ('aceptado', 'en_camino'),
        ('aceptado', 'en_curso'),
        ('en_camino', 'en_curso'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
    ELSE
      RETURN (p_desde, p_hacia) IN (
        ('pendiente', 'aceptado'),
        ('pendiente', 'expirado'),
        ('aceptado', 'en_camino'),
        ('aceptado', 'en_curso'),
        ('aceptado', 'pendiente'),
        ('en_camino', 'en_curso'),
        ('en_curso', 'esperando_aprobacion_cliente'),
        ('en_curso', 'no_asistio'),
        ('en_curso', 'pausado_orden_cambio'),
        ('pausado_orden_cambio', 'en_curso')
      );
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.transiciones_trabajo_posibles(
  p_desde text,
  p_modalidad text DEFAULT 'legado'
)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(array_agg(candidato ORDER BY candidato), ARRAY[]::text[])
  FROM unnest(ARRAY[
    'pendiente',
    'esperando_cotizaciones',
    'cotizacion_seleccionada',
    'esperando_pago',
    'aceptado',
    'en_camino',
    'en_curso',
    'pausado_orden_cambio',
    'esperando_aprobacion_cliente',
    'completado',
    'cancelado',
    'expirado',
    'no_asistio'
  ]::text[]) AS candidato
  WHERE public.transicion_trabajo_permitida(
    p_desde,
    candidato,
    COALESCE(NULLIF(trim(p_modalidad), ''), 'legado')
  );
$$;

REVOKE ALL ON FUNCTION public.transiciones_trabajo_posibles(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transiciones_trabajo_posibles(text, text) TO authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'ubicacion_en_vivo'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.ubicacion_en_vivo;
    END IF;
  END IF;
EXCEPTION
  WHEN undefined_object OR insufficient_privilege THEN
    NULL;
END $$;

COMMIT;
