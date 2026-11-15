-- Cobro Webpay ya capturado, trabajo todavía sin confirmar.
-- El reintento y el reembolso los hace la Edge Function webpay-reconcile.
-- pg_cron de este archivo solo sigue expirando pagos pendientes, y no toca
-- pagado_por_confirmar. No se aplica a la base viva en este PR.

BEGIN;

CREATE INDEX IF NOT EXISTS pagos_por_confirmar_idx
  ON public.pagos (estado)
  WHERE estado = 'pagado_por_confirmar';

-- No cancelar un pedido cuyo cobro ya fue capturado.
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
          AND p.estado IN (
            'retenido', 'liberado', 'autorizado', 'pagado_por_confirmar'
          )
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

REVOKE ALL ON FUNCTION public.expirar_pagos_abandonados() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.expirar_pagos_abandonados() TO service_role;

-- Idempotente: no cobra y no abre dos veces el mismo trabajo.
CREATE OR REPLACE FUNCTION public.confirmar_trabajo_tras_captura(p_id_pago text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
BEGIN
  IF COALESCE(auth.role(), '') <> 'service_role'
     AND NOT (auth.role() IS NULL AND auth.uid() IS NULL) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_pago FROM public.pagos WHERE id = p_id_pago FOR UPDATE;
  IF NOT FOUND THEN
    RETURN 'missing';
  END IF;
  IF v_pago.estado = 'retenido' OR v_pago.estado = 'liberado' THEN
    RETURN 'already';
  END IF;
  IF v_pago.estado <> 'pagado_por_confirmar' THEN
    RETURN 'skip';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_pago.id_trabajo FOR UPDATE;
  IF NOT FOUND THEN
    RETURN 'missing_job';
  END IF;

  IF v_job.estado = 'esperando_pago' THEN
    UPDATE public.trabajos
    SET estado = 'pendiente',
        estado_pago = 'retenido',
        actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id
      AND estado = 'esperando_pago';
  END IF;

  UPDATE public.pagos
  SET estado = 'retenido',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id = v_pago.id
    AND estado = 'pagado_por_confirmar';

  RETURN 'confirmed';
END;
$$;

REVOKE ALL ON FUNCTION public.confirmar_trabajo_tras_captura(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.confirmar_trabajo_tras_captura(text) TO service_role;

CREATE OR REPLACE FUNCTION public.marcar_reembolso_automatico(
  p_id_pago text,
  p_modo text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_estado text;
  v_marca text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
BEGIN
  IF COALESCE(auth.role(), '') <> 'service_role'
     AND NOT (auth.role() IS NULL AND auth.uid() IS NULL) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_modo NOT IN ('reembolso', 'sin_captura') THEN
    RAISE EXCEPTION 'modo inválido';
  END IF;

  SELECT * INTO v_pago FROM public.pagos WHERE id = p_id_pago FOR UPDATE;
  IF NOT FOUND THEN
    RETURN 'missing';
  END IF;
  IF v_pago.estado IN ('reembolsado', 'reembolsado_auto', 'fallido', 'liberado', 'retenido') THEN
    RETURN 'already';
  END IF;
  IF v_pago.estado <> 'pagado_por_confirmar' THEN
    RETURN 'skip';
  END IF;

  v_estado := CASE WHEN p_modo = 'reembolso' THEN 'reembolsado_auto' ELSE 'fallido' END;
  UPDATE public.pagos
  SET estado = v_estado,
      actualizado_en = v_marca
  WHERE id = v_pago.id
    AND estado = 'pagado_por_confirmar';

  SELECT * INTO v_job FROM public.trabajos WHERE id = v_pago.id_trabajo;
  IF FOUND THEN
    IF v_job.estado = 'esperando_pago' THEN
      UPDATE public.trabajos
      SET estado = 'cancelado',
          estado_pago = v_estado,
          actualizado_en = v_marca
      WHERE id = v_job.id
        AND estado = 'esperando_pago';
    END IF;

    INSERT INTO public.notificaciones (
    id, id_usuario, tipo, titulo, cuerpo, id_relacionado, leido, creado_en
  )
  SELECT
    gen_random_uuid()::text,
    parte,
    'pago_reembolsado',
    CASE WHEN p_modo = 'reembolso'
      THEN 'Cobro devuelto'
      ELSE 'Cobro no confirmado'
    END,
    CASE WHEN p_modo = 'reembolso'
      THEN 'No pudimos confirmar el trabajo y devolvimos el cobro a la tarjeta.'
      ELSE 'El cobro no quedó confirmado. El pedido se canceló sin un cargo vigente.'
    END,
    v_pago.id_trabajo,
    0,
    v_marca
  FROM (
    SELECT v_job.id_usuario::text AS parte
    UNION
    SELECT v_job.id_trabajador::text
  ) partes
    WHERE parte IS NOT NULL AND parte <> '';
  END IF;

  RETURN v_estado;
END;
$$;

REVOKE ALL ON FUNCTION public.marcar_reembolso_automatico(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.marcar_reembolso_automatico(text, text) TO service_role;

COMMIT;
