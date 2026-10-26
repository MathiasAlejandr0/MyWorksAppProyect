-- Catálogo geográfico Chile (país → región → comuna) y FKs de localización.
-- Idempotente. Alinea trabajos.id_comuna y la zona del profesional.

BEGIN;

CREATE TABLE IF NOT EXISTS public.paises (
  id text PRIMARY KEY,
  nombre text NOT NULL,
  iso2 text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.regiones (
  id text PRIMARY KEY,
  id_pais text NOT NULL REFERENCES public.paises (id),
  nombre text NOT NULL,
  codigo_oficial text
);

CREATE TABLE IF NOT EXISTS public.comunas (
  id text PRIMARY KEY,
  id_region text NOT NULL REFERENCES public.regiones (id),
  nombre text NOT NULL,
  latitud double precision,
  longitud double precision,
  activa integer NOT NULL DEFAULT 1,
  CONSTRAINT comunas_lat_chk CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
  CONSTRAINT comunas_lng_chk CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180)
);

CREATE INDEX IF NOT EXISTS comunas_region_idx ON public.comunas (id_region);
CREATE INDEX IF NOT EXISTS comunas_nombre_idx ON public.comunas (nombre);

ALTER TABLE public.paises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comunas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS paises_select ON public.paises;
CREATE POLICY paises_select ON public.paises
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS regiones_select ON public.regiones;
CREATE POLICY regiones_select ON public.regiones
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS comunas_select ON public.comunas;
CREATE POLICY comunas_select ON public.comunas
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS paises_admin_write ON public.paises;
CREATE POLICY paises_admin_write ON public.paises
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS regiones_admin_write ON public.regiones;
CREATE POLICY regiones_admin_write ON public.regiones
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS comunas_admin_write ON public.comunas;
CREATE POLICY comunas_admin_write ON public.comunas
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT ON public.paises, public.regiones, public.comunas TO anon, authenticated;
GRANT ALL ON public.paises, public.regiones, public.comunas TO service_role;

INSERT INTO public.paises (id, nombre, iso2)
VALUES ('CL', 'Chile', 'CL')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.regiones (id, id_pais, nombre, codigo_oficial)
VALUES
  ('rm', 'CL', 'Región Metropolitana de Santiago', 'XIII'),
  ('ll', 'CL', 'Los Lagos', 'X'),
  ('vs', 'CL', 'Valparaíso', 'V'),
  ('bi', 'CL', 'Biobío', 'VIII'),
  ('nb', 'CL', 'Ñuble', 'XVI'),
  ('ar', 'CL', 'La Araucanía', 'IX'),
  ('co', 'CL', 'Coquimbo', 'IV'),
  ('an', 'CL', 'Antofagasta', 'II'),
  ('ta', 'CL', 'Tarapacá', 'I'),
  ('li', 'CL', 'O''Higgins', 'VI'),
  ('ml', 'CL', 'Maule', 'VII')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.comunas (id, id_region, nombre, latitud, longitud)
VALUES
  ('santiago', 'rm', 'Santiago Centro', -33.4489, -70.6693),
  ('santiago_centro', 'rm', 'Santiago Centro', -33.4489, -70.6693),
  ('providencia', 'rm', 'Providencia', -33.4314, -70.6093),
  ('las_condes', 'rm', 'Las Condes', -33.4172, -70.5476),
  ('nunoa', 'rm', 'Ñuñoa', -33.4569, -70.5978),
  ('maipu', 'rm', 'Maipú', -33.5111, -70.7580),
  ('la_florida', 'rm', 'La Florida', -33.5225, -70.5980),
  ('puente_alto', 'rm', 'Puente Alto', -33.6103, -70.5756),
  ('san_bernardo', 'rm', 'San Bernardo', -33.5920, -70.6990),
  ('penalolen', 'rm', 'Peñalolén', -33.4860, -70.5440),
  ('la_reina', 'rm', 'La Reina', -33.4453, -70.5414),
  ('vitacura', 'rm', 'Vitacura', -33.3905, -70.5735),
  ('lo_barnechea', 'rm', 'Lo Barnechea', -33.3515, -70.5160),
  ('quilicura', 'rm', 'Quilicura', -33.3600, -70.7300),
  ('estacion_central', 'rm', 'Estación Central', -33.4510, -70.6790),
  ('independencia', 'rm', 'Independencia', -33.4170, -70.6650),
  ('recoleta', 'rm', 'Recoleta', -33.4100, -70.6400),
  ('huechuraba', 'rm', 'Huechuraba', -33.3740, -70.6380),
  ('macul', 'rm', 'Macul', -33.4850, -70.5990),
  ('la_cisterna', 'rm', 'La Cisterna', -33.5290, -70.6630),
  ('el_bosque', 'rm', 'El Bosque', -33.5610, -70.6750),
  ('pudahuel', 'rm', 'Pudahuel', -33.4410, -70.7560),
  ('san_miguel', 'rm', 'San Miguel', -33.4960, -70.6510),
  ('puerto_montt', 'll', 'Puerto Montt', -41.4717, -72.9369),
  ('puerto_varas', 'll', 'Puerto Varas', -41.3195, -72.9854),
  ('osorno', 'll', 'Osorno', -40.5740, -73.1349),
  ('castro', 'll', 'Castro', -42.4820, -73.7630),
  ('ancud', 'll', 'Ancud', -41.8682, -73.8275),
  ('valparaiso', 'vs', 'Valparaíso', -33.0472, -71.6127),
  ('vina_del_mar', 'vs', 'Viña del Mar', -33.0245, -71.5518),
  ('concepcion', 'bi', 'Concepción', -36.8201, -73.0444),
  ('chillan', 'nb', 'Chillán', -36.6064, -72.1034),
  ('temuco', 'ar', 'Temuco', -38.7359, -72.5904),
  ('la_serena', 'co', 'La Serena', -29.9027, -71.2520),
  ('antofagasta', 'an', 'Antofagasta', -23.6509, -70.3975),
  ('iquique', 'ta', 'Iquique', -20.2307, -70.1355),
  ('rancagua', 'li', 'Rancagua', -34.1708, -70.7444),
  ('talca', 'ml', 'Talca', -35.4264, -71.6554)
ON CONFLICT (id) DO UPDATE
SET nombre = EXCLUDED.nombre,
    id_region = EXCLUDED.id_region,
    latitud = COALESCE(public.comunas.latitud, EXCLUDED.latitud),
    longitud = COALESCE(public.comunas.longitud, EXCLUDED.longitud);

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS id_comuna text,
  ADD COLUMN IF NOT EXISTS id_region text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trabajadores_id_comuna_fkey'
  ) THEN
    ALTER TABLE public.trabajadores
      ADD CONSTRAINT trabajadores_id_comuna_fkey
      FOREIGN KEY (id_comuna) REFERENCES public.comunas (id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trabajadores_id_region_fkey'
  ) THEN
    ALTER TABLE public.trabajadores
      ADD CONSTRAINT trabajadores_id_region_fkey
      FOREIGN KEY (id_region) REFERENCES public.regiones (id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.slug_geo(p_texto text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT NULLIF(trim(regexp_replace(
    lower(translate(coalesce(p_texto, ''), 'áéíóúñÁÉÍÓÚÑ', 'aeiounAEIOUN')),
    '[^a-z0-9]+', '_', 'g'
  ), '_'), '');
$$;

-- Cobertura regional "(todas)" no es comuna.
UPDATE public.trabajadores t
SET id_region = CASE
      WHEN public.slug_geo(t.zona_trabajo) LIKE '%metropolitana%' THEN 'rm'
      WHEN public.slug_geo(t.zona_trabajo) LIKE '%los_lagos%' THEN 'll'
      ELSE t.id_region
    END,
    id_comuna = CASE
      WHEN coalesce(t.zona_trabajo, '') ILIKE '%(todas)%' THEN NULL
      ELSE t.id_comuna
    END
WHERE t.zona_trabajo IS NOT NULL
  AND t.zona_trabajo ILIKE '%(todas)%';

UPDATE public.trabajadores t
SET id_comuna = c.id,
    id_region = c.id_region
FROM public.comunas c
WHERE t.id_comuna IS NULL
  AND t.zona_trabajo IS NOT NULL
  AND t.zona_trabajo NOT ILIKE '%(todas)%'
  AND (
    public.slug_geo(t.zona_trabajo) = c.id
    OR public.slug_geo(t.zona_trabajo) = public.slug_geo(c.nombre)
  );

UPDATE public.trabajos
SET id_comuna = 'santiago'
WHERE id_comuna IN ('santiago_centro');

UPDATE public.trabajos j
SET id_comuna = NULL
WHERE j.id_comuna IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.comunas c WHERE c.id = j.id_comuna);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trabajos_id_comuna_fkey'
  ) THEN
    ALTER TABLE public.trabajos
      ADD CONSTRAINT trabajos_id_comuna_fkey
      FOREIGN KEY (id_comuna) REFERENCES public.comunas (id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.fijar_geo_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
    IF v_slug LIKE '%metropolitana%' THEN
      NEW.id_region := 'rm';
    ELSIF v_slug LIKE '%los_lagos%' THEN
      NEW.id_region := 'll';
    END IF;
    RETURN NEW;
  END IF;

  SELECT * INTO v_comuna
  FROM public.comunas
  WHERE id = v_slug OR public.slug_geo(nombre) = v_slug
  LIMIT 1;

  IF FOUND THEN
    NEW.id_comuna := v_comuna.id;
    NEW.id_region := v_comuna.id_region;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_fijar_geo ON public.trabajadores;
CREATE TRIGGER trabajadores_fijar_geo
  BEFORE INSERT OR UPDATE OF zona_trabajo
  ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.fijar_geo_trabajador();

-- ID huérfano de auditoría: el GPS en vivo apuntaba al trabajador sin FK.
DO $$
BEGIN
  IF to_regclass('public.ubicacion_en_vivo') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint WHERE conname = 'ubicacion_en_vivo_trabajador_fkey'
     ) THEN
    EXECUTE $fk$
      ALTER TABLE public.ubicacion_en_vivo
        ADD CONSTRAINT ubicacion_en_vivo_trabajador_fkey
        FOREIGN KEY (id_trabajador) REFERENCES public.trabajadores (id_usuario)
        ON DELETE CASCADE
    $fk$;
  END IF;
END $$;

COMMENT ON TABLE public.paises IS 'País operativo. Hoy solo CL.';
COMMENT ON TABLE public.regiones IS 'Región administrativa chilena.';
COMMENT ON TABLE public.comunas IS 'Comuna / ciudad de cobertura. PK slug = trabajos.id_comuna.';
COMMENT ON COLUMN public.trabajadores.id_comuna IS 'Comuna de cobertura. zona_trabajo sigue como texto de UI.';
COMMENT ON COLUMN public.trabajadores.id_region IS 'Cobertura regional (p. ej. RM todas).';
COMMENT ON COLUMN public.trabajos.id_comuna IS 'FK a comunas.id (slug).';

COMMIT;
