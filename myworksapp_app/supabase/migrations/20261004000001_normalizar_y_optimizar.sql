-- Normaliza copias que podían desfasarse y cubre las búsquedas del cobro.
-- La app sigue guardando niveles_precio y servicios_personalizados en el
-- trabajador; el trigger los parte en filas en la misma transacción.

-- -----------------------------------------------------------------------------
-- Dinero en pesos enteros
-- -----------------------------------------------------------------------------
ALTER TABLE public.pagos
  ALTER COLUMN monto TYPE numeric(12, 0) USING round(monto);

ALTER TABLE public.trabajadores
  ALTER COLUMN tarifa_visita TYPE numeric(12, 0) USING round(COALESCE(tarifa_visita, 0));

ALTER TABLE public.trabajadores
  ALTER COLUMN calificacion TYPE numeric(4, 2) USING round(COALESCE(calificacion, 0)::numeric, 2);

-- -----------------------------------------------------------------------------
-- Un solo pago principal vivo por trabajo, y búsquedas del cobro
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.pagos
    WHERE tipo_pago = 'principal'
      AND estado IN ('pendiente', 'retenido', 'autorizado')
    GROUP BY id_trabajo
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'hay más de un pago principal activo por trabajo';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS pagos_un_principal_activo_uidx
  ON public.pagos (id_trabajo)
  WHERE tipo_pago = 'principal'
    AND estado IN ('pendiente', 'retenido', 'autorizado');

CREATE INDEX IF NOT EXISTS pagos_token_tbk_idx
  ON public.pagos (token_tbk)
  WHERE token_tbk IS NOT NULL AND length(trim(token_tbk)) > 0;

CREATE INDEX IF NOT EXISTS pagos_buy_order_idx
  ON public.pagos (buy_order)
  WHERE buy_order IS NOT NULL AND length(trim(buy_order)) > 0;

-- La inscripción Oneclick todavía no está en este proyecto.
DO $$
BEGIN
  IF to_regclass('public.metodos_pago_oneclick') IS NOT NULL THEN
    EXECUTE $idx$
      CREATE INDEX IF NOT EXISTS metodos_pago_oneclick_token_idx
      ON public.metodos_pago_oneclick (token_inscripcion)
      WHERE token_inscripcion IS NOT NULL AND length(trim(token_inscripcion)) > 0
    $idx$;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.calificaciones') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS calificaciones_trabajo_idx ON public.calificaciones (id_trabajo)';
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Precios y servicios extra en filas (4NF). El JSON queda como formato de escritura.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.trabajador_precios (
  id_usuario text NOT NULL,
  codigo text NOT NULL,
  monto_clp numeric(12, 0) NOT NULL CHECK (monto_clp >= 0),
  PRIMARY KEY (id_usuario, codigo)
);

CREATE TABLE IF NOT EXISTS public.trabajador_servicios_extra (
  id text NOT NULL,
  id_usuario text NOT NULL,
  titulo text NOT NULL,
  subtitulo text NOT NULL DEFAULT '',
  monto_clp numeric(12, 0) NOT NULL CHECK (monto_clp >= 0),
  unidad text NOT NULL DEFAULT 'fijo' CHECK (unidad IN ('fijo', 'por_m2')),
  PRIMARY KEY (id_usuario, id)
);

ALTER TABLE public.trabajador_precios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trabajador_servicios_extra ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trabajador_precios_propio ON public.trabajador_precios;
CREATE POLICY trabajador_precios_propio ON public.trabajador_precios
  FOR ALL TO authenticated
  USING (id_usuario = auth.uid()::text)
  WITH CHECK (id_usuario = auth.uid()::text);

DROP POLICY IF EXISTS trabajador_servicios_extra_propio ON public.trabajador_servicios_extra;
CREATE POLICY trabajador_servicios_extra_propio ON public.trabajador_servicios_extra
  FOR ALL TO authenticated
  USING (id_usuario = auth.uid()::text)
  WITH CHECK (id_usuario = auth.uid()::text);

REVOKE ALL ON TABLE public.trabajador_precios FROM PUBLIC, anon;
REVOKE ALL ON TABLE public.trabajador_servicios_extra FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trabajador_precios TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.trabajador_servicios_extra TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.explotar_oferta_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.niveles_precio IS NOT DISTINCT FROM OLD.niveles_precio
     AND NEW.servicios_personalizados IS NOT DISTINCT FROM OLD.servicios_personalizados
     AND NEW.categoria_servicio IS NOT DISTINCT FROM OLD.categoria_servicio THEN
    RETURN NEW;
  END IF;

  DELETE FROM public.trabajador_precios WHERE id_usuario = NEW.id_usuario::text;
  INSERT INTO public.trabajador_precios (id_usuario, codigo, monto_clp)
  SELECT NEW.id_usuario::text, e.key, round(e.value::numeric)
  FROM jsonb_each_text(
    CASE
      WHEN jsonb_typeof(COALESCE(NEW.niveles_precio, '{}'::jsonb)) = 'object'
        THEN COALESCE(NEW.niveles_precio, '{}'::jsonb)
      ELSE '{}'::jsonb
    END
  ) AS e(key, value)
  WHERE e.value ~ '^[0-9]+(\.[0-9]+)?$';

  DELETE FROM public.trabajador_servicios_extra WHERE id_usuario = NEW.id_usuario::text;
  INSERT INTO public.trabajador_servicios_extra (
    id, id_usuario, titulo, subtitulo, monto_clp, unidad
  )
  SELECT
    COALESCE(NULLIF(elem->>'id', ''), gen_random_uuid()::text),
    NEW.id_usuario::text,
    COALESCE(elem->>'title', ''),
    COALESCE(elem->>'subtitle', ''),
    round(COALESCE(NULLIF(elem->>'priceClp', '')::numeric, 0)),
    CASE WHEN elem->>'unit' = 'perSqm' THEN 'por_m2' ELSE 'fijo' END
  FROM jsonb_array_elements(
    CASE
      WHEN jsonb_typeof(COALESCE(NEW.servicios_personalizados, '[]'::jsonb)) = 'array'
        THEN COALESCE(NEW.servicios_personalizados, '[]'::jsonb)
      ELSE '[]'::jsonb
    END
  ) AS elem
  WHERE COALESCE(elem->>'title', '') <> '';

  IF to_regclass('public.trabajador_servicios') IS NOT NULL
     AND NEW.categoria_servicio IS NOT NULL
     AND length(trim(NEW.categoria_servicio)) > 0 THEN
    INSERT INTO public.trabajador_servicios (id_trabajador, categoria_servicio)
    VALUES (NEW.id_usuario, NEW.categoria_servicio)
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trabajadores_explotar_oferta ON public.trabajadores;
CREATE TRIGGER trabajadores_explotar_oferta
  AFTER INSERT OR UPDATE OF niveles_precio, servicios_personalizados, categoria_servicio
  ON public.trabajadores
  FOR EACH ROW
  EXECUTE FUNCTION public.explotar_oferta_trabajador();

REVOKE ALL ON FUNCTION public.explotar_oferta_trabajador() FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- estado_pago sale del pago principal. calificacion sale de las notas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.copiar_estado_pago_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.tipo_pago IS DISTINCT FROM 'principal' THEN
    RETURN NEW;
  END IF;
  UPDATE public.trabajos
  SET estado_pago = NEW.estado
  WHERE id::text = NEW.id_trabajo::text
    AND estado_pago IS DISTINCT FROM NEW.estado;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pagos_copiar_estado_trabajo ON public.pagos;
CREATE TRIGGER pagos_copiar_estado_trabajo
  AFTER INSERT OR UPDATE OF estado
  ON public.pagos
  FOR EACH ROW
  EXECUTE FUNCTION public.copiar_estado_pago_trabajo();

REVOKE ALL ON FUNCTION public.copiar_estado_pago_trabajo() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.refrescar_calificacion_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job text := COALESCE(NEW.id_trabajo, OLD.id_trabajo)::text;
  v_worker text;
BEGIN
  SELECT id_trabajador::text INTO v_worker
  FROM public.trabajos
  WHERE id::text = v_job;

  IF v_worker IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  UPDATE public.trabajadores
  SET calificacion = COALESCE((
    SELECT round(avg(c.puntaje)::numeric, 2)
    FROM public.calificaciones c
    JOIN public.trabajos t ON t.id::text = c.id_trabajo::text
    WHERE t.id_trabajador::text = v_worker
  ), 0)
  WHERE id_usuario::text = v_worker;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.calificaciones') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS calificaciones_refrescar_trabajador ON public.calificaciones';
    EXECUTE 'CREATE TRIGGER calificaciones_refrescar_trabajador AFTER INSERT OR UPDATE OR DELETE ON public.calificaciones FOR EACH ROW EXECUTE FUNCTION public.refrescar_calificacion_trabajador()';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.refrescar_calificacion_trabajador() FROM PUBLIC, anon, authenticated;

-- -----------------------------------------------------------------------------
-- La liquidación no elige trabajo ni profesional: salen del pago.
-- El código de recuperación no guarda un correo distinto al del perfil.
-- El ticket de soporte, si apunta a un trabajo, toma nombre y monto de ahí.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fijar_liquidacion_desde_pago()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_job text;
  v_worker text;
BEGIN
  SELECT t.id::text, t.id_trabajador::text
  INTO v_job, v_worker
  FROM public.pagos p
  JOIN public.trabajos t ON t.id::text = p.id_trabajo::text
  WHERE p.id::text = NEW.id_pago::text;

  IF v_job IS NULL THEN
    RAISE EXCEPTION 'el pago de la liquidación no existe';
  END IF;

  NEW.id_trabajo := v_job;
  NEW.id_trabajador := v_worker;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.liquidaciones') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS liquidaciones_desde_pago ON public.liquidaciones';
    EXECUTE 'CREATE TRIGGER liquidaciones_desde_pago BEFORE INSERT OR UPDATE OF id_pago ON public.liquidaciones FOR EACH ROW EXECUTE FUNCTION public.fijar_liquidacion_desde_pago()';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.fijar_liquidacion_desde_pago() FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  IF to_regclass('public.liquidaciones') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname = 'liquidaciones_id_trabajo_fkey'
     ) THEN
    EXECUTE 'ALTER TABLE public.liquidaciones ADD CONSTRAINT liquidaciones_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES public.trabajos (id) NOT VALID';
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.fijar_correo_codigo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_correo text;
BEGIN
  SELECT correo INTO v_correo
  FROM public.perfiles
  WHERE id::text = NEW.id_usuario::text;
  IF v_correo IS NULL OR length(trim(v_correo)) = 0 THEN
    RAISE EXCEPTION 'el usuario no tiene correo';
  END IF;
  NEW.correo := v_correo;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.codigos_restablecimiento') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS codigos_correo_desde_perfil ON public.codigos_restablecimiento';
    EXECUTE 'CREATE TRIGGER codigos_correo_desde_perfil BEFORE INSERT OR UPDATE OF id_usuario ON public.codigos_restablecimiento FOR EACH ROW EXECUTE FUNCTION public.fijar_correo_codigo()';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.fijar_correo_codigo() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fijar_ticket_desde_trabajo()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_cliente text;
  v_trabajador text;
  v_monto numeric;
BEGIN
  IF NEW.id_trabajo IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT pc.nombre, pt.nombre
  INTO v_cliente, v_trabajador
  FROM public.trabajos t
  LEFT JOIN public.perfiles pc ON pc.id::text = t.id_usuario::text
  LEFT JOIN public.perfiles pt ON pt.id::text = t.id_trabajador::text
  WHERE t.id::text = NEW.id_trabajo::text;

  SELECT p.monto INTO v_monto
  FROM public.pagos p
  WHERE p.id_trabajo::text = NEW.id_trabajo::text
    AND p.tipo_pago = 'principal'
    AND p.estado IN ('retenido', 'autorizado', 'liberado')
  ORDER BY p.creado_en DESC
  LIMIT 1;

  IF v_cliente IS NOT NULL THEN
    NEW.nombre_cliente := v_cliente;
  END IF;
  IF v_trabajador IS NOT NULL THEN
    NEW.nombre_trabajador := v_trabajador;
  END IF;
  IF v_monto IS NOT NULL THEN
    NEW.monto_escrow := round(v_monto);
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.tickets_soporte') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS tickets_desde_trabajo ON public.tickets_soporte';
    EXECUTE 'CREATE TRIGGER tickets_desde_trabajo BEFORE INSERT OR UPDATE OF id_trabajo ON public.tickets_soporte FOR EACH ROW EXECUTE FUNCTION public.fijar_ticket_desde_trabajo()';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.fijar_ticket_desde_trabajo() FROM PUBLIC, anon, authenticated;

-- Rellena las tablas de precios con lo que ya está en el JSON.
UPDATE public.trabajadores
SET categoria_servicio = categoria_servicio
WHERE categoria_servicio IS NOT NULL;
