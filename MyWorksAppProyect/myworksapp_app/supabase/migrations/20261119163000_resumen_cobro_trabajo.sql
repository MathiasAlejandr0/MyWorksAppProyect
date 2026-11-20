-- El catálogo público redondea la base del profesional a 2 decimales.
-- El cobro (monto_esperado_trabajo / recargo_traslado_clp) usa la coordenada
-- real. Esta lectura devuelve el mismo entero en CLP que acepta
-- crear_intencion_pago, sin entregar la coordenada.

CREATE OR REPLACE FUNCTION public.resumen_cobro_trabajo(p_id_trabajo text)
RETURNS TABLE (
  total_clp integer,
  tarifa_clp integer,
  traslado_clp integer,
  comision_clp integer,
  neto_clp integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job public.trabajos;
  v_worker public.trabajadores%ROWTYPE;
  v_total integer;
  v_traslado integer := 0;
  v_tarifa integer;
  v_fee integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'no autenticado';
  END IF;

  SELECT * INTO v_job
  FROM public.trabajos
  WHERE id::text = p_id_trabajo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trabajo no encontrado';
  END IF;

  IF v_job.id_usuario::text <> auth.uid()::text
     AND v_job.id_trabajador::text IS DISTINCT FROM auth.uid()::text
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'No puedes ver el cobro de este trabajo';
  END IF;

  v_total := round(public.monto_esperado_trabajo(v_job))::integer;

  IF v_job.id_cotizacion_seleccionada IS NULL
     AND COALESCE(v_job.modalidad_cobro, '') NOT IN ('cotizacion_abierta', 'cotizacion')
     AND v_job.id_trabajador IS NOT NULL THEN
    SELECT * INTO v_worker
    FROM public.trabajadores
    WHERE id_usuario::text = v_job.id_trabajador::text;
    IF FOUND THEN
      v_traslado := COALESCE(public.recargo_traslado_clp(
        v_worker.latitud_base,
        v_worker.longitud_base,
        v_job.latitud,
        v_job.longitud,
        v_worker.radio_servicio_km
      ), 0);
    END IF;
  END IF;

  v_tarifa := GREATEST(v_total - v_traslado, 0);
  v_fee := public.comision_servicio_clp(v_total);

  RETURN QUERY
  SELECT v_total, v_tarifa, v_traslado, v_fee, v_total - v_fee;
END;
$$;

COMMENT ON FUNCTION public.resumen_cobro_trabajo(text) IS
  'Total, tarifa, traslado, comisión y neto en CLP enteros. Igual que el monto que acepta el pago.';

REVOKE ALL ON FUNCTION public.resumen_cobro_trabajo(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resumen_cobro_trabajo(text) TO authenticated, service_role;
