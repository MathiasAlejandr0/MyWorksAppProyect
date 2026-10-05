-- Cierra cobros que el cliente abandona en Webpay y publica qué oficios
-- tienen un profesional disponible. Idempotente.
-- Aplicar después de 20261008000005.
-- pg_cron se programa si la extensión existe. Si no, el dueño corre
-- SELECT public.expirar_pagos_abandonados(); cada 10 minutos.

BEGIN;

CREATE OR REPLACE FUNCTION public.texto_a_timestamptz(p_valor text)
RETURNS timestamptz
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF p_valor IS NULL OR btrim(p_valor) = '' THEN
    RETURN NULL;
  END IF;
  RETURN p_valor::timestamptz;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.texto_a_timestamptz(text) FROM PUBLIC, anon, authenticated;

-- Invitados sin cobro retenido, liberado ni autorizado, pasadas 24 h.
CREATE OR REPLACE FUNCTION public.limpiar_invitados_sin_pago()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  n integer := 0;
  r record;
BEGIN
  FOR r IN
    SELECT u.id
    FROM auth.users u
    WHERE COALESCE(u.raw_user_meta_data->>'guest_checkout', '') IN ('true', '1')
      AND u.created_at < now() - interval '24 hours'
      AND NOT EXISTS (
        SELECT 1
        FROM public.trabajos t
        JOIN public.pagos p ON p.id_trabajo::text = t.id::text
        WHERE t.id_usuario::text = u.id::text
          AND p.estado IN ('retenido', 'autorizado', 'liberado')
      )
  LOOP
    BEGIN
      DELETE FROM public.pagos p
      USING public.trabajos t
      WHERE p.id_trabajo::text = t.id::text
        AND t.id_usuario::text = r.id::text
        AND p.estado IN ('pendiente', 'anulado', 'fallido');

      DELETE FROM public.trabajos t
      WHERE t.id_usuario::text = r.id::text
        AND t.estado IN ('esperando_pago', 'cancelado')
        AND NOT EXISTS (
          SELECT 1
          FROM public.pagos p
          WHERE p.id_trabajo::text = t.id::text
            AND p.estado IN ('retenido', 'autorizado', 'liberado')
        );

      DELETE FROM public.perfiles WHERE id::text = r.id::text;
      DELETE FROM auth.users WHERE id = r.id;
      n := n + 1;
    EXCEPTION
      WHEN others THEN
        NULL;
    END;
  END LOOP;
  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.limpiar_invitados_sin_pago() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.limpiar_invitados_sin_pago() TO service_role;
REVOKE EXECUTE ON FUNCTION public.limpiar_invitados_sin_pago() FROM anon, authenticated;

-- Pedidos en esperando_pago de más de 30 minutos, sin garantía, pasan a cancelado.
-- El pago pendiente queda anulado. No toca retenido, autorizado ni liberado.
CREATE OR REPLACE FUNCTION public.expirar_pagos_abandonados()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  n integer := 0;
  v_guests integer := 0;
  r record;
  v_marca text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
BEGIN
  FOR r IN
    SELECT t.id::text AS id_trabajo
    FROM public.trabajos t
    WHERE t.estado = 'esperando_pago'
      AND NOT EXISTS (
        SELECT 1
        FROM public.pagos p
        WHERE p.id_trabajo::text = t.id::text
          AND p.estado IN ('retenido', 'liberado', 'autorizado')
      )
      AND COALESCE(
        (
          SELECT max(public.texto_a_timestamptz(p.creado_en))
          FROM public.pagos p
          WHERE p.id_trabajo::text = t.id::text
            AND p.estado = 'pendiente'
        ),
        public.texto_a_timestamptz(t.creado_en)
      ) < now() - interval '30 minutes'
  LOOP
    UPDATE public.pagos p
    SET estado = 'anulado',
        actualizado_en = v_marca
    WHERE p.id_trabajo::text = r.id_trabajo
      AND p.estado = 'pendiente';

    UPDATE public.trabajos t
    SET estado = 'cancelado',
        actualizado_en = v_marca
    WHERE t.id::text = r.id_trabajo
      AND t.estado = 'esperando_pago';

    IF FOUND THEN
      n := n + 1;
    END IF;
  END LOOP;

  v_guests := public.limpiar_invitados_sin_pago();
  RETURN n + COALESCE(v_guests, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.expirar_pagos_abandonados() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expirar_pagos_abandonados() TO service_role;
REVOKE EXECUTE ON FUNCTION public.expirar_pagos_abandonados() FROM anon, authenticated;

-- Oficios que el catálogo puede mostrar: hay alguien disponible y con precio.
CREATE OR REPLACE FUNCTION public.categorias_con_disponibles()
RETURNS SETOF text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT t.categoria_servicio
  FROM public.trabajadores t
  WHERE COALESCE(t.disponible, 0) = 1
    AND COALESCE(t.precios_configurados, 0) = 1
    AND t.categoria_servicio IS NOT NULL
    AND length(btrim(t.categoria_servicio)) > 0;
$$;

REVOKE ALL ON FUNCTION public.categorias_con_disponibles() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.categorias_con_disponibles() TO anon, authenticated;

DO $cron$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION
    WHEN others THEN
      RAISE NOTICE 'pg_cron no se pudo crear: %', SQLERRM;
  END;

  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (
      SELECT 1 FROM cron.job WHERE jobname = 'mwa_expirar_pagos_abandonados'
    ) THEN
      PERFORM cron.unschedule('mwa_expirar_pagos_abandonados');
    END IF;
    PERFORM cron.schedule(
      'mwa_expirar_pagos_abandonados',
      '*/10 * * * *',
      'SELECT public.expirar_pagos_abandonados();'
    );
  ELSE
    RAISE NOTICE 'pg_cron no está instalado. Programa SELECT public.expirar_pagos_abandonados(); cada 10 minutos.';
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'No se programó pg_cron: %. Usa SELECT public.expirar_pagos_abandonados(); cada 10 minutos.', SQLERRM;
END;
$cron$;

COMMIT;
