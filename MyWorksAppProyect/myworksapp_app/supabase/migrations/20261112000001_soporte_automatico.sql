-- Soporte automático.
-- El silencio, el acuerdo de las dos partes y las reglas cierran el caso.
-- Conducta, reincidencia, monto alto y lo que no calza quedan en requiere_humano.
-- El reembolso a la tarjeta lo completa la función soporte-automatico:
-- esta migración solo deja el caso en reembolso_pendiente.

BEGIN;

INSERT INTO public.app_config (clave, valor)
VALUES
  ('soporte_plazo_silencio_horas', '48'),
  ('soporte_plazo_disputa_horas', '24'),
  ('soporte_monto_max_auto', '80000'),
  ('soporte_reincidencia_max', '1')
ON CONFLICT (clave) DO NOTHING;

ALTER TABLE public.disputas
  ADD COLUMN IF NOT EXISTS origen text NOT NULL DEFAULT 'admin',
  ADD COLUMN IF NOT EXISTS decision_sugerida text,
  ADD COLUMN IF NOT EXISTS motivo_regla text,
  ADD COLUMN IF NOT EXISTS vence_en timestamptz;

ALTER TABLE public.disputas
  DROP CONSTRAINT IF EXISTS disputas_origen_chk;
ALTER TABLE public.disputas
  ADD CONSTRAINT disputas_origen_chk
  CHECK (origen IN ('sistema', 'acuerdo', 'admin'));

ALTER TABLE public.disputas
  DROP CONSTRAINT IF EXISTS disputas_decision_chk;
ALTER TABLE public.disputas
  ADD CONSTRAINT disputas_decision_chk
  CHECK (
    decision_sugerida IS NULL
    OR decision_sugerida IN ('liberar', 'reembolsar', 'humano')
  );

CREATE TABLE IF NOT EXISTS public.disputa_mensajes (
  id text PRIMARY KEY,
  id_disputa text NOT NULL REFERENCES public.disputas (id) ON DELETE CASCADE,
  id_autor uuid REFERENCES public.perfiles (id),
  cuerpo text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.acuerdos_trabajo (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES public.trabajos (id) ON DELETE CASCADE,
  tipo text NOT NULL,
  propuesto_por uuid NOT NULL REFERENCES public.perfiles (id),
  acepta_cliente boolean,
  acepta_trabajador boolean,
  estado text NOT NULL DEFAULT 'pendiente',
  creado_en timestamptz NOT NULL DEFAULT now(),
  aplicado_en timestamptz,
  CONSTRAINT acuerdos_tipo_chk CHECK (tipo IN ('rehacer', 'aceptar', 'anular')),
  CONSTRAINT acuerdos_estado_chk CHECK (estado IN ('pendiente', 'confirmado', 'rechazado', 'aplicado'))
);

CREATE UNIQUE INDEX IF NOT EXISTS acuerdos_trabajo_pendiente_uidx
  ON public.acuerdos_trabajo (id_trabajo)
  WHERE estado = 'pendiente';

ALTER TABLE public.disputa_mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.acuerdos_trabajo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS disputa_mensajes_select ON public.disputa_mensajes;
CREATE POLICY disputa_mensajes_select ON public.disputa_mensajes
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.disputas d
      WHERE d.id::text = id_disputa::text
        AND public.es_parte_trabajo(d.id_trabajo::text)
    )
  );

DROP POLICY IF EXISTS acuerdos_trabajo_select ON public.acuerdos_trabajo;
CREATE POLICY acuerdos_trabajo_select ON public.acuerdos_trabajo
  FOR SELECT TO authenticated
  USING (public.es_parte_trabajo(id_trabajo::text) OR public.is_admin());

GRANT SELECT ON public.disputa_mensajes, public.acuerdos_trabajo TO authenticated;

CREATE OR REPLACE FUNCTION public.disputa_esta_activa(p_estado text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(p_estado, '') IN (
    'abierta', 'en_revision', 'requiere_humano', 'reembolso_pendiente'
  );
$$;

CREATE OR REPLACE FUNCTION public.soporte_numero(p_clave text, p_default numeric)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(
    (
      SELECT NULLIF(btrim(c.valor), '')::numeric
      FROM public.app_config c
      WHERE c.clave = p_clave
    ),
    p_default
  );
$$;

CREATE OR REPLACE FUNCTION public.clasificar_disputa(
  p_trabajo_id text,
  p_motivo text
)
RETURNS TABLE (decision text, regla text, estado text, vence timestamptz)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_motivo text := lower(btrim(COALESCE(p_motivo, '')));
  v_monto numeric := 0;
  v_prev integer := 0;
  v_max numeric := public.soporte_numero('soporte_monto_max_auto', 80000);
  v_reinc integer := public.soporte_numero('soporte_reincidencia_max', 1)::integer;
  v_horas integer := GREATEST(public.soporte_numero('soporte_plazo_disputa_horas', 24)::integer, 1);
  v_worker uuid;
  v_verificado boolean := false;
  v_evidencia boolean := false;
  v_llego boolean := false;
BEGIN
  SELECT t.id_trabajador INTO v_worker
  FROM public.trabajos t
  WHERE t.id::text = p_trabajo_id;

  SELECT COALESCE(p.monto, 0) INTO v_monto
  FROM public.pagos p
  WHERE p.id_trabajo::text = p_trabajo_id
    AND p.tipo_pago = 'principal'
  ORDER BY p.creado_en DESC
  LIMIT 1;

  IF v_worker IS NOT NULL THEN
    SELECT COUNT(*) INTO v_prev
    FROM public.disputas d
    JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
    WHERE t.id_trabajador = v_worker
      AND d.estado = 'resuelta';

    SELECT COALESCE(w.estado_verificacion, '') = 'verificado'
    INTO v_verificado
    FROM public.trabajadores w
    WHERE w.id_usuario = v_worker;
  END IF;

  v_evidencia := public.trabajo_tiene_evidencia(p_trabajo_id);
  v_llego := EXISTS (
    SELECT 1
    FROM public.ubicacion_en_vivo u
    WHERE u.id_trabajo::text = p_trabajo_id
  );

  IF v_motivo = 'conducta' THEN
    decision := 'humano';
    regla := 'conducta';
    estado := 'requiere_humano';
    vence := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_prev >= v_reinc THEN
    decision := 'humano';
    regla := 'reincidencia';
    estado := 'requiere_humano';
    vence := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_monto > v_max THEN
    decision := 'humano';
    regla := 'monto_alto';
    estado := 'requiere_humano';
    vence := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  IF NOT v_evidencia AND NOT v_llego THEN
    decision := 'reembolsar';
    regla := 'sin_llegada_ni_evidencia';
    estado := 'abierta';
    vence := now() + make_interval(hours => v_horas);
    RETURN NEXT;
    RETURN;
  END IF;

  IF v_evidencia AND v_verificado THEN
    decision := 'liberar';
    regla := 'primer_reclamo_con_evidencia';
    estado := 'abierta';
    vence := now() + make_interval(hours => v_horas);
    RETURN NEXT;
    RETURN;
  END IF;

  decision := 'humano';
  regla := 'revision_manual';
  estado := 'requiere_humano';
  vence := NULL;
  RETURN NEXT;
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
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clase record;
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
  IF EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo = p_id_trabajo
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'Ya existe una disputa abierta para este trabajo';
  END IF;

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
$$;

CREATE OR REPLACE FUNCTION public.comentar_disputa(
  p_id text,
  p_comentario text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_row public.disputas%ROWTYPE;
  v_nota text := left(btrim(COALESCE(p_comentario, '')), 1000);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_nota = '' THEN
    RAISE EXCEPTION 'El comentario es requerido';
  END IF;

  SELECT * INTO v_row
  FROM public.disputas
  WHERE id::text = btrim(p_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  IF NOT public.es_parte_trabajo(v_row.id_trabajo::text) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF NOT public.disputa_esta_activa(v_row.estado) THEN
    RAISE EXCEPTION 'La disputa ya fue resuelta';
  END IF;

  INSERT INTO public.disputa_mensajes (id, id_disputa, id_autor, cuerpo)
  VALUES (gen_random_uuid()::text, v_row.id, v_uid, v_nota);

  UPDATE public.disputas
  SET descripcion = left(
        concat_ws(
          E'\n',
          NULLIF(v_row.descripcion, ''),
          concat(to_char(now(), 'DD/MM HH24:MI'), ' · ', v_nota)
        ),
        4000
      ),
      actualizado_en = now()
  WHERE id::text = v_row.id::text;
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
  v_pago public.pagos%ROWTYPE;
  v_resolucion text;
  v_origen text := CASE
    WHEN p_operador IN ('sistema', 'acuerdo') THEN p_operador
    ELSE 'admin'
  END;
  v_resuelta uuid := CASE
    WHEN p_operador IS NULL OR p_operador IN ('sistema', 'acuerdo') THEN NULL
    ELSE p_operador::uuid
  END;
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

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  v_resolucion := NULLIF(trim(COALESCE(p_resolucion, '')), '');
  IF v_resolucion IS NULL THEN
    RAISE EXCEPTION 'resolucion requerida';
  END IF;

  IF p_decision = 'liberar' THEN
    IF v_job.estado = 'cancelado' THEN
      RAISE EXCEPTION 'el trabajo esta cancelado; no se liberan fondos';
    END IF;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para liberar';
    END IF;
    IF v_pago.estado IN ('retenido', 'autorizado') THEN
      PERFORM public.marcar_pago_liberado(
        v_pago.id,
        COALESCE(p_operador, 'sistema'),
        'DISPUTA-' || left(replace(v_disputa.id::text, '-', ''), 16),
        v_resolucion
      );
    ELSIF v_pago.estado <> 'liberado' THEN
      RAISE EXCEPTION 'Pago no liberable (estado %)', v_pago.estado;
    END IF;

    IF v_job.estado <> 'completado' THEN
      UPDATE public.trabajos
      SET
        estado = 'completado',
        actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
      WHERE id = v_job.id;
    END IF;
  ELSE
    IF NOT FOUND THEN
      RAISE EXCEPTION 'no hay pago para reembolsar';
    END IF;
    IF v_pago.estado = 'liberado' THEN
      RAISE EXCEPTION 'el pago ya fue liberado al profesional';
    END IF;
    IF v_pago.estado <> 'reembolsado' THEN
      IF v_pago.estado NOT IN ('retenido', 'autorizado', 'pendiente') THEN
        RAISE EXCEPTION 'Pago no reembolsable (estado %)', v_pago.estado;
      END IF;
      UPDATE public.pagos SET
        estado = 'reembolsado',
        reembolsado_en = now(),
        actualizado_en = now()
      WHERE id = v_pago.id;
    END IF;

    UPDATE public.trabajos SET
      estado = 'cancelado',
      estado_pago = 'reembolsado',
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
    WHERE id = v_job.id;
  END IF;

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
  v_pago public.pagos%ROWTYPE;
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

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_job.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado', 'liberado')
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND AND v_pago.estado IN ('retenido', 'autorizado') THEN
    PERFORM public.marcar_pago_liberado(
      v_pago.id,
      'sistema',
      'PLAZO-' || left(replace(v_job.id::text, '-', ''), 16),
      v_nota
    );
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

CREATE OR REPLACE FUNCTION public.proponer_acuerdo(
  p_id text,
  p_id_trabajo text,
  p_tipo text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
  IF v_job.estado IN ('completado', 'cancelado') THEN
    RAISE EXCEPTION 'el trabajo ya esta cerrado';
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
$$;

CREATE OR REPLACE FUNCTION public.responder_acuerdo(
  p_id text,
  p_acepta boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
  IF v_uid = v_row.propuesto_por THEN
    RAISE EXCEPTION 'la otra parte debe responder';
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
$$;

CREATE OR REPLACE FUNCTION public.acuerdo_pendiente(p_id_trabajo text)
RETURNS TABLE (
  id text,
  tipo text,
  estado text,
  acepta_cliente boolean,
  acepta_trabajador boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT public.es_parte_trabajo(p_id_trabajo) THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT a.id, a.tipo, a.estado, a.acepta_cliente, a.acepta_trabajador
  FROM public.acuerdos_trabajo a
  WHERE a.id_trabajo::text = p_id_trabajo
    AND a.estado = 'pendiente'
  ORDER BY a.creado_en DESC
  LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION public.evidencia_disputa(p_id_disputa text)
RETURNS TABLE (id text, imagen_base64 text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT f.id::text, encode(f.imagen_webp, 'base64')
  FROM public.fotos_trabajo f
  JOIN public.disputas d ON d.id_trabajo::text = f.id_trabajo::text
  WHERE d.id::text = btrim(p_id_disputa)
    AND f.imagen_webp IS NOT NULL
    AND octet_length(f.imagen_webp) >= 12
  ORDER BY f.creado_en
  LIMIT 4;
END;
$$;

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
  v_pago_id text;
  v_liberados integer := 0;
  v_acuerdos integer := 0;
  v_reembolsos jsonb := '[]'::jsonb;
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
      IF v_acuerdo.tipo = 'aceptar' THEN
        IF EXISTS (
          SELECT 1 FROM public.disputas d
          WHERE d.id_trabajo::text = v_acuerdo.id_trabajo::text
            AND public.disputa_esta_activa(d.estado)
        ) THEN
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
        ELSE
          PERFORM public.liberar_trabajo_sistema(
            v_acuerdo.id_trabajo::text,
            'Las dos partes aceptaron la entrega.'
          );
        END IF;
      ELSIF v_acuerdo.tipo = 'rehacer' THEN
        UPDATE public.trabajos
        SET
          estado = 'en_curso',
          actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
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
      ELSIF v_acuerdo.tipo = 'anular' THEN
        SELECT id INTO v_pago_id
        FROM public.pagos
        WHERE id_trabajo::text = v_acuerdo.id_trabajo::text
          AND tipo_pago = 'principal'
          AND estado IN ('retenido', 'autorizado', 'pendiente')
        ORDER BY creado_en DESC
        LIMIT 1;
        IF v_pago_id IS NULL THEN
          UPDATE public.trabajos
          SET estado = 'cancelado',
              actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
          WHERE id::text = v_acuerdo.id_trabajo::text;
        ELSE
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
        END IF;
      END IF;

      UPDATE public.acuerdos_trabajo
      SET estado = 'aplicado', aplicado_en = now()
      WHERE id = v_acuerdo.id;
      v_acuerdos := v_acuerdos + 1;
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
  JOIN LATERAL (
    SELECT id
    FROM public.pagos
    WHERE id_trabajo::text = d.id_trabajo::text
      AND tipo_pago = 'principal'
      AND estado IN ('retenido', 'autorizado', 'pendiente', 'reembolsado')
    ORDER BY creado_en DESC
    LIMIT 1
  ) p ON true
  WHERE d.estado = 'reembolso_pendiente';

  RETURN jsonb_build_object(
    'liberados', v_liberados,
    'acuerdos', v_acuerdos,
    'reembolsos', COALESCE(v_reembolsos, '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.disputa_esta_activa(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.soporte_numero(text, numeric) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.clasificar_disputa(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.liberar_trabajo_sistema(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.resolver_soporte_automatico() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.evidencia_disputa(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.abrir_disputa(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.comentar_disputa(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.proponer_acuerdo(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.responder_acuerdo(text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.acuerdo_pendiente(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.evidencia_disputa(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolver_soporte_automatico() TO service_role;
GRANT EXECUTE ON FUNCTION public.aplicar_cierre_disputa(text, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.liberar_trabajo_sistema(text, text) TO service_role;

-- El bloqueo de una disputa activa incluye los estados nuevos.
CREATE OR REPLACE FUNCTION public.transicionar_trabajo(
  p_trabajo_id text,
  p_nuevo_estado text,
  p_pin text DEFAULT NULL::text
)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.trabajos;
  v_expected_pin text;
  v_mode text;
  v_disputa boolean;
  v_admin boolean;
  v_es_cliente boolean;
  v_es_pro boolean;
  v_retenido boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;

  v_admin := public.is_admin();
  v_es_cliente := v_row.id_usuario::text = auth.uid()::text;
  v_es_pro := v_row.id_trabajador IS NOT NULL
    AND v_row.id_trabajador::text = auth.uid()::text;

  IF NOT (v_admin OR v_es_cliente OR v_es_pro) THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;

  v_disputa := EXISTS (
    SELECT 1
    FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND public.disputa_esta_activa(d.estado)
  );

  IF v_disputa AND NOT v_admin THEN
    RAISE EXCEPTION 'hay una disputa abierta; solo atencion al cliente puede continuar';
  END IF;

  IF v_disputa AND p_nuevo_estado = 'cancelado' THEN
    RAISE EXCEPTION 'hay una disputa abierta; resuelvela para liberar o devolver el pago';
  END IF;

  IF NOT v_admin AND p_nuevo_estado = 'completado' THEN
    RAISE EXCEPTION 'recibe conforme el trabajo para liberar el pago';
  END IF;

  IF p_nuevo_estado = 'cancelado'
     AND v_row.estado = 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'si no estas conforme, abre una disputa; el pago sigue retenido';
  END IF;

  v_retenido := EXISTS (
    SELECT 1
    FROM public.pagos p
    WHERE p.id_trabajo::text = v_row.id::text
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado')
  );

  IF p_nuevo_estado = 'cancelado' AND v_retenido THEN
    RAISE EXCEPTION 'devuelve el pago a la tarjeta antes de cancelar';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');

  IF NOT v_admin THEN
    IF NOT public.transicion_trabajo_permitida(
      v_row.estado::text,
      p_nuevo_estado::text,
      v_mode
    ) THEN
      RAISE EXCEPTION 'transicion no permitida: % -> %', v_row.estado, p_nuevo_estado;
    END IF;

    IF p_nuevo_estado IN (
         'aceptado', 'en_camino', 'esperando_aprobacion_cliente',
         'pausado_orden_cambio', 'no_asistio'
       ) AND NOT v_es_pro THEN
      RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'en_curso'
       AND NOT v_es_pro
       AND NOT (v_es_cliente AND v_row.estado = 'pausado_orden_cambio') THEN
      RAISE EXCEPTION 'solo el profesional del trabajo puede pasar a en_curso';
    END IF;

    IF p_nuevo_estado IN ('cotizacion_seleccionada', 'esperando_pago')
       AND NOT v_es_cliente THEN
      RAISE EXCEPTION 'solo el cliente del trabajo puede pasar a %', p_nuevo_estado;
    END IF;

    IF p_nuevo_estado = 'no_asistio' AND v_retenido THEN
      RAISE EXCEPTION 'hay un pago retenido; abre una disputa para cerrar por inasistencia';
    END IF;

    IF v_mode <> 'legado'
       AND (
         p_nuevo_estado IN ('aceptado', 'en_curso', 'completado')
         OR (
           v_row.estado = 'esperando_pago'
           AND p_nuevo_estado = 'pendiente'
         )
       )
       AND NOT v_retenido THEN
      RAISE EXCEPTION 'se requiere un pago en garantia antes de %', p_nuevo_estado;
    END IF;
  END IF;

  BEGIN
    v_expected_pin := NULLIF(trim(v_row.metadatos_servicio::jsonb ->> 'pin'), '');
  EXCEPTION WHEN others THEN
    v_expected_pin := NULL;
  END;

  IF NOT v_admin
     AND v_expected_pin IS NOT NULL
     AND p_nuevo_estado IN ('en_curso', 'completado') THEN
    IF p_pin IS NULL OR trim(p_pin) <> v_expected_pin THEN
      RAISE EXCEPTION 'pin incorrecto o requerido';
    END IF;
  END IF;

  IF p_pin IS NOT NULL
     AND length(trim(p_pin)) > 0
     AND v_expected_pin IS NULL THEN
    RAISE EXCEPTION 'pin requerido pero no configurado en el trabajo';
  END IF;

  UPDATE public.trabajos
  SET
    estado = p_nuevo_estado,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cerrar_trabajo_conforme(p_trabajo_id text)
RETURNS public.trabajos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_row public.trabajos;
  v_pago public.pagos%ROWTYPE;
  v_mode text;
  v_tier boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_row
  FROM public.trabajos
  WHERE id::text = p_trabajo_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trabajo no encontrado';
  END IF;
  IF v_row.id_usuario::text <> auth.uid()::text THEN
    RAISE EXCEPTION 'solo el cliente puede recibir conforme';
  END IF;
  IF v_row.estado <> 'esperando_aprobacion_cliente' THEN
    RAISE EXCEPTION 'el trabajo no espera tu conformidad';
  END IF;
  IF NOT public.trabajo_tiene_evidencia(v_row.id::text) THEN
    RAISE EXCEPTION 'falta la evidencia del especialista; el pago sigue retenido';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.disputas d
    WHERE d.id_trabajo::text = v_row.id::text
      AND public.disputa_esta_activa(d.estado)
  ) THEN
    RAISE EXCEPTION 'hay una disputa abierta; el pago sigue retenido';
  END IF;

  v_mode := COALESCE(v_row.modalidad_cobro::text, 'legado');
  BEGIN
    v_tier := COALESCE(v_row.metadatos_servicio::jsonb ->> 'request_type', '')
      = 'worker_tier_invitation';
  EXCEPTION WHEN others THEN
    v_tier := false;
  END;

  SELECT * INTO v_pago
  FROM public.pagos
  WHERE id_trabajo::text = v_row.id::text
    AND tipo_pago = 'principal'
    AND estado IN ('retenido', 'autorizado', 'liberado')
  ORDER BY creado_en DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND AND (v_mode <> 'legado' OR v_tier) THEN
    RAISE EXCEPTION 'no hay un pago en garantia para liberar';
  END IF;

  IF FOUND AND v_pago.estado IN ('retenido', 'autorizado') THEN
    PERFORM public.marcar_pago_liberado(
      v_pago.id,
      auth.uid()::text,
      'CONFORME-' || left(replace(v_row.id::text, '-', ''), 16),
      'Liberado al recibir conforme el trabajo'
    );
  END IF;

  UPDATE public.trabajos
  SET
    estado = 'completado',
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = p_trabajo_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron')
     OR EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron') THEN
    BEGIN
      CREATE EXTENSION IF NOT EXISTS pg_cron;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'pg_cron no se pudo crear: %', SQLERRM;
    END;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'mwa_resolver_soporte_automatico') THEN
      PERFORM cron.unschedule('mwa_resolver_soporte_automatico');
    END IF;
    PERFORM cron.schedule(
      'mwa_resolver_soporte_automatico',
      '*/10 * * * *',
      'SELECT public.resolver_soporte_automatico()'
    );
  ELSE
    RAISE NOTICE 'pg_cron no está instalado. Programa SELECT public.resolver_soporte_automatico(); cada 10 minutos y la función soporte-automatico para devolver a la tarjeta.';
  END IF;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'No se programó el soporte automático: %', SQLERRM;
END;
$cron$;

COMMIT;
