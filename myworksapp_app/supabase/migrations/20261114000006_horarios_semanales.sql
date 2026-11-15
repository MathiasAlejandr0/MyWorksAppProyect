-- Horario semanal del profesional.
-- Si `trabajador_horarios` ya existe en vivo, no se borran filas:
-- solo se agregan columnas que falten. `usa_horario` nace en falso,
-- así la búsqueda actual no cambia hasta que el profesional lo active.
-- No aplicar en vivo desde este PR.

BEGIN;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS usa_horario boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.trabajador_horarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid,
  dia_semana smallint,
  hora_inicio time,
  hora_fin time,
  activo boolean DEFAULT true,
  creado_en timestamptz DEFAULT now(),
  actualizado_en timestamptz DEFAULT now()
);

ALTER TABLE public.trabajador_horarios
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS id_usuario uuid,
  ADD COLUMN IF NOT EXISTS dia_semana smallint,
  ADD COLUMN IF NOT EXISTS hora_inicio time,
  ADD COLUMN IF NOT EXISTS hora_fin time,
  ADD COLUMN IF NOT EXISTS activo boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS creado_en timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS actualizado_en timestamptz DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'trabajador_horarios_dia_chk'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.trabajador_horarios
      WHERE dia_semana IS NOT NULL
        AND (dia_semana < 1 OR dia_semana > 7)
    ) THEN
      ALTER TABLE public.trabajador_horarios
        ADD CONSTRAINT trabajador_horarios_dia_chk
        CHECK (dia_semana IS NULL OR dia_semana BETWEEN 1 AND 7);
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS trabajador_horarios_usuario_idx
  ON public.trabajador_horarios (id_usuario, dia_semana);

ALTER TABLE public.trabajador_horarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trabajador_horarios_select ON public.trabajador_horarios;
CREATE POLICY trabajador_horarios_select
  ON public.trabajador_horarios
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS trabajador_horarios_write ON public.trabajador_horarios;
CREATE POLICY trabajador_horarios_write
  ON public.trabajador_horarios
  FOR ALL
  TO authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  )
  WITH CHECK (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

GRANT SELECT ON TABLE public.trabajador_horarios TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.trabajador_horarios TO authenticated;
GRANT ALL ON TABLE public.trabajador_horarios TO service_role;

COMMENT ON TABLE public.trabajador_horarios IS
  'Rangos por día (1=lunes … 7=domingo). Filas previas se conservan. usa_horario en trabajadores enciende el filtro.';

COMMIT;
