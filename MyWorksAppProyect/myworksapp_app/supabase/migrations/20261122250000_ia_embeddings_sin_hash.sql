-- El hash local no es un embedding: contaminaba la similitud.
-- Si gte-small no corre, la columna queda null y el texto sigue en la cola.
-- La búsqueda híbrida usa texto, distancia y nota mientras no haya vector real.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

BEGIN;

UPDATE public.trabajadores
SET embedding = NULL, embedding_origen = NULL
WHERE embedding_origen = 'hash';

UPDATE public.trabajos
SET embedding = NULL, embedding_origen = NULL
WHERE embedding_origen = 'hash';

ALTER TABLE public.trabajadores DROP CONSTRAINT IF EXISTS trabajadores_embedding_origen_chk;
ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_embedding_origen_chk
  CHECK (embedding_origen IS NULL OR embedding_origen = 'gte-small');

ALTER TABLE public.trabajos DROP CONSTRAINT IF EXISTS trabajos_embedding_origen_chk;
ALTER TABLE public.trabajos
  ADD CONSTRAINT trabajos_embedding_origen_chk
  CHECK (embedding_origen IS NULL OR embedding_origen = 'gte-small');

DROP FUNCTION IF EXISTS privado.embedding_hash(text);

CREATE OR REPLACE FUNCTION public.trabajadores_preparar_embedding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_texto text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.profesion IS NOT DISTINCT FROM OLD.profesion
     AND NEW.descripcion IS NOT DISTINCT FROM OLD.descripcion THEN
    RETURN NEW;
  END IF;
  v_texto := left(btrim(coalesce(NEW.profesion, '') || ' ' || coalesce(NEW.descripcion, '')), 2000);
  NEW.embedding := NULL;
  NEW.embedding_origen := NULL;
  IF v_texto <> '' THEN
    INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
    VALUES ('trabajadores', NEW.id_usuario::text, v_texto);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trabajos_preparar_embedding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_texto text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.descripcion IS NOT DISTINCT FROM OLD.descripcion THEN
    RETURN NEW;
  END IF;
  v_texto := left(btrim(coalesce(NEW.descripcion, '')), 2000);
  NEW.embedding := NULL;
  NEW.embedding_origen := NULL;
  IF v_texto <> '' THEN
    INSERT INTO public.ia_cola_embeddings (tabla, entidad_id, texto)
    VALUES ('trabajos', NEW.id::text, v_texto);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.ia_guardar_embedding(
  p_tabla text,
  p_id text,
  p_vector text,
  p_origen text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v extensions.vector;
BEGIN
  IF coalesce(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_tabla NOT IN ('trabajadores', 'trabajos') THEN
    RAISE EXCEPTION 'tabla no permitida';
  END IF;
  IF p_origen IS DISTINCT FROM 'gte-small' THEN
    RAISE EXCEPTION 'solo se acepta el embedding de gte-small';
  END IF;
  v := p_vector::extensions.vector;
  IF vector_dims(v) <> 384 THEN
    RAISE EXCEPTION 'el embedding tiene que tener 384 dimensiones';
  END IF;
  IF p_tabla = 'trabajadores' THEN
    UPDATE public.trabajadores
    SET embedding = v, embedding_origen = 'gte-small'
    WHERE id_usuario::text = btrim(p_id);
  ELSE
    UPDATE public.trabajos
    SET embedding = v, embedding_origen = 'gte-small'
    WHERE id::text = btrim(p_id);
  END IF;
  UPDATE public.ia_cola_embeddings
  SET estado = 'listo'
  WHERE tabla = p_tabla AND entidad_id = btrim(p_id) AND estado = 'pendiente';
END;
$$;

COMMENT ON FUNCTION public.buscar_profesionales_hibrido(text, double precision, double precision, text, extensions.vector, integer) IS
  'Mezcla coseno solo si el vector es de gte-small. Si no, usa texto, cercanía y nota. La app vuelve al catálogo si la RPC falla.';

COMMIT;
