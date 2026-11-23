-- BCNF: el destinatario del mensaje y las cifras del profesional dejan de
-- ser datos editables. Los nombres y el monto del ticket se leen del trabajo,
-- del perfil y del pago. No borra trabajos, pagos, perfiles ni disputas.
-- Idempotente. demo_modo y las comisiones no se tocan.

-- ---------------------------------------------------------------------------
-- mensajes.id_destinatario
-- Postgres no admite en GENERATED ALWAYS una lectura de otra tabla.
-- El trigger es la única escritura.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mensajes_fijar_destinatario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_cliente uuid;
  v_trabajador uuid;
BEGIN
  SELECT t.id_usuario, t.id_trabajador
  INTO v_cliente, v_trabajador
  FROM public.trabajos t
  WHERE t.id = NEW.id_trabajo;

  IF v_cliente IS NULL THEN
    RAISE EXCEPTION 'el mensaje no tiene un trabajo valido';
  END IF;

  IF NEW.id_remitente = v_cliente THEN
    IF v_trabajador IS NULL THEN
      RAISE EXCEPTION 'el trabajo aun no tiene profesional';
    END IF;
    NEW.id_destinatario := v_trabajador;
  ELSIF NEW.id_remitente = v_trabajador THEN
    NEW.id_destinatario := v_cliente;
  ELSE
    RAISE EXCEPTION 'el remitente no participa en el trabajo';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.mensajes_fijar_destinatario() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS mensajes_fijar_destinatario ON public.mensajes;
CREATE TRIGGER mensajes_fijar_destinatario
  BEFORE INSERT OR UPDATE OF id_trabajo, id_remitente, id_destinatario
  ON public.mensajes
  FOR EACH ROW
  EXECUTE FUNCTION public.mensajes_fijar_destinatario();

COMMENT ON COLUMN public.mensajes.id_destinatario IS
  'El otro participante del trabajo. Lo fija solo mensajes_fijar_destinatario. No cabe en GENERATED ALWAYS porque hay que leer trabajos.';

-- ---------------------------------------------------------------------------
-- tickets_soporte: quitar la foto repetida si la tabla sigue vacía.
-- El estado queda en español, que es lo que muestra la consola.
-- ---------------------------------------------------------------------------
UPDATE public.tickets_soporte
SET estado = CASE estado
  WHEN 'Pending' THEN 'pendiente'
  WHEN 'Resolved' THEN 'resuelto'
  ELSE lower(estado)
END
WHERE estado IN ('Pending', 'Resolved');

ALTER TABLE public.tickets_soporte
  ALTER COLUMN estado SET DEFAULT 'pendiente';

ALTER TABLE public.tickets_soporte
  DROP CONSTRAINT IF EXISTS tickets_soporte_estado_chk;

ALTER TABLE public.tickets_soporte
  ADD CONSTRAINT tickets_soporte_estado_chk
  CHECK (
    estado IS NULL
    OR estado = ANY (ARRAY['pendiente'::text, 'respondido'::text, 'resuelto'::text])
  );

DROP TRIGGER IF EXISTS tickets_desde_trabajo ON public.tickets_soporte;
DROP FUNCTION IF EXISTS public.fijar_ticket_desde_trabajo();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tickets_soporte'
      AND column_name = 'nombre_cliente'
  ) THEN
    IF (SELECT count(*) FROM public.tickets_soporte) > 0 THEN
      RAISE EXCEPTION 'tickets_soporte tiene filas; no se quitan los nombres ni el monto';
    END IF;
    ALTER TABLE public.tickets_soporte
      DROP CONSTRAINT IF EXISTS tickets_monto_escrow_chk,
      DROP COLUMN nombre_cliente,
      DROP COLUMN nombre_trabajador,
      DROP COLUMN monto_escrow;
  END IF;
END $$;

CREATE OR REPLACE VIEW public.consola_tickets
WITH (security_invoker = false) AS
SELECT
  t.id,
  t.asunto,
  t.estado,
  t.creado_en,
  t.id_trabajo,
  COALESCE(pc.nombre, '') AS nombre_cliente,
  COALESCE(pt.nombre, '') AS nombre_trabajador,
  COALESCE((
    SELECT round(p.monto)::integer
    FROM public.pagos p
    WHERE p.id_trabajo = t.id_trabajo
      AND p.tipo_pago = 'principal'
      AND p.estado IN ('retenido', 'autorizado', 'liberado')
    ORDER BY p.creado_en DESC
    LIMIT 1
  ), 0) AS monto_escrow
FROM public.tickets_soporte t
LEFT JOIN public.trabajos tr ON tr.id = t.id_trabajo
LEFT JOIN public.perfiles pc ON pc.id = tr.id_usuario
LEFT JOIN public.perfiles pt ON pt.id = tr.id_trabajador
WHERE public.rol_consola() IS NOT NULL;

COMMENT ON VIEW public.consola_tickets IS
  'Tickets para la consola. Nombres y monto se leen del trabajo, del perfil y del pago; no se guardan en tickets_soporte.';

REVOKE ALL ON public.consola_tickets FROM PUBLIC, anon;
GRANT SELECT ON public.consola_tickets TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- trabajadores: la nota y los trabajos completados salen de la estadística.
-- score_listado solo lo persiste el recálculo de ranking (mwa.ranking = 1).
-- El ORDER BY de listar_profesionales_catalogo no se modifica.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trabajadores_cifras_desde_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_nota numeric;
  v_hechos integer;
BEGIN
  SELECT s.calificacion, s.trabajos_completados
  INTO v_nota, v_hechos
  FROM public.stats_profesional(NEW.id_usuario) AS s;

  NEW.calificacion := COALESCE(v_nota, 0);
  NEW.trabajos_completados := COALESCE(v_hechos, 0);

  IF TG_OP = 'UPDATE'
     AND COALESCE(current_setting('mwa.ranking', true), '') IS DISTINCT FROM '1' THEN
    NEW.score_listado := OLD.score_listado;
    NEW.score_desglose := OLD.score_desglose;
    NEW.ranking_actualizado_en := OLD.ranking_actualizado_en;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trabajadores_cifras_desde_stats() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trabajadores_z_cifras_desde_stats ON public.trabajadores;
CREATE TRIGGER trabajadores_z_cifras_desde_stats
  BEFORE INSERT OR UPDATE
  ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.trabajadores_cifras_desde_stats();

COMMENT ON COLUMN public.trabajadores.calificacion IS
  'Igual a privado.stats_profesionales. La escribe solo trabajadores_z_cifras_desde_stats: la consulta no cabe en GENERATED ALWAYS.';
COMMENT ON COLUMN public.trabajadores.trabajos_completados IS
  'Trabajos en estado completado, copiados por trabajadores_z_cifras_desde_stats desde la estadística. No se editan a mano.';
COMMENT ON COLUMN public.trabajadores.score_listado IS
  'Orden interno del ranking. Solo lo cambia refrescar_ranking_trabajador. El catálogo público ordena por cercanía, nota y tarifa.';

DO $$
BEGIN
  IF to_regprocedure('public.refrescar_ranking_trabajador_calculo(uuid)') IS NULL THEN
    ALTER FUNCTION public.refrescar_ranking_trabajador(uuid)
      RENAME TO refrescar_ranking_trabajador_calculo;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.refrescar_ranking_trabajador(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM set_config('mwa.ranking', '1', true);
  PERFORM public.refrescar_ranking_trabajador_calculo(p_id);
END;
$$;

REVOKE ALL ON FUNCTION public.refrescar_ranking_trabajador(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.refrescar_ranking_trabajador_calculo(uuid) FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.refrescar_ranking_trabajador(uuid) IS
  'Recalcula score_listado. Marca mwa.ranking para que el trigger de cifras no restaure el valor anterior. La nota pública no la escribe esta función: la deja el trigger desde la estadística.';
