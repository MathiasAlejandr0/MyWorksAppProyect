-- Afirmaciones de la migración 20261008000006.
-- Corre en una transacción que hace ROLLBACK: no deja filas de prueba.
-- Si algo falla, el bloque DO lanza y no aparece la línea OK.
-- Aplicar antes la migración. Luego este archivo en el SQL Editor.

BEGIN;

DO $$
DECLARE
  v_expirar text;
  v_limpiar text;
  v_categorias text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'expirar_pagos_abandonados'
  ) THEN
    RAISE EXCEPTION 'falta public.expirar_pagos_abandonados';
  END IF;

  v_expirar := pg_get_functiondef('public.expirar_pagos_abandonados()'::regprocedure);
  IF position('30 minutes' IN v_expirar) = 0
     OR position('cancelado' IN v_expirar) = 0
     OR position('anulado' IN v_expirar) = 0
     OR position('limpiar_invitados_sin_pago' IN v_expirar) = 0
     OR position('retenido' IN v_expirar) = 0
  THEN
    RAISE EXCEPTION 'expirar_pagos_abandonados no cierra esperando_pago a los 30 minutos';
  END IF;

  IF has_function_privilege('anon', 'public.expirar_pagos_abandonados()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.expirar_pagos_abandonados()', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'anon o authenticated pueden expirar pagos';
  END IF;

  v_limpiar := pg_get_functiondef('public.limpiar_invitados_sin_pago()'::regprocedure);
  IF position('24 hours' IN v_limpiar) = 0 THEN
    RAISE EXCEPTION 'limpiar_invitados_sin_pago no espera 24 horas';
  END IF;
  IF position('guest_checkout' IN v_limpiar) = 0
     OR position('retenido' IN v_limpiar) = 0
  THEN
    RAISE EXCEPTION 'limpiar_invitados_sin_pago borraría cuentas que sí pagaron';
  END IF;

  v_categorias := pg_get_functiondef('public.categorias_con_disponibles()'::regprocedure);
  IF position('disponible' IN v_categorias) = 0
     OR position('precios_configurados' IN v_categorias) = 0
  THEN
    RAISE EXCEPTION 'categorias_con_disponibles no mira disponibilidad y precio';
  END IF;

  IF NOT has_function_privilege('anon', 'public.categorias_con_disponibles()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.categorias_con_disponibles()', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'el catálogo no puede leer categorías con profesionales';
  END IF;
END $$;

ROLLBACK;

SELECT 'RLS 20261010 ok';
