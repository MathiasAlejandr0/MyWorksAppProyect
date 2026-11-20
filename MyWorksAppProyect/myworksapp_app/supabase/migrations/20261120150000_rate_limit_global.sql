-- Límite de tasa en Postgres, compartido por todas las instancias de las
-- Edge Functions. Solo service_role ejecuta la función. No hay políticas
-- para anon ni authenticated. No está aplicada.

BEGIN;

CREATE TABLE IF NOT EXISTS public.rate_limit_ventana (
  clave text PRIMARY KEY,
  conteo integer NOT NULL,
  vence_en timestamptz NOT NULL
);

COMMENT ON TABLE public.rate_limit_ventana IS
  'Contador de rate limit por clave (IP o correo). Lo escribe rate_limit_consumir.';

ALTER TABLE public.rate_limit_ventana ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.rate_limit_ventana FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.rate_limit_ventana TO service_role;

CREATE OR REPLACE FUNCTION public.rate_limit_consumir(
  p_clave text,
  p_max integer,
  p_ventana_segundos integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_ahora timestamptz := clock_timestamp();
  v_conteo integer;
  v_clave text := left(btrim(coalesce(p_clave, '')), 200);
BEGIN
  IF v_clave = '' OR p_max IS NULL OR p_max < 1
     OR p_ventana_segundos IS NULL OR p_ventana_segundos < 1 THEN
    RETURN false;
  END IF;

  INSERT INTO public.rate_limit_ventana AS fila (clave, conteo, vence_en)
  VALUES (v_clave, 1, v_ahora + make_interval(secs => p_ventana_segundos))
  ON CONFLICT (clave) DO UPDATE
    SET conteo = CASE
          WHEN fila.vence_en <= v_ahora THEN 1
          ELSE fila.conteo + 1
        END,
        vence_en = CASE
          WHEN fila.vence_en <= v_ahora THEN v_ahora + make_interval(secs => p_ventana_segundos)
          ELSE fila.vence_en
        END
  RETURNING conteo INTO v_conteo;

  RETURN v_conteo <= p_max;
END;
$$;

REVOKE ALL ON FUNCTION public.rate_limit_consumir(text, integer, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rate_limit_consumir(text, integer, integer) TO service_role;

COMMENT ON FUNCTION public.rate_limit_consumir(text, integer, integer) IS
  'true si la clave todavía cabe en la ventana. Falla cerrado si la clave o el tope no sirven.';

COMMIT;
