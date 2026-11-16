-- E2E 16-nov: el profesional no recibía ningún aviso cuando le llegaba un
-- pedido pagado. La web (con sesión, invitado y Oneclick) y la app crean el
-- trabajo en 'esperando_pago' y el cobro lo pasa a 'pendiente', pero nadie
-- insertaba una fila en notificaciones: la campana quedaba vacía y tampoco
-- salía el push (send-push escucha los INSERT en notificaciones).
--
-- Arreglo en la base, para que valga para todos los canales: cuando un trabajo
-- con profesional asignado queda 'pendiente' (insert directo o salida de
-- 'esperando_pago'), se avisa al profesional con el monto retenido.
BEGIN;

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

  v_cuerpo := coalesce(v_cliente, 'Un cliente') || ' te pidió '
    || coalesce(nullif(trim(NEW.descripcion), ''), 'un servicio')
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

DROP TRIGGER IF EXISTS trabajos_notificar_nuevo_pedido ON public.trabajos;
CREATE TRIGGER trabajos_notificar_nuevo_pedido
AFTER INSERT OR UPDATE OF estado ON public.trabajos
FOR EACH ROW EXECUTE FUNCTION public.trabajos_notificar_nuevo_pedido();

COMMIT;
