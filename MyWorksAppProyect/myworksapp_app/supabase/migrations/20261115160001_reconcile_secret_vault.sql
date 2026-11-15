-- webpay-reconcile valida el header del cron contra el secreto de Vault, sin
-- tener que copiar RECONCILE_CRON_SECRET a los secretos de la función (plan free).
-- Solo service_role puede ejecutarla; nunca devuelve el secreto.
BEGIN;

CREATE OR REPLACE FUNCTION public.reconcile_secret_valido(p_secret text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_esperado text;
BEGIN
  IF p_secret IS NULL OR length(p_secret) = 0 THEN
    RETURN false;
  END IF;

  SELECT ds.decrypted_secret
    INTO v_esperado
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'mwa_reconcile_cron_secret'
  LIMIT 1;

  IF v_esperado IS NULL OR length(v_esperado) = 0 THEN
    RETURN false;
  END IF;

  -- Se comparan resúmenes de largo fijo para no filtrar el largo ni el prefijo.
  RETURN pg_catalog.sha256(pg_catalog.convert_to(p_secret, 'UTF8'))
       = pg_catalog.sha256(pg_catalog.convert_to(v_esperado, 'UTF8'));
END;
$$;

REVOKE ALL ON FUNCTION public.reconcile_secret_valido(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_secret_valido(text) FROM anon;
REVOKE ALL ON FUNCTION public.reconcile_secret_valido(text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.reconcile_secret_valido(text) TO service_role;

COMMIT;
