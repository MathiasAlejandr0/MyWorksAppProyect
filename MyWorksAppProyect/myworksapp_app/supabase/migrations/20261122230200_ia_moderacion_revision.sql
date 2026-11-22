-- Revisión humana de la cola. Confirmar no borra el mensaje.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

CREATE OR REPLACE FUNCTION public.consola_listar_moderacion(p_limite integer DEFAULT 40)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_rol text := public.rol_consola();
BEGIN
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'id', c.id,
      'id_mensaje', c.id_mensaje,
      'motivo', c.motivo,
      'detalle', c.detalle,
      'estado', c.estado,
      'veredicto_llm', c.veredicto_llm,
      'cuando', c.creado_en,
      'extracto', left(m.contenido, 180)
    ) ORDER BY c.creado_en DESC)
    FROM (
      SELECT *
      FROM public.cola_moderacion
      ORDER BY creado_en DESC
      LIMIT LEAST(GREATEST(COALESCE(p_limite, 40), 1), 80)
    ) c
    LEFT JOIN public.mensajes m ON m.id = c.id_mensaje
  ), '[]'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.consola_listar_moderacion(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_listar_moderacion(integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.consola_revisar_moderacion(
  p_id uuid,
  p_estado text,
  p_motivo text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_antes text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_estado NOT IN ('confirmado', 'descartado') THEN
    RAISE EXCEPTION 'estado no permitido';
  END IF;
  IF char_length(btrim(coalesce(p_motivo, ''))) < 10 THEN
    RAISE EXCEPTION 'motivo demasiado corto';
  END IF;
  SELECT estado INTO v_antes
  FROM public.cola_moderacion
  WHERE id = p_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Marca no encontrada';
  END IF;
  UPDATE public.cola_moderacion
  SET estado = p_estado,
      revisado_por = auth.uid(),
      revisado_en = now()
  WHERE id = p_id;
  PERFORM public.registrar_auditoria(
    'revisar_moderacion', 'cola_moderacion', p_id::text,
    jsonb_build_object('estado', v_antes),
    jsonb_build_object('estado', p_estado),
    btrim(p_motivo), NULL, NULL, NULL, NULL
  );
END;
$$;

REVOKE ALL ON FUNCTION public.consola_revisar_moderacion(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_revisar_moderacion(uuid, text, text) TO authenticated;

COMMENT ON FUNCTION public.consola_revisar_moderacion(uuid, text, text) IS
  'Un humano confirma o descarta la marca. El mensaje sigue en el chat.';
