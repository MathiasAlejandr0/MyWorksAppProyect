-- Portado desde MathiasAlejandr0/MyWorksAppProyect PR #55 (20261114000004_calificacion_bidireccional.sql).
-- Aplicada en vivo dentro de 20261115051320–20261115051532.
-- No reaplicar el SQL en wxqrfcqifkfgawrnqmnj: ya está en la base.

-- Calificación en los dos sentidos: el cliente nota al profesional y
-- el profesional nota al cliente. Una por dirección y trabajo.
-- El promedio del cliente sale solo por RPC (promedio y cantidad).
-- No aplicar en vivo desde este PR.

BEGIN;

ALTER TABLE public.calificaciones
  ADD COLUMN IF NOT EXISTS direccion text,
  ADD COLUMN IF NOT EXISTS id_calificado uuid;

UPDATE public.calificaciones c
SET direccion = 'cliente_a_trabajador'
WHERE c.direccion IS NULL;

UPDATE public.calificaciones c
SET id_calificado = t.id_trabajador
FROM public.trabajos t
WHERE c.id_calificado IS NULL
  AND c.direccion = 'cliente_a_trabajador'
  AND t.id::text = c.id_trabajo::text
  AND t.id_trabajador IS NOT NULL;

ALTER TABLE public.calificaciones
  ALTER COLUMN direccion SET DEFAULT 'cliente_a_trabajador';

ALTER TABLE public.calificaciones
  ALTER COLUMN direccion SET NOT NULL;

ALTER TABLE public.calificaciones
  DROP CONSTRAINT IF EXISTS calificaciones_direccion_chk;

ALTER TABLE public.calificaciones
  ADD CONSTRAINT calificaciones_direccion_chk
  CHECK (direccion IN ('cliente_a_trabajador', 'trabajador_a_cliente'));

DELETE FROM public.calificaciones c
WHERE c.ctid IN (
  SELECT ctid FROM (
    SELECT
      ctid,
      row_number() OVER (
        PARTITION BY id_trabajo, direccion
        ORDER BY creado_en DESC NULLS LAST, ctid DESC
      ) AS rn
    FROM public.calificaciones
  ) s
  WHERE rn > 1
);

DROP INDEX IF EXISTS public.calificaciones_trabajo_usuario_uidx;

CREATE UNIQUE INDEX IF NOT EXISTS calificaciones_trabajo_direccion_uidx
  ON public.calificaciones (id_trabajo, direccion);

CREATE OR REPLACE FUNCTION public.refrescar_calificacion_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job text := COALESCE(NEW.id_trabajo, OLD.id_trabajo)::text;
  v_worker text;
BEGIN
  SELECT id_trabajador::text INTO v_worker
  FROM public.trabajos
  WHERE id::text = v_job;

  IF v_worker IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  UPDATE public.trabajadores
  SET calificacion = COALESCE((
    SELECT round(avg(c.puntaje)::numeric, 2)
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    WHERE t.id_trabajador::text = v_worker
      AND c.direccion = 'cliente_a_trabajador'
  ), 0)
  WHERE id_usuario::text = v_worker;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP POLICY IF EXISTS calificaciones_select ON public.calificaciones;
CREATE POLICY calificaciones_select ON public.calificaciones
  FOR SELECT TO authenticated
  USING (
    direccion = 'cliente_a_trabajador'
    OR id_usuario = (SELECT auth.uid())
    OR id_calificado = (SELECT auth.uid())
    OR public.is_admin()
  );

DROP POLICY IF EXISTS calificaciones_insert ON public.calificaciones;
CREATE POLICY calificaciones_insert ON public.calificaciones
  FOR INSERT TO authenticated
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    AND id_calificado IS NOT NULL
    AND (
      (
        direccion = 'cliente_a_trabajador'
        AND EXISTS (
          SELECT 1
          FROM public.trabajos t
          WHERE t.id::text = calificaciones.id_trabajo::text
            AND t.id_usuario = (SELECT auth.uid())
            AND t.id_trabajador = calificaciones.id_calificado
            AND t.estado = 'completado'
            AND NOT EXISTS (
              SELECT 1
              FROM public.disputas d
              WHERE d.id_trabajo::text = t.id::text
                AND d.estado IN ('abierta', 'en_revision')
            )
        )
      )
      OR (
        direccion = 'trabajador_a_cliente'
        AND EXISTS (
          SELECT 1
          FROM public.trabajos t
          WHERE t.id::text = calificaciones.id_trabajo::text
            AND t.id_trabajador = (SELECT auth.uid())
            AND t.id_usuario = calificaciones.id_calificado
            AND t.estado = 'completado'
            AND NOT EXISTS (
              SELECT 1
              FROM public.disputas d
              WHERE d.id_trabajo::text = t.id::text
                AND d.estado IN ('abierta', 'en_revision')
            )
        )
      )
    )
  );

CREATE OR REPLACE FUNCTION public.resumen_calificacion_clientes(p_ids uuid[])
RETURNS TABLE (id_usuario uuid, promedio numeric, cantidad integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF p_ids IS NULL OR cardinality(p_ids) = 0 THEN
    RETURN;
  END IF;
  IF cardinality(p_ids) > 50 THEN
    RAISE EXCEPTION 'demasiados clientes';
  END IF;

  RETURN QUERY
  SELECT
    ids.id,
    round(avg(c.puntaje)::numeric, 2),
    count(c.id)::integer
  FROM unnest(p_ids) AS ids(id)
  LEFT JOIN public.calificaciones c
    ON c.id_calificado = ids.id
   AND c.direccion = 'trabajador_a_cliente'
  GROUP BY ids.id;
END;
$$;

REVOKE ALL ON FUNCTION public.resumen_calificacion_clientes(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resumen_calificacion_clientes(uuid[]) TO authenticated;

COMMIT;
