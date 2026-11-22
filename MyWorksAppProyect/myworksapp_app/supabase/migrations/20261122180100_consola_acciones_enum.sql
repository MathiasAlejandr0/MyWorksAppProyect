-- Valores nuevos de la bitácora. Van en su propia migración: Postgres no
-- deja usar un valor de enum en la misma transacción en que se agrega.
-- No aplicar en el proyecto remoto.

ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'responder_ticket';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'resolver_ticket';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'forzar_reset';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'bloquear_cuenta';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'umbral_seguridad';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'reconocer_incidente';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'editar_servicio';
