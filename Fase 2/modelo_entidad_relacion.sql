-- MyWorksApp — modelo entidad-relación (PostgreSQL)
-- Versión 2.5 · 57 tablas public · generado 2026-11-17 (America/Santiago)
--
-- Documentación del esquema REAL de wxqrfcqifkfgawrnqmnj
-- hasta 20261117223850_quitar_indice_duplicado_servicios.
-- Incluye tipos, nulos, defaults, PK, FK, UNIQUE, CHECK e índices.
-- No incluye RLS, triggers ni el cuerpo de las funciones (van en el diccionario).
-- No es un script de restauración completa. No ejecutar contra producción.
--
-- perfiles.id coincide con auth.users.id.
-- No hay ENUM en public; la vista encuestas_testing_con_puntaje no se incluye.
-- trabajador_precios.id_usuario y trabajador_servicios_extra.id_usuario son uuid
-- con FK a trabajadores.id_usuario (auditoría 2026-11-16).

BEGIN;

CREATE TABLE perfiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL DEFAULT '',
  correo text,
  rol text NOT NULL DEFAULT 'usuario',
  estado_cuenta text NOT NULL DEFAULT 'activo',
  ruta_foto_perfil text,
  creado_en text NOT NULL DEFAULT to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text),
  reputacion_cliente numeric(3,2),
  calificaciones_cliente integer NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT perfiles_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT perfiles_estado_cuenta_chk CHECK ((estado_cuenta = ANY (ARRAY['activo'::text, 'suspendido'::text, 'bloqueado'::text, 'eliminado'::text]))),
  CONSTRAINT perfiles_reputacion_cliente_chk CHECK (((reputacion_cliente IS NULL) OR ((reputacion_cliente >= (1)::numeric) AND (reputacion_cliente <= (5)::numeric)))),
  CONSTRAINT perfiles_rol_chk CHECK ((rol = ANY (ARRAY['usuario'::text, 'trabajador'::text, 'administrador'::text, 'soporte'::text, 'qa'::text])))
);

COMMENT ON TABLE perfiles IS 'Identidad de la aplicación: perfiles.id coincide con auth.users.id (esquema auth de Supabase, fuera de public; clave foránea con ON DELETE CASCADE desde la auditoría 2026-11-16). El default de rol es ''usuario'' y el de estado_cuenta es ''activo''. Los CHECK perfiles_rol_chk y perfiles_estado_cuenta_chk cierran los conjuntos: usuario, trabajador, administrador, soporte y qa; activo, suspendido, bloqueado y eliminado. Los roles privilegiados (administrador, soporte, qa) no se pueden autoasignar: el trigger perfiles_rol_inicial_seguro y protect_profile_sensitive_fields lo impiden. reputacion_cliente y calificaciones_cliente los calcula calificar_cliente(); el usuario no puede editarlos (trigger protect_profile_sensitive_fields).';
COMMENT ON COLUMN perfiles.rol IS 'usuario | trabajador | administrador';
COMMENT ON COLUMN perfiles.estado_cuenta IS 'activo | suspendido | bloqueado | eliminado';

CREATE TABLE notificaciones (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo text NOT NULL,
  titulo text NOT NULL,
  cuerpo text NOT NULL,
  id_relacionado text,
  leido integer NOT NULL DEFAULT 0,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT notificaciones_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT notificaciones_leido_bool_chk CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE notificaciones IS 'Aviso dentro de la aplicación dirigido a un usuario.';

CREATE TABLE suscripciones (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_plan text NOT NULL,
  estado text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT suscripciones_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT suscripciones_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT suscripciones_fecha_fin_iso_chk CHECK (es_marca_tiempo_iso(fecha_fin)),
  CONSTRAINT suscripciones_fecha_inicio_iso_chk CHECK (es_marca_tiempo_iso(fecha_inicio))
);

COMMENT ON TABLE suscripciones IS 'Plan de suscripción contratado por un usuario.';

CREATE TABLE codigos_restablecimiento (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  codigo text NOT NULL,
  correo text NOT NULL,
  expira_en text NOT NULL,
  usado integer DEFAULT 0,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT codigos_restablecimiento_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT codigos_restablecimiento_expira_en_iso_chk CHECK (es_marca_tiempo_iso(expira_en)),
  CONSTRAINT codigos_restablecimiento_usado_bool_chk CHECK (((usado IS NULL) OR (usado = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE codigos_restablecimiento IS 'Código temporal para restablecer la contraseña.';

CREATE TABLE consentimientos_usuario (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  version_consentimiento text NOT NULL,
  aceptado integer NOT NULL DEFAULT 0,
  aceptado_en text NOT NULL,
  direccion_ip text,
  agente_usuario text,
  PRIMARY KEY (id),
  CONSTRAINT consentimientos_usuario_aceptado_bool_chk CHECK (((aceptado IS NULL) OR (aceptado = ANY (ARRAY[0, 1])))),
  CONSTRAINT consentimientos_usuario_aceptado_en_iso_chk CHECK (es_marca_tiempo_iso(aceptado_en))
);

COMMENT ON TABLE consentimientos_usuario IS 'Registro de aceptación de una versión de consentimiento.';

CREATE TABLE bloqueos_usuario (
  id text NOT NULL,
  id_bloqueador uuid NOT NULL,
  id_bloqueado uuid NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT bloqueos_usuario_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT bloqueos_usuario_distintos_chk CHECK ((id_bloqueador <> id_bloqueado))
);

COMMENT ON TABLE bloqueos_usuario IS 'Bloqueo de un usuario hacia otro.';

CREATE TABLE reportes (
  id text NOT NULL,
  id_reportante uuid NOT NULL,
  id_usuario_reportado uuid NOT NULL,
  motivo text NOT NULL,
  descripcion text,
  estado text NOT NULL DEFAULT 'pendiente',
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT reportes_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en))
);

COMMENT ON TABLE reportes IS 'Denuncia de un usuario contra otro.';

CREATE TABLE eventos_abuso (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_abuso text NOT NULL,
  conteo integer NOT NULL,
  detectado_en text NOT NULL,
  accion_tomada text,
  accion_tomada_en text,
  resuelto integer DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT eventos_abuso_accion_tomada_en_iso_chk CHECK (es_marca_tiempo_iso(accion_tomada_en)),
  CONSTRAINT eventos_abuso_detectado_en_iso_chk CHECK (es_marca_tiempo_iso(detectado_en)),
  CONSTRAINT eventos_abuso_resuelto_bool_chk CHECK (((resuelto IS NULL) OR (resuelto = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE eventos_abuso IS 'Detección de abuso y la acción que se tomó.';

CREATE TABLE acciones_pendientes (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  tipo_accion text NOT NULL,
  tipo_entidad text NOT NULL,
  id_entidad text,
  datos text NOT NULL,
  estado text NOT NULL DEFAULT 'pending_sync',
  conteo_reintentos integer DEFAULT 0,
  mensaje_error text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT acciones_pendientes_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT acciones_pendientes_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en))
);

COMMENT ON TABLE acciones_pendientes IS 'Acción hecha sin conexión, pendiente de sincronizar.';

CREATE TABLE registros_error_app (
  id text NOT NULL,
  id_usuario uuid,
  tipo_error text NOT NULL DEFAULT 'error',
  mensaje text NOT NULL,
  traza_pila text,
  metadatos jsonb,
  estado text NOT NULL DEFAULT 'nuevo',
  version_app text,
  plataforma text,
  creado_en text NOT NULL DEFAULT to_char((now() AT TIME ZONE 'utc'::text), 'YYYY-MM-DD"T"HH24:MI:SS.US'::text),
  PRIMARY KEY (id),
  CONSTRAINT registros_error_app_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en))
);

COMMENT ON TABLE registros_error_app IS 'Error de la aplicación informado por un cliente.';

CREATE TABLE eventos_analitica (
  id text NOT NULL,
  nombre_evento text NOT NULL,
  id_usuario uuid,
  rol text,
  marca_tiempo text NOT NULL,
  metadatos text,
  PRIMARY KEY (id),
  CONSTRAINT eventos_analitica_marca_tiempo_iso_chk CHECK (es_marca_tiempo_iso(marca_tiempo))
);

COMMENT ON TABLE eventos_analitica IS 'Evento de uso registrado por la aplicación.';

CREATE TABLE banderas_funcionalidad (
  id text NOT NULL,
  nombre_bandera text NOT NULL,
  habilitada integer NOT NULL DEFAULT 0,
  version_app text,
  rol text,
  id_usuario uuid,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT banderas_funcionalidad_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT banderas_funcionalidad_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT banderas_funcionalidad_habilitada_bool_chk CHECK (((habilitada IS NULL) OR (habilitada = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE banderas_funcionalidad IS 'Interruptor de una función por versión, rol o usuario.';

CREATE TABLE dispositivos_push (
  token text NOT NULL,
  id_usuario uuid NOT NULL,
  plataforma text NOT NULL DEFAULT 'android',
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (token),
  CONSTRAINT dispositivos_push_plataforma_check CHECK ((plataforma = ANY (ARRAY['android'::text, 'ios'::text, 'web'::text]))),
  CONSTRAINT dispositivos_push_token_largo CHECK (((char_length(token) >= 20) AND (char_length(token) <= 4096)))
);

COMMENT ON TABLE dispositivos_push IS 'Token del dispositivo del usuario para avisos push (FCM u otra plataforma). El alta y el baja se hacen por RPC.';

CREATE TABLE verificacion_eventos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL,
  estado text NOT NULL,
  nota text,
  id_actor uuid,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);

COMMENT ON TABLE verificacion_eventos IS 'Historial de cambios del estado de verificación de un profesional (pendiente, en revisión, verificado, rechazado).';

CREATE TABLE paises (
  id text NOT NULL,
  nombre text NOT NULL,
  iso2 text NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE paises IS 'País operativo. Hoy solo CL.';

CREATE TABLE regiones (
  id text NOT NULL,
  id_pais text NOT NULL,
  nombre text NOT NULL,
  codigo_oficial text,
  PRIMARY KEY (id)
);

COMMENT ON TABLE regiones IS 'Región administrativa de un país.';

CREATE TABLE comunas (
  id text NOT NULL,
  id_region text NOT NULL,
  nombre text NOT NULL,
  latitud double precision,
  longitud double precision,
  activa integer NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  CONSTRAINT comunas_activa_bool_chk CHECK (((activa IS NULL) OR (activa = ANY (ARRAY[0, 1])))),
  CONSTRAINT comunas_lat_chk CHECK (((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision)))),
  CONSTRAINT comunas_lng_chk CHECK (((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))))
);

COMMENT ON TABLE comunas IS 'Comuna de cobertura. Su identificador es el slug usado por trabajos y trabajadores.';

CREATE TABLE trabajadores (
  id_usuario uuid NOT NULL,
  profesion text NOT NULL DEFAULT '',
  descripcion text,
  calificacion numeric(4,2) NOT NULL DEFAULT 0,
  disponible integer NOT NULL DEFAULT 1,
  tarifa_visita numeric(12,0) NOT NULL DEFAULT 15000,
  conteo_rechazos integer NOT NULL DEFAULT 0,
  precios_configurados integer NOT NULL DEFAULT 0,
  zona_trabajo text,
  estado_verificacion text NOT NULL DEFAULT 'pendiente',
  nota_verificacion text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric NOT NULL DEFAULT 15,
  origen_base text,
  score_listado numeric(8,4) NOT NULL DEFAULT 0,
  prioridad_manual integer NOT NULL DEFAULT 0,
  score_desglose jsonb NOT NULL DEFAULT '{}',
  ranking_actualizado_en timestamptz,
  radio_urbano_km numeric(5,2) NOT NULL DEFAULT 5,
  tarifa_fuera_radio_clp integer NOT NULL DEFAULT 0,
  trabajos_completados integer NOT NULL DEFAULT 0,
  es_elite boolean GENERATED ALWAYS AS (((COALESCE(calificacion, (0)::numeric) >= 4.7) AND (trabajos_completados >= 5))) STORED,
  id_comuna text,
  usa_horario boolean NOT NULL DEFAULT false,
  pausa_por_trabajo boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id_usuario),
  CONSTRAINT trabajadores_base_lat_chk CHECK (((latitud_base IS NULL) OR ((latitud_base >= ('-90'::integer)::double precision) AND (latitud_base <= (90)::double precision)))),
  CONSTRAINT trabajadores_base_lng_chk CHECK (((longitud_base IS NULL) OR ((longitud_base >= ('-180'::integer)::double precision) AND (longitud_base <= (180)::double precision)))),
  CONSTRAINT trabajadores_calificacion_chk CHECK (((calificacion >= (0)::numeric) AND (calificacion <= (5)::numeric))),
  CONSTRAINT trabajadores_contadores_chk CHECK (((trabajos_completados >= 0) AND (conteo_rechazos >= 0))),
  CONSTRAINT trabajadores_disponible_bool_chk CHECK (((disponible IS NULL) OR (disponible = ANY (ARRAY[0, 1])))),
  CONSTRAINT trabajadores_estado_verificacion_check CHECK ((estado_verificacion = ANY (ARRAY['pendiente'::text, 'en_revision'::text, 'verificado'::text, 'rechazado'::text]))),
  CONSTRAINT trabajadores_origen_base_chk CHECK (((origen_base IS NULL) OR (origen_base = ANY (ARRAY['mapa'::text, 'comuna'::text])))),
  CONSTRAINT trabajadores_precios_configurados_bool_chk CHECK (((precios_configurados IS NULL) OR (precios_configurados = ANY (ARRAY[0, 1])))),
  CONSTRAINT trabajadores_prioridad_manual_chk CHECK (((prioridad_manual >= '-50'::integer) AND (prioridad_manual <= 50))),
  CONSTRAINT trabajadores_radio_chk CHECK (((radio_servicio_km >= (1)::numeric) AND (radio_servicio_km <= (80)::numeric))),
  CONSTRAINT trabajadores_radio_urbano_chk CHECK (((radio_urbano_km >= (1)::numeric) AND (radio_urbano_km <= (40)::numeric))),
  CONSTRAINT trabajadores_tarifa_fuera_radio_chk CHECK (((tarifa_fuera_radio_clp >= 0) AND (tarifa_fuera_radio_clp <= 200000))),
  CONSTRAINT trabajadores_tarifa_visita_chk CHECK ((tarifa_visita >= (0)::numeric))
);

COMMENT ON TABLE trabajadores IS 'Ficha 1:1 del profesional (PK = perfiles.id). Sus precios, servicios adicionales y oficios están en trabajador_precios, trabajador_servicios_extra y trabajador_servicios; la región se obtiene desde la comuna. es_elite es una columna GENERATED. La agenda semanal está en trabajador_horarios y trabajador_horas_publicadas; usa_horario enciende el filtro. pausa_por_trabajo queda en true cuando un trabajo activo dejó disponible = 0, y se restablece al terminar.';
COMMENT ON COLUMN trabajadores.conteo_rechazos IS 'Rechazos de invitaciones; penaliza orden en listados (no visible en UI)';
COMMENT ON COLUMN trabajadores.precios_configurados IS '1 si el trabajador completó la guía de configuración de precios';
COMMENT ON COLUMN trabajadores.zona_trabajo IS 'Comuna o zona donde atiende el trabajador';
COMMENT ON COLUMN trabajadores.latitud_base IS 'Latitud de la base de servicio. origen_base=comuna es el centro de la comuna declarada; mapa la fijó el profesional.';
COMMENT ON COLUMN trabajadores.radio_servicio_km IS 'Radio máximo de matching en kilómetros desde la base.';
COMMENT ON COLUMN trabajadores.score_listado IS 'Orden de marketplace. Incluye pesos configurables + prioridad_manual*2.';
COMMENT ON COLUMN trabajadores.prioridad_manual IS 'Override de admin (-50..50) para mostrar un profesional antes o después.';
COMMENT ON COLUMN trabajadores.radio_urbano_km IS 'Kilómetros alrededor de la base donde la movilización es $0.';
COMMENT ON COLUMN trabajadores.tarifa_fuera_radio_clp IS 'Movilización fija si el cliente está fuera del radio urbano. 0 = tampoco cobra fuera.';
COMMENT ON COLUMN trabajadores.es_elite IS 'Destacado del mes: nota >= 4.7 y al menos 5 trabajos completados.';
COMMENT ON COLUMN trabajadores.id_comuna IS 'Comuna de cobertura. zona_trabajo sigue como texto de UI.';
COMMENT ON COLUMN trabajadores.pausa_por_trabajo IS 'true cuando disponible = 0 lo dejó un trabajo activo; se restablece al terminar.';

CREATE TABLE trabajador_precios (
  id_usuario uuid NOT NULL,
  codigo text NOT NULL,
  monto_clp numeric(12,0) NOT NULL,
  PRIMARY KEY (id_usuario, codigo),
  CONSTRAINT trabajador_precios_monto_clp_check CHECK ((monto_clp >= (0)::numeric))
);

COMMENT ON TABLE trabajador_precios IS 'Precio por código de servicio del profesional. id_usuario es uuid con clave foránea a trabajadores (ON DELETE CASCADE). Es la única fuente de los precios del profesional.';

CREATE TABLE trabajador_servicios_extra (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  titulo text NOT NULL,
  subtitulo text NOT NULL DEFAULT '',
  monto_clp numeric(12,0) NOT NULL,
  unidad text NOT NULL DEFAULT 'fijo',
  PRIMARY KEY (id_usuario, id),
  CONSTRAINT trabajador_servicios_extra_monto_clp_check CHECK ((monto_clp >= (0)::numeric)),
  CONSTRAINT trabajador_servicios_extra_unidad_check CHECK ((unidad = ANY (ARRAY['fijo'::text, 'por_m2'::text])))
);

COMMENT ON TABLE trabajador_servicios_extra IS 'Servicio adicional definido por el profesional (título, subtítulo, monto y unidad fijo o por m²). id_usuario es uuid con clave foránea a trabajadores. Es la única fuente de sus servicios adicionales.';

CREATE TABLE trabajador_servicios (
  id_trabajador uuid NOT NULL,
  categoria_servicio text NOT NULL,
  PRIMARY KEY (id_trabajador, categoria_servicio)
);

COMMENT ON TABLE trabajador_servicios IS 'Oficios del catálogo que el profesional declara atender. categoria_servicio es clave foránea a categorias_servicio.';

CREATE TABLE trabajador_horarios (
  id_usuario uuid NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  dia_semana smallint NOT NULL,
  hora_inicio time NOT NULL,
  hora_fin time NOT NULL,
  activo boolean NOT NULL DEFAULT true,
  creado_en timestamptz DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT trabajador_horarios_dia_chk CHECK (((dia_semana IS NULL) OR ((dia_semana >= 1) AND (dia_semana <= 7)))),
  CONSTRAINT trabajador_horarios_rango_chk CHECK (((NOT activo) OR (hora_inicio < hora_fin)))
);

COMMENT ON TABLE trabajador_horarios IS 'Ventana de atención semanal: siete filas por profesional, una por día (1 = lunes … 7 = domingo), con hora_inicio y hora_fin, únicas por (id_usuario, dia_semana). Las horas reservables dentro de la ventana están en trabajador_horas_publicadas. usa_horario en trabajadores enciende el filtro.';

CREATE TABLE trabajador_horas_publicadas (
  id_usuario uuid NOT NULL,
  dia_semana smallint NOT NULL,
  hora time NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_usuario, dia_semana, hora),
  CONSTRAINT trabajador_horas_publicadas_dia_semana_check CHECK (((dia_semana >= 1) AND (dia_semana <= 7)))
);

COMMENT ON TABLE trabajador_horas_publicadas IS 'Horas que el profesional publica como reservables en cada día (clave id_usuario, dia_semana, hora). Un trigger de reserva acepta solo horas publicadas y libres. El cliente las ve con la RPC horarios_libres_profesional.';

CREATE TABLE portafolio_trabajador (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  ruta_foto text NOT NULL,
  descripcion text,
  creado_en text NOT NULL,
  tipo_medio text NOT NULL DEFAULT 'foto',
  PRIMARY KEY (id),
  CONSTRAINT portafolio_tipo_medio_chk CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text]))),
  CONSTRAINT portafolio_trabajador_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en))
);

COMMENT ON TABLE portafolio_trabajador IS 'Foto o medio del portafolio de un profesional.';

CREATE TABLE impulsos (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  tipo_impulso text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text NOT NULL,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT impulsos_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT impulsos_fecha_fin_iso_chk CHECK (es_marca_tiempo_iso(fecha_fin)),
  CONSTRAINT impulsos_fecha_inicio_iso_chk CHECK (es_marca_tiempo_iso(fecha_inicio))
);

COMMENT ON TABLE impulsos IS 'Promoción temporal de visibilidad de un profesional.';

CREATE TABLE categorias_servicio (
  id text NOT NULL,
  nombre text NOT NULL,
  activa boolean NOT NULL DEFAULT true,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT categorias_servicio_id_check CHECK ((id ~ '^[a-z][a-z0-9_]*$'::text)),
  CONSTRAINT categorias_servicio_nombre_check CHECK ((length(btrim(nombre)) > 0))
);

COMMENT ON TABLE categorias_servicio IS 'Categorías u oficios del catálogo (gasfitería, electricidad y otros). Las usan servicios y trabajador_servicios.';

CREATE TABLE servicios (
  id text NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  categoria text NOT NULL DEFAULT 'general',
  activo integer NOT NULL DEFAULT 1,
  requiere_certificacion integer NOT NULL DEFAULT 0,
  modelo_precio text NOT NULL DEFAULT 'por_hora',
  aviso_legal text,
  creado_en text,
  actualizado_en text,
  PRIMARY KEY (id),
  CONSTRAINT servicios_activo_bool_chk CHECK (((activo IS NULL) OR (activo = ANY (ARRAY[0, 1])))),
  CONSTRAINT servicios_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT servicios_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT servicios_requiere_certificacion_bool_chk CHECK (((requiere_certificacion IS NULL) OR (requiere_certificacion = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE servicios IS 'Catálogo de oficios que la plataforma ofrece.';

CREATE TABLE configuraciones_servicio (
  id text NOT NULL,
  id_servicio text NOT NULL,
  esquema_config text NOT NULL,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT configuraciones_servicio_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT configuraciones_servicio_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en))
);

COMMENT ON TABLE configuraciones_servicio IS 'Esquema de configuración asociado a un servicio.';

CREATE TABLE trabajos (
  id text NOT NULL,
  id_usuario uuid NOT NULL,
  id_trabajador uuid,
  id_servicio text,
  estado text NOT NULL,
  direccion text NOT NULL DEFAULT '',
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
  PRIMARY KEY (id),
  CONSTRAINT trabajos_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT trabajos_coordenadas_chk CHECK ((((latitud IS NULL) OR ((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))) AND ((longitud IS NULL) OR ((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision))))),
  CONSTRAINT trabajos_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT trabajos_estado_chk CHECK ((estado = ANY (ARRAY['pendiente'::text, 'esperando_cotizaciones'::text, 'cotizacion_seleccionada'::text, 'esperando_pago'::text, 'aceptado'::text, 'en_camino'::text, 'en_curso'::text, 'pausado_orden_cambio'::text, 'esperando_aprobacion_cliente'::text, 'completado'::text, 'cancelado'::text, 'expirado'::text, 'no_asistio'::text]))),
  CONSTRAINT trabajos_estado_pago_chk CHECK (((estado_pago IS NULL) OR (estado_pago = ANY (ARRAY['ninguno'::text, 'pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text])))),
  CONSTRAINT trabajos_fecha_programada_iso_chk CHECK (es_marca_tiempo_iso(fecha_programada)),
  CONSTRAINT trabajos_horas_bloque_chk CHECK (((horas_bloque IS NULL) OR ((horas_bloque >= 1) AND (horas_bloque <= 24)))),
  CONSTRAINT trabajos_modalidad_cobro_chk CHECK (((modalidad_cobro IS NULL) OR (modalidad_cobro = ANY (ARRAY['legado'::text, 'precio_fijo'::text, 'bloque_horas'::text, 'cotizacion_abierta'::text]))))
);

COMMENT ON TABLE trabajos IS 'Pedido de un cliente a un profesional (o abierto a cotizaciones). estado_pago es una copia derivada del pago principal. La fecha programada se guarda como texto y, desde CU-33, solo cambia por las RPC de reagendamiento (trabajos_fecha_solo_por_rpc). Hay un índice único que impide dos trabajos activos del mismo profesional en el mismo minuto (minuto_utc de fecha_programada).';
COMMENT ON COLUMN trabajos.id_comuna IS 'FK a comunas.id (slug).';

CREATE TABLE mensajes (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_remitente uuid NOT NULL,
  id_destinatario uuid NOT NULL,
  contenido text NOT NULL,
  tipo text NOT NULL DEFAULT 'texto',
  ruta_imagen text,
  leido integer NOT NULL DEFAULT 0,
  creado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT mensajes_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT mensajes_leido_bool_chk CHECK (((leido IS NULL) OR (leido = ANY (ARRAY[0, 1]))))
);

COMMENT ON TABLE mensajes IS 'Mensaje del chat de un trabajo.';

CREATE TABLE fotos_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  ruta_foto text NOT NULL,
  creado_en text NOT NULL,
  tipo_medio text NOT NULL DEFAULT 'foto',
  imagen_webp bytea,
  PRIMARY KEY (id),
  CONSTRAINT fotos_trabajo_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT fotos_trabajo_tipo_medio_chk CHECK ((tipo_medio = ANY (ARRAY['foto'::text, 'video'::text])))
);

COMMENT ON TABLE fotos_trabajo IS 'Evidencia fotográfica o de video de un trabajo (bucket de evidencias).';
COMMENT ON COLUMN fotos_trabajo.tipo_medio IS 'photo or video evidence';
COMMENT ON COLUMN fotos_trabajo.imagen_webp IS 'Imagen de evidencia en WebP. Se guarda en la fila para no depender de archivos locales y ocupar menos espacio que JPEG/PNG.';

CREATE TABLE calificaciones (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_usuario uuid,
  puntaje integer NOT NULL,
  comentario text,
  creado_en text NOT NULL,
  peso_confianza numeric(4,3) NOT NULL DEFAULT 1,
  estado_revision text NOT NULL DEFAULT 'vigente',
  motivo_revision text,
  direccion text NOT NULL DEFAULT 'cliente_a_trabajador',
  id_calificado uuid NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT calificaciones_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT calificaciones_direccion_chk CHECK ((direccion = ANY (ARRAY['cliente_a_trabajador'::text, 'trabajador_a_cliente'::text]))),
  CONSTRAINT calificaciones_estado_revision_chk CHECK ((estado_revision = ANY (ARRAY['vigente'::text, 'en_revision'::text, 'excluida'::text]))),
  CONSTRAINT calificaciones_peso_confianza_chk CHECK (((peso_confianza >= (0)::numeric) AND (peso_confianza <= (1)::numeric))),
  CONSTRAINT calificaciones_puntaje_chk CHECK (((puntaje >= 1) AND (puntaje <= 5)))
);

COMMENT ON TABLE calificaciones IS 'Valoración de un trabajo. Desde la calificación bidireccional admite direccion cliente_a_trabajador o trabajador_a_cliente, con unicidad por (id_trabajo, direccion). Alimenta trabajadores.calificacion.';

CREATE TABLE calificaciones_cliente (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_cliente uuid NOT NULL,
  id_trabajador uuid NOT NULL,
  puntaje smallint NOT NULL,
  comentario text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT calificaciones_cliente_puntaje_chk CHECK (((puntaje >= 1) AND (puntaje <= 5)))
);

COMMENT ON TABLE calificaciones_cliente IS 'El profesional nota al cliente. 1:1 con el trabajo. Alimenta perfiles.reputacion_cliente. puntaje es smallint en la base viva.';

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
  origen text NOT NULL DEFAULT 'admin',
  decision_sugerida text,
  motivo_regla text,
  vence_en timestamptz,
  PRIMARY KEY (id),
  CONSTRAINT disputas_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT disputas_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT disputas_decision_chk CHECK (((decision_sugerida IS NULL) OR (decision_sugerida = ANY (ARRAY['liberar'::text, 'reembolsar'::text, 'humano'::text])))),
  CONSTRAINT disputas_origen_chk CHECK ((origen = ANY (ARRAY['sistema'::text, 'acuerdo'::text, 'admin'::text]))),
  CONSTRAINT disputas_resuelta_en_iso_chk CHECK (es_marca_tiempo_iso(resuelta_en))
);

COMMENT ON TABLE disputas IS 'Disputa abierta sobre un trabajo y su resolución (incluye sugerencia automática y vencimiento).';

CREATE TABLE disputa_mensajes (
  id text NOT NULL,
  id_disputa text NOT NULL,
  id_autor uuid,
  cuerpo text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);

COMMENT ON TABLE disputa_mensajes IS 'Mensajes del hilo de una disputa, de las partes o de soporte.';

CREATE TABLE acuerdos_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  tipo text NOT NULL,
  propuesto_por uuid NOT NULL,
  acepta_cliente boolean,
  acepta_trabajador boolean,
  estado text NOT NULL DEFAULT 'pendiente',
  creado_en timestamptz NOT NULL DEFAULT now(),
  aplicado_en timestamptz,
  PRIMARY KEY (id),
  CONSTRAINT acuerdos_estado_chk CHECK ((estado = ANY (ARRAY['pendiente'::text, 'confirmado'::text, 'rechazado'::text, 'aplicado'::text]))),
  CONSTRAINT acuerdos_tipo_chk CHECK ((tipo = ANY (ARRAY['rehacer'::text, 'aceptar'::text, 'anular'::text])))
);

COMMENT ON TABLE acuerdos_trabajo IS 'Acuerdo entre cliente y profesional para rehacer, aceptar o anular un trabajo. Como máximo un acuerdo pendiente por trabajo.';

CREATE TABLE cancelaciones_trabajo (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  cancelado_por uuid NOT NULL,
  motivo text NOT NULL,
  cancelado_en text NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT cancelaciones_trabajo_cancelado_en_iso_chk CHECK (es_marca_tiempo_iso(cancelado_en))
);

COMMENT ON TABLE cancelaciones_trabajo IS 'Como máximo una cancelación por trabajo.';

CREATE TABLE tickets_soporte (
  id text NOT NULL DEFAULT (gen_random_uuid())::text,
  id_trabajo text,
  nombre_cliente text NOT NULL,
  nombre_trabajador text NOT NULL,
  asunto text NOT NULL,
  monto_escrow integer NOT NULL,
  estado text DEFAULT 'Pending',
  creado_en timestamptz DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT tickets_monto_escrow_chk CHECK ((monto_escrow >= 0)),
  CONSTRAINT tickets_status_check CHECK ((estado = ANY (ARRAY['Pending'::text, 'Resolved'::text])))
);

COMMENT ON TABLE tickets_soporte IS 'Ticket de soporte asociado a un trabajo.';

CREATE TABLE ubicacion_en_vivo (
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  precision_metros double precision,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_trabajo),
  CONSTRAINT ubicacion_lat_chk CHECK (((latitud >= ('-90'::integer)::double precision) AND (latitud <= (90)::double precision))),
  CONSTRAINT ubicacion_lng_chk CHECK (((longitud >= ('-180'::integer)::double precision) AND (longitud <= (180)::double precision)))
);

COMMENT ON TABLE ubicacion_en_vivo IS 'GPS en vivo durante el trabajo. 1:1 con el trabajo.';

CREATE TABLE reprogramaciones_trabajo (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  id_trabajo text NOT NULL,
  propuesta_por uuid NOT NULL,
  rol_proponente text NOT NULL,
  fecha_anterior timestamptz NOT NULL,
  fecha_propuesta timestamptz NOT NULL,
  motivo text,
  estado text NOT NULL DEFAULT 'pendiente',
  respondida_por uuid,
  respondida_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT reprogramaciones_trabajo_check CHECK ((fecha_propuesta <> fecha_anterior)),
  CONSTRAINT reprogramaciones_trabajo_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'vencida'::text]))),
  CONSTRAINT reprogramaciones_trabajo_motivo_check CHECK (((motivo IS NULL) OR (char_length(motivo) <= 300))),
  CONSTRAINT reprogramaciones_trabajo_rol_proponente_check CHECK ((rol_proponente = ANY (ARRAY['cliente'::text, 'profesional'::text])))
);

COMMENT ON TABLE reprogramaciones_trabajo IS 'Historial de propuestas para reagendar un trabajo (CU-33). Como máximo una propuesta pendiente por trabajo. Solo se escribe por las RPC proponer_reprogramacion, responder_reprogramacion y retirar_reprogramacion.';

CREATE TABLE pines_inicio_trabajo (
  id_trabajo text NOT NULL,
  pin text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_trabajo),
  CONSTRAINT pines_inicio_trabajo_pin_check CHECK ((pin ~ '^[0-9]{4}$'::text))
);

COMMENT ON TABLE pines_inicio_trabajo IS 'PIN que el cliente muestra al profesional para iniciar el trabajo (aceptado o en_camino → en_curso). El cliente (o un administrador) puede leerlo; el profesional lo valida con intentar_pin_inicio o transicionar_trabajo. Lo crea el trigger trabajos_crear_pin_inicio.';

CREATE TABLE bloqueos_pin_inicio (
  id_trabajo text NOT NULL,
  fallos integer NOT NULL DEFAULT 0,
  bloqueado_hasta timestamptz,
  pin_ok_hasta timestamptz,
  pin_ok_usuario uuid,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_trabajo),
  CONSTRAINT bloqueos_pin_inicio_fallos_check CHECK ((fallos >= 0))
);

COMMENT ON TABLE bloqueos_pin_inicio IS 'Contador de intentos fallidos del PIN, bloqueo temporal (15 minutos tras 5 fallos) y ventana en la que el PIN ya fue validado. Escriben solo las funciones SECURITY DEFINER o service_role; un administrador puede leerla.';

CREATE TABLE intentos_pin_inicio (
  id bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY,
  id_trabajo text NOT NULL,
  id_usuario uuid,
  resultado text NOT NULL,
  intentos_restantes integer NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT intentos_pin_inicio_resultado_check CHECK ((resultado = ANY (ARRAY['correcto'::text, 'incorrecto'::text, 'bloqueado'::text])))
);

COMMENT ON TABLE intentos_pin_inicio IS 'Auditoría de cada intento de PIN de inicio. Escriben solo funciones SECURITY DEFINER; un administrador puede leerla.';

CREATE TABLE propuestas_cotizacion (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  monto_total_clp integer NOT NULL,
  descripcion text NOT NULL,
  validez_hasta text,
  estado text NOT NULL,
  creado_en text NOT NULL,
  horas_estimadas numeric,
  PRIMARY KEY (id),
  CONSTRAINT propuestas_cotizacion_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT propuestas_cotizacion_horas_estimadas_check CHECK (((horas_estimadas IS NULL) OR (horas_estimadas >= (0)::numeric))),
  CONSTRAINT propuestas_cotizacion_validez_hasta_iso_chk CHECK (es_marca_tiempo_iso(validez_hasta)),
  CONSTRAINT propuestas_monto_chk CHECK ((monto_total_clp > 0))
);

COMMENT ON TABLE propuestas_cotizacion IS 'Cotización que un profesional envía para un trabajo. Guarda el total y las horas estimadas; las líneas están en propuesta_cotizacion_items.';

CREATE TABLE propuesta_cotizacion_items (
  id_propuesta text NOT NULL,
  linea smallint NOT NULL,
  concepto text NOT NULL,
  monto numeric NOT NULL,
  PRIMARY KEY (id_propuesta, linea),
  CONSTRAINT propuesta_cotizacion_items_concepto_check CHECK ((length(btrim(concepto)) > 0)),
  CONSTRAINT propuesta_cotizacion_items_linea_check CHECK ((linea >= 1)),
  CONSTRAINT propuesta_cotizacion_items_monto_check CHECK ((monto >= (0)::numeric))
);

COMMENT ON TABLE propuesta_cotizacion_items IS 'Línea de una cotización: concepto y monto, numeradas por propuesta (clave id_propuesta, linea).';

CREATE TABLE pagos (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_orden_cambio text,
  tipo_pago text NOT NULL DEFAULT 'principal',
  monto numeric(12,0) NOT NULL,
  moneda text NOT NULL DEFAULT 'CLP',
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
  handoff_consumido_en timestamptz,
  reembolso_solicitado_en timestamptz,
  orden_detalle_oneclick text,
  cobro_reclamado_en timestamptz,
  origen_retorno text,
  alta_nonce_hash text,
  alta_jti text,
  alta_consumido_en timestamptz,
  PRIMARY KEY (id),
  CONSTRAINT pagos_actualizado_en_iso_chk CHECK (es_marca_tiempo_iso(actualizado_en)),
  CONSTRAINT pagos_ambiente_chk CHECK (((ambiente IS NULL) OR (ambiente = ANY (ARRAY['integration'::text, 'production'::text])))),
  CONSTRAINT pagos_autorizado_en_iso_chk CHECK (es_marca_tiempo_iso(autorizado_en)),
  CONSTRAINT pagos_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT pagos_estado_chk CHECK ((estado = ANY (ARRAY['pendiente'::text, 'autorizado'::text, 'retenido'::text, 'pagado_por_confirmar'::text, 'liberado'::text, 'reembolso_pendiente'::text, 'reembolsado'::text, 'reembolsado_auto'::text, 'anulado'::text, 'fallido'::text, 'rechazado'::text, 'expirado'::text, 'cancelado'::text]))),
  CONSTRAINT pagos_liberado_en_iso_chk CHECK (es_marca_tiempo_iso(liberado_en)),
  CONSTRAINT pagos_metodo_pago_chk CHECK (((metodo_pago IS NULL) OR (metodo_pago = ANY (ARRAY['webpay'::text, 'oneclick'::text])))),
  CONSTRAINT pagos_moneda_chk CHECK ((moneda = 'CLP'::text)),
  CONSTRAINT pagos_monto_chk CHECK ((monto >= (0)::numeric)),
  CONSTRAINT pagos_reembolsado_en_iso_chk CHECK (es_marca_tiempo_iso(reembolsado_en)),
  CONSTRAINT pagos_tipo_pago_chk CHECK ((tipo_pago = ANY (ARRAY['principal'::text, 'orden_cambio'::text])))
);

COMMENT ON TABLE pagos IS 'Cobro asociado a un trabajo o a una orden de cambio, con retención (escrow) vía Transbank Webpay / Oneclick. Las columnas alta_nonce_hash, alta_jti y alta_consumido_en sustentan el alta del invitado después del pago: el nonce solo lo tiene el navegador y el jti es de un solo uso. El default de tipo_pago es ''primary'' (inglés legado); el índice de un solo pago principal activo busca el valor ''principal''.';
COMMENT ON COLUMN pagos.ambiente IS 'integration | production';
COMMENT ON COLUMN pagos.token_tbk IS 'token_ws de Webpay Plus. No guardar aquí la orden Oneclick.';
COMMENT ON COLUMN pagos.url_tbk IS 'URL TBK — solo service_role / Edge Functions';
COMMENT ON COLUMN pagos.buy_order IS 'buy_order Webpay';
COMMENT ON COLUMN pagos.reembolso_solicitado_en IS 'Marca que ya se pidió la devolución a Transbank. Un reintento no vuelve a llamar a la tarjeta.';
COMMENT ON COLUMN pagos.orden_detalle_oneclick IS 'buy_order de detalle de Oneclick Mall, para el reembolso.';
COMMENT ON COLUMN pagos.cobro_reclamado_en IS 'Marca exclusiva de una autorización Oneclick en curso.';
COMMENT ON COLUMN pagos.origen_retorno IS 'Origen del navegador ya contrastado con la allowlist. webpay-commit redirige ahí.';
COMMENT ON COLUMN pagos.alta_nonce_hash IS 'SHA-256 del nonce que solo tiene el navegador del invitado.';
COMMENT ON COLUMN pagos.alta_jti IS 'Identificador de un solo uso del enlace para crear la contraseña.';
COMMENT ON COLUMN pagos.alta_consumido_en IS 'Cuándo se usó el enlace. Un segundo intento no sirve.';

CREATE TABLE ordenes_cambio (
  id text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador uuid NOT NULL,
  tipo text NOT NULL,
  titulo text NOT NULL,
  descripcion text NOT NULL,
  monto_clp integer NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente_cliente',
  id_pago text,
  creado_en text NOT NULL,
  respondido_en text,
  PRIMARY KEY (id),
  CONSTRAINT ordenes_cambio_creado_en_iso_chk CHECK (es_marca_tiempo_iso(creado_en)),
  CONSTRAINT ordenes_cambio_monto_chk CHECK ((monto_clp >= 0)),
  CONSTRAINT ordenes_cambio_respondido_en_iso_chk CHECK (es_marca_tiempo_iso(respondido_en))
);

COMMENT ON TABLE ordenes_cambio IS 'Cambio de alcance o de precio durante un trabajo.';

CREATE TABLE liquidaciones (
  id text NOT NULL DEFAULT (gen_random_uuid())::text,
  id_pago text NOT NULL,
  id_trabajo text NOT NULL,
  id_trabajador uuid,
  monto_clp numeric NOT NULL,
  proveedor text NOT NULL DEFAULT 'manual',
  referencia_transferencia text NOT NULL,
  notas text,
  id_operador uuid,
  creado_en timestamptz NOT NULL DEFAULT now(),
  estado_transferencia text NOT NULL DEFAULT 'transferido',
  liberada_por_sistema boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id),
  CONSTRAINT liquidaciones_estado_transferencia_chk CHECK ((estado_transferencia = ANY (ARRAY['pendiente'::text, 'transferido'::text, 'fallido'::text]))),
  CONSTRAINT liquidaciones_monto_clp_check CHECK ((monto_clp > (0)::numeric)),
  CONSTRAINT liquidaciones_operador_chk CHECK (((id_operador IS NOT NULL) OR liberada_por_sistema)),
  CONSTRAINT liquidaciones_proveedor_check CHECK ((proveedor = ANY (ARRAY['manual'::text, 'khipu'::text, 'fintoc'::text, 'conformidad'::text])))
);

COMMENT ON TABLE liquidaciones IS 'Un pago → una liquidación al profesional. manual = transferencia externa confirmada por admin; khipu/fintoc = PSP futuro.';

CREATE TABLE metodos_pago_oneclick (
  id_usuario uuid NOT NULL,
  username text NOT NULL,
  tbk_user text,
  tipo_tarjeta text,
  ultimos4 text,
  estado text NOT NULL DEFAULT 'pendiente',
  token_inscripcion text,
  id_trabajo_pendiente text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  url_inscripcion text,
  ticket_handoff text,
  PRIMARY KEY (id_usuario),
  CONSTRAINT metodos_pago_oneclick_estado_chk CHECK ((estado = ANY (ARRAY['pendiente'::text, 'activa'::text, 'rechazada'::text])))
);

COMMENT ON TABLE metodos_pago_oneclick IS 'Tarjeta inscrita Oneclick. RLS niega el acceso a anon y authenticated: solo service_role (Edge Functions).';

CREATE TABLE cuentas_bancarias (
  id_usuario uuid NOT NULL,
  banco text NOT NULL,
  tipo_cuenta text NOT NULL,
  numero_cuenta text NOT NULL,
  rut_titular text NOT NULL,
  nombre_titular text NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_usuario),
  CONSTRAINT cuentas_bancarias_numero_chk CHECK ((numero_cuenta ~ '^[0-9]{4,20}$'::text)),
  CONSTRAINT cuentas_bancarias_tipo_chk CHECK ((tipo_cuenta = ANY (ARRAY['vista'::text, 'corriente'::text, 'rut'::text, 'ahorro'::text])))
);

COMMENT ON TABLE cuentas_bancarias IS 'Datos bancarios del profesional para pagar la liquidación. RLS: solo el dueño y un administrador. No es un dato público.';

CREATE TABLE app_config (
  clave text NOT NULL,
  valor text NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (clave)
);

COMMENT ON TABLE app_config IS 'Pares clave/valor de configuración (demo_modo, admin_requiere_aal2, etc.). RLS niega el acceso a clientes; lo lee el backend.';

CREATE TABLE ranking_config (
  id text NOT NULL DEFAULT 'default',
  peso_calificacion numeric NOT NULL DEFAULT 0.32,
  peso_completados numeric NOT NULL DEFAULT 0.18,
  peso_rechazos numeric NOT NULL DEFAULT 0.12,
  peso_verificacion numeric NOT NULL DEFAULT 0.10,
  peso_impulso numeric NOT NULL DEFAULT 0.08,
  peso_recencia numeric NOT NULL DEFAULT 0.08,
  peso_confianza numeric NOT NULL DEFAULT 0.12,
  prior_bayes numeric NOT NULL DEFAULT 3.80,
  n_bayes numeric NOT NULL DEFAULT 8,
  umbral_revision numeric NOT NULL DEFAULT 0.55,
  umbral_auto_excluir numeric NOT NULL DEFAULT 0.90,
  aprendizaje_activo integer NOT NULL DEFAULT 1,
  tasa_aprendizaje numeric NOT NULL DEFAULT 0.15,
  pesos_senal jsonb NOT NULL DEFAULT '{"rafaga": 0.45, "outlier": 0.22, "auto_resena": 1.00, "cuenta_nueva": 0.25, "duplicado_texto": 0.40, "sin_trabajo_valido": 0.95, "texto_vacio_extremo": 0.20, "granja_cinco_estrellas": 0.50}',
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT ranking_config_aprendizaje_activo_bool_chk CHECK (((aprendizaje_activo IS NULL) OR (aprendizaje_activo = ANY (ARRAY[0, 1])))),
  CONSTRAINT ranking_config_unica CHECK ((id = 'default'::text))
);

COMMENT ON TABLE ranking_config IS 'Una fila default. Pesos del listado de profesionales.';

CREATE TABLE senales_resena (
  id text NOT NULL,
  id_calificacion text NOT NULL,
  tipo_senal text NOT NULL,
  puntaje numeric NOT NULL,
  detalle text,
  estado text NOT NULL DEFAULT 'pendiente',
  resuelto_por uuid,
  resuelto_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id),
  CONSTRAINT senales_resena_estado_chk CHECK ((estado = ANY (ARRAY['pendiente'::text, 'fraude_confirmado'::text, 'falso_positivo'::text, 'descartada'::text])))
);

COMMENT ON TABLE senales_resena IS 'Señales de reseña dudosa. Un falso positivo baja el peso de esa señal.';

CREATE TABLE ranking_aprendizaje (
  id text NOT NULL,
  motivo text NOT NULL,
  pesos_antes jsonb NOT NULL,
  pesos_despues jsonb NOT NULL,
  metricas jsonb,
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);

COMMENT ON TABLE ranking_aprendizaje IS 'Ajuste de los pesos del ranking y las métricas de ese cambio.';

CREATE TABLE eventos_ranking (
  id text NOT NULL,
  id_trabajador uuid NOT NULL,
  id_trabajo text,
  tipo_evento text NOT NULL,
  factores jsonb NOT NULL DEFAULT '{}',
  creado_en timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);

COMMENT ON TABLE eventos_ranking IS 'Evento que alimenta el ranking de un profesional.';

CREATE TABLE encuestas_testing (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  creado_en timestamptz NOT NULL DEFAULT now(),
  id_usuario uuid DEFAULT auth.uid(),
  plataforma text NOT NULL,
  rol text NOT NULL,
  tarea_completada text NOT NULL,
  satisfaccion smallint NOT NULL,
  que_funciono text,
  que_mejorar text,
  version_app text,
  PRIMARY KEY (id),
  CONSTRAINT encuestas_testing_plataforma_check CHECK ((plataforma = ANY (ARRAY['web'::text, 'app'::text, 'escritorio'::text]))),
  CONSTRAINT encuestas_testing_que_funciono_check CHECK (((que_funciono IS NULL) OR (char_length(que_funciono) <= 1000))),
  CONSTRAINT encuestas_testing_que_mejorar_check CHECK (((que_mejorar IS NULL) OR (char_length(que_mejorar) <= 1000))),
  CONSTRAINT encuestas_testing_rol_check CHECK ((rol = ANY (ARRAY['visitante'::text, 'cliente'::text, 'profesional'::text, 'administrador'::text]))),
  CONSTRAINT encuestas_testing_satisfaccion_check CHECK (((satisfaccion >= 1) AND (satisfaccion <= 5))),
  CONSTRAINT encuestas_testing_tarea_completada_check CHECK ((tarea_completada = ANY (ARRAY['si'::text, 'parcial'::text, 'no'::text]))),
  CONSTRAINT encuestas_testing_version_app_check CHECK (((version_app IS NULL) OR (char_length(version_app) <= 40)))
);

COMMENT ON TABLE encuestas_testing IS 'Encuesta de usabilidad de quienes prueban la app: plataforma, rol, si completó la tarea, satisfacción y comentarios. Las respuestas SUS están en encuesta_testing_respuestas y el puntaje lo calcula la vista encuestas_testing_con_puntaje.';

CREATE TABLE encuesta_testing_respuestas (
  id_encuesta uuid NOT NULL,
  item smallint NOT NULL,
  valor smallint NOT NULL,
  PRIMARY KEY (id_encuesta, item),
  CONSTRAINT encuesta_testing_respuestas_item_check CHECK (((item >= 1) AND (item <= 10))),
  CONSTRAINT encuesta_testing_respuestas_valor_check CHECK (((valor >= 1) AND (valor <= 5)))
);

COMMENT ON TABLE encuesta_testing_respuestas IS 'Respuesta a cada uno de los 10 ítems SUS de una encuesta (item de 1 a 10, valor de 1 a 5).';

-- Claves foráneas, únicos e índices

ALTER TABLE perfiles ADD FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
CREATE INDEX idx_perfiles_rol ON public.perfiles USING btree (rol);

ALTER TABLE notificaciones ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX notificaciones_usuario_creado_idx ON public.notificaciones USING btree (id_usuario, creado_en DESC);

ALTER TABLE suscripciones ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_suscripciones_id_usuario_fkey ON public.suscripciones USING btree (id_usuario);

ALTER TABLE codigos_restablecimiento ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_codigos_restablecimiento_id_usuario_fkey ON public.codigos_restablecimiento USING btree (id_usuario);

ALTER TABLE consentimientos_usuario ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_consentimientos_usuario_id_usuario_fkey ON public.consentimientos_usuario USING btree (id_usuario);

ALTER TABLE bloqueos_usuario ADD FOREIGN KEY (id_bloqueado) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE bloqueos_usuario ADD FOREIGN KEY (id_bloqueador) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE bloqueos_usuario ADD CONSTRAINT user_blocks_blockerId_blockedUserId_key UNIQUE (id_bloqueador, id_bloqueado);
CREATE INDEX idx_bloqueos_usuario_id_bloqueado_fkey ON public.bloqueos_usuario USING btree (id_bloqueado);
CREATE UNIQUE INDEX "user_blocks_blockerId_blockedUserId_key" ON public.bloqueos_usuario USING btree (id_bloqueador, id_bloqueado);

ALTER TABLE reportes ADD FOREIGN KEY (id_reportante) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE reportes ADD FOREIGN KEY (id_usuario_reportado) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_reportes_id_reportante_fkey ON public.reportes USING btree (id_reportante);
CREATE INDEX idx_reportes_id_usuario_reportado_fkey ON public.reportes USING btree (id_usuario_reportado);

ALTER TABLE eventos_abuso ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_eventos_abuso_id_usuario_fkey ON public.eventos_abuso USING btree (id_usuario);

ALTER TABLE acciones_pendientes ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_acciones_pendientes_id_usuario_fkey ON public.acciones_pendientes USING btree (id_usuario);

ALTER TABLE registros_error_app ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id);
CREATE INDEX idx_registros_error_app_id_usuario_fkey ON public.registros_error_app USING btree (id_usuario);

ALTER TABLE eventos_analitica ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE SET NULL;
CREATE INDEX idx_eventos_analitica_id_usuario_fkey ON public.eventos_analitica USING btree (id_usuario);

ALTER TABLE banderas_funcionalidad ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_banderas_funcionalidad_id_usuario_fkey ON public.banderas_funcionalidad USING btree (id_usuario);

ALTER TABLE dispositivos_push ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_dispositivos_push_usuario ON public.dispositivos_push USING btree (id_usuario);

ALTER TABLE verificacion_eventos ADD FOREIGN KEY (id_actor) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE verificacion_eventos ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_verificacion_eventos_id_actor_fkey ON public.verificacion_eventos USING btree (id_actor);
CREATE INDEX verificacion_eventos_usuario_idx ON public.verificacion_eventos USING btree (id_usuario, creado_en);

ALTER TABLE paises ADD CONSTRAINT paises_iso2_key UNIQUE (iso2);
CREATE UNIQUE INDEX paises_iso2_key ON public.paises USING btree (iso2);

ALTER TABLE regiones ADD FOREIGN KEY (id_pais) REFERENCES paises(id);
CREATE INDEX idx_regiones_id_pais_fkey ON public.regiones USING btree (id_pais);

ALTER TABLE comunas ADD FOREIGN KEY (id_region) REFERENCES regiones(id);
CREATE INDEX comunas_nombre_idx ON public.comunas USING btree (nombre);
CREATE INDEX comunas_region_idx ON public.comunas USING btree (id_region);
CREATE UNIQUE INDEX comunas_region_nombre_activa_uidx ON public.comunas USING btree (id_region, lower(nombre)) WHERE (activa = 1);

ALTER TABLE trabajadores ADD FOREIGN KEY (id_comuna) REFERENCES comunas(id) ON DELETE SET NULL;
ALTER TABLE trabajadores ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_trabajadores_id_comuna_fkey ON public.trabajadores USING btree (id_comuna);
CREATE INDEX trabajadores_base_geo_idx ON public.trabajadores USING btree (latitud_base, longitud_base) WHERE ((latitud_base IS NOT NULL) AND (longitud_base IS NOT NULL));
CREATE INDEX trabajadores_calificacion_idx ON public.trabajadores USING btree (calificacion DESC NULLS LAST) WHERE (COALESCE(disponible, 0) = 1);
CREATE INDEX trabajadores_score_listado_idx ON public.trabajadores USING btree (score_listado DESC, id_usuario);
CREATE INDEX trabajadores_zona_trabajo_idx ON public.trabajadores USING btree (zona_trabajo) WHERE ((COALESCE(disponible, 0) = 1) AND (zona_trabajo IS NOT NULL));

ALTER TABLE trabajador_precios ADD FOREIGN KEY (id_usuario) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;

ALTER TABLE trabajador_servicios_extra ADD FOREIGN KEY (id_usuario) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;

ALTER TABLE trabajador_servicios ADD FOREIGN KEY (categoria_servicio) REFERENCES categorias_servicio(id) ON UPDATE CASCADE;
ALTER TABLE trabajador_servicios ADD FOREIGN KEY (id_trabajador) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;
CREATE INDEX trabajador_servicios_categoria_idx ON public.trabajador_servicios USING btree (categoria_servicio, id_trabajador);

ALTER TABLE trabajador_horarios ADD FOREIGN KEY (id_usuario) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;
CREATE UNIQUE INDEX trabajador_horarios_usuario_dia_uidx ON public.trabajador_horarios USING btree (id_usuario, dia_semana);

ALTER TABLE trabajador_horas_publicadas ADD FOREIGN KEY (id_usuario) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;

ALTER TABLE portafolio_trabajador ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_portfolio_worker ON public.portafolio_trabajador USING btree (id_trabajador);

ALTER TABLE impulsos ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_impulsos_id_trabajador_fkey ON public.impulsos USING btree (id_trabajador);

ALTER TABLE servicios ADD FOREIGN KEY (categoria) REFERENCES categorias_servicio(id) ON UPDATE CASCADE;
CREATE INDEX idx_servicios_categoria ON public.servicios USING btree (categoria);
CREATE INDEX servicios_activo_categoria_idx ON public.servicios USING btree (activo, categoria) WHERE (COALESCE(activo, 1) = 1);

ALTER TABLE configuraciones_servicio ADD FOREIGN KEY (id_servicio) REFERENCES servicios(id) ON DELETE CASCADE;
ALTER TABLE configuraciones_servicio ADD CONSTRAINT service_configs_serviceId_key UNIQUE (id_servicio);
CREATE UNIQUE INDEX "service_configs_serviceId_key" ON public.configuraciones_servicio USING btree (id_servicio);

ALTER TABLE trabajos ADD FOREIGN KEY (id_servicio) REFERENCES servicios(id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE trabajos ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD FOREIGN KEY (id_comuna) REFERENCES comunas(id) ON DELETE SET NULL;
ALTER TABLE trabajos ADD FOREIGN KEY (id_cotizacion_seleccionada) REFERENCES propuestas_cotizacion(id) ON DELETE SET NULL;
CREATE INDEX idx_trabajos_creado_en ON public.trabajos USING btree (creado_en DESC);
CREATE INDEX idx_trabajos_estado ON public.trabajos USING btree (estado);
CREATE INDEX idx_trabajos_id_comuna_fkey ON public.trabajos USING btree (id_comuna);
CREATE INDEX idx_trabajos_id_cotizacion_seleccionada_fkey ON public.trabajos USING btree (id_cotizacion_seleccionada);
CREATE INDEX idx_trabajos_id_servicio_fkey ON public.trabajos USING btree (id_servicio);
CREATE INDEX idx_trabajos_id_trabajador ON public.trabajos USING btree (id_trabajador);
CREATE INDEX trabajos_trabajador_estado_idx ON public.trabajos USING btree (id_trabajador, estado) WHERE (id_trabajador IS NOT NULL);
CREATE INDEX trabajos_trabajador_fecha_programada_idx ON public.trabajos USING btree (id_trabajador, fecha_programada) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL));
CREATE UNIQUE INDEX trabajos_trabajador_minuto_activo_uidx ON public.trabajos USING btree (id_trabajador, minuto_utc(fecha_programada)) WHERE ((fecha_programada IS NOT NULL) AND (id_trabajador IS NOT NULL) AND (estado <> ALL (ARRAY['cancelado'::text, 'expirado'::text, 'completado'::text, 'no_asistio'::text])));
CREATE INDEX trabajos_usuario_creado_idx ON public.trabajos USING btree (id_usuario, creado_en DESC);

ALTER TABLE mensajes ADD FOREIGN KEY (id_destinatario) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE mensajes ADD FOREIGN KEY (id_remitente) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE mensajes ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX idx_mensajes_id_remitente_fkey ON public.mensajes USING btree (id_remitente);
CREATE INDEX idx_messages_receiver ON public.mensajes USING btree (id_destinatario);
CREATE INDEX mensajes_trabajo_creado_idx ON public.mensajes USING btree (id_trabajo, creado_en);

ALTER TABLE fotos_trabajo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX idx_job_photos_job ON public.fotos_trabajo USING btree (id_trabajo);

ALTER TABLE calificaciones ADD FOREIGN KEY (id_calificado) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE calificaciones ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE calificaciones ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX calificaciones_calificado_idx ON public.calificaciones USING btree (id_calificado, direccion, creado_en DESC);
CREATE INDEX calificaciones_estado_revision_idx ON public.calificaciones USING btree (estado_revision);
CREATE UNIQUE INDEX calificaciones_trabajo_direccion_uidx ON public.calificaciones USING btree (id_trabajo, direccion);
CREATE INDEX calificaciones_trabajo_idx ON public.calificaciones USING btree (id_trabajo);
CREATE INDEX idx_calificaciones_id_usuario_fkey ON public.calificaciones USING btree (id_usuario);

ALTER TABLE calificaciones_cliente ADD FOREIGN KEY (id_cliente) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE calificaciones_cliente ADD CONSTRAINT calificaciones_cliente_trabajo_unica UNIQUE (id_trabajo);
CREATE UNIQUE INDEX calificaciones_cliente_trabajo_unica ON public.calificaciones_cliente USING btree (id_trabajo);
CREATE INDEX idx_calificaciones_cliente_id_cliente_fkey ON public.calificaciones_cliente USING btree (id_cliente);
CREATE INDEX idx_calificaciones_cliente_id_trabajador_fkey ON public.calificaciones_cliente USING btree (id_trabajador);

ALTER TABLE disputas ADD FOREIGN KEY (abierta_por) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE disputas ADD FOREIGN KEY (resuelta_por) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE disputas ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX idx_disputas_abierta_por_fkey ON public.disputas USING btree (abierta_por);
CREATE INDEX idx_disputas_estado ON public.disputas USING btree (estado);
CREATE INDEX idx_disputas_resuelta_por_fkey ON public.disputas USING btree (resuelta_por);
CREATE INDEX idx_disputes_job ON public.disputas USING btree (id_trabajo);

ALTER TABLE disputa_mensajes ADD FOREIGN KEY (id_autor) REFERENCES perfiles(id);
ALTER TABLE disputa_mensajes ADD FOREIGN KEY (id_disputa) REFERENCES disputas(id) ON DELETE CASCADE;
CREATE INDEX idx_disputa_mensajes_id_autor_fkey ON public.disputa_mensajes USING btree (id_autor);
CREATE INDEX idx_disputa_mensajes_id_disputa_fkey ON public.disputa_mensajes USING btree (id_disputa);

ALTER TABLE acuerdos_trabajo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE acuerdos_trabajo ADD FOREIGN KEY (propuesto_por) REFERENCES perfiles(id);
CREATE UNIQUE INDEX acuerdos_trabajo_pendiente_uidx ON public.acuerdos_trabajo USING btree (id_trabajo) WHERE (estado = 'pendiente'::text);
CREATE INDEX idx_acuerdos_trabajo_id_trabajo_fkey ON public.acuerdos_trabajo USING btree (id_trabajo);
CREATE INDEX idx_acuerdos_trabajo_propuesto_por_fkey ON public.acuerdos_trabajo USING btree (propuesto_por);

ALTER TABLE cancelaciones_trabajo ADD FOREIGN KEY (cancelado_por) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE cancelaciones_trabajo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE cancelaciones_trabajo ADD CONSTRAINT job_cancellations_jobId_key UNIQUE (id_trabajo);
CREATE INDEX idx_cancelaciones_trabajo_cancelado_por_fkey ON public.cancelaciones_trabajo USING btree (cancelado_por);
CREATE UNIQUE INDEX "job_cancellations_jobId_key" ON public.cancelaciones_trabajo USING btree (id_trabajo);

ALTER TABLE tickets_soporte ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE SET NULL;
CREATE INDEX idx_tickets_soporte_id_trabajo_fkey ON public.tickets_soporte USING btree (id_trabajo);

ALTER TABLE ubicacion_en_vivo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE ubicacion_en_vivo ADD FOREIGN KEY (id_trabajador) REFERENCES trabajadores(id_usuario) ON DELETE CASCADE;
CREATE INDEX idx_ubicacion_en_vivo_id_trabajador_fkey ON public.ubicacion_en_vivo USING btree (id_trabajador);

ALTER TABLE reprogramaciones_trabajo ADD FOREIGN KEY (propuesta_por) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE reprogramaciones_trabajo ADD FOREIGN KEY (respondida_por) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE reprogramaciones_trabajo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX idx_reprogramaciones_trabajo_propuesta_por_fkey ON public.reprogramaciones_trabajo USING btree (propuesta_por);
CREATE INDEX idx_reprogramaciones_trabajo_respondida_por_fkey ON public.reprogramaciones_trabajo USING btree (respondida_por);
CREATE INDEX reprogramaciones_por_trabajo ON public.reprogramaciones_trabajo USING btree (id_trabajo, creado_en DESC);
CREATE UNIQUE INDEX reprogramaciones_una_pendiente ON public.reprogramaciones_trabajo USING btree (id_trabajo) WHERE (estado = 'pendiente'::text);

ALTER TABLE pines_inicio_trabajo ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;

ALTER TABLE bloqueos_pin_inicio ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;

ALTER TABLE intentos_pin_inicio ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE intentos_pin_inicio ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE SET NULL;
CREATE INDEX idx_intentos_pin_inicio_id_usuario_fkey ON public.intentos_pin_inicio USING btree (id_usuario);
CREATE INDEX intentos_pin_inicio_trabajo_idx ON public.intentos_pin_inicio USING btree (id_trabajo, creado_en DESC);

ALTER TABLE propuestas_cotizacion ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE propuestas_cotizacion ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_quotes_job ON public.propuestas_cotizacion USING btree (id_trabajo);
CREATE INDEX idx_quotes_worker ON public.propuestas_cotizacion USING btree (id_trabajador);

ALTER TABLE propuesta_cotizacion_items ADD FOREIGN KEY (id_propuesta) REFERENCES propuestas_cotizacion(id) ON DELETE CASCADE;

ALTER TABLE pagos ADD FOREIGN KEY (id_orden_cambio) REFERENCES ordenes_cambio(id) ON DELETE SET NULL;
ALTER TABLE pagos ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
CREATE INDEX idx_pagos_id_orden_cambio_fkey ON public.pagos USING btree (id_orden_cambio);
CREATE UNIQUE INDEX pagos_alta_jti_uidx ON public.pagos USING btree (alta_jti) WHERE (alta_jti IS NOT NULL);
CREATE INDEX pagos_buy_order_idx ON public.pagos USING btree (buy_order) WHERE ((buy_order IS NOT NULL) AND (length(TRIM(BOTH FROM buy_order)) > 0));
CREATE INDEX pagos_por_confirmar_idx ON public.pagos USING btree (estado) WHERE (estado = 'pagado_por_confirmar'::text);
CREATE INDEX pagos_token_tbk_idx ON public.pagos USING btree (token_tbk) WHERE ((token_tbk IS NOT NULL) AND (length(TRIM(BOTH FROM token_tbk)) > 0));
CREATE INDEX pagos_trabajo_estado_idx ON public.pagos USING btree (id_trabajo, estado);
CREATE UNIQUE INDEX pagos_un_principal_activo_uidx ON public.pagos USING btree (id_trabajo) WHERE ((tipo_pago = 'principal'::text) AND (estado = ANY (ARRAY['pendiente'::text, 'retenido'::text, 'autorizado'::text])));

ALTER TABLE ordenes_cambio ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE CASCADE;
ALTER TABLE ordenes_cambio ADD FOREIGN KEY (id_pago) REFERENCES pagos(id) ON DELETE SET NULL;
ALTER TABLE ordenes_cambio ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE INDEX idx_change_orders_job ON public.ordenes_cambio USING btree (id_trabajo);
CREATE INDEX idx_ordenes_cambio_id_pago_fkey ON public.ordenes_cambio USING btree (id_pago);
CREATE INDEX idx_ordenes_cambio_id_trabajador_fkey ON public.ordenes_cambio USING btree (id_trabajador);

ALTER TABLE liquidaciones ADD FOREIGN KEY (id_operador) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE liquidaciones ADD FOREIGN KEY (id_pago) REFERENCES pagos(id);
ALTER TABLE liquidaciones ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE liquidaciones ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id);
CREATE INDEX idx_liquidaciones_id_trabajo_fkey ON public.liquidaciones USING btree (id_trabajo);
CREATE INDEX liquidaciones_creado_idx ON public.liquidaciones USING btree (creado_en DESC);
CREATE INDEX liquidaciones_operador_idx ON public.liquidaciones USING btree (id_operador) WHERE (id_operador IS NOT NULL);
CREATE UNIQUE INDEX liquidaciones_pago_uidx ON public.liquidaciones USING btree (id_pago);
CREATE INDEX liquidaciones_trabajador_creado_idx ON public.liquidaciones USING btree (id_trabajador, creado_en DESC);

ALTER TABLE metodos_pago_oneclick ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;
CREATE UNIQUE INDEX metodos_pago_oneclick_ticket_handoff_uidx ON public.metodos_pago_oneclick USING btree (ticket_handoff) WHERE (ticket_handoff IS NOT NULL);
CREATE INDEX metodos_pago_oneclick_token_idx ON public.metodos_pago_oneclick USING btree (token_inscripcion) WHERE ((token_inscripcion IS NOT NULL) AND (length(TRIM(BOTH FROM token_inscripcion)) > 0));

ALTER TABLE cuentas_bancarias ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE;

ALTER TABLE senales_resena ADD FOREIGN KEY (id_calificacion) REFERENCES calificaciones(id) ON DELETE CASCADE;
ALTER TABLE senales_resena ADD FOREIGN KEY (resuelto_por) REFERENCES perfiles(id) ON DELETE SET NULL;
ALTER TABLE senales_resena ADD CONSTRAINT senales_resena_unica UNIQUE (id_calificacion, tipo_senal);
CREATE INDEX idx_senales_resena_resuelto_por_fkey ON public.senales_resena USING btree (resuelto_por);
CREATE INDEX senales_resena_estado_idx ON public.senales_resena USING btree (estado, creado_en DESC);
CREATE UNIQUE INDEX senales_resena_unica ON public.senales_resena USING btree (id_calificacion, tipo_senal);

ALTER TABLE eventos_ranking ADD FOREIGN KEY (id_trabajador) REFERENCES perfiles(id) ON DELETE CASCADE;
ALTER TABLE eventos_ranking ADD FOREIGN KEY (id_trabajo) REFERENCES trabajos(id) ON DELETE SET NULL;
CREATE INDEX eventos_ranking_trabajador_idx ON public.eventos_ranking USING btree (id_trabajador, tipo_evento);
CREATE INDEX idx_eventos_ranking_id_trabajo_fkey ON public.eventos_ranking USING btree (id_trabajo);

ALTER TABLE encuestas_testing ADD FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE SET NULL;
CREATE INDEX encuestas_testing_creado_en_idx ON public.encuestas_testing USING btree (creado_en DESC);
CREATE INDEX encuestas_testing_id_usuario_idx ON public.encuestas_testing USING btree (id_usuario);

ALTER TABLE encuesta_testing_respuestas ADD FOREIGN KEY (id_encuesta) REFERENCES encuestas_testing(id) ON DELETE CASCADE;

COMMIT;
