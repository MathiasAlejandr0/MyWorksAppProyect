-- Catálogo de categorías de servicio (oficios) con clave primaria propia.
-- Antes `servicios.categoria` y `trabajador_servicios.categoria_servicio` eran
-- texto libre sin clave foránea: nada impedía escribir una categoría inexistente.

CREATE TABLE public.categorias_servicio (
  id text PRIMARY KEY CHECK (id ~ '^[a-z][a-z0-9_]*$'),
  nombre text NOT NULL CHECK (length(btrim(nombre)) > 0),
  activa boolean NOT NULL DEFAULT true,
  creado_en timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.categorias_servicio IS
  'Categorías (oficios) que ofrece la plataforma. servicios y trabajador_servicios apuntan a ella.';

INSERT INTO public.categorias_servicio (id, nombre)
SELECT c.id, COALESCE(n.nombre, initcap(replace(c.id, '_', ' ')))
FROM (
  SELECT categoria AS id FROM public.servicios
  UNION SELECT categoria_servicio FROM public.trabajador_servicios
  UNION SELECT categoria_servicio FROM public.trabajadores
  WHERE categoria_servicio IS NOT NULL AND btrim(categoria_servicio) <> ''
) c
LEFT JOIN (VALUES
  ('cerrajeria', 'Cerrajería'),
  ('climatizacion', 'Climatización'),
  ('construccion', 'Construcción'),
  ('electricidad', 'Electricidad'),
  ('ensamblaje', 'Ensamblaje'),
  ('gasfiteria', 'Gasfitería'),
  ('jardineria', 'Jardinería'),
  ('limpieza', 'Limpieza'),
  ('mudanza', 'Mudanza'),
  ('pintura', 'Pintura'),
  ('plomeria', 'Plomería'),
  ('soporte_tecnico', 'Soporte técnico')
) AS n(id, nombre) ON n.id = c.id;

ALTER TABLE public.servicios
  ADD CONSTRAINT servicios_categoria_fkey
  FOREIGN KEY (categoria) REFERENCES public.categorias_servicio (id) ON UPDATE CASCADE;

ALTER TABLE public.trabajador_servicios
  ADD CONSTRAINT trabajador_servicios_categoria_fkey
  FOREIGN KEY (categoria_servicio) REFERENCES public.categorias_servicio (id) ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS servicios_categoria_idx ON public.servicios (categoria);
CREATE INDEX IF NOT EXISTS trabajador_servicios_categoria_idx
  ON public.trabajador_servicios (categoria_servicio, id_trabajador);

-- Mismo acceso que `servicios`: lectura pública, escritura solo del administrador.
ALTER TABLE public.categorias_servicio ENABLE ROW LEVEL SECURITY;

CREATE POLICY categorias_servicio_select_anon ON public.categorias_servicio
  FOR SELECT TO anon USING (activa);
CREATE POLICY categorias_servicio_select ON public.categorias_servicio
  FOR SELECT TO authenticated
  USING (activa OR (SELECT public.is_admin()));
CREATE POLICY categorias_servicio_admin_insert ON public.categorias_servicio
  FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY categorias_servicio_admin_update ON public.categorias_servicio
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY categorias_servicio_admin_delete ON public.categorias_servicio
  FOR DELETE TO authenticated USING ((SELECT public.is_admin()));

REVOKE ALL ON public.categorias_servicio FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.categorias_servicio TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.categorias_servicio TO authenticated;
GRANT ALL ON public.categorias_servicio TO service_role;
