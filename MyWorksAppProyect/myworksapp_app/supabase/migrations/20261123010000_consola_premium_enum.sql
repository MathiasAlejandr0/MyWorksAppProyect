-- Acciones nuevas de la consola premium.
-- No aplicar en el proyecto remoto wxqrfcqifkfgawrnqmnj.
-- Este archivo solo agrega valores al enum. Las funciones que los usan
-- están en la migración siguiente, porque PostgreSQL no deja usar un
-- valor nuevo en la misma transacción en la que se crea.

ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'asignar_disputa';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'prioridad_disputa';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'reasignar_pedido';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'marcar_resena';
