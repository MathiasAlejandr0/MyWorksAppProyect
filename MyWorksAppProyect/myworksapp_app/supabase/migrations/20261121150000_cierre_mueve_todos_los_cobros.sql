-- Un acuerdo solo vale con una disputa abierta.
-- Cerrar por silencio, acuerdo o disputa mueve principal, orden de cambio y horas extra.
-- Un sí adelantado no sobrevive: al abrir la disputa se descarta.

CREATE OR REPLACE FUNCTION public.liberar_cobros_retenidos(
  p_trabajo_id text,
  p_operador text,
  p_notas text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_pago public.pagos%ROWTYPE;
  v_n integer := 0;
BEGIN
  FOR v_pago IN
    SELECT *
    FROM public.pagos
    WHERE id_trabajo::text = p_trabajo_id
      AND tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
      AND estado IN ('retenido', 'autorizado')
    ORDER BY creado_en
    FOR UPDATE
  LOOP
    PERFORM public.marcar_pago_liberado(
      v_pago.id,
      COALESCE(NULLIF(btrim(p_operador), ''), 'sistema'),
      left(replace(v_pago.id::text, '-', ''), 16),
      left(btrim(COALESCE(p_notas, 'Cierre')), 240)
    );
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.liberar_cobros_retenidos(text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.liberar_cobros_retenidos(text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION public.liberar_trabajo_sistema(
  p_trabajo_id text,
  p_nota text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos%ROWTYPE;
  v_nota text := left(btrim(COALESCE(p_nota, 'Cierre automático')), 240);
BEGIN
  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_job.estado = 'cancelado' THEN
    RAISE EXCEPTION 'el trabajo esta cancelado';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo::text = v_job.id::text
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'hay una disputa activa';
  END IF;

  PERFORM public.liberar_cobros_retenidos(v_job.id::text, 'sistema', v_nota);
  IF EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_job.id::text
      AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
      AND p.estado IN ('retenido', 'autorizado', 'pendiente')
  ) THEN
    RAISE EXCEPTION 'quedo un cobro sin liberar';
  END IF;

  IF v_job.estado <> 'completado' THEN
    UPDATE public.trabajos
    SET
      estado = 'completado',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.aplicar_cierre_disputa(
  p_disputa_id text,
  p_operador text,
  p_decision text,
  p_resolucion text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_disputa public.disputas%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_resolucion text;
  v_origen text := CASE
    WHEN p_operador IN ('sistema', 'acuerdo') THEN p_operador
    ELSE 'admin'
  END;
  v_resuelta uuid := CASE
    WHEN p_operador IS NULL OR p_operador IN ('sistema', 'acuerdo') THEN NULL
    ELSE p_operador::uuid
  END;
  v_hay_pago boolean;
BEGIN
  IF p_decision NOT IN ('liberar', 'reembolsar') THEN
    RAISE EXCEPTION 'decision invalida';
  END IF;

  SELECT * INTO v_disputa
  FROM public.disputas
  WHERE id::text = p_disputa_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'disputa no encontrada';
  END IF;
  IF v_disputa.estado = 'resuelta' THEN
    RETURN jsonb_build_object('already', true, 'decision', p_decision);
  END IF;
  IF NOT public.disputa_esta_activa(v_disputa.estado) THEN
    RAISE EXCEPTION 'la disputa no esta abierta';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = v_disputa.id_trabajo::text
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  v_resolucion := NULLIF(trim(COALESCE(p_resolucion, '')), '');
  IF v_resolucion IS NULL THEN
    RAISE EXCEPTION 'resolucion requerida';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_job.id::text
      AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
  ) INTO v_hay_pago;

  IF p_decision = 'liberar' THEN
    IF v_job.estado = 'cancelado' THEN
      RAISE EXCEPTION 'el trabajo esta cancelado; no se liberan fondos';
    END IF;
    IF NOT v_hay_pago THEN
      RAISE EXCEPTION 'no hay pago para liberar';
    END IF;
    PERFORM public.liberar_cobros_retenidos(v_job.id::text, COALESCE(p_operador, 'sistema'), v_resolucion);
    IF NOT EXISTS (
      SELECT 1
      FROM public.pagos p
      WHERE p.id_trabajo::text = v_job.id::text
        AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
        AND p.estado = 'liberado'
    ) THEN
      RAISE EXCEPTION 'no hay pago para liberar';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.pagos p
      WHERE p.id_trabajo::text = v_job.id::text
        AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
        AND p.estado IN ('retenido', 'autorizado', 'pendiente')
    ) THEN
      RAISE EXCEPTION 'quedo un cobro sin liberar';
    END IF;
    IF v_job.estado <> 'completado' THEN
      UPDATE public.trabajos
      SET
        estado = 'completado',
        actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      WHERE id = v_job.id;
    END IF;
  ELSE
    IF NOT v_hay_pago THEN
      RAISE EXCEPTION 'no hay pago para reembolsar';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.pagos p
      WHERE p.id_trabajo::text = v_job.id::text
        AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
        AND p.estado = 'liberado'
    ) THEN
      RAISE EXCEPTION 'el pago ya fue liberado al profesional';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.pagos p
      WHERE p.id_trabajo::text = v_job.id::text
        AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
        AND p.estado IN ('retenido', 'autorizado', 'pendiente')
    ) THEN
      RAISE EXCEPTION 'devuelve todos los cobros a la tarjeta antes de cerrar';
    END IF;

    UPDATE public.trabajos SET
      estado = 'cancelado',
      estado_pago = 'reembolsado',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

  UPDATE public.acuerdos_trabajo
  SET estado = 'rechazado'
  WHERE id_trabajo::text = v_job.id::text
    AND estado IN ('pendiente', 'confirmado');

  UPDATE public.disputas SET
    estado = 'resuelta',
    origen = v_origen,
    resolucion = v_resolucion,
    resuelta_por = v_resuelta,
    resuelta_en = now(),
    actualizado_en = now()
  WHERE id = v_disputa.id;

  RETURN jsonb_build_object(
    'dispute_id', v_disputa.id,
    'decision', p_decision,
    'estado', 'resuelta',
    'origen', v_origen
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.abrir_disputa(
  p_id text,
  p_id_trabajo text,
  p_motivo text,
  p_descripcion text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_clase record;
  v_estado_trabajo text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_id IS NULL OR btrim(p_id) = '' OR p_id_trabajo IS NULL OR btrim(p_id_trabajo) = '' THEN
    RAISE EXCEPTION 'Faltan el identificador y el trabajo';
  END IF;
  IF NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF btrim(COALESCE(p_motivo, '')) = '' THEN
    RAISE EXCEPTION 'El motivo es requerido';
  END IF;

  SELECT t.estado INTO v_estado_trabajo
  FROM public.trabajos t
  WHERE t.id::text = btrim(p_id_trabajo);
  IF NOT public.trabajo_admite_disputa(v_estado_trabajo) THEN
    RAISE EXCEPTION 'El trabajo ya está cerrado: no admite disputas';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo = p_id_trabajo
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'Ya existe una disputa abierta para este trabajo';
  END IF;

  -- Un acuerdo pulsado antes de la disputa no puede cerrar el pago después.
  UPDATE public.acuerdos_trabajo
  SET estado = 'rechazado'
  WHERE id_trabajo::text = btrim(p_id_trabajo)
    AND estado IN ('pendiente', 'confirmado');

  SELECT * INTO v_clase
  FROM public.clasificar_disputa(btrim(p_id_trabajo), p_motivo)
  LIMIT 1;

  INSERT INTO public.disputas (
    id, id_trabajo, abierta_por, motivo, descripcion, estado,
    origen, decision_sugerida, motivo_regla, vence_en,
    creado_en, actualizado_en
  ) VALUES (
    btrim(p_id),
    btrim(p_id_trabajo),
    v_uid,
    left(btrim(p_motivo), 80),
    NULLIF(left(btrim(COALESCE(p_descripcion, '')), 2000), ''),
    COALESCE(v_clase.estado, 'requiere_humano'),
    CASE WHEN COALESCE(v_clase.decision, 'humano') = 'humano' THEN 'admin' ELSE 'sistema' END,
    COALESCE(v_clase.decision, 'humano'),
    COALESCE(v_clase.regla, 'revision_manual'),
    v_clase.vence,
    now(),
    now()
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.proponer_acuerdo(p_id text, p_id_trabajo text, p_tipo text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_job public.trabajos%ROWTYPE;
  v_tipo text := lower(btrim(COALESCE(p_tipo, '')));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_tipo NOT IN ('rehacer', 'aceptar', 'anular') THEN
    RAISE EXCEPTION 'tipo de acuerdo invalido';
  END IF;
  IF NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_job.estado IN ('completado', 'cancelado', 'expirado', 'no_asistio') THEN
    RAISE EXCEPTION 'el trabajo ya esta cerrado';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = p_id_trabajo
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'solo se acuerda con una disputa abierta';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.acuerdos_trabajo a
    WHERE a.id_trabajo::text = p_id_trabajo
      AND a.estado = 'pendiente'
  ) THEN
    RAISE EXCEPTION 'ya hay un acuerdo pendiente';
  END IF;

  INSERT INTO public.acuerdos_trabajo (
    id, id_trabajo, tipo, propuesto_por, acepta_cliente, acepta_trabajador, estado
  ) VALUES (
    btrim(p_id),
    btrim(p_id_trabajo),
    v_tipo,
    v_uid,
    CASE WHEN v_job.id_usuario = v_uid THEN true ELSE NULL END,
    CASE WHEN v_job.id_trabajador = v_uid THEN true ELSE NULL END,
    'pendiente'
  );

  RETURN jsonb_build_object('id', btrim(p_id), 'tipo', v_tipo, 'estado', 'pendiente');
END;
$function$;

CREATE OR REPLACE FUNCTION public.responder_acuerdo(p_id text, p_acepta boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.acuerdos_trabajo%ROWTYPE;
  v_job public.trabajos%ROWTYPE;
  v_estado text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_row
  FROM public.acuerdos_trabajo
  WHERE id::text = btrim(p_id)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'acuerdo no encontrado';
  END IF;
  IF v_row.estado <> 'pendiente' THEN
    RAISE EXCEPTION 'el acuerdo ya fue respondido';
  END IF;
  IF NOT public.es_parte_trabajo(v_row.id_trabajo::text) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_job FROM public.trabajos WHERE id::text = v_row.id_trabajo::text;
  IF NOT EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = v_job.id::text
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'solo se acuerda con una disputa abierta';
  END IF;
  IF v_uid = v_row.propuesto_por THEN
    RAISE EXCEPTION 'la otra parte debe responder';
  END IF;
  IF COALESCE(p_acepta, false)
     AND v_job.estado IN ('completado', 'cancelado', 'expirado', 'no_asistio') THEN
    RAISE EXCEPTION 'el trabajo ya esta cerrado';
  END IF;

  IF NOT COALESCE(p_acepta, false) THEN
    UPDATE public.acuerdos_trabajo
    SET estado = 'rechazado'
    WHERE id = v_row.id;
    RETURN jsonb_build_object('id', v_row.id, 'estado', 'rechazado');
  END IF;

  UPDATE public.acuerdos_trabajo
  SET
    acepta_cliente = CASE WHEN v_job.id_usuario = v_uid THEN true ELSE acepta_cliente END,
    acepta_trabajador = CASE WHEN v_job.id_trabajador = v_uid THEN true ELSE acepta_trabajador END
  WHERE id = v_row.id
  RETURNING * INTO v_row;

  v_estado := CASE
    WHEN v_row.acepta_cliente IS TRUE AND v_row.acepta_trabajador IS TRUE THEN 'confirmado'
    ELSE 'pendiente'
  END;

  UPDATE public.acuerdos_trabajo
  SET estado = v_estado
  WHERE id = v_row.id;

  RETURN jsonb_build_object('id', v_row.id, 'estado', v_estado, 'tipo', v_row.tipo);
END;
$function$;

CREATE OR REPLACE FUNCTION public.resolver_soporte_automatico()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_silencio_horas', 48)::integer, 1);
  v_job record;
  v_acuerdo public.acuerdos_trabajo%ROWTYPE;
  v_disputa public.disputas%ROWTYPE;
  v_liberados integer := 0;
  v_acuerdos integer := 0;
  v_reembolsos jsonb := '[]'::jsonb;
  v_marca text := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US');
BEGIN
  FOR v_job IN
    SELECT t.id::text AS id
    FROM public.trabajos t
    WHERE t.estado = 'esperando_aprobacion_cliente'
      AND public.trabajo_tiene_evidencia(t.id::text)
      AND NOT EXISTS (
        SELECT 1 FROM public.disputas d
        WHERE d.id_trabajo::text = t.id::text
          AND public.disputa_esta_activa(d.estado)
      )
      AND NULLIF(t.actualizado_en, '')::timestamptz
        < now() - make_interval(hours => v_horas)
  LOOP
    BEGIN
      PERFORM public.liberar_trabajo_sistema(
        v_job.id,
        'El cliente no respondió dentro del plazo. El pago queda liberado.'
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'silencio %: %', v_job.id, SQLERRM;
    END;
  END LOOP;

  FOR v_acuerdo IN
    SELECT *
    FROM public.acuerdos_trabajo
    WHERE estado = 'confirmado'
    FOR UPDATE
  LOOP
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM public.disputas d
        WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
          AND public.disputa_esta_activa(d.estado)
      ) THEN
        UPDATE public.acuerdos_trabajo
        SET estado = 'rechazado'
        WHERE id = v_acuerdo.id;
      ELSIF v_acuerdo.tipo = 'aceptar' THEN
        PERFORM public.aplicar_cierre_disputa(
          (
            SELECT d.id::text FROM public.disputas d
            WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
              AND public.disputa_esta_activa(d.estado)
            ORDER BY d.creado_en DESC
            LIMIT 1
          ),
          'acuerdo',
          'liberar',
          'Las dos partes aceptaron la entrega.'
        );
        UPDATE public.acuerdos_trabajo
        SET estado = 'aplicado', aplicado_en = now()
        WHERE id = v_acuerdo.id;
        v_acuerdos := v_acuerdos + 1;
      ELSIF v_acuerdo.tipo = 'rehacer' THEN
        PERFORM set_config('mwa.pin_inicio_ok', '1', true);
        UPDATE public.trabajos
        SET estado = 'en_curso', actualizado_en = v_marca
        WHERE id::text = v_acuerdo.id_trabajo::text
          AND estado <> 'cancelado';
        UPDATE public.disputas
        SET
          estado = 'resuelta',
          origen = 'acuerdo',
          resolucion = 'Acordaron rehacer el trabajo. El pago sigue retenido.',
          resuelta_en = now(),
          actualizado_en = now()
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND public.disputa_esta_activa(estado);
        UPDATE public.acuerdos_trabajo
        SET estado = 'aplicado', aplicado_en = now()
        WHERE id = v_acuerdo.id;
        v_acuerdos := v_acuerdos + 1;
      ELSIF v_acuerdo.tipo = 'anular' THEN
        IF EXISTS (
          SELECT 1
          FROM public.pagos p
          WHERE p.id_trabajo::text = v_acuerdo.id_trabajo::text
            AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
            AND p.estado IN ('retenido', 'autorizado', 'pendiente')
        ) THEN
          INSERT INTO public.disputas (
            id, id_trabajo, abierta_por, motivo, descripcion, estado,
            origen, decision_sugerida, motivo_regla, creado_en, actualizado_en
          )
          SELECT
            'acuerdo-' || v_acuerdo.id,
            v_acuerdo.id_trabajo,
            v_acuerdo.propuesto_por,
            'acuerdo',
            'Las dos partes anularon el trabajo.',
            'reembolso_pendiente',
            'acuerdo',
            'reembolsar',
            'acuerdo_anular',
            now(),
            now()
          WHERE NOT EXISTS (
            SELECT 1 FROM public.disputas d
            WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
              AND public.disputa_esta_activa(d.estado)
          );
          UPDATE public.disputas
          SET estado = 'reembolso_pendiente',
              decision_sugerida = 'reembolsar',
              motivo_regla = 'acuerdo_anular',
              origen = 'acuerdo',
              actualizado_en = now()
          WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(estado)
            AND estado <> 'reembolso_pendiente';
        ELSE
          UPDATE public.trabajos
          SET estado = 'cancelado',
              estado_pago = CASE
                WHEN EXISTS (
                  SELECT 1 FROM public.pagos p
                  WHERE p.id_trabajo::text = v_acuerdo.id_trabajo::text
                    AND p.tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
                    AND p.estado = 'reembolsado'
                ) THEN 'reembolsado'
                ELSE estado_pago
              END,
              actualizado_en = v_marca
          WHERE id::text = v_acuerdo.id_trabajo::text;
          UPDATE public.disputas
          SET estado = 'resuelta',
              origen = 'acuerdo',
              resolucion = 'Las dos partes anularon el trabajo.',
              resuelta_en = now(),
              actualizado_en = now()
          WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(estado);
        END IF;
        UPDATE public.acuerdos_trabajo
        SET estado = 'aplicado', aplicado_en = now()
        WHERE id = v_acuerdo.id;
        v_acuerdos := v_acuerdos + 1;
      END IF;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'acuerdo %: %', v_acuerdo.id, SQLERRM;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'liberar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    BEGIN
      PERFORM public.aplicar_cierre_disputa(
        v_disputa.id::text,
        'sistema',
        'liberar',
        'Cierre automático: ' || COALESCE(v_disputa.motivo_regla, 'plazo')
      );
      v_liberados := v_liberados + 1;
    EXCEPTION WHEN others THEN
      UPDATE public.disputas
      SET estado = 'requiere_humano',
          decision_sugerida = 'humano',
          motivo_regla = 'fallo_cierre_automatico',
          actualizado_en = now()
      WHERE id = v_disputa.id;
    END;
  END LOOP;

  FOR v_disputa IN
    SELECT *
    FROM public.disputas
    WHERE estado = 'abierta'
      AND decision_sugerida = 'reembolsar'
      AND vence_en IS NOT NULL
      AND vence_en <= now()
    FOR UPDATE
  LOOP
    UPDATE public.disputas
    SET estado = 'reembolso_pendiente', actualizado_en = now()
    WHERE id = v_disputa.id;
  END LOOP;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'disputa_id', d.id,
    'pago_id', p.id,
    'resolucion', 'Devolución automática: ' || COALESCE(d.motivo_regla, 'plazo')
  )), '[]'::jsonb)
  INTO v_reembolsos
  FROM public.disputas d
  LEFT JOIN LATERAL (
    SELECT id
    FROM public.pagos
    WHERE id_trabajo::text = d.id_trabajo::text
      AND tipo_pago IN ('principal', 'orden_cambio', 'horas_extra')
      AND estado IN ('retenido', 'autorizado', 'pendiente')
    ORDER BY creado_en
  ) p ON true
  WHERE d.estado = 'reembolso_pendiente';

  RETURN jsonb_build_object(
    'liberados', v_liberados,
    'acuerdos', v_acuerdos,
    'reembolsos', COALESCE(v_reembolsos, '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.liberar_trabajo_sistema(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.liberar_trabajo_sistema(text, text) TO service_role;
REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) TO service_role;
REVOKE ALL ON FUNCTION public.resolver_soporte_automatico() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolver_soporte_automatico() TO service_role;
