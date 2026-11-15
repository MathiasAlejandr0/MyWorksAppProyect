-- Las partes abren la disputa y agregan un comentario. No resuelven:
-- el UPDATE directo sigue siendo solo de admin (admin_actualizar_estado_disputa).
-- La evidencia sigue en fotos_trabajo. El trabajo se lee si eres parte.

BEGIN;

DROP POLICY IF EXISTS disputas_select ON public.disputas;
CREATE POLICY disputas_select ON public.disputas
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

DROP POLICY IF EXISTS disputas_insert ON public.disputas;
CREATE POLICY disputas_insert ON public.disputas
  FOR INSERT TO authenticated
  WITH CHECK (
    abierta_por::text = (SELECT auth.uid())::text
    AND public.es_parte_trabajo(id_trabajo::text)
    AND estado = 'abierta'
    AND resolucion IS NULL
    AND resuelta_por IS NULL
  );

DROP POLICY IF EXISTS disputas_update ON public.disputas;
CREATE POLICY disputas_update ON public.disputas
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS fotos_trabajo_all ON public.fotos_trabajo;
CREATE POLICY fotos_trabajo_all ON public.fotos_trabajo
  FOR ALL TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin())
  WITH CHECK (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

-- Misma lectura que 20260928000001: cliente, profesional o admin.
-- No vuelve el listado abierto de trabajos sin profesional (escondía la dirección).
DROP POLICY IF EXISTS trabajos_select ON public.trabajos;
CREATE POLICY trabajos_select ON public.trabajos
  FOR SELECT TO authenticated
  USING (
    id_usuario::text = (SELECT auth.uid())::text
    OR id_trabajador::text = (SELECT auth.uid())::text
    OR public.is_admin()
  );

CREATE OR REPLACE FUNCTION public.abrir_disputa(
  p_id text,
  p_id_trabajo text,
  p_motivo text,
  p_descripcion text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_id IS NULL OR btrim(p_id) = '' OR p_id_trabajo IS NULL OR btrim(p_id_trabajo) = '' THEN
    RAISE EXCEPTION 'Faltan el identificador y el trabajo';
  END IF;
  IF NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF btrim(COALESCE(p_motivo, '')) = '' THEN
    RAISE EXCEPTION 'El motivo es requerido';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo = p_id_trabajo
      AND d.estado IN ('abierta', 'en_revision')
  ) THEN
    RAISE EXCEPTION 'Ya existe una disputa abierta para este trabajo';
  END IF;

  INSERT INTO public.disputas (
    id, id_trabajo, abierta_por, motivo, descripcion, estado, creado_en, actualizado_en
  ) VALUES (
    btrim(p_id),
    btrim(p_id_trabajo),
    v_uid,
    left(btrim(p_motivo), 80),
    NULLIF(left(btrim(COALESCE(p_descripcion, '')), 2000), ''),
    'abierta',
    now(),
    now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.comentar_disputa(
  p_id text,
  p_comentario text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.disputas%ROWTYPE;
  v_nota text := left(btrim(COALESCE(p_comentario, '')), 1000);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_nota = '' THEN
    RAISE EXCEPTION 'El comentario es requerido';
  END IF;

  SELECT * INTO v_row
  FROM public.disputas
  WHERE id::text = btrim(p_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  IF NOT public.es_parte_trabajo(v_row.id_trabajo::text) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_row.estado NOT IN ('abierta', 'en_revision') THEN
    RAISE EXCEPTION 'La disputa ya fue resuelta';
  END IF;

  UPDATE public.disputas
  SET descripcion = left(
        concat_ws(
          E'\n',
          NULLIF(v_row.descripcion, ''),
          concat(to_char(now(), 'DD/MM HH24:MI'), ' · ', v_nota)
        ),
        4000
      ),
      actualizado_en = now()
  WHERE id::text = v_row.id::text;
END;
$$;

REVOKE ALL ON FUNCTION public.abrir_disputa(text, text, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.comentar_disputa(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.abrir_disputa(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.comentar_disputa(text, text) TO authenticated;

COMMIT;
