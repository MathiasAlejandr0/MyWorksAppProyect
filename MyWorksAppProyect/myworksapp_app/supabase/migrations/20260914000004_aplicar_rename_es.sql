-- =============================================================================
-- APLICAR ESTE ARCHIVO COMPLETO en Supabase SQL Editor (Ctrl+A → pegar → Run)
-- No cortes trozos. No ejecutes el dump CREATE TABLE.
-- Idempotente: si ya renombró parcialmente, continúa.
-- =============================================================================
BEGIN;

-- IF EXISTS del trigger NO evita error si la TABLA no existe
DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS protect_profiles_sensitive ON public.profiles';
  END IF;
  IF to_regclass('public.perfiles') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS protect_profiles_sensitive ON public.perfiles';
  END IF;
END $$;

DO $$
BEGIN
  -- Solo renombrar si el destino NO existe
  IF to_regclass('public.profiles') IS NOT NULL AND to_regclass('public.perfiles') IS NULL THEN
    ALTER TABLE public.profiles RENAME TO perfiles;
  END IF;
  IF to_regclass('public.workers') IS NOT NULL AND to_regclass('public.trabajadores') IS NULL THEN
    ALTER TABLE public.workers RENAME TO trabajadores;
  END IF;
  IF to_regclass('public.services') IS NOT NULL AND to_regclass('public.servicios') IS NULL THEN
    ALTER TABLE public.services RENAME TO servicios;
  END IF;
  IF to_regclass('public.jobs') IS NOT NULL AND to_regclass('public.trabajos') IS NULL THEN
    ALTER TABLE public.jobs RENAME TO trabajos;
  END IF;
  IF to_regclass('public.payments') IS NOT NULL AND to_regclass('public.pagos') IS NULL THEN
    ALTER TABLE public.payments RENAME TO pagos;
  END IF;
  IF to_regclass('public.messages') IS NOT NULL AND to_regclass('public.mensajes') IS NULL THEN
    ALTER TABLE public.messages RENAME TO mensajes;
  END IF;
  IF to_regclass('public.disputes') IS NOT NULL AND to_regclass('public.disputas') IS NULL THEN
    ALTER TABLE public.disputes RENAME TO disputas;
  END IF;
  IF to_regclass('public.notifications') IS NOT NULL AND to_regclass('public.notificaciones') IS NULL THEN
    ALTER TABLE public.notifications RENAME TO notificaciones;
  END IF;
  IF to_regclass('public.ratings') IS NOT NULL AND to_regclass('public.calificaciones') IS NULL THEN
    ALTER TABLE public.ratings RENAME TO calificaciones;
  END IF;
  IF to_regclass('public.reports') IS NOT NULL AND to_regclass('public.reportes') IS NULL THEN
    ALTER TABLE public.reports RENAME TO reportes;
  END IF;
  IF to_regclass('public.quote_proposals') IS NOT NULL AND to_regclass('public.propuestas_cotizacion') IS NULL THEN
    ALTER TABLE public.quote_proposals RENAME TO propuestas_cotizacion;
  END IF;
  IF to_regclass('public.change_orders') IS NOT NULL AND to_regclass('public.ordenes_cambio') IS NULL THEN
    ALTER TABLE public.change_orders RENAME TO ordenes_cambio;
  END IF;
  IF to_regclass('public.job_photos') IS NOT NULL AND to_regclass('public.fotos_trabajo') IS NULL THEN
    ALTER TABLE public.job_photos RENAME TO fotos_trabajo;
  END IF;
  IF to_regclass('public.worker_portfolio') IS NOT NULL AND to_regclass('public.portafolio_trabajador') IS NULL THEN
    ALTER TABLE public.worker_portfolio RENAME TO portafolio_trabajador;
  END IF;
  IF to_regclass('public.worker_services') IS NOT NULL AND to_regclass('public.trabajador_servicios') IS NULL THEN
    ALTER TABLE public.worker_services RENAME TO trabajador_servicios;
  END IF;
  IF to_regclass('public.job_cancellations') IS NOT NULL AND to_regclass('public.cancelaciones_trabajo') IS NULL THEN
    ALTER TABLE public.job_cancellations RENAME TO cancelaciones_trabajo;
  END IF;
  IF to_regclass('public.app_error_logs') IS NOT NULL AND to_regclass('public.registros_error_app') IS NULL THEN
    ALTER TABLE public.app_error_logs RENAME TO registros_error_app;
  END IF;
  IF to_regclass('public.abuse_events') IS NOT NULL AND to_regclass('public.eventos_abuso') IS NULL THEN
    ALTER TABLE public.abuse_events RENAME TO eventos_abuso;
  END IF;
  IF to_regclass('public.pending_actions') IS NOT NULL AND to_regclass('public.acciones_pendientes') IS NULL THEN
    ALTER TABLE public.pending_actions RENAME TO acciones_pendientes;
  END IF;
  IF to_regclass('public.user_blocks') IS NOT NULL AND to_regclass('public.bloqueos_usuario') IS NULL THEN
    ALTER TABLE public.user_blocks RENAME TO bloqueos_usuario;
  END IF;
  IF to_regclass('public.user_consents') IS NOT NULL AND to_regclass('public.consentimientos_usuario') IS NULL THEN
    ALTER TABLE public.user_consents RENAME TO consentimientos_usuario;
  END IF;
  IF to_regclass('public.feature_flags') IS NOT NULL AND to_regclass('public.banderas_funcionalidad') IS NULL THEN
    ALTER TABLE public.feature_flags RENAME TO banderas_funcionalidad;
  END IF;
  IF to_regclass('public.subscriptions') IS NOT NULL AND to_regclass('public.suscripciones') IS NULL THEN
    ALTER TABLE public.subscriptions RENAME TO suscripciones;
  END IF;
  IF to_regclass('public.boosts') IS NOT NULL AND to_regclass('public.impulsos') IS NULL THEN
    ALTER TABLE public.boosts RENAME TO impulsos;
  END IF;
  IF to_regclass('public.analytics_events') IS NOT NULL AND to_regclass('public.eventos_analitica') IS NULL THEN
    ALTER TABLE public.analytics_events RENAME TO eventos_analitica;
  END IF;
  IF to_regclass('public.service_configs') IS NOT NULL AND to_regclass('public.configuraciones_servicio') IS NULL THEN
    ALTER TABLE public.service_configs RENAME TO configuraciones_servicio;
  END IF;
  IF to_regclass('public.password_reset_codes') IS NOT NULL AND to_regclass('public.codigos_restablecimiento') IS NULL THEN
    ALTER TABLE public.password_reset_codes RENAME TO codigos_restablecimiento;
  END IF;
  IF to_regclass('public.tickets') IS NOT NULL AND to_regclass('public.tickets_soporte') IS NULL THEN
    ALTER TABLE public.tickets RENAME TO tickets_soporte;
  END IF;

  IF to_regclass('public.perfiles') IS NULL THEN
    RAISE EXCEPTION 'No existe public.perfiles ni se pudo renombrar profiles. Abortando.';
  END IF;
END $$;

-- Helper columnas
CREATE OR REPLACE FUNCTION public._rename_col_if_exists(p_table text, p_old text, p_new text)
RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF to_regclass('public.' || p_table) IS NULL THEN RETURN; END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name=p_table AND column_name=p_old
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name=p_table AND column_name=p_new
  ) THEN
    EXECUTE format('ALTER TABLE public.%I RENAME COLUMN %I TO %I', p_table, p_old, p_new);
  END IF;
END;
$$;

SELECT public._rename_col_if_exists('perfiles','name','nombre');
SELECT public._rename_col_if_exists('perfiles','email','correo');
SELECT public._rename_col_if_exists('perfiles','role','rol');
SELECT public._rename_col_if_exists('perfiles','accountStatus','estado_cuenta');
SELECT public._rename_col_if_exists('perfiles','profilePhotoPath','ruta_foto_perfil');
SELECT public._rename_col_if_exists('perfiles','createdAt','creado_en');

SELECT public._rename_col_if_exists('trabajadores','userId','id_usuario');
SELECT public._rename_col_if_exists('trabajadores','profession','profesion');
SELECT public._rename_col_if_exists('trabajadores','description','descripcion');
SELECT public._rename_col_if_exists('trabajadores','rating','calificacion');
SELECT public._rename_col_if_exists('trabajadores','isAvailable','disponible');
SELECT public._rename_col_if_exists('trabajadores','visitFee','tarifa_visita');
SELECT public._rename_col_if_exists('trabajadores','serviceCategory','categoria_servicio');
SELECT public._rename_col_if_exists('trabajadores','pricingTiers','niveles_precio');
SELECT public._rename_col_if_exists('trabajadores','customServices','servicios_personalizados');
SELECT public._rename_col_if_exists('trabajadores','pricingConfigured','precios_configurados');
SELECT public._rename_col_if_exists('trabajadores','workZone','zona_trabajo');
SELECT public._rename_col_if_exists('trabajadores','rejectionCount','conteo_rechazos');

SELECT public._rename_col_if_exists('servicios','name','nombre');
SELECT public._rename_col_if_exists('servicios','description','descripcion');
SELECT public._rename_col_if_exists('servicios','category','categoria');
SELECT public._rename_col_if_exists('servicios','isActive','activo');
SELECT public._rename_col_if_exists('servicios','requiresCertification','requiere_certificacion');
SELECT public._rename_col_if_exists('servicios','pricingModel','modelo_precio');
SELECT public._rename_col_if_exists('servicios','legalDisclaimer','aviso_legal');
SELECT public._rename_col_if_exists('servicios','createdAt','creado_en');
SELECT public._rename_col_if_exists('servicios','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('trabajos','userId','id_usuario');
SELECT public._rename_col_if_exists('trabajos','workerId','id_trabajador');
SELECT public._rename_col_if_exists('trabajos','serviceId','id_servicio');
SELECT public._rename_col_if_exists('trabajos','status','estado');
SELECT public._rename_col_if_exists('trabajos','address','direccion');
SELECT public._rename_col_if_exists('trabajos','latitude','latitud');
SELECT public._rename_col_if_exists('trabajos','longitude','longitud');
SELECT public._rename_col_if_exists('trabajos','description','descripcion');
SELECT public._rename_col_if_exists('trabajos','scheduledDate','fecha_programada');
SELECT public._rename_col_if_exists('trabajos','serviceMetadata','metadatos_servicio');
SELECT public._rename_col_if_exists('trabajos','pricingMode','modalidad_cobro');
SELECT public._rename_col_if_exists('trabajos','paymentStatus','estado_pago');
SELECT public._rename_col_if_exists('trabajos','comunaId','id_comuna');
SELECT public._rename_col_if_exists('trabajos','pricingSnapshot','instantanea_precio');
SELECT public._rename_col_if_exists('trabajos','serviceSkuId','id_sku_servicio');
SELECT public._rename_col_if_exists('trabajos','hourlyBlockHours','horas_bloque');
SELECT public._rename_col_if_exists('trabajos','selectedQuoteId','id_cotizacion_seleccionada');
SELECT public._rename_col_if_exists('trabajos','createdAt','creado_en');
SELECT public._rename_col_if_exists('trabajos','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('pagos','jobId','id_trabajo');
SELECT public._rename_col_if_exists('pagos','changeOrderId','id_orden_cambio');
SELECT public._rename_col_if_exists('pagos','paymentType','tipo_pago');
SELECT public._rename_col_if_exists('pagos','amount','monto');
SELECT public._rename_col_if_exists('pagos','currency','moneda');
SELECT public._rename_col_if_exists('pagos','status','estado');
SELECT public._rename_col_if_exists('pagos','paymentMethod','metodo_pago');
SELECT public._rename_col_if_exists('pagos','transactionId','id_transaccion');
SELECT public._rename_col_if_exists('pagos','authorizedAt','autorizado_en');
SELECT public._rename_col_if_exists('pagos','releasedAt','liberado_en');
SELECT public._rename_col_if_exists('pagos','refundedAt','reembolsado_en');
SELECT public._rename_col_if_exists('pagos','createdAt','creado_en');
SELECT public._rename_col_if_exists('pagos','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('mensajes','jobId','id_trabajo');
SELECT public._rename_col_if_exists('mensajes','senderId','id_remitente');
SELECT public._rename_col_if_exists('mensajes','receiverId','id_destinatario');
SELECT public._rename_col_if_exists('mensajes','content','contenido');
SELECT public._rename_col_if_exists('mensajes','type','tipo');
SELECT public._rename_col_if_exists('mensajes','imagePath','ruta_imagen');
SELECT public._rename_col_if_exists('mensajes','isRead','leido');
SELECT public._rename_col_if_exists('mensajes','createdAt','creado_en');

SELECT public._rename_col_if_exists('disputas','jobId','id_trabajo');
SELECT public._rename_col_if_exists('disputas','openedBy','abierta_por');
SELECT public._rename_col_if_exists('disputas','reason','motivo');
SELECT public._rename_col_if_exists('disputas','description','descripcion');
SELECT public._rename_col_if_exists('disputas','status','estado');
SELECT public._rename_col_if_exists('disputas','resolution','resolucion');
SELECT public._rename_col_if_exists('disputas','resolvedBy','resuelta_por');
SELECT public._rename_col_if_exists('disputas','resolvedAt','resuelta_en');
SELECT public._rename_col_if_exists('disputas','createdAt','creado_en');
SELECT public._rename_col_if_exists('disputas','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('notificaciones','userId','id_usuario');
SELECT public._rename_col_if_exists('notificaciones','type','tipo');
SELECT public._rename_col_if_exists('notificaciones','title','titulo');
SELECT public._rename_col_if_exists('notificaciones','body','cuerpo');
SELECT public._rename_col_if_exists('notificaciones','relatedId','id_relacionado');
SELECT public._rename_col_if_exists('notificaciones','isRead','leido');
SELECT public._rename_col_if_exists('notificaciones','createdAt','creado_en');

SELECT public._rename_col_if_exists('calificaciones','jobId','id_trabajo');
SELECT public._rename_col_if_exists('calificaciones','userId','id_usuario');
SELECT public._rename_col_if_exists('calificaciones','score','puntaje');
SELECT public._rename_col_if_exists('calificaciones','comment','comentario');
SELECT public._rename_col_if_exists('calificaciones','createdAt','creado_en');

SELECT public._rename_col_if_exists('reportes','reporterId','id_reportante');
SELECT public._rename_col_if_exists('reportes','reportedUserId','id_usuario_reportado');
SELECT public._rename_col_if_exists('reportes','reason','motivo');
SELECT public._rename_col_if_exists('reportes','description','descripcion');
SELECT public._rename_col_if_exists('reportes','status','estado');
SELECT public._rename_col_if_exists('reportes','createdAt','creado_en');

SELECT public._rename_col_if_exists('propuestas_cotizacion','jobId','id_trabajo');
SELECT public._rename_col_if_exists('propuestas_cotizacion','workerId','id_trabajador');
SELECT public._rename_col_if_exists('propuestas_cotizacion','montoTotalClp','monto_total_clp');
SELECT public._rename_col_if_exists('propuestas_cotizacion','validezHasta','validez_hasta');
SELECT public._rename_col_if_exists('propuestas_cotizacion','createdAt','creado_en');

SELECT public._rename_col_if_exists('ordenes_cambio','jobId','id_trabajo');
SELECT public._rename_col_if_exists('ordenes_cambio','workerId','id_trabajador');
SELECT public._rename_col_if_exists('ordenes_cambio','montoClp','monto_clp');
SELECT public._rename_col_if_exists('ordenes_cambio','paymentId','id_pago');
SELECT public._rename_col_if_exists('ordenes_cambio','createdAt','creado_en');
SELECT public._rename_col_if_exists('ordenes_cambio','respondedAt','respondido_en');

SELECT public._rename_col_if_exists('fotos_trabajo','jobId','id_trabajo');
SELECT public._rename_col_if_exists('fotos_trabajo','photoPath','ruta_foto');
SELECT public._rename_col_if_exists('fotos_trabajo','mediaType','tipo_medio');
SELECT public._rename_col_if_exists('fotos_trabajo','createdAt','creado_en');

SELECT public._rename_col_if_exists('portafolio_trabajador','workerId','id_trabajador');
SELECT public._rename_col_if_exists('portafolio_trabajador','photoPath','ruta_foto');
SELECT public._rename_col_if_exists('portafolio_trabajador','description','descripcion');
SELECT public._rename_col_if_exists('portafolio_trabajador','mediaType','tipo_medio');
SELECT public._rename_col_if_exists('portafolio_trabajador','createdAt','creado_en');

SELECT public._rename_col_if_exists('trabajador_servicios','workerId','id_trabajador');
SELECT public._rename_col_if_exists('trabajador_servicios','serviceCategory','categoria_servicio');

SELECT public._rename_col_if_exists('cancelaciones_trabajo','jobId','id_trabajo');
SELECT public._rename_col_if_exists('cancelaciones_trabajo','cancelledBy','cancelado_por');
SELECT public._rename_col_if_exists('cancelaciones_trabajo','reason','motivo');
SELECT public._rename_col_if_exists('cancelaciones_trabajo','cancelledAt','cancelado_en');

SELECT public._rename_col_if_exists('registros_error_app','userId','id_usuario');
SELECT public._rename_col_if_exists('registros_error_app','errorType','tipo_error');
SELECT public._rename_col_if_exists('registros_error_app','message','mensaje');
SELECT public._rename_col_if_exists('registros_error_app','stackTrace','traza_pila');
SELECT public._rename_col_if_exists('registros_error_app','metadata','metadatos');
SELECT public._rename_col_if_exists('registros_error_app','status','estado');
SELECT public._rename_col_if_exists('registros_error_app','appVersion','version_app');
SELECT public._rename_col_if_exists('registros_error_app','platform','plataforma');
SELECT public._rename_col_if_exists('registros_error_app','createdAt','creado_en');

SELECT public._rename_col_if_exists('eventos_abuso','userId','id_usuario');
SELECT public._rename_col_if_exists('eventos_abuso','abuseType','tipo_abuso');
SELECT public._rename_col_if_exists('eventos_abuso','count','conteo');
SELECT public._rename_col_if_exists('eventos_abuso','detectedAt','detectado_en');
SELECT public._rename_col_if_exists('eventos_abuso','actionTaken','accion_tomada');
SELECT public._rename_col_if_exists('eventos_abuso','actionTakenAt','accion_tomada_en');
SELECT public._rename_col_if_exists('eventos_abuso','isResolved','resuelto');

SELECT public._rename_col_if_exists('acciones_pendientes','userId','id_usuario');
SELECT public._rename_col_if_exists('acciones_pendientes','actionType','tipo_accion');
SELECT public._rename_col_if_exists('acciones_pendientes','entityType','tipo_entidad');
SELECT public._rename_col_if_exists('acciones_pendientes','entityId','id_entidad');
SELECT public._rename_col_if_exists('acciones_pendientes','data','datos');
SELECT public._rename_col_if_exists('acciones_pendientes','status','estado');
SELECT public._rename_col_if_exists('acciones_pendientes','retryCount','conteo_reintentos');
SELECT public._rename_col_if_exists('acciones_pendientes','errorMessage','mensaje_error');
SELECT public._rename_col_if_exists('acciones_pendientes','createdAt','creado_en');
SELECT public._rename_col_if_exists('acciones_pendientes','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('bloqueos_usuario','blockerId','id_bloqueador');
SELECT public._rename_col_if_exists('bloqueos_usuario','blockedUserId','id_bloqueado');
SELECT public._rename_col_if_exists('bloqueos_usuario','createdAt','creado_en');

SELECT public._rename_col_if_exists('consentimientos_usuario','userId','id_usuario');
SELECT public._rename_col_if_exists('consentimientos_usuario','consentVersion','version_consentimiento');
SELECT public._rename_col_if_exists('consentimientos_usuario','accepted','aceptado');
SELECT public._rename_col_if_exists('consentimientos_usuario','acceptedAt','aceptado_en');
SELECT public._rename_col_if_exists('consentimientos_usuario','ipAddress','direccion_ip');
SELECT public._rename_col_if_exists('consentimientos_usuario','userAgent','agente_usuario');

SELECT public._rename_col_if_exists('banderas_funcionalidad','flagName','nombre_bandera');
SELECT public._rename_col_if_exists('banderas_funcionalidad','isEnabled','habilitada');
SELECT public._rename_col_if_exists('banderas_funcionalidad','appVersion','version_app');
SELECT public._rename_col_if_exists('banderas_funcionalidad','role','rol');
SELECT public._rename_col_if_exists('banderas_funcionalidad','userId','id_usuario');
SELECT public._rename_col_if_exists('banderas_funcionalidad','createdAt','creado_en');
SELECT public._rename_col_if_exists('banderas_funcionalidad','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('suscripciones','userId','id_usuario');
SELECT public._rename_col_if_exists('suscripciones','planType','tipo_plan');
SELECT public._rename_col_if_exists('suscripciones','status','estado');
SELECT public._rename_col_if_exists('suscripciones','startDate','fecha_inicio');
SELECT public._rename_col_if_exists('suscripciones','endDate','fecha_fin');
SELECT public._rename_col_if_exists('suscripciones','createdAt','creado_en');
SELECT public._rename_col_if_exists('suscripciones','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('impulsos','workerId','id_trabajador');
SELECT public._rename_col_if_exists('impulsos','boostType','tipo_impulso');
SELECT public._rename_col_if_exists('impulsos','startDate','fecha_inicio');
SELECT public._rename_col_if_exists('impulsos','endDate','fecha_fin');
SELECT public._rename_col_if_exists('impulsos','createdAt','creado_en');

SELECT public._rename_col_if_exists('eventos_analitica','eventName','nombre_evento');
SELECT public._rename_col_if_exists('eventos_analitica','userId','id_usuario');
SELECT public._rename_col_if_exists('eventos_analitica','role','rol');
SELECT public._rename_col_if_exists('eventos_analitica','timestamp','marca_tiempo');
SELECT public._rename_col_if_exists('eventos_analitica','metadata','metadatos');

SELECT public._rename_col_if_exists('configuraciones_servicio','serviceId','id_servicio');
SELECT public._rename_col_if_exists('configuraciones_servicio','configSchema','esquema_config');
SELECT public._rename_col_if_exists('configuraciones_servicio','createdAt','creado_en');
SELECT public._rename_col_if_exists('configuraciones_servicio','updatedAt','actualizado_en');

SELECT public._rename_col_if_exists('codigos_restablecimiento','userId','id_usuario');
SELECT public._rename_col_if_exists('codigos_restablecimiento','code','codigo');
SELECT public._rename_col_if_exists('codigos_restablecimiento','email','correo');
SELECT public._rename_col_if_exists('codigos_restablecimiento','expiresAt','expira_en');
SELECT public._rename_col_if_exists('codigos_restablecimiento','isUsed','usado');
SELECT public._rename_col_if_exists('codigos_restablecimiento','createdAt','creado_en');

SELECT public._rename_col_if_exists('tickets_soporte','job_id','id_trabajo');
SELECT public._rename_col_if_exists('tickets_soporte','client_name','nombre_cliente');
SELECT public._rename_col_if_exists('tickets_soporte','worker_name','nombre_trabajador');
SELECT public._rename_col_if_exists('tickets_soporte','issue','asunto');
SELECT public._rename_col_if_exists('tickets_soporte','escrow_amount','monto_escrow');
SELECT public._rename_col_if_exists('tickets_soporte','status','estado');
SELECT public._rename_col_if_exists('tickets_soporte','created_at','creado_en');

DROP FUNCTION IF EXISTS public._rename_col_if_exists(text, text, text);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'workers_userId_fkey') THEN
    ALTER TABLE public.trabajadores RENAME CONSTRAINT "workers_userId_fkey" TO trabajadores_id_usuario_fkey;
  END IF;
END $$;

-- is_admin ANTES de updates con trigger
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.perfiles
    WHERE id = auth.uid() AND rol IN ('admin', 'administrador')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.rol IS DISTINCT FROM OLD.rol THEN
      RAISE EXCEPTION 'No puedes cambiar tu rol';
    END IF;
    IF NEW.estado_cuenta IS DISTINCT FROM OLD.estado_cuenta THEN
      RAISE EXCEPTION 'No puedes cambiar el estado de tu cuenta';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Valores ES (trigger aÃºn dropeado)
UPDATE public.perfiles SET rol = CASE rol
  WHEN 'user' THEN 'usuario' WHEN 'worker' THEN 'trabajador' WHEN 'admin' THEN 'administrador' ELSE rol END
WHERE rol IN ('user','worker','admin');

UPDATE public.perfiles SET estado_cuenta = CASE estado_cuenta
  WHEN 'active' THEN 'activo' WHEN 'suspended' THEN 'suspendido'
  WHEN 'blocked' THEN 'bloqueado' WHEN 'deleted' THEN 'eliminado' ELSE estado_cuenta END
WHERE estado_cuenta IN ('active','suspended','blocked','deleted');

UPDATE public.trabajos SET estado = CASE estado
  WHEN 'pending' THEN 'pendiente' WHEN 'accepted' THEN 'aceptado' WHEN 'in_progress' THEN 'en_curso'
  WHEN 'completed' THEN 'completado' WHEN 'cancelled' THEN 'cancelado' WHEN 'expired' THEN 'expirado'
  WHEN 'no_show' THEN 'no_asistio' WHEN 'awaiting_payment' THEN 'esperando_pago'
  WHEN 'awaiting_quotes' THEN 'esperando_cotizaciones' WHEN 'quote_selected' THEN 'cotizacion_seleccionada'
  WHEN 'paused_change_order' THEN 'pausado_orden_cambio' WHEN 'awaiting_client_approval' THEN 'esperando_aprobacion_cliente'
  ELSE estado END;

UPDATE public.trabajos SET estado_pago = CASE estado_pago
  WHEN 'none' THEN 'ninguno' WHEN 'pending' THEN 'pendiente' WHEN 'authorized' THEN 'autorizado'
  WHEN 'held' THEN 'retenido' WHEN 'released' THEN 'liberado' WHEN 'refunded' THEN 'reembolsado'
  ELSE estado_pago END WHERE estado_pago IS NOT NULL;

UPDATE public.trabajos SET modalidad_cobro = CASE modalidad_cobro
  WHEN 'legacy' THEN 'legado' WHEN 'fixed_price' THEN 'precio_fijo'
  WHEN 'hourly_block' THEN 'bloque_horas' WHEN 'open_quote' THEN 'cotizacion_abierta'
  ELSE modalidad_cobro END WHERE modalidad_cobro IS NOT NULL;

UPDATE public.pagos SET estado = CASE estado
  WHEN 'pending' THEN 'pendiente' WHEN 'authorized' THEN 'autorizado' WHEN 'held' THEN 'retenido'
  WHEN 'released' THEN 'liberado' WHEN 'refunded' THEN 'reembolsado' ELSE estado END;

UPDATE public.pagos SET tipo_pago = CASE tipo_pago
  WHEN 'primary' THEN 'principal' WHEN 'change_order' THEN 'orden_cambio' WHEN 'overtime' THEN 'horas_extra'
  ELSE tipo_pago END WHERE tipo_pago IS NOT NULL;

UPDATE public.disputas SET estado = CASE estado
  WHEN 'open' THEN 'abierta' WHEN 'under_review' THEN 'en_revision' WHEN 'resolved' THEN 'resuelta' ELSE estado END;

UPDATE public.disputas SET motivo = CASE motivo
  WHEN 'quality' THEN 'calidad' WHEN 'payment' THEN 'pago' WHEN 'behavior' THEN 'conducta' WHEN 'other' THEN 'otro'
  ELSE motivo END;

UPDATE public.reportes SET estado = CASE estado
  WHEN 'pending' THEN 'pendiente' WHEN 'reviewed' THEN 'revisado' WHEN 'resolved' THEN 'resuelto' WHEN 'dismissed' THEN 'descartado'
  ELSE estado END;

UPDATE public.servicios SET categoria = CASE categoria
  WHEN 'construction' THEN 'construccion' WHEN 'plumbing' THEN 'plomeria' WHEN 'electrical' THEN 'electricidad'
  WHEN 'cleaning' THEN 'limpieza' WHEN 'assembly' THEN 'ensamblaje' WHEN 'tech_support' THEN 'soporte_tecnico'
  WHEN 'gardening' THEN 'jardinera' WHEN 'moving' THEN 'mudanza' ELSE categoria END;

UPDATE public.servicios SET modelo_precio = CASE modelo_precio
  WHEN 'hourly' THEN 'por_hora' WHEN 'fixed' THEN 'fijo' WHEN 'per_item' THEN 'por_item' ELSE modelo_precio END
WHERE modelo_precio IS NOT NULL;

UPDATE public.trabajadores SET categoria_servicio = CASE categoria_servicio
  WHEN 'construction' THEN 'construccion' WHEN 'plumbing' THEN 'plomeria' WHEN 'electrical' THEN 'electricidad'
  WHEN 'cleaning' THEN 'limpieza' WHEN 'assembly' THEN 'ensamblaje' WHEN 'tech_support' THEN 'soporte_tecnico'
  WHEN 'gardening' THEN 'jardinera' WHEN 'moving' THEN 'mudanza' ELSE categoria_servicio END
WHERE categoria_servicio IS NOT NULL;

DO $$
BEGIN
  IF to_regclass('public.trabajador_servicios') IS NOT NULL THEN
    UPDATE public.trabajador_servicios SET categoria_servicio = CASE categoria_servicio
      WHEN 'construction' THEN 'construccion' WHEN 'plumbing' THEN 'plomeria' WHEN 'electrical' THEN 'electricidad'
      WHEN 'cleaning' THEN 'limpieza' WHEN 'assembly' THEN 'ensamblaje' WHEN 'tech_support' THEN 'soporte_tecnico'
      WHEN 'gardening' THEN 'jardinera' WHEN 'moving' THEN 'mudanza' ELSE categoria_servicio END
    WHERE categoria_servicio IS NOT NULL;
  END IF;
  IF to_regclass('public.propuestas_cotizacion') IS NOT NULL THEN
    UPDATE public.propuestas_cotizacion SET estado = CASE estado
      WHEN 'submitted' THEN 'enviada' WHEN 'withdrawn' THEN 'retirada' WHEN 'accepted' THEN 'aceptada' WHEN 'rejected' THEN 'rechazada'
      ELSE estado END;
  END IF;
  IF to_regclass('public.ordenes_cambio') IS NOT NULL THEN
    UPDATE public.ordenes_cambio SET estado = CASE estado
      WHEN 'pending_client' THEN 'pendiente_cliente' WHEN 'approved' THEN 'aprobada' WHEN 'rejected' THEN 'rechazada'
      WHEN 'paid' THEN 'pagada' WHEN 'cancelled' THEN 'cancelada' ELSE estado END;
  END IF;
  IF to_regclass('public.registros_error_app') IS NOT NULL THEN
    UPDATE public.registros_error_app SET estado = CASE estado
      WHEN 'new' THEN 'nuevo' WHEN 'acknowledged' THEN 'reconocido' WHEN 'resolved' THEN 'resuelto' WHEN 'ignored' THEN 'ignorado'
      ELSE estado END;
  END IF;
  IF to_regclass('public.acciones_pendientes') IS NOT NULL THEN
    UPDATE public.acciones_pendientes SET estado = CASE estado
      WHEN 'pending_sync' THEN 'pendiente_sync' WHEN 'syncing' THEN 'sincronizando' WHEN 'synced' THEN 'sincronizado' WHEN 'failed' THEN 'fallido'
      ELSE estado END;
  END IF;
  IF to_regclass('public.suscripciones') IS NOT NULL THEN
    UPDATE public.suscripciones SET estado = CASE estado
      WHEN 'active' THEN 'activa' WHEN 'cancelled' THEN 'cancelada' WHEN 'expired' THEN 'expirada' ELSE estado END;
    UPDATE public.suscripciones SET tipo_plan = CASE tipo_plan
      WHEN 'free' THEN 'gratuito' WHEN 'basic' THEN 'basico' WHEN 'premium' THEN 'premium' WHEN 'enterprise' THEN 'empresarial'
      ELSE tipo_plan END;
  END IF;
  IF to_regclass('public.impulsos') IS NOT NULL THEN
    UPDATE public.impulsos SET tipo_impulso = CASE tipo_impulso
      WHEN 'visibility' THEN 'visibilidad' WHEN 'priority' THEN 'prioridad' WHEN 'featured' THEN 'destacado' ELSE tipo_impulso END;
  END IF;
  IF to_regclass('public.mensajes') IS NOT NULL THEN
    UPDATE public.mensajes SET tipo = CASE tipo WHEN 'text' THEN 'texto' WHEN 'image' THEN 'imagen' ELSE tipo END;
  END IF;
  IF to_regclass('public.fotos_trabajo') IS NOT NULL THEN
    UPDATE public.fotos_trabajo SET tipo_medio = CASE tipo_medio WHEN 'photo' THEN 'foto' WHEN 'video' THEN 'video' ELSE tipo_medio END;
  END IF;
  IF to_regclass('public.portafolio_trabajador') IS NOT NULL THEN
    UPDATE public.portafolio_trabajador SET tipo_medio = CASE tipo_medio WHEN 'photo' THEN 'foto' WHEN 'video' THEN 'video' ELSE tipo_medio END;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.tickets_soporte') IS NOT NULL THEN
    UPDATE public.tickets_soporte SET estado = CASE estado
      WHEN 'Pending' THEN 'pendiente' WHEN 'Resolved' THEN 'resuelto' ELSE lower(estado) END;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  requested_role text;
  safe_role text;
  display_name text;
BEGIN
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', 'usuario')));
  IF requested_role IN ('worker', 'trabajador') THEN
    safe_role := 'trabajador';
  ELSE
    safe_role := 'usuario';
  END IF;

  display_name := trim(coalesce(
    nullif(new.raw_user_meta_data->>'name', ''),
    nullif(new.raw_user_meta_data->>'nombre', ''),
    nullif(new.raw_user_meta_data->>'full_name', ''),
    nullif(new.raw_user_meta_data->>'given_name', ''),
    split_part(coalesce(new.email, ''), '@', 1)
  ));

  INSERT INTO public.perfiles (id, nombre, correo, rol, estado_cuenta, creado_en)
  VALUES (
    new.id, display_name, new.email, safe_role, 'activo',
    to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS protect_profiles_sensitive ON public.perfiles;
CREATE TRIGGER protect_profiles_sensitive
  BEFORE UPDATE ON public.perfiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_sensitive_fields();

DO $$
BEGIN
  IF to_regclass('public.registros_error_app') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS app_error_logs_insert ON public.registros_error_app';
    EXECUTE 'DROP POLICY IF EXISTS registros_error_app_insert ON public.registros_error_app';
    EXECUTE $pol$
      CREATE POLICY registros_error_app_insert ON public.registros_error_app
        FOR INSERT TO authenticated
        WITH CHECK (id_usuario IS NULL OR id_usuario = auth.uid())
    $pol$;
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.trabajos') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_trabajos_estado ON public.trabajos (estado)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_trabajos_id_usuario ON public.trabajos (id_usuario)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_trabajos_id_trabajador ON public.trabajos (id_trabajador)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_trabajos_creado_en ON public.trabajos (creado_en DESC)';
  END IF;
  IF to_regclass('public.disputas') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_disputas_estado ON public.disputas (estado)';
  END IF;
  IF to_regclass('public.pagos') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_pagos_id_trabajo ON public.pagos (id_trabajo)';
  END IF;
  IF to_regclass('public.notificaciones') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_notificaciones_id_usuario ON public.notificaciones (id_usuario)';
  END IF;
  IF to_regclass('public.mensajes') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_mensajes_id_trabajo ON public.mensajes (id_trabajo)';
  END IF;
  IF to_regclass('public.perfiles') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_perfiles_rol ON public.perfiles (rol)';
  END IF;
  IF to_regclass('public.servicios') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_servicios_categoria ON public.servicios (categoria)';
  END IF;
  IF to_regclass('public.trabajadores') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_trabajadores_categoria ON public.trabajadores (categoria_servicio)';
  END IF;
END $$;

COMMENT ON TABLE public.perfiles IS 'Perfiles de usuario vinculados a auth.users';
COMMENT ON COLUMN public.perfiles.rol IS 'usuario | trabajador | administrador';
COMMENT ON COLUMN public.perfiles.estado_cuenta IS 'activo | suspendido | bloqueado | eliminado';

COMMIT;
