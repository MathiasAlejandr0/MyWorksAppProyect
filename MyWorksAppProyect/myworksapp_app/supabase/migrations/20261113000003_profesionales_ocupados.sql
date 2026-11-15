-- El filtro de profesionales «ocupados» del catálogo no funcionaba: la app
-- consultaba trabajos por id_trabajador, pero la RLS de trabajos solo deja
-- ver los trabajos propios, así que nunca veía los de otros clientes.
--
-- profesionales_ocupados devuelve SOLO los ids (de la lista pedida) que
-- tienen un trabajo activo. No expone ningún dato del trabajo.
-- Estados = WORKER_ACTIVE_JOB_STATUSES sin 'esperando_pago'
-- (WorkerJobStatus.busyStatuses en la app).
--
-- Idempotente.

BEGIN;

CREATE OR REPLACE FUNCTION public.profesionales_ocupados(p_ids uuid[])
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT DISTINCT t.id_trabajador
  FROM public.trabajos t
  WHERE auth.uid() IS NOT NULL
    AND cardinality(p_ids) <= 200
    AND t.id_trabajador = ANY (p_ids)
    AND t.estado IN (
      'aceptado',
      'en_camino',
      'en_curso',
      'esperando_aprobacion_cliente',
      'pausado_orden_cambio',
      'cotizacion_seleccionada'
    );
$$;

REVOKE ALL ON FUNCTION public.profesionales_ocupados(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.profesionales_ocupados(uuid[]) TO authenticated, service_role;

COMMIT;
