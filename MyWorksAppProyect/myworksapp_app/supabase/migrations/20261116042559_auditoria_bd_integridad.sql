-- Auditoría de base de datos 2026-11-16 (1/5): integridad y normalización.
--
-- Hallazgos que corrige (detalle en docs/pruebas/auditoria_base_datos.md):
--   N1. Valores por defecto en inglés que no pertenecen al dominio en español
--       que usan el código y los datos (rol 'user', estado_cuenta 'active',
--       tipo_pago 'primary', tipo 'text', tipo_medio 'photo', ...). Un INSERT
--       que omitiera la columna guardaba un valor que ninguna regla reconoce.
--   N2. Columnas de estado sin CHECK: el dominio solo vivía en el código.
--   N3. Banderas booleanas guardadas como integer sin restringir a 0/1.
--   N4. Fechas guardadas como text sin validar el formato ISO-8601.
--   N5. Claves foráneas faltantes (31 columnas que referencian perfiles,
--       trabajos, pagos, propuestas u órdenes de cambio sin FK declarada).
--       Se verificó antes que no hay filas huérfanas (0 en todas).
--   N6. trabajador_precios.id_usuario, trabajador_servicios_extra.id_usuario y
--       metodos_pago_oneclick.id_usuario eran text: pasan a uuid con FK.
--   N7. Comuna duplicada sin uso ('santiago_centro' = 'santiago'): se desactiva
--       y se impide repetir el nombre activo dentro de una región.
--
-- Todo es no destructivo: no borra filas, y cada restricción se agrega como
-- NOT VALID y luego se valida contra los datos existentes.


-- ---------------------------------------------------------------------------
-- N1. Valores por defecto alineados con el dominio en español
-- ---------------------------------------------------------------------------
ALTER TABLE public.perfiles
  ALTER COLUMN rol SET DEFAULT 'usuario',
  ALTER COLUMN estado_cuenta SET DEFAULT 'activo';
ALTER TABLE public.pagos ALTER COLUMN tipo_pago SET DEFAULT 'principal';
ALTER TABLE public.mensajes ALTER COLUMN tipo SET DEFAULT 'texto';
ALTER TABLE public.fotos_trabajo ALTER COLUMN tipo_medio SET DEFAULT 'foto';
ALTER TABLE public.portafolio_trabajador ALTER COLUMN tipo_medio SET DEFAULT 'foto';
ALTER TABLE public.portafolio_trabajador ALTER COLUMN tipo_medio SET NOT NULL;
ALTER TABLE public.registros_error_app ALTER COLUMN estado SET DEFAULT 'nuevo';
ALTER TABLE public.reportes ALTER COLUMN estado SET DEFAULT 'pendiente';
ALTER TABLE public.servicios ALTER COLUMN modelo_precio SET DEFAULT 'por_hora';
ALTER TABLE public.ordenes_cambio ALTER COLUMN estado SET DEFAULT 'pendiente_cliente';

-- ---------------------------------------------------------------------------
-- N4. Validador de marcas de tiempo guardadas como texto
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.es_marca_tiempo_iso(p_valor text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = public
AS $$
  SELECT p_valor IS NULL
      OR p_valor ~ '^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d{1,6})?)?)?(Z|[+-]\d{2}(:?\d{2})?)?$';
$$;
COMMENT ON FUNCTION public.es_marca_tiempo_iso(text) IS
  'true si el texto es una fecha u hora ISO-8601 (o NULL). Lo usan los CHECK de las columnas *_en guardadas como text.';
REVOKE ALL ON FUNCTION public.es_marca_tiempo_iso(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.es_marca_tiempo_iso(text) TO authenticated, service_role;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.table_name, c.column_name
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.data_type = 'text'
      AND (c.column_name ~ '(_en|_hasta|marca_tiempo)$' OR c.column_name IN ('fecha_programada', 'fecha_inicio', 'fecha_fin'))
      AND c.table_name IN (
        'acciones_pendientes','banderas_funcionalidad','bloqueos_usuario','calificaciones',
        'cancelaciones_trabajo','codigos_restablecimiento','configuraciones_servicio',
        'consentimientos_usuario','disputas','eventos_abuso','eventos_analitica','fotos_trabajo',
        'impulsos','mensajes','notificaciones','ordenes_cambio','pagos','perfiles',
        'portafolio_trabajador','propuestas_cotizacion','registros_error_app','reportes',
        'servicios','suscripciones','trabajos')
  LOOP
    EXECUTE format(
      'ALTER TABLE public.%I ADD CONSTRAINT %I CHECK (public.es_marca_tiempo_iso(%I)) NOT VALID',
      r.table_name, left(r.table_name || '_' || r.column_name || '_iso_chk', 63), r.column_name);
    EXECUTE format('ALTER TABLE public.%I VALIDATE CONSTRAINT %I',
      r.table_name, left(r.table_name || '_' || r.column_name || '_iso_chk', 63));
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- N2. Dominios de estado (CHECK). Valores tomados de la máquina de estados
--     (transicion_trabajo_permitida), las Edge Functions y las constantes de
--     la app; incluyen todos los valores presentes hoy en la base.
-- ---------------------------------------------------------------------------
ALTER TABLE public.perfiles
  ADD CONSTRAINT perfiles_rol_chk
    CHECK (rol IN ('usuario', 'trabajador', 'administrador', 'soporte', 'qa')) NOT VALID,
  ADD CONSTRAINT perfiles_estado_cuenta_chk
    CHECK (estado_cuenta IN ('activo', 'suspendido', 'bloqueado', 'eliminado')) NOT VALID;

ALTER TABLE public.trabajos
  ADD CONSTRAINT trabajos_estado_chk CHECK (estado IN (
    'pendiente', 'esperando_cotizaciones', 'cotizacion_seleccionada', 'esperando_pago',
    'aceptado', 'en_camino', 'en_curso', 'pausado_orden_cambio',
    'esperando_aprobacion_cliente', 'completado', 'cancelado', 'expirado', 'no_asistio'
  )) NOT VALID,
  ADD CONSTRAINT trabajos_modalidad_cobro_chk CHECK (modalidad_cobro IS NULL OR modalidad_cobro IN (
    'legado', 'precio_fijo', 'bloque_horas', 'cotizacion_abierta'
  )) NOT VALID,
  ADD CONSTRAINT trabajos_estado_pago_chk CHECK (estado_pago IS NULL OR estado_pago IN (
    'ninguno', 'pendiente', 'autorizado', 'retenido', 'pagado_por_confirmar', 'liberado',
    'reembolso_pendiente', 'reembolsado', 'reembolsado_auto', 'anulado', 'fallido',
    'rechazado', 'expirado', 'cancelado'
  )) NOT VALID,
  ADD CONSTRAINT trabajos_coordenadas_chk CHECK (
    (latitud IS NULL OR latitud BETWEEN -90 AND 90)
    AND (longitud IS NULL OR longitud BETWEEN -180 AND 180)
  ) NOT VALID,
  ADD CONSTRAINT trabajos_horas_bloque_chk CHECK (horas_bloque IS NULL OR horas_bloque BETWEEN 1 AND 24) NOT VALID;

ALTER TABLE public.pagos
  ADD CONSTRAINT pagos_estado_chk CHECK (estado IN (
    'pendiente', 'autorizado', 'retenido', 'pagado_por_confirmar', 'liberado',
    'reembolso_pendiente', 'reembolsado', 'reembolsado_auto', 'anulado', 'fallido',
    'rechazado', 'expirado', 'cancelado'
  )) NOT VALID,
  ADD CONSTRAINT pagos_tipo_pago_chk CHECK (tipo_pago IN ('principal', 'orden_cambio')) NOT VALID,
  ADD CONSTRAINT pagos_moneda_chk CHECK (moneda = 'CLP') NOT VALID,
  ADD CONSTRAINT pagos_monto_chk CHECK (monto >= 0) NOT VALID,
  ADD CONSTRAINT pagos_metodo_pago_chk CHECK (metodo_pago IS NULL OR metodo_pago IN ('webpay', 'oneclick')) NOT VALID,
  ADD CONSTRAINT pagos_ambiente_chk CHECK (ambiente IS NULL OR ambiente IN ('integration', 'production')) NOT VALID;

ALTER TABLE public.calificaciones
  ADD CONSTRAINT calificaciones_puntaje_chk CHECK (puntaje BETWEEN 1 AND 5) NOT VALID;

ALTER TABLE public.fotos_trabajo
  ADD CONSTRAINT fotos_trabajo_tipo_medio_chk CHECK (tipo_medio IN ('foto', 'video')) NOT VALID;
ALTER TABLE public.portafolio_trabajador
  ADD CONSTRAINT portafolio_tipo_medio_chk CHECK (tipo_medio IN ('foto', 'video')) NOT VALID;

ALTER TABLE public.trabajadores
  ADD CONSTRAINT trabajadores_calificacion_chk CHECK (calificacion BETWEEN 0 AND 5) NOT VALID,
  ADD CONSTRAINT trabajadores_tarifa_visita_chk CHECK (tarifa_visita >= 0) NOT VALID,
  ADD CONSTRAINT trabajadores_contadores_chk CHECK (trabajos_completados >= 0 AND conteo_rechazos >= 0) NOT VALID;

ALTER TABLE public.ordenes_cambio
  ADD CONSTRAINT ordenes_cambio_monto_chk CHECK (monto_clp >= 0) NOT VALID;
ALTER TABLE public.propuestas_cotizacion
  ADD CONSTRAINT propuestas_monto_chk CHECK (monto_total_clp > 0) NOT VALID;
ALTER TABLE public.tickets_soporte
  ADD CONSTRAINT tickets_monto_escrow_chk CHECK (monto_escrow >= 0) NOT VALID;

-- liquidaciones guarda los ids como texto (libro contable inmutable): al
-- menos se exige que id_trabajador tenga forma de UUID.
ALTER TABLE public.liquidaciones
  ADD CONSTRAINT liquidaciones_id_trabajador_uuid_chk CHECK (
    id_trabajador IS NULL
    OR id_trabajador ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ) NOT VALID;

-- ---------------------------------------------------------------------------
-- N3. Banderas 0/1
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('notificaciones','leido'), ('mensajes','leido'), ('consentimientos_usuario','aceptado'),
      ('banderas_funcionalidad','habilitada'), ('eventos_abuso','resuelto'),
      ('codigos_restablecimiento','usado'), ('ranking_config','aprendizaje_activo'),
      ('comunas','activa'), ('trabajadores','disponible'), ('trabajadores','precios_configurados'),
      ('servicios','activo'), ('servicios','requiere_certificacion')
    ) v(t, c)
  LOOP
    EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I CHECK (%I IS NULL OR %I IN (0, 1)) NOT VALID',
      r.t, left(r.t || '_' || r.c || '_bool_chk', 63), r.c, r.c);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- N6. Ids de usuario guardados como text -> uuid
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS trabajador_precios_propio ON public.trabajador_precios;
DROP POLICY IF EXISTS trabajador_servicios_extra_propio ON public.trabajador_servicios_extra;

ALTER TABLE public.trabajador_precios
  ALTER COLUMN id_usuario TYPE uuid USING id_usuario::uuid;
ALTER TABLE public.trabajador_servicios_extra
  ALTER COLUMN id_usuario TYPE uuid USING id_usuario::uuid;
ALTER TABLE public.metodos_pago_oneclick
  ALTER COLUMN id_usuario TYPE uuid USING id_usuario::uuid;

CREATE POLICY trabajador_precios_propio ON public.trabajador_precios
  FOR ALL TO authenticated
  USING (id_usuario = (SELECT auth.uid()))
  WITH CHECK (id_usuario = (SELECT auth.uid()));
CREATE POLICY trabajador_servicios_extra_propio ON public.trabajador_servicios_extra
  FOR ALL TO authenticated
  USING (id_usuario = (SELECT auth.uid()))
  WITH CHECK (id_usuario = (SELECT auth.uid()));

-- El trigger que deriva las tablas 4FN desde los JSON de la ficha ya no
-- convierte el id a texto.
CREATE OR REPLACE FUNCTION public.explotar_oferta_trabajador()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.niveles_precio IS NOT DISTINCT FROM OLD.niveles_precio
     AND NEW.servicios_personalizados IS NOT DISTINCT FROM OLD.servicios_personalizados
     AND NEW.categoria_servicio IS NOT DISTINCT FROM OLD.categoria_servicio THEN
    RETURN NEW;
  END IF;

  DELETE FROM public.trabajador_precios WHERE id_usuario = NEW.id_usuario;
  INSERT INTO public.trabajador_precios (id_usuario, codigo, monto_clp)
  SELECT NEW.id_usuario, e.key, round(e.value::numeric)
  FROM jsonb_each_text(
    CASE
      WHEN jsonb_typeof(COALESCE(NEW.niveles_precio, '{}'::jsonb)) = 'object'
        THEN COALESCE(NEW.niveles_precio, '{}'::jsonb)
      ELSE '{}'::jsonb
    END
  ) AS e(key, value)
  WHERE e.value ~ '^[0-9]+(\.[0-9]+)?$';

  DELETE FROM public.trabajador_servicios_extra WHERE id_usuario = NEW.id_usuario;
  INSERT INTO public.trabajador_servicios_extra (
    id, id_usuario, titulo, subtitulo, monto_clp, unidad
  )
  SELECT
    COALESCE(NULLIF(elem->>'id', ''), gen_random_uuid()::text),
    NEW.id_usuario,
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
$function$;

-- ---------------------------------------------------------------------------
-- N5. Claves foráneas faltantes (0 huérfanos verificados antes de aplicar)
-- ---------------------------------------------------------------------------
ALTER TABLE public.trabajador_precios
  ADD CONSTRAINT trabajador_precios_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.trabajadores(id_usuario) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.trabajador_servicios_extra
  ADD CONSTRAINT trabajador_servicios_extra_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.trabajadores(id_usuario) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.metodos_pago_oneclick
  ADD CONSTRAINT metodos_pago_oneclick_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;

ALTER TABLE public.calificaciones
  ADD CONSTRAINT calificaciones_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID,
  ADD CONSTRAINT calificaciones_id_calificado_fkey FOREIGN KEY (id_calificado)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.calificaciones ALTER COLUMN id_calificado SET NOT NULL;

ALTER TABLE public.calificaciones_cliente
  ADD CONSTRAINT calificaciones_cliente_id_trabajo_fkey FOREIGN KEY (id_trabajo)
    REFERENCES public.trabajos(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT calificaciones_cliente_id_cliente_fkey FOREIGN KEY (id_cliente)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT calificaciones_cliente_id_trabajador_fkey FOREIGN KEY (id_trabajador)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;

ALTER TABLE public.cancelaciones_trabajo
  ADD CONSTRAINT cancelaciones_trabajo_cancelado_por_fkey FOREIGN KEY (cancelado_por)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.codigos_restablecimiento
  ADD CONSTRAINT codigos_restablecimiento_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.bloqueos_usuario
  ADD CONSTRAINT bloqueos_usuario_id_bloqueador_fkey FOREIGN KEY (id_bloqueador)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT bloqueos_usuario_id_bloqueado_fkey FOREIGN KEY (id_bloqueado)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT bloqueos_usuario_distintos_chk CHECK (id_bloqueador <> id_bloqueado) NOT VALID;
ALTER TABLE public.banderas_funcionalidad
  ADD CONSTRAINT banderas_funcionalidad_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.eventos_analitica
  ADD CONSTRAINT eventos_analitica_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.eventos_ranking
  ADD CONSTRAINT eventos_ranking_id_trabajador_fkey FOREIGN KEY (id_trabajador)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT eventos_ranking_id_trabajo_fkey FOREIGN KEY (id_trabajo)
    REFERENCES public.trabajos(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.intentos_pin_inicio
  ADD CONSTRAINT intentos_pin_inicio_id_trabajo_fkey FOREIGN KEY (id_trabajo)
    REFERENCES public.trabajos(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT intentos_pin_inicio_id_usuario_fkey FOREIGN KEY (id_usuario)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.mensajes
  ADD CONSTRAINT mensajes_id_remitente_fkey FOREIGN KEY (id_remitente)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT mensajes_id_destinatario_fkey FOREIGN KEY (id_destinatario)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.ordenes_cambio
  ADD CONSTRAINT ordenes_cambio_id_trabajador_fkey FOREIGN KEY (id_trabajador)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT ordenes_cambio_id_pago_fkey FOREIGN KEY (id_pago)
    REFERENCES public.pagos(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.pagos
  ADD CONSTRAINT pagos_id_orden_cambio_fkey FOREIGN KEY (id_orden_cambio)
    REFERENCES public.ordenes_cambio(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.reportes
  ADD CONSTRAINT reportes_id_reportante_fkey FOREIGN KEY (id_reportante)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT reportes_id_usuario_reportado_fkey FOREIGN KEY (id_usuario_reportado)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID;
ALTER TABLE public.reprogramaciones_trabajo
  ADD CONSTRAINT reprogramaciones_propuesta_por_fkey FOREIGN KEY (propuesta_por)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT reprogramaciones_respondida_por_fkey FOREIGN KEY (respondida_por)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.senales_resena
  ADD CONSTRAINT senales_resena_resuelto_por_fkey FOREIGN KEY (resuelto_por)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.tickets_soporte
  ADD CONSTRAINT tickets_soporte_id_trabajo_fkey FOREIGN KEY (id_trabajo)
    REFERENCES public.trabajos(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.disputas
  ADD CONSTRAINT disputas_abierta_por_fkey FOREIGN KEY (abierta_por)
    REFERENCES public.perfiles(id) ON DELETE CASCADE NOT VALID,
  ADD CONSTRAINT disputas_resuelta_por_fkey FOREIGN KEY (resuelta_por)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.verificacion_eventos
  ADD CONSTRAINT verificacion_eventos_id_actor_fkey FOREIGN KEY (id_actor)
    REFERENCES public.perfiles(id) ON DELETE SET NULL NOT VALID;
ALTER TABLE public.trabajos
  ADD CONSTRAINT trabajos_id_cotizacion_seleccionada_fkey FOREIGN KEY (id_cotizacion_seleccionada)
    REFERENCES public.propuestas_cotizacion(id) ON DELETE SET NULL NOT VALID;

-- perfiles.id debe corresponder a una cuenta de auth.users. Hay 8 perfiles
-- de demostración (catálogo semilla) sin cuenta de acceso: la FK queda
-- NOT VALID para no borrarlos; se aplica a todo perfil nuevo o modificado
-- en su id.
ALTER TABLE public.perfiles
  ADD CONSTRAINT perfiles_id_auth_users_fkey FOREIGN KEY (id)
    REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;

-- La FK de liquidaciones -> trabajos venía NOT VALID; ya no hay huérfanos.
ALTER TABLE public.liquidaciones VALIDATE CONSTRAINT liquidaciones_id_trabajo_fkey;

-- ---------------------------------------------------------------------------
-- N7. Comuna duplicada
-- ---------------------------------------------------------------------------
UPDATE public.comunas SET activa = 0
WHERE id = 'santiago_centro'
  AND NOT EXISTS (SELECT 1 FROM public.trabajos WHERE id_comuna = 'santiago_centro')
  AND NOT EXISTS (SELECT 1 FROM public.trabajadores WHERE id_comuna = 'santiago_centro');
CREATE UNIQUE INDEX IF NOT EXISTS comunas_region_nombre_activa_uidx
  ON public.comunas (id_region, lower(nombre)) WHERE activa = 1;

-- ---------------------------------------------------------------------------
-- Validación de todas las restricciones agregadas como NOT VALID
-- (excepto perfiles_id_auth_users_fkey, explicada arriba).
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT conrelid::regclass AS tbl, conname
    FROM pg_constraint
    WHERE connamespace = 'public'::regnamespace
      AND NOT convalidated
      AND conname <> 'perfiles_id_auth_users_fkey'
  LOOP
    EXECUTE format('ALTER TABLE %s VALIDATE CONSTRAINT %I', r.tbl, r.conname);
  END LOOP;
END $$;

