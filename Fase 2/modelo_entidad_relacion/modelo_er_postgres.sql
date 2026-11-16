-- MyWorksApp — modelo entidad-relación (PostgreSQL)
-- Generado desde la BD viva wxqrfcqifkfgawrnqmnj (migración 20261116044049).
-- Solo estructura (tablas, PK, UNIQUE, FK). Sin RLS, funciones ni datos.
-- Esquema de referencia: no ejecutar contra producción.

-- perfiles.id referencia auth.users(id) en Supabase; aquí se omite esa FK externa.

CREATE TABLE acciones_pendientes (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_accion text NOT NULL,
  tipo_entidad text NOT NULL,
  id_entidad text,
  datos text NOT NULL,
  estado text NOT NULL,
  conteo_reintentos integer,
  mensaje_error text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE acuerdos_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  tipo text NOT NULL,
  propuesto_por uuid NOT NULL,
  acepta_cliente boolean,
  acepta_trabajador boolean,
  estado text NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  aplicado_en timestamp with time zone,
  PRIMARY KEY (id)
);

CREATE TABLE app_config (
  clave text NOT NULL,
  valor text NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (clave)
);

CREATE TABLE banderas_funcionalidad (
  id text NOT NULL,
  nombre_bandera text NOT NULL,
  habilitada integer NOT NULL,
  version_app text,
  rol text,
  id_usuario uuid,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE bloqueos_pin_inicio (
  id_trabajo text NOT NULL,
  fallos integer NOT NULL,
  bloqueado_hasta timestamp with time zone,
  pin_ok_hasta timestamp with time zone,
  pin_ok_usuario uuid,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id_trabajo)
);

CREATE TABLE bloqueos_usuario (
  id text NOT NULL,
  id_bloqueador uuid NOT NULL,
  id_bloqueado uuid NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_bloqueador, id_bloqueado)
);

CREATE TABLE calificaciones (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_usuario uuid,
  puntaje integer NOT NULL,
  comentario text,
  creado_en text NOT NULL,
  peso_confianza numeric(4,3) NOT NULL,
  estado_revision text NOT NULL,
  motivo_revision text,
  direccion text NOT NULL,
  id_calificado uuid NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_trabajo, direccion)
);

CREATE TABLE calificaciones_cliente (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_cliente uuid NOT NULL,
  id_trabajador uuid NOT NULL,
  puntaje smallint NOT NULL,
  comentario text,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_trabajo)
);

CREATE TABLE cancelaciones_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  cancelado_por uuid NOT NULL,
  motivo text NOT NULL,
  cancelado_en text NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_trabajo)
);

CREATE TABLE codigos_restablecimiento (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  codigo text NOT NULL,
  correo text NOT NULL,
  expira_en text NOT NULL,
  usado integer,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE comunas (
  id text NOT NULL,
  id_region text NOT NULL,
  nombre text NOT NULL,
  latitud double precision,
  longitud double precision,
  activa integer NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE configuraciones_servicio (
  id text NOT NULL,
  id_servicio text NOT NULL,
  esquema_config text NOT NULL,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_servicio)
);

CREATE TABLE consentimientos_usuario (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  version_consentimiento text NOT NULL,
  aceptado integer NOT NULL,
  aceptado_en text NOT NULL,
  direccion_ip text,
  agente_usuario text,
  PRIMARY KEY (id)
);

CREATE TABLE cuentas_bancarias (
  id_usuario uuid NOT NULL,
  banco text NOT NULL,
  tipo_cuenta text NOT NULL,
  numero_cuenta text NOT NULL,
  rut_titular text NOT NULL,
  nombre_titular text NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id_usuario)
);

CREATE TABLE dispositivos_push (
  token text NOT NULL,
  id_usuario uuid NOT NULL,
  plataforma text NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (token)
);

CREATE TABLE disputa_mensajes (
  id text NOT NULL,
  id_disputa text NOT NULL,
  id_autor uuid,
  cuerpo text NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE disputas (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  abierta_por uuid NOT NULL,
  motivo text NOT NULL,
  descripcion text,
  estado text NOT NULL,
  resolucion text,
  resuelta_por uuid,
  resuelta_en text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  origen text NOT NULL,
  decision_sugerida text,
  motivo_regla text,
  vence_en timestamp with time zone,
  PRIMARY KEY (id)
);

CREATE TABLE eventos_abuso (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_abuso text NOT NULL,
  conteo integer NOT NULL,
  detectado_en text NOT NULL,
  accion_tomada text,
  accion_tomada_en text,
  resuelto integer,
  PRIMARY KEY (id)
);

CREATE TABLE eventos_analitica (
  id text NOT NULL,
  nombre_evento text NOT NULL,
  id_usuario uuid,
  rol text,
  marca_tiempo text NOT NULL,
  metadatos text,
  PRIMARY KEY (id)
);

CREATE TABLE eventos_ranking (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  id_trabajo text,
  tipo_evento text NOT NULL,
  factores jsonb NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE fotos_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  ruta_foto text NOT NULL,
  creado_en text NOT NULL,
  tipo_medio text NOT NULL,
  imagen_webp bytea,
  PRIMARY KEY (id)
);

CREATE TABLE impulsos (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  tipo_impulso text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE intentos_pin_inicio (
  id bigint NOT NULL,
  id_trabajo text NOT NULL,
  id_usuario uuid,
  resultado text NOT NULL,
  intentos_restantes integer NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE liquidaciones (
  id text NOT NULL,
  id_pago text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador text,
  monto_clp numeric NOT NULL,
  proveedor text NOT NULL,
  referencia_transferencia text NOT NULL,
  notas text,
  id_operador text NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  estado_transferencia text NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_pago)
);

CREATE TABLE mensajes (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_remitente uuid NOT NULL,
  id_destinatario uuid NOT NULL,
  contenido text NOT NULL,
  tipo text NOT NULL,
  ruta_imagen text,
  leido integer NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE metodos_pago_oneclick (
  id_usuario uuid NOT NULL,
  username text NOT NULL,
  tbk_user text,
  tipo_tarjeta text,
  ultimos4 text,
  estado text NOT NULL,
  token_inscripcion text,
  id_trabajo_pendiente text,
  creado_en timestamp with time zone NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  url_inscripcion text,
  ticket_handoff text,
  PRIMARY KEY (id_usuario)
);

CREATE TABLE notificaciones (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo text NOT NULL,
  titulo text NOT NULL,
  cuerpo text NOT NULL,
  id_relacionado text,
  leido integer NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE ordenes_cambio (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  tipo text NOT NULL,
  titulo text NOT NULL,
  descripcion text NOT NULL,
  monto_clp integer NOT NULL,
  estado text NOT NULL,
  id_pago text,
  creado_en text NOT NULL,
  respondido_en text,
  PRIMARY KEY (id)
);

CREATE TABLE pagos (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_orden_cambio text,
  tipo_pago text NOT NULL,
  monto numeric(12,0) NOT NULL,
  moneda text NOT NULL,
  estado text NOT NULL,
  metodo_pago text,
  id_transaccion text,
  autorizado_en text,
  liberado_en text,
  reembolsado_en text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  ambiente text,
  token_tbk text,
  url_tbk text,
  buy_order text,
  handoff_consumido_en timestamp with time zone,
  reembolso_solicitado_en timestamp with time zone,
  orden_detalle_oneclick text,
  cobro_reclamado_en timestamp with time zone,
  origen_retorno text,
  alta_nonce_hash text,
  alta_jti text,
  alta_consumido_en timestamp with time zone,
  PRIMARY KEY (id)
);

CREATE TABLE paises (
  id text NOT NULL,
  nombre text NOT NULL,
  iso2 text NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (iso2)
);

CREATE TABLE perfiles (
  id uuid NOT NULL,
  nombre text NOT NULL,
  correo text,
  rol text NOT NULL,
  estado_cuenta text NOT NULL,
  ruta_foto_perfil text,
  creado_en text NOT NULL,
  reputacion_cliente numeric(3,2),
  calificaciones_cliente integer NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE pines_inicio_trabajo (
  id_trabajo text NOT NULL,
  pin text NOT NULL,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id_trabajo)
);

CREATE TABLE portafolio_trabajador (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  ruta_foto text NOT NULL,
  descripcion text,
  creado_en text NOT NULL,
  tipo_medio text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE propuestas_cotizacion (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  monto_total_clp integer NOT NULL,
  descripcion text NOT NULL,
  validez_hasta text,
  desglose text,
  estado text NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE ranking_aprendizaje (
  id text NOT NULL,
  motivo text NOT NULL,
  pesos_antes jsonb NOT NULL,
  pesos_despues jsonb NOT NULL,
  metricas jsonb,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE ranking_config (
  id text NOT NULL,
  peso_calificacion numeric NOT NULL,
  peso_completados numeric NOT NULL,
  peso_rechazos numeric NOT NULL,
  peso_verificacion numeric NOT NULL,
  peso_impulso numeric NOT NULL,
  peso_recencia numeric NOT NULL,
  peso_confianza numeric NOT NULL,
  prior_bayes numeric NOT NULL,
  n_bayes numeric NOT NULL,
  umbral_revision numeric NOT NULL,
  umbral_auto_excluir numeric NOT NULL,
  aprendizaje_activo integer NOT NULL,
  tasa_aprendizaje numeric NOT NULL,
  pesos_senal jsonb NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE regiones (
  id text NOT NULL,
  id_pais text NOT NULL,
  nombre text NOT NULL,
  codigo_oficial text,
  PRIMARY KEY (id)
);

CREATE TABLE registros_error_app (
  id text NOT NULL,
  id_usuario uuid,
  tipo_error text NOT NULL,
  mensaje text NOT NULL,
  traza_pila text,
  metadatos jsonb,
  estado text NOT NULL,
  version_app text,
  plataforma text,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE reportes (
  id text NOT NULL,
  id_reportante uuid NOT NULL,
  id_usuario_reportado uuid NOT NULL,
  motivo text NOT NULL,
  descripcion text,
  estado text NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE reprogramaciones_trabajo (
  id uuid NOT NULL,
  id_trabajo text NOT NULL,
  propuesta_por uuid NOT NULL,
  rol_proponente text NOT NULL,
  fecha_anterior timestamp with time zone NOT NULL,
  fecha_propuesta timestamp with time zone NOT NULL,
  motivo text,
  estado text NOT NULL,
  respondida_por uuid,
  respondida_en timestamp with time zone,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE senales_resena (
  id text NOT NULL,
  id_calificacion text NOT NULL,
  tipo_senal text NOT NULL,
  puntaje numeric NOT NULL,
  detalle text,
  estado text NOT NULL,
  resuelto_por uuid,
  resuelto_en timestamp with time zone,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id_calificacion, tipo_senal)
);

CREATE TABLE servicios (
  id text NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  categoria text NOT NULL,
  activo integer NOT NULL,
  requiere_certificacion integer NOT NULL,
  modelo_precio text NOT NULL,
  aviso_legal text,
  creado_en text,
  actualizado_en text,
  PRIMARY KEY (id)
);

CREATE TABLE suscripciones (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_plan text NOT NULL,
  estado text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE tickets_soporte (
  id text NOT NULL,
  id_trabajo text,
  nombre_cliente text NOT NULL,
  nombre_trabajador text NOT NULL,
  asunto text NOT NULL,
  monto_escrow integer NOT NULL,
  estado text,
  creado_en timestamp with time zone,
  PRIMARY KEY (id)
);

CREATE TABLE trabajador_horarios (
  id_usuario uuid NOT NULL,
  horarios jsonb NOT NULL,
  actualizado_en timestamp with time zone NOT NULL,
  id uuid NOT NULL,
  dia_semana smallint,
  hora_inicio time without time zone,
  hora_fin time without time zone,
  activo boolean,
  creado_en timestamp with time zone,
  PRIMARY KEY (id),
  UNIQUE (id_usuario, dia_semana)
);

CREATE TABLE trabajador_precios (
  id_usuario uuid NOT NULL,
  codigo text NOT NULL,
  monto_clp numeric(12,0) NOT NULL,
  PRIMARY KEY (id_usuario, codigo)
);

CREATE TABLE trabajador_servicios (
  id_trabajador uuid NOT NULL,
  categoria_servicio text NOT NULL,
  PRIMARY KEY (id_trabajador, categoria_servicio)
);

CREATE TABLE trabajador_servicios_extra (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  titulo text NOT NULL,
  subtitulo text NOT NULL,
  monto_clp numeric(12,0) NOT NULL,
  unidad text NOT NULL,
  PRIMARY KEY (id_usuario, id)
);

CREATE TABLE trabajadores (
  id_usuario uuid NOT NULL,
  profesion text NOT NULL,
  descripcion text,
  calificacion numeric(4,2) NOT NULL,
  disponible integer NOT NULL,
  tarifa_visita numeric(12,0) NOT NULL,
  categoria_servicio text NOT NULL,
  niveles_precio jsonb NOT NULL,
  conteo_rechazos integer NOT NULL,
  servicios_personalizados jsonb NOT NULL,
  precios_configurados integer NOT NULL,
  zona_trabajo text,
  estado_verificacion text NOT NULL,
  nota_verificacion text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric NOT NULL,
  origen_base text,
  score_listado numeric(8,4) NOT NULL,
  prioridad_manual integer NOT NULL,
  score_desglose jsonb NOT NULL,
  ranking_actualizado_en timestamp with time zone,
  radio_urbano_km numeric(5,2) NOT NULL,
  tarifa_fuera_radio_clp integer NOT NULL,
  trabajos_completados integer NOT NULL,
  es_elite boolean,
  id_comuna text,
  id_region text,
  usa_horario boolean NOT NULL,
  pausa_por_trabajo boolean NOT NULL,
  PRIMARY KEY (id_usuario)
);

CREATE TABLE trabajos (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  id_trabajador uuid,
  id_servicio text,
  estado text NOT NULL,
  direccion text NOT NULL,
  latitud double precision,
  longitud double precision,
  descripcion text,
  fecha_programada text,
  metadatos_servicio text,
  modalidad_cobro text,
  estado_pago text,
  id_comuna text,
  instantanea_precio text,
  id_sku_servicio text,
  horas_bloque integer,
  id_cotizacion_seleccionada text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE ubicacion_en_vivo (
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  precision_metros double precision,
  actualizado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id_trabajo)
);

CREATE TABLE verificacion_eventos (
  id uuid NOT NULL,
  id_usuario uuid NOT NULL,
  estado text NOT NULL,
  nota text,
  id_actor uuid,
  creado_en timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

ALTER TABLE acciones_pendientes ADD CONSTRAINT "pending_actions_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE acuerdos_trabajo ADD CONSTRAINT acuerdos_trabajo_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE acuerdos_trabajo ADD CONSTRAINT acuerdos_trabajo_propuesto_por_fkey FOREIGN KEY (propuesto_por) REFERENCES perfiles (id) ON DELETE NO ACTION;
ALTER TABLE banderas_funcionalidad ADD CONSTRAINT banderas_funcionalidad_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE bloqueos_pin_inicio ADD CONSTRAINT bloqueos_pin_inicio_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE bloqueos_usuario ADD CONSTRAINT bloqueos_usuario_id_bloqueado_fkey FOREIGN KEY (id_bloqueado) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE bloqueos_usuario ADD CONSTRAINT bloqueos_usuario_id_bloqueador_fkey FOREIGN KEY (id_bloqueador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE calificaciones ADD CONSTRAINT calificaciones_id_calificado_fkey FOREIGN KEY (id_calificado) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE calificaciones ADD CONSTRAINT calificaciones_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE calificaciones ADD CONSTRAINT "ratings_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD CONSTRAINT calificaciones_cliente_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD CONSTRAINT calificaciones_cliente_id_trabajador_fkey FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD CONSTRAINT calificaciones_cliente_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE cancelaciones_trabajo ADD CONSTRAINT cancelaciones_trabajo_cancelado_por_fkey FOREIGN KEY (cancelado_por) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE cancelaciones_trabajo ADD CONSTRAINT "job_cancellations_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE codigos_restablecimiento ADD CONSTRAINT codigos_restablecimiento_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE comunas ADD CONSTRAINT comunas_id_region_fkey FOREIGN KEY (id_region) REFERENCES regiones (id) ON DELETE NO ACTION;
ALTER TABLE configuraciones_servicio ADD CONSTRAINT "service_configs_serviceId_fkey" FOREIGN KEY (id_servicio) REFERENCES servicios (id) ON DELETE CASCADE;
ALTER TABLE consentimientos_usuario ADD CONSTRAINT "user_consents_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE cuentas_bancarias ADD CONSTRAINT cuentas_bancarias_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE dispositivos_push ADD CONSTRAINT dispositivos_push_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE disputa_mensajes ADD CONSTRAINT disputa_mensajes_id_autor_fkey FOREIGN KEY (id_autor) REFERENCES perfiles (id) ON DELETE NO ACTION;
ALTER TABLE disputa_mensajes ADD CONSTRAINT disputa_mensajes_id_disputa_fkey FOREIGN KEY (id_disputa) REFERENCES disputas (id) ON DELETE CASCADE;
ALTER TABLE disputas ADD CONSTRAINT disputas_abierta_por_fkey FOREIGN KEY (abierta_por) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE disputas ADD CONSTRAINT disputas_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE disputas ADD CONSTRAINT "disputes_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE eventos_abuso ADD CONSTRAINT "abuse_events_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE eventos_analitica ADD CONSTRAINT eventos_analitica_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE eventos_ranking ADD CONSTRAINT eventos_ranking_id_trabajador_fkey FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE eventos_ranking ADD CONSTRAINT eventos_ranking_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE SET NULL;
ALTER TABLE fotos_trabajo ADD CONSTRAINT "job_photos_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE impulsos ADD CONSTRAINT "boosts_workerId_fkey" FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE intentos_pin_inicio ADD CONSTRAINT intentos_pin_inicio_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE intentos_pin_inicio ADD CONSTRAINT intentos_pin_inicio_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE liquidaciones ADD CONSTRAINT liquidaciones_id_pago_fkey FOREIGN KEY (id_pago) REFERENCES pagos (id) ON DELETE NO ACTION;
ALTER TABLE liquidaciones ADD CONSTRAINT liquidaciones_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE NO ACTION;
ALTER TABLE mensajes ADD CONSTRAINT mensajes_id_destinatario_fkey FOREIGN KEY (id_destinatario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE mensajes ADD CONSTRAINT mensajes_id_remitente_fkey FOREIGN KEY (id_remitente) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE mensajes ADD CONSTRAINT "messages_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE metodos_pago_oneclick ADD CONSTRAINT metodos_pago_oneclick_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE notificaciones ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE ordenes_cambio ADD CONSTRAINT "change_orders_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE ordenes_cambio ADD CONSTRAINT ordenes_cambio_id_pago_fkey FOREIGN KEY (id_pago) REFERENCES pagos (id) ON DELETE SET NULL;
ALTER TABLE ordenes_cambio ADD CONSTRAINT ordenes_cambio_id_trabajador_fkey FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE pagos ADD CONSTRAINT pagos_id_orden_cambio_fkey FOREIGN KEY (id_orden_cambio) REFERENCES ordenes_cambio (id) ON DELETE SET NULL;
ALTER TABLE pagos ADD CONSTRAINT "payments_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE pines_inicio_trabajo ADD CONSTRAINT pines_inicio_trabajo_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE portafolio_trabajador ADD CONSTRAINT "worker_portfolio_workerId_fkey" FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE propuestas_cotizacion ADD CONSTRAINT "quote_proposals_jobId_fkey" FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE propuestas_cotizacion ADD CONSTRAINT "quote_proposals_workerId_fkey" FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE regiones ADD CONSTRAINT regiones_id_pais_fkey FOREIGN KEY (id_pais) REFERENCES paises (id) ON DELETE NO ACTION;
ALTER TABLE registros_error_app ADD CONSTRAINT "app_error_logs_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE NO ACTION;
ALTER TABLE reportes ADD CONSTRAINT reportes_id_reportante_fkey FOREIGN KEY (id_reportante) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE reportes ADD CONSTRAINT reportes_id_usuario_reportado_fkey FOREIGN KEY (id_usuario_reportado) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE reprogramaciones_trabajo ADD CONSTRAINT reprogramaciones_propuesta_por_fkey FOREIGN KEY (propuesta_por) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE reprogramaciones_trabajo ADD CONSTRAINT reprogramaciones_respondida_por_fkey FOREIGN KEY (respondida_por) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE reprogramaciones_trabajo ADD CONSTRAINT reprogramaciones_trabajo_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE senales_resena ADD CONSTRAINT senales_resena_id_calificacion_fkey FOREIGN KEY (id_calificacion) REFERENCES calificaciones (id) ON DELETE CASCADE;
ALTER TABLE senales_resena ADD CONSTRAINT senales_resena_resuelto_por_fkey FOREIGN KEY (resuelto_por) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE suscripciones ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE tickets_soporte ADD CONSTRAINT tickets_soporte_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE SET NULL;
ALTER TABLE trabajador_horarios ADD CONSTRAINT trabajador_horarios_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES trabajadores (id_usuario) ON DELETE CASCADE;
ALTER TABLE trabajador_precios ADD CONSTRAINT trabajador_precios_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES trabajadores (id_usuario) ON DELETE CASCADE;
ALTER TABLE trabajador_servicios ADD CONSTRAINT "worker_services_workerId_fkey" FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE trabajador_servicios_extra ADD CONSTRAINT trabajador_servicios_extra_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES trabajadores (id_usuario) ON DELETE CASCADE;
ALTER TABLE trabajadores ADD CONSTRAINT trabajadores_id_comuna_fkey FOREIGN KEY (id_comuna) REFERENCES comunas (id) ON DELETE SET NULL;
ALTER TABLE trabajadores ADD CONSTRAINT trabajadores_id_region_fkey FOREIGN KEY (id_region) REFERENCES regiones (id) ON DELETE SET NULL;
ALTER TABLE trabajadores ADD CONSTRAINT trabajadores_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE trabajos ADD CONSTRAINT "jobs_serviceId_fkey" FOREIGN KEY (id_servicio) REFERENCES servicios (id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD CONSTRAINT "jobs_userId_fkey" FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;
ALTER TABLE trabajos ADD CONSTRAINT "jobs_workerId_fkey" FOREIGN KEY (id_trabajador) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD CONSTRAINT trabajos_id_comuna_fkey FOREIGN KEY (id_comuna) REFERENCES comunas (id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD CONSTRAINT trabajos_id_cotizacion_seleccionada_fkey FOREIGN KEY (id_cotizacion_seleccionada) REFERENCES propuestas_cotizacion (id) ON DELETE SET NULL;
ALTER TABLE ubicacion_en_vivo ADD CONSTRAINT ubicacion_en_vivo_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES trabajos (id) ON DELETE CASCADE;
ALTER TABLE ubicacion_en_vivo ADD CONSTRAINT ubicacion_en_vivo_trabajador_fkey FOREIGN KEY (id_trabajador) REFERENCES trabajadores (id_usuario) ON DELETE CASCADE;
ALTER TABLE verificacion_eventos ADD CONSTRAINT verificacion_eventos_id_actor_fkey FOREIGN KEY (id_actor) REFERENCES perfiles (id) ON DELETE SET NULL;
ALTER TABLE verificacion_eventos ADD CONSTRAINT verificacion_eventos_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES perfiles (id) ON DELETE CASCADE;

-- Relaciones lógicas (sin FOREIGN KEY física en la BD real):
--   liquidaciones(id_trabajador) -> perfiles(id): profesional liquidado; text que guarda el uuid del perfil
--   liquidaciones(id_operador) -> perfiles(id): administrador que confirmó la transferencia; text con uuid o 'sistema'
--   metodos_pago_oneclick(id_trabajo_pendiente) -> trabajos(id): trabajo que espera la inscripción Oneclick para cobrarse
--   bloqueos_pin_inicio(pin_ok_usuario) -> perfiles(id): usuario que validó el PIN (ventana pin_ok_hasta)
--   trabajos(id_trabajador, id_sku_servicio) -> trabajador_precios(id_usuario, codigo): SKU de precio elegido; también admite 'tier_<n>', por eso no es FK
--   trabajador_servicios(categoria_servicio) -> servicios(categoria): categoría ofrecida; servicios.categoria no es única
