-- Encuesta de testing (UAT) para quienes prueban MyWorksApp.
--
-- Antes la opinión quedaba solo en el teléfono (SharedPreferences) y nadie la
-- podía juntar para el informe. Ahora se guarda en la base:
--   * cualquiera puede responder (anon o con sesión), sin poder leer nada;
--   * solo un administrador (is_admin) puede leer las respuestas;
--   * nadie puede editar ni borrar desde la API.
-- Cuestionario: SUS de 10 ítems (escala 1 a 5), satisfacción general 1 a 5,
-- si pudo completar la tarea y dos comentarios abiertos. El puntaje SUS
-- (0 a 100) lo calcula la base con la fórmula estándar de Brooke (1996).

CREATE TABLE IF NOT EXISTS public.encuestas_testing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  id_usuario uuid DEFAULT auth.uid() REFERENCES public.perfiles(id) ON DELETE SET NULL,
  plataforma text NOT NULL CHECK (plataforma IN ('web', 'app', 'escritorio')),
  rol text NOT NULL CHECK (rol IN ('visitante', 'cliente', 'profesional', 'administrador')),
  tarea_completada text NOT NULL CHECK (tarea_completada IN ('si', 'parcial', 'no')),
  satisfaccion smallint NOT NULL CHECK (satisfaccion BETWEEN 1 AND 5),
  sus smallint[] NOT NULL CHECK (
    array_length(sus, 1) = 10
    AND array_ndims(sus) = 1
    AND 1 <= ALL (sus)
    AND 5 >= ALL (sus)
  ),
  sus_puntaje numeric(5, 1) GENERATED ALWAYS AS (
    (
      (sus[1] - 1) + (5 - sus[2]) + (sus[3] - 1) + (5 - sus[4]) + (sus[5] - 1)
      + (5 - sus[6]) + (sus[7] - 1) + (5 - sus[8]) + (sus[9] - 1) + (5 - sus[10])
    ) * 2.5
  ) STORED,
  que_funciono text CHECK (que_funciono IS NULL OR char_length(que_funciono) <= 1000),
  que_mejorar text CHECK (que_mejorar IS NULL OR char_length(que_mejorar) <= 1000),
  version_app text CHECK (version_app IS NULL OR char_length(version_app) <= 40)
);

COMMENT ON TABLE public.encuestas_testing IS
  'Respuestas de la encuesta de testing (UAT): SUS de 10 ítems, satisfacción 1-5, tarea completada y comentarios. Inserta cualquiera; lee solo admin.';
COMMENT ON COLUMN public.encuestas_testing.sus IS
  'Respuestas SUS 1..10 en escala 1 (muy en desacuerdo) a 5 (muy de acuerdo). Ítems impares positivos, pares negativos.';
COMMENT ON COLUMN public.encuestas_testing.sus_puntaje IS
  'Puntaje SUS 0-100 (Brooke, 1996). 68 es el promedio de referencia.';

CREATE INDEX IF NOT EXISTS encuestas_testing_creado_en_idx
  ON public.encuestas_testing (creado_en DESC);
CREATE INDEX IF NOT EXISTS encuestas_testing_id_usuario_idx
  ON public.encuestas_testing (id_usuario);

ALTER TABLE public.encuestas_testing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS encuestas_testing_insertar ON public.encuestas_testing;
CREATE POLICY encuestas_testing_insertar ON public.encuestas_testing
  FOR INSERT TO anon, authenticated
  WITH CHECK (id_usuario IS NULL OR id_usuario = (SELECT auth.uid()));

DROP POLICY IF EXISTS encuestas_testing_leer_admin ON public.encuestas_testing;
CREATE POLICY encuestas_testing_leer_admin ON public.encuestas_testing
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

REVOKE ALL ON public.encuestas_testing FROM PUBLIC, anon, authenticated;
GRANT INSERT (
  plataforma, rol, tarea_completada, satisfaccion, sus,
  que_funciono, que_mejorar, version_app
) ON public.encuestas_testing TO anon, authenticated;
GRANT SELECT ON public.encuestas_testing TO authenticated;
GRANT ALL ON public.encuestas_testing TO service_role;


