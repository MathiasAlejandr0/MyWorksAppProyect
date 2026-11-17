-- Encuesta de testing: las 10 respuestas SUS dejan de ser un arreglo
-- (encuestas_testing.sus smallint[]) y pasan a una fila por ítem en
-- encuesta_testing_respuestas(id_encuesta, item, valor). El puntaje SUS se
-- calcula en una vista y en una función; ya no se guarda.

CREATE TABLE public.encuesta_testing_respuestas (
  id_encuesta uuid NOT NULL REFERENCES public.encuestas_testing (id) ON DELETE CASCADE,
  item smallint NOT NULL CHECK (item BETWEEN 1 AND 10),
  valor smallint NOT NULL CHECK (valor BETWEEN 1 AND 5),
  PRIMARY KEY (id_encuesta, item)
);

COMMENT ON TABLE public.encuesta_testing_respuestas IS
  'Respuesta a cada ítem SUS (1 a 10) en escala 1 (muy en desacuerdo) a 5 (muy de acuerdo). Ítems impares positivos, pares negativos.';

INSERT INTO public.encuesta_testing_respuestas (id_encuesta, item, valor)
SELECT e.id, (u.ord)::smallint, u.valor
FROM public.encuestas_testing e
CROSS JOIN LATERAL unnest(e.sus) WITH ORDINALITY AS u(valor, ord);

ALTER TABLE public.encuestas_testing DROP CONSTRAINT IF EXISTS encuestas_testing_sus_check;
ALTER TABLE public.encuestas_testing DROP COLUMN sus_puntaje;
ALTER TABLE public.encuestas_testing DROP COLUMN sus;

-- Puntaje SUS (0 a 100, Brooke 1996): impares valor-1, pares 5-valor, suma x 2,5.
-- Solo existe si la encuesta tiene los 10 ítems.
CREATE OR REPLACE FUNCTION public.sus_puntaje(p_id_encuesta uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO 'public'
AS $$
  SELECT round(sum(CASE WHEN r.item % 2 = 1 THEN r.valor - 1 ELSE 5 - r.valor END) * 2.5, 1)
  FROM public.encuesta_testing_respuestas r
  WHERE r.id_encuesta = p_id_encuesta
  HAVING count(*) = 10;
$$;

CREATE VIEW public.encuestas_testing_con_puntaje
WITH (security_invoker = true) AS
SELECT e.*, public.sus_puntaje(e.id) AS sus_puntaje
FROM public.encuestas_testing e;

COMMENT ON VIEW public.encuestas_testing_con_puntaje IS
  'Encuestas de testing con el puntaje SUS calculado desde encuesta_testing_respuestas.';

-- Acceso: las respuestas las lee solo un administrador; se escriben solo con la función.
ALTER TABLE public.encuesta_testing_respuestas ENABLE ROW LEVEL SECURITY;
CREATE POLICY encuesta_respuestas_leer_admin ON public.encuesta_testing_respuestas
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

REVOKE ALL ON public.encuesta_testing_respuestas FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.encuesta_testing_respuestas TO authenticated;
GRANT ALL ON public.encuesta_testing_respuestas TO service_role;

REVOKE ALL ON public.encuestas_testing_con_puntaje FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.encuestas_testing_con_puntaje TO authenticated;
GRANT ALL ON public.encuestas_testing_con_puntaje TO service_role;

REVOKE ALL ON FUNCTION public.sus_puntaje(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sus_puntaje(uuid) TO authenticated, service_role;

-- Ya no se inserta directo en encuestas_testing: la encuesta y sus 10 respuestas
-- entran juntas por enviar_encuesta_testing (todo o nada, con validación).
DROP POLICY IF EXISTS encuestas_testing_insertar ON public.encuestas_testing;
REVOKE INSERT ON public.encuestas_testing FROM PUBLIC, anon, authenticated;
REVOKE INSERT (plataforma, rol, tarea_completada, satisfaccion, que_funciono, que_mejorar, version_app)
  ON public.encuestas_testing FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.enviar_encuesta_testing(
  p_plataforma text,
  p_rol text,
  p_tarea_completada text,
  p_satisfaccion smallint,
  p_sus smallint[],
  p_que_funciono text DEFAULT NULL,
  p_que_mejorar text DEFAULT NULL,
  p_version_app text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_id uuid := gen_random_uuid();
  i int;
BEGIN
  IF p_sus IS NULL OR array_ndims(p_sus) <> 1 OR array_length(p_sus, 1) <> 10 THEN
    RAISE EXCEPTION 'la encuesta SUS necesita exactamente 10 respuestas';
  END IF;
  FOR i IN 1..10 LOOP
    IF p_sus[i] IS NULL OR p_sus[i] NOT BETWEEN 1 AND 5 THEN
      RAISE EXCEPTION 'cada respuesta SUS debe estar entre 1 y 5';
    END IF;
  END LOOP;

  INSERT INTO public.encuestas_testing (
    id, id_usuario, plataforma, rol, tarea_completada, satisfaccion,
    que_funciono, que_mejorar, version_app
  ) VALUES (
    v_id, (SELECT auth.uid()), p_plataforma, p_rol, p_tarea_completada, p_satisfaccion,
    p_que_funciono, p_que_mejorar, p_version_app
  );

  INSERT INTO public.encuesta_testing_respuestas (id_encuesta, item, valor)
  SELECT v_id, n::smallint, p_sus[n] FROM generate_series(1, 10) AS n;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enviar_encuesta_testing(text, text, text, smallint, smallint[], text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.enviar_encuesta_testing(text, text, text, smallint, smallint[], text, text, text)
  TO anon, authenticated, service_role;
