-- Un profesional que pasó a "no disponible" porque tomó un trabajo vuelve
-- solo al catálogo cuando ese trabajo (y cualquier otro activo) termina.
--
-- Antes la app lo ocultaba al aceptar (disponible = 0) y solo las cuentas
-- demo volvían a 1 al terminar; un profesional real quedaba "Ocupado" hasta
-- reactivarse a mano. Ahora la regla vive en la base:
--   * trabajadores.pausa_por_trabajo marca que el 0 lo puso un trabajo
--     activo (no una pausa voluntaria fuera de un trabajo).
--   * Al salir el último trabajo activo (completado, cancelado, expirado,
--     no asistió, o vuelta a pendiente) se restablece disponible = 1.
-- Una pausa voluntaria hecha sin trabajos activos no se toca.
-- Backfill: solo marca la bandera en profesionales hoy en 0 con un trabajo
-- activo; no cambia la disponibilidad de nadie.

BEGIN;

ALTER TABLE public.trabajadores
  ADD COLUMN IF NOT EXISTS pausa_por_trabajo boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.trabajadores.pausa_por_trabajo IS
  'true cuando disponible = 0 lo dejó un trabajo activo; se restablece al terminar.';

CREATE OR REPLACE FUNCTION public.profesional_tiene_trabajo_activo(p_id_trabajador uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trabajos t
    WHERE t.id_trabajador = p_id_trabajador
      AND t.estado IN (
        'aceptado',
        'en_camino',
        'en_curso',
        'esperando_aprobacion_cliente',
        'pausado_orden_cambio',
        'cotizacion_seleccionada'
      )
  );
$$;
REVOKE ALL ON FUNCTION public.profesional_tiene_trabajo_activo(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.profesional_tiene_trabajo_activo(uuid) TO service_role;

-- Marca o limpia la bandera cuando cambia la disponibilidad.
CREATE OR REPLACE FUNCTION public.trabajadores_marcar_pausa_por_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF COALESCE(NEW.disponible, 0) = 1 THEN
    NEW.pausa_por_trabajo := false;
  ELSIF COALESCE(OLD.disponible, 0) = 1
        AND public.profesional_tiene_trabajo_activo(NEW.id_usuario) THEN
    NEW.pausa_por_trabajo := true;
  ELSIF COALESCE(OLD.disponible, 0) = 1 THEN
    NEW.pausa_por_trabajo := false;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.trabajadores_marcar_pausa_por_trabajo() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajadores_marcar_pausa_por_trabajo ON public.trabajadores;
CREATE TRIGGER trabajadores_marcar_pausa_por_trabajo
  BEFORE UPDATE OF disponible ON public.trabajadores
  FOR EACH ROW
  WHEN (NEW.disponible IS DISTINCT FROM OLD.disponible)
  EXECUTE FUNCTION public.trabajadores_marcar_pausa_por_trabajo();

-- Al terminar el último trabajo activo, el profesional vuelve a recibir pedidos.
CREATE OR REPLACE FUNCTION public.trabajos_restablecer_disponibilidad()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_activos constant text[] := ARRAY[
    'aceptado',
    'en_camino',
    'en_curso',
    'esperando_aprobacion_cliente',
    'pausado_orden_cambio',
    'cotizacion_seleccionada'
  ];
BEGIN
  IF NEW.id_trabajador IS NULL
     OR NEW.estado IS NOT DISTINCT FROM OLD.estado
     OR NOT (OLD.estado = ANY (v_activos))
     OR NEW.estado = ANY (v_activos) THEN
    RETURN NULL;
  END IF;

  IF public.profesional_tiene_trabajo_activo(NEW.id_trabajador) THEN
    RETURN NULL;
  END IF;

  UPDATE public.trabajadores
  SET disponible = 1
  WHERE id_usuario = NEW.id_trabajador
    AND COALESCE(disponible, 0) = 0
    AND pausa_por_trabajo;

  RETURN NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.trabajos_restablecer_disponibilidad() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajos_restablecer_disponibilidad ON public.trabajos;
CREATE TRIGGER trabajos_restablecer_disponibilidad
  AFTER UPDATE OF estado ON public.trabajos
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajos_restablecer_disponibilidad();

-- Backfill: profesionales ocultos hoy por un trabajo activo.
UPDATE public.trabajadores w
SET pausa_por_trabajo = true
WHERE COALESCE(w.disponible, 0) = 0
  AND NOT w.pausa_por_trabajo
  AND public.profesional_tiene_trabajo_activo(w.id_usuario);

COMMIT;
