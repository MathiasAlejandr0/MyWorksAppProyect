-- Verificación de profesionales (cédula / nota) y chat en vivo.
-- Idempotente. El dueño debe aplicarla en el proyecto Supabase
-- (supabase db push o SQL Editor) antes de usar el flujo en producción.
-- No incluye credenciales.

BEGIN;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS estado_verificacion text NOT NULL DEFAULT 'pendiente';

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS nota_verificacion text;

ALTER TABLE public.trabajadores
  DROP CONSTRAINT IF EXISTS trabajadores_estado_verificacion_check;

ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_estado_verificacion_check
  CHECK (estado_verificacion IN ('pendiente', 'en_revision', 'verificado', 'rechazado'));

CREATE OR REPLACE FUNCTION public.proteger_verificacion_profesional()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.estado_verificacion IS NOT DISTINCT FROM OLD.estado_verificacion THEN
    RETURN NEW;
  END IF;

  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF OLD.estado_verificacion = 'verificado' THEN
    RAISE EXCEPTION 'la verificacion aprobada solo la cambia un administrador';
  END IF;

  IF NEW.estado_verificacion NOT IN ('pendiente', 'en_revision') THEN
    RAISE EXCEPTION 'solo un administrador puede aprobar o rechazar la verificacion';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_proteger_verificacion ON public.trabajadores;
CREATE TRIGGER trabajadores_proteger_verificacion
  BEFORE UPDATE OF estado_verificacion ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.proteger_verificacion_profesional();

INSERT INTO storage.buckets (id, name, public)
VALUES ('verificacion-profesional', 'verificacion-profesional', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS verificacion_select_propio ON storage.objects;
CREATE POLICY verificacion_select_propio ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verificacion-profesional'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

DROP POLICY IF EXISTS verificacion_insert_propio ON storage.objects;
CREATE POLICY verificacion_insert_propio ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'verificacion-profesional'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS verificacion_update_propio ON storage.objects;
CREATE POLICY verificacion_update_propio ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'verificacion-profesional'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'mensajes'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.mensajes;
    END IF;
  END IF;
EXCEPTION
  WHEN undefined_object OR insufficient_privilege THEN
    NULL;
END $$;

COMMIT;
