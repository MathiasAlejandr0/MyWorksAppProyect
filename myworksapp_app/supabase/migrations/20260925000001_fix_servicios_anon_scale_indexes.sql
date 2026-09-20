-- Fix lectura pública de catálogo `servicios` (401 anon en PostgREST)
-- Causa típica: GRANT ausente o política sin rol anon / USING con is_admin().

ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS servicios_select ON public.servicios;
DROP POLICY IF EXISTS servicios_select_admin ON public.servicios;
DROP POLICY IF EXISTS servicios_write ON public.servicios;

-- Público: solo oficios activos. NO llamar is_admin() aquí (rompe anon).
CREATE POLICY servicios_select ON public.servicios
  FOR SELECT TO anon, authenticated
  USING (COALESCE(activo, 1) = 1);

-- Admin puede ver también inactivos
CREATE POLICY servicios_select_admin ON public.servicios
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY servicios_write ON public.servicios
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT ON TABLE public.servicios TO anon, authenticated;

-- Índices de lectura marketplace (escala ~20k usuarios registrados)
CREATE INDEX IF NOT EXISTS servicios_activo_categoria_idx
  ON public.servicios (activo, categoria)
  WHERE COALESCE(activo, 1) = 1;

CREATE INDEX IF NOT EXISTS trabajadores_disponible_cat_idx
  ON public.trabajadores (disponible, categoria_servicio)
  WHERE COALESCE(disponible, 0) = 1;

CREATE INDEX IF NOT EXISTS trabajadores_calificacion_idx
  ON public.trabajadores (calificacion DESC NULLS LAST)
  WHERE COALESCE(disponible, 0) = 1;

CREATE INDEX IF NOT EXISTS trabajos_usuario_creado_idx
  ON public.trabajos (id_usuario, creado_en DESC);

CREATE INDEX IF NOT EXISTS trabajos_trabajador_estado_idx
  ON public.trabajos (id_trabajador, estado)
  WHERE id_trabajador IS NOT NULL;

CREATE INDEX IF NOT EXISTS pagos_trabajo_estado_idx
  ON public.pagos (id_trabajo, estado);

COMMENT ON POLICY servicios_select ON public.servicios IS
  'Catálogo público de oficios activos — anon + authenticated; sin is_admin() en USING.';
