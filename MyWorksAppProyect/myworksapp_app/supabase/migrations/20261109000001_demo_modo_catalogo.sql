-- El selector de login de la demo lee listar_cuentas_demo_acceso, que
-- exige app_config.demo_modo = 1.
--
-- NEUTRALIZADA (13 nov 2026): la versión original forzaba demo_modo = '1'
-- y con eso listar_cuentas_demo_acceso expone a anon los correos de las
-- cuentas demo. En producción el interruptor está en 0 a propósito.
-- Ahora solo asegura que la clave exista, sin pisar el valor actual.
-- Para encender la demo en un entorno local:
--   UPDATE public.app_config SET valor = '1' WHERE clave = 'demo_modo';
-- Idempotente.

BEGIN;

INSERT INTO public.app_config (clave, valor)
VALUES ('demo_modo', '0')
ON CONFLICT (clave) DO NOTHING;

COMMIT;
