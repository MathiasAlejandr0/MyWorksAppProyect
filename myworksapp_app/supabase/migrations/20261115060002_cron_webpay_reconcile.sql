-- Documenta el cron que ya debe existir en vivo para reconciliar Webpay.
-- Idempotente. No contiene el valor del secreto: el job lee
-- vault.decrypted_secrets.name = 'mwa_reconcile_cron_secret', creado a mano.
-- webpay-reconcile acepta el header x-reconcile-secret y lo compara con
-- el secreto de entorno RECONCILE_CRON_SECRET.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
DECLARE
  r record;
BEGIN
  IF to_regclass('cron.job') IS NULL THEN
    RAISE EXCEPTION 'pg_cron no está disponible';
  END IF;
  FOR r IN
    SELECT jobid
    FROM cron.job
    WHERE jobname = 'mwa_webpay_reconcile'
  LOOP
    PERFORM cron.unschedule(r.jobid);
  END LOOP;
END $$;

SELECT cron.schedule(
  'mwa_webpay_reconcile',
  '*/5 * * * *',
  $cmd$
  SELECT net.http_post(
    url := 'https://wxqrfcqifkfgawrnqmnj.supabase.co/functions/v1/webpay-reconcile',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-reconcile-secret', (
        SELECT decrypted_secret
        FROM vault.decrypted_secrets
        WHERE name = 'mwa_reconcile_cron_secret'
        LIMIT 1
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $cmd$
);
