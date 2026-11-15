-- La tabla viva tenía PRIMARY KEY en id_usuario (una fila por profesional,
-- con el jsonb legado `horarios`). Guardar un día más chocaba con esa clave.
-- Se conserva cada fila. Las que no tienen dia_semana siguen siendo válidas.
-- No incluye secretos.

BEGIN;

ALTER TABLE public.trabajador_horarios
  ADD COLUMN IF NOT EXISTS id uuid,
  ADD COLUMN IF NOT EXISTS dia_semana smallint,
  ADD COLUMN IF NOT EXISTS hora_inicio time,
  ADD COLUMN IF NOT EXISTS hora_fin time,
  ADD COLUMN IF NOT EXISTS activo boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS creado_en timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS actualizado_en timestamptz DEFAULT now();

UPDATE public.trabajador_horarios
SET id = gen_random_uuid()
WHERE id IS NULL;

ALTER TABLE public.trabajador_horarios
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE public.trabajador_horarios
  ALTER COLUMN id SET NOT NULL;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'trabajador_horarios'
      AND con.contype = 'p'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.trabajador_horarios DROP CONSTRAINT %I',
      r.conname
    );
  END LOOP;
END $$;

ALTER TABLE public.trabajador_horarios
  ADD CONSTRAINT trabajador_horarios_pkey PRIMARY KEY (id);

-- Índice único no parcial: Postgres trata NULL como distinto, así que la
-- fila legada (dia_semana nulo) convive con los días nuevos. PostgREST
-- arma ON CONFLICT (id_usuario, dia_semana) y no puede usar un índice
-- parcial (haría falta WHERE dia_semana IS NOT NULL).
CREATE UNIQUE INDEX IF NOT EXISTS trabajador_horarios_usuario_dia_uidx
  ON public.trabajador_horarios (id_usuario, dia_semana);

-- Una política por comando. El acceso efectivo no cambia:
-- cualquiera lee; escribe el dueño o un administrador.
DROP POLICY IF EXISTS trabajador_horarios_propio ON public.trabajador_horarios;
DROP POLICY IF EXISTS trabajador_horarios_select ON public.trabajador_horarios;
DROP POLICY IF EXISTS trabajador_horarios_write ON public.trabajador_horarios;

CREATE POLICY trabajador_horarios_select
  ON public.trabajador_horarios
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY trabajador_horarios_insert
  ON public.trabajador_horarios
  FOR INSERT
  TO authenticated
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

CREATE POLICY trabajador_horarios_update
  ON public.trabajador_horarios
  FOR UPDATE
  TO authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  )
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

CREATE POLICY trabajador_horarios_delete
  ON public.trabajador_horarios
  FOR DELETE
  TO authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

-- SELECT de liquidaciones era dos políticas permisivas (admin y trabajador).
-- Queda una sola. Escribir sigue siendo solo del administrador.
DROP POLICY IF EXISTS liquidaciones_admin_all ON public.liquidaciones;
DROP POLICY IF EXISTS liquidaciones_trabajador_select ON public.liquidaciones;

CREATE POLICY liquidaciones_select
  ON public.liquidaciones
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR id_trabajador = (SELECT auth.uid())::text
  );

CREATE POLICY liquidaciones_admin_insert
  ON public.liquidaciones
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY liquidaciones_admin_update
  ON public.liquidaciones
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY liquidaciones_admin_delete
  ON public.liquidaciones
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

COMMIT;
