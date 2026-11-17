-- Portado desde MathiasAlejandr0/MyWorksAppProyect PR #55 (20261114000007_verificacion_eventos.sql).
-- Aplicada en vivo dentro de 20261115051320–20261115051532.
-- No reaplicar el SQL en wxqrfcqifkfgawrnqmnj: ya está en la base.

-- Historial de la verificación documental. El trigger solo inserta;
-- no reescribe el estado ni las filas ya guardadas en trabajadores.
-- No aplicar en vivo desde este PR.

BEGIN;

CREATE TABLE IF NOT EXISTS public.verificacion_eventos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.perfiles (id) ON DELETE CASCADE,
  estado text NOT NULL,
  nota text,
  id_actor uuid,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS verificacion_eventos_usuario_idx
  ON public.verificacion_eventos (id_usuario, creado_en);

ALTER TABLE public.verificacion_eventos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS verificacion_eventos_select ON public.verificacion_eventos;
CREATE POLICY verificacion_eventos_select
  ON public.verificacion_eventos
  FOR SELECT
  TO authenticated
  USING (
    id_usuario = (SELECT auth.uid())
    OR public.is_admin()
  );

REVOKE ALL ON TABLE public.verificacion_eventos FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.verificacion_eventos TO authenticated;
GRANT ALL ON TABLE public.verificacion_eventos TO service_role;

CREATE OR REPLACE FUNCTION public.registrar_evento_verificacion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT'
     OR NEW.estado_verificacion IS DISTINCT FROM OLD.estado_verificacion
     OR NEW.nota_verificacion IS DISTINCT FROM OLD.nota_verificacion THEN
    INSERT INTO public.verificacion_eventos (id_usuario, estado, nota, id_actor)
    VALUES (
      NEW.id_usuario,
      NEW.estado_verificacion,
      NEW.nota_verificacion,
      auth.uid()
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_evento_verificacion ON public.trabajadores;
CREATE TRIGGER trabajadores_evento_verificacion
  AFTER INSERT OR UPDATE OF estado_verificacion, nota_verificacion
  ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_evento_verificacion();

REVOKE ALL ON FUNCTION public.registrar_evento_verificacion() FROM PUBLIC, anon, authenticated;

COMMIT;
