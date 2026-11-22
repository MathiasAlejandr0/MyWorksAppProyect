-- Valores de bitácora para defensa, pruebas y respaldos.
-- Van solos: Postgres no permite usar el valor en la misma transacción.
-- No aplicar en el proyecto remoto.

ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'activar_defensa';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'desactivar_defensa';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'bloquear_ip';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'desbloquear_ip';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'ejecutar_prueba';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'crear_respaldo';
ALTER TYPE public.accion_auditoria_consola ADD VALUE IF NOT EXISTS 'restaurar_respaldo';
