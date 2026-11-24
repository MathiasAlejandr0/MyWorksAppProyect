-- Revoca EXECUTE de PUBLIC y anon en las 6 RPC de disputas/evidencia y en
-- registrar_evidencia_video_captura. Conserva authenticated y service_role,
-- que es lo que usan la app, la consola y (en las demás RPC del cron) el
-- jobid 8 / la Edge Function soporte-automatico.
--
-- El cron mwa_resolver_soporte_automatico ejecuta
-- public.encadenar_soporte_automatico() como postgres; esa función y las que
-- llama soporte-automatico (resolver_soporte_automatico, soporte_secret_valido,
-- aplicar_cierre_disputa, marcar_reembolso_automatico) ya no tienen EXECUTE
-- para anon y no se tocan aquí.
--
-- Índice en fotos_trabajo(hash_sha256). La tabla es pequeña (~17 filas, < 1 MB),
-- así que se crea en la transacción de la migración. CREATE INDEX CONCURRENTLY
-- no corre dentro de una transacción y no haría falta aquí.

REVOKE EXECUTE ON FUNCTION public.pedir_nonce_evidencia(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pedir_nonce_evidencia(text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.registrar_evidencia_captura(text, text, text, text, text, bytea, double precision, double precision, text, timestamptz, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_evidencia_captura(text, text, text, text, text, bytea, double precision, double precision, text, timestamptz, text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.registrar_evidencia_web(text, text, text, text, bytea, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_evidencia_web(text, text, text, text, bytea, text, jsonb) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.apelar_disputa(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.apelar_disputa(text, text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.consola_disputas_abiertas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_disputas_abiertas() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.evidencia_disputa(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.evidencia_disputa(text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.registrar_evidencia_video_captura(text, text, text, text, double precision, double precision, text, integer, integer, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_evidencia_video_captura(text, text, text, text, double precision, double precision, text, integer, integer, timestamptz) TO authenticated, service_role;

CREATE INDEX IF NOT EXISTS fotos_trabajo_hash_sha256_idx
  ON public.fotos_trabajo (hash_sha256)
  WHERE hash_sha256 IS NOT NULL;
