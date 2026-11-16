-- Una disputa o un acuerdo solo tienen sentido mientras el trabajo sigue en
-- marcha. Un trabajo completado, cancelado, expirado o con inasistencia ya
-- liberó o devolvió el pago: abrir ahí una disputa retenía la calificación
-- sin poder actuar sobre el dinero (la app además mostraba los botones de
-- acuerdo en un trabajo cerrado).
--
-- abrir_disputa: misma firma y cuerpo, más la validación del estado.
-- proponer_acuerdo / responder_acuerdo: el cierre incluye expirado y
-- no_asistio, y responder también lo valida (antes solo proponer).
-- No borra ni modifica filas existentes.

BEGIN;

CREATE OR REPLACE FUNCTION public.trabajo_admite_disputa(p_estado text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT p_estado IN (
    'aceptado',
    'en_camino',
    'en_curso',
    'esperando_aprobacion_cliente',
    'pausado_orden_cambio'
  );
$$;
REVOKE ALL ON FUNCTION public.trabajo_admite_disputa(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.trabajo_admite_disputa(text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.abrir_disputa(p_id text, p_id_trabajo text, p_motivo text, p_descripcion text)
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

COMMIT;
