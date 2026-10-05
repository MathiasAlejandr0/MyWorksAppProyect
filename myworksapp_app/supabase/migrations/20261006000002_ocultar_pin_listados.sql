-- Los listados abiertos no deben devolver el PIN de inicio.
-- Idempotente. Aplicar después de 20261006000001.

BEGIN;

CREATE OR REPLACE FUNCTION public.metadatos_sin_pin(p_raw text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_json jsonb;
BEGIN
  IF p_raw IS NULL OR btrim(p_raw) = '' THEN
    RETURN p_raw;
  END IF;
  v_json := p_raw::jsonb;
  IF jsonb_typeof(v_json) = 'object' THEN
    RETURN (v_json - 'pin')::text;
  END IF;
  RETURN p_raw;
EXCEPTION WHEN others THEN
  RETURN p_raw;
END;
$$;

REVOKE ALL ON FUNCTION public.metadatos_sin_pin(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.listar_trabajos_marketplace(
  p_limite integer DEFAULT 50
)
RETURNS TABLE (
  id text,
  estado text,
  descripcion text,
  creado_en text,
  actualizado_en text,
  id_servicio text,
  modalidad_cobro text,
  metadatos_servicio text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id::text,
         t.estado::text,
         t.descripcion::text,
         t.creado_en::text,
         t.actualizado_en::text,
         t.id_servicio::text,
         COALESCE(t.modalidad_cobro::text, 'legado'),
         public.metadatos_sin_pin(t.metadatos_servicio::text)
  FROM public.trabajos t
  WHERE t.id_trabajador IS NULL
    AND t.estado IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago')
  ORDER BY t.creado_en DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limite, 50), 100));
$$;

REVOKE ALL ON FUNCTION public.listar_trabajos_marketplace(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.listar_trabajos_marketplace(integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.obtener_trabajo_sin_direccion(p_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row FROM public.trabajos WHERE id::text = p_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  IF v_row.id_trabajador IS NOT NULL
     OR v_row.estado NOT IN ('pendiente', 'esperando_cotizaciones', 'esperando_pago') THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'id', v_row.id,
    'estado', v_row.estado,
    'descripcion', v_row.descripcion,
    'creado_en', v_row.creado_en,
    'actualizado_en', v_row.actualizado_en,
    'id_servicio', v_row.id_servicio,
    'modalidad_cobro', COALESCE(v_row.modalidad_cobro, 'legado'),
    'metadatos_servicio', public.metadatos_sin_pin(v_row.metadatos_servicio::text)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.obtener_trabajo_sin_direccion(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.obtener_trabajo_sin_direccion(text) TO authenticated;

COMMIT;
