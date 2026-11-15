-- Origen web validado (http://localhost:5173, allowlist) para que webpay-commit
-- vuelva al sitio aunque WEBPAY_WEB_RETURN_URL no esté en los secretos.
-- Lo escribe el service role. El cliente no actualiza pagos.

BEGIN;

ALTER TABLE public.pagos
  ADD COLUMN IF NOT EXISTS origen_retorno text;

COMMENT ON COLUMN public.pagos.origen_retorno IS
  'Origen del navegador ya contrastado con la allowlist. webpay-commit redirige ahí.';

COMMIT;
