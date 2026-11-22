-- Valor de bitácora para la revisión humana de la cola de moderación.
-- Va solo: Postgres no deja usar el valor en la misma transacción.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'revisar_moderacion';
