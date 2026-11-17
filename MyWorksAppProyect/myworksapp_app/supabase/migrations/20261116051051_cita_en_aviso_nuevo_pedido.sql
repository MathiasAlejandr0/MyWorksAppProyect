-- Cita al pedir el trabajo (pedido de Mathias, 16-nov).
--
-- 1) El aviso «Nuevo pedido» que recibe el profesional no decía para cuándo
--    era la visita: solo el servicio y el monto. Ahora incluye el día y la
--    hora de la cita en hora de Chile (America/Santiago), igual que los avisos
--    de reprogramación («del 18/11 16:00»).
-- 2) _notificar_reprogramacion guardaba creado_en en UTC pero sin «Z». La app
--    lee un texto sin zona como hora local del teléfono, así que la campana
--    mostraba esos avisos 3 horas corridos. Ahora se escribe con «Z», como ya
--    lo hace trabajos_notificar_nuevo_pedido.
--
-- Solo cambia funciones. No toca filas existentes.

CREATE OR REPLACE FUNCTION public.trabajos_notificar_nuevo_pedido()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_monto numeric;
  v_cliente text;
  v_cuerpo text;
  v_cita timestamptz;
BEGIN
  IF NEW.id_trabajador IS NULL OR NEW.estado IS DISTINCT FROM 'pendiente' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.estado IS NOT DISTINCT FROM NEW.estado THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.estado IS DISTINCT FROM 'esperando_pago' THEN
    RETURN NEW;
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.notificaciones
    WHERE id_relacionado = NEW.id
      AND id_usuario = NEW.id_trabajador
      AND tipo = 'new_job'
  ) THEN
    RETURN NEW;
  END IF;

  SELECT p.monto INTO v_monto
  FROM public.pagos p
  WHERE p.id_trabajo = NEW.id
    AND p.estado IN ('retenido', 'pagado_por_confirmar')
  ORDER BY p.creado_en DESC NULLS LAST
  LIMIT 1;

  SELECT NULLIF(trim(split_part(coalesce(pf.nombre, ''), ' ', 1)), '')
  INTO v_cliente
  FROM public.perfiles pf
  WHERE pf.id = NEW.id_usuario;

  v_cita := public.texto_a_timestamptz(NEW.fecha_programada::text);

  v_cuerpo := coalesce(v_cliente, 'Un cliente') || ' te pidió '
    || coalesce(nullif(trim(NEW.descripcion), ''), 'un servicio')
    || CASE WHEN v_cita IS NOT NULL
         THEN ' para el ' || to_char(v_cita AT TIME ZONE 'America/Santiago', 'DD/MM')
              || ' a las ' || to_char(v_cita AT TIME ZONE 'America/Santiago', 'HH24:MI')
              || ' (hora de Chile)'
         ELSE ''
       END
    || CASE WHEN v_monto IS NOT NULL AND v_monto > 0
         THEN '. Oferta: $' || replace(to_char(v_monto, 'FM999G999G999'), ',', '.')
              || ' (pago retenido).'
         ELSE '.'
       END
    || ' Acéptalo o recházalo desde Pendientes.';

  INSERT INTO public.notificaciones (
    id, id_usuario, tipo, titulo, cuerpo, id_relacionado, leido, creado_en
  ) VALUES (
    gen_random_uuid()::text,
    NEW.id_trabajador,
    'new_job',
    'Nuevo pedido',
    v_cuerpo,
    NEW.id,
    0,
    -- Con «Z»: la app y la web la leen como UTC y muestran «Hace N min» bien.
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Un aviso nunca debe bloquear el cobro ni el cambio de estado.
  RAISE WARNING 'trabajos_notificar_nuevo_pedido: %', SQLERRM;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trabajos_notificar_nuevo_pedido() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public._notificar_reprogramacion(
  p_destino uuid,
  p_id_trabajo text,
  p_titulo text,
  p_cuerpo text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  INSERT INTO public.notificaciones (
    id, id_usuario, tipo, titulo, cuerpo, id_relacionado, leido, creado_en
  )
  SELECT
    gen_random_uuid()::text,
    p_destino,
    'job_rescheduled',
    p_titulo,
    p_cuerpo,
    p_id_trabajo,
    0,
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  WHERE p_destino IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION public._notificar_reprogramacion(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public._notificar_reprogramacion(uuid, text, text, text) TO service_role;


