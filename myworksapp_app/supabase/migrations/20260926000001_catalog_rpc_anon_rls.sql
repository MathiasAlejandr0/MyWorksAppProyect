-- Catálogo público acotado (plan Free): RLS anon solo marketplace,
-- RPC paginada sin PII (sin correo), índice de listado.
--
-- EXPLAIN esperado (SQL editor, con ANALYZE opcional):
--   EXPLAIN (FORMAT TEXT)
--   SELECT * FROM public.listar_profesionales_catalogo('electricidad', NULL, NULL, NULL, 20);
-- Preferible: Index Scan / Bitmap Index Scan sobre
--   trabajadores_catalog_list_idx o trabajadores_disponible_cat_idx.
-- Evitar Seq Scan sobre trabajadores cuando hay >1k filas.

DROP POLICY IF EXISTS trabajadores_select ON public.trabajadores;
DROP POLICY IF EXISTS trabajadores_select_marketplace ON public.trabajadores;
DROP POLICY IF EXISTS trabajadores_select_authenticated ON public.trabajadores;

-- Anon: solo fichas publicables (disponible + tarifa configurada).
CREATE POLICY trabajadores_select_marketplace ON public.trabajadores
  FOR SELECT TO anon
  USING (
    COALESCE(disponible, 0) = 1
    AND COALESCE(precios_configurados, 0) = 1
  );

-- Autenticados: marketplace público, ficha propia o admin.
CREATE POLICY trabajadores_select_authenticated ON public.trabajadores
  FOR SELECT TO authenticated
  USING (
    (
      COALESCE(disponible, 0) = 1
      AND COALESCE(precios_configurados, 0) = 1
    )
    OR id_usuario = auth.uid()
    OR public.is_admin()
  );

GRANT SELECT ON TABLE public.trabajadores TO anon, authenticated;

REVOKE ALL ON TABLE public.perfiles FROM anon;
REVOKE ALL ON TABLE public.pagos FROM anon;
REVOKE ALL ON TABLE public.trabajos FROM anon;
REVOKE ALL ON TABLE public.mensajes FROM anon;

CREATE INDEX IF NOT EXISTS trabajadores_catalog_list_idx
  ON public.trabajadores (
    categoria_servicio,
    calificacion DESC NULLS LAST,
    id_usuario
  )
  WHERE COALESCE(disponible, 0) = 1
    AND COALESCE(precios_configurados, 0) = 1;

COMMENT ON INDEX public.trabajadores_catalog_list_idx IS
  'Listado marketplace: categoría + rating + cursor id. Usar en RPC y REST limit.';

-- Zona: btree útil en igualdad / prefijo. ILIKE '%texto%' no lo usa (sin pg_trgm).
CREATE INDEX IF NOT EXISTS trabajadores_zona_trabajo_idx
  ON public.trabajadores (zona_trabajo)
  WHERE COALESCE(disponible, 0) = 1
    AND zona_trabajo IS NOT NULL;

COMMENT ON INDEX public.trabajadores_zona_trabajo_idx IS
  'Filtro zona_trabajo del RPC. Nearby real (lat/lng) no está en trabajadores; solo zona texto.';

CREATE OR REPLACE FUNCTION public.listar_profesionales_catalogo(
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
  ruta_foto_perfil text
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
    p.ruta_foto_perfil
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

COMMENT ON FUNCTION public.listar_profesionales_catalogo IS
  'Marketplace público paginado. Sin correo ni campos de pago. SECURITY DEFINER solo para nombre/foto.';

REVOKE ALL ON FUNCTION public.listar_profesionales_catalogo(
  text, text, numeric, uuid, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.listar_profesionales_catalogo(
  text, text, numeric, uuid, integer
) TO anon, authenticated;
