-- MyWorksApp — modelo entidad-relación (PostgreSQL)
-- Versión 2.3 · 43 tablas public · 4NF + catálogo geográfico + ranking + agenda · 2026-11-08
--
-- Modelo LÓGICO normalizado (consulta), alineado a la base viva
-- wxqrfcqifkfgawrnqmnj hasta 20261108000005_trabajador_horarios.sql
--
-- Forma 4NF de la oferta:
--   trabajador_precios (id_usuario, codigo, monto_clp)
--   trabajador_servicios_extra (id_usuario, id, titulo, monto_clp, unidad)
-- JSON niveles_precio / servicios_personalizados sigue en trabajadores
-- solo como formato de ESCRITURA de la app; el trigger lo parte a filas.
-- La plantilla semanal vive en trabajador_horarios (no en trabajadores).
--
-- Copias derivadas (no son fuente):
--   trabajadores.calificacion ← promedio ponderado de calificaciones
--   trabajadores.es_elite     ← GENERATED (nota ≥ 4.7 y ≥ 5 completados)
--   perfiles.reputacion_cliente ← promedio de calificaciones_cliente
--   trabajos.estado_pago      ← estado del pago principal
--
-- En Postgres vivo, trabajador_precios.id_usuario es text (cast del uuid).
-- Aquí se modela uuid + FK: esa es la dependencia funcional 4NF.
-- liquidaciones.id_trabajador y metodos_pago_oneclick.id_usuario siguen
-- en text (así está la BD; no hay FK uuid).
--
-- Importar: pgModeler / DBeaver / DataGrip / dbdiagram.io (.dbml)
-- No ejecutar contra el proyecto Supabase de producción.

BEGIN;

CREATE TABLE perfiles (
  id uuid PRIMARY KEY,
  nombre text NOT NULL DEFAULT '',
  correo text,
  rol text NOT NULL DEFAULT 'usuario',
  estado_cuenta text NOT NULL DEFAULT 'activo',
  ruta_foto_perfil text,
  reputacion_cliente numeric(3, 2),
  calificaciones_cliente integer NOT NULL DEFAULT 0,
  creado_en text NOT NULL
);

CREATE TABLE paises (
  id text PRIMARY KEY,
  nombre text NOT NULL,
  iso2 text NOT NULL UNIQUE
);

CREATE TABLE regiones (
  id text PRIMARY KEY,
  id_pais text NOT NULL REFERENCES paises (id),
  nombre text NOT NULL,
  codigo_oficial text
);

CREATE TABLE comunas (
  id text PRIMARY KEY,
  id_region text NOT NULL REFERENCES regiones (id),
  nombre text NOT NULL,
  latitud double precision,
  longitud double precision,
  activa integer NOT NULL DEFAULT 1
);

CREATE TABLE trabajadores (
  id_usuario uuid PRIMARY KEY REFERENCES perfiles (id) ON DELETE CASCADE,
  profesion text NOT NULL DEFAULT '',
  descripcion text,
  calificacion numeric(4, 2) NOT NULL DEFAULT 0,
  disponible integer NOT NULL DEFAULT 1,
  tarifa_visita numeric(12, 0) NOT NULL DEFAULT 15000,
  categoria_servicio text NOT NULL DEFAULT 'general',
  niveles_precio jsonb NOT NULL DEFAULT '{}'::jsonb,
  servicios_personalizados jsonb NOT NULL DEFAULT '[]'::jsonb,
  precios_configurados integer NOT NULL DEFAULT 0,
  zona_trabajo text,
  conteo_rechazos integer NOT NULL DEFAULT 0,
  estado_verificacion text NOT NULL DEFAULT 'pendiente',
  nota_verificacion text,
  latitud_base double precision,
  longitud_base double precision,
  radio_servicio_km numeric NOT NULL DEFAULT 15,
  origen_base text,
  id_comuna text REFERENCES comunas (id) ON DELETE SET NULL,
  id_region text REFERENCES regiones (id) ON DELETE SET NULL,
  score_listado numeric(8, 4) NOT NULL DEFAULT 0,
  prioridad_manual integer NOT NULL DEFAULT 0,
  score_desglose jsonb NOT NULL DEFAULT '{}'::jsonb,
  ranking_actualizado_en timestamptz,
  radio_urbano_km numeric(5, 2) NOT NULL DEFAULT 5,
  tarifa_fuera_radio_clp integer NOT NULL DEFAULT 0,
  trabajos_completados integer NOT NULL DEFAULT 0,
  es_elite boolean GENERATED ALWAYS AS (
    COALESCE(calificacion, 0) >= 4.7 AND trabajos_completados >= 5
  ) STORED,
  CONSTRAINT trabajadores_prioridad_manual_chk CHECK (prioridad_manual BETWEEN -50 AND 50),
  CONSTRAINT trabajadores_radio_urbano_km_chk CHECK (radio_urbano_km BETWEEN 1 AND 40),
  CONSTRAINT trabajadores_tarifa_fuera_radio_clp_chk CHECK (tarifa_fuera_radio_clp BETWEEN 0 AND 200000)
);

CREATE TABLE servicios (
  id text PRIMARY KEY,
  nombre text NOT NULL,
  descripcion text,
  categoria text NOT NULL DEFAULT 'general',
  activo integer NOT NULL DEFAULT 1,
  requiere_certificacion integer NOT NULL DEFAULT 0,
  modelo_precio text NOT NULL DEFAULT 'por_hora',
  aviso_legal text,
  creado_en text,
  actualizado_en text
);

CREATE TABLE trabajador_servicios (
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  categoria_servicio text NOT NULL,
  PRIMARY KEY (id_trabajador, categoria_servicio)
);

CREATE TABLE trabajador_precios (
  id_usuario uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  codigo text NOT NULL,
  monto_clp numeric(12, 0) NOT NULL CHECK (monto_clp >= 0),
  PRIMARY KEY (id_usuario, codigo)
);

CREATE TABLE trabajador_servicios_extra (
  id text NOT NULL,
  id_usuario uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  titulo text NOT NULL,
  subtitulo text NOT NULL DEFAULT '',
  monto_clp numeric(12, 0) NOT NULL CHECK (monto_clp >= 0),
  unidad text NOT NULL DEFAULT 'fijo' CHECK (unidad IN ('fijo', 'por_m2')),
  PRIMARY KEY (id_usuario, id)
);

CREATE TABLE trabajador_horarios (
  id_usuario uuid PRIMARY KEY REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  horarios jsonb NOT NULL DEFAULT '[]'::jsonb,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE portafolio_trabajador (
  id text PRIMARY KEY,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  ruta_foto text NOT NULL,
  descripcion text,
  tipo_medio text DEFAULT 'foto',
  creado_en text NOT NULL
);

CREATE TABLE impulsos (
  id text PRIMARY KEY,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  tipo_impulso text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text NOT NULL,
  creado_en text NOT NULL
);

CREATE TABLE configuraciones_servicio (
  id text PRIMARY KEY,
  id_servicio text NOT NULL UNIQUE REFERENCES servicios (id) ON DELETE CASCADE,
  esquema_config text NOT NULL,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

CREATE TABLE trabajos (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  id_trabajador uuid REFERENCES trabajadores (id_usuario) ON DELETE SET NULL,
  id_servicio text REFERENCES servicios (id) ON DELETE SET NULL,
  estado text NOT NULL,
  direccion text NOT NULL DEFAULT '',
  latitud double precision,
  longitud double precision,
  descripcion text,
  fecha_programada text,
  metadatos_servicio text,
  modalidad_cobro text,
  estado_pago text,
  id_comuna text REFERENCES comunas (id) ON DELETE SET NULL,
  instantanea_precio text,
  id_sku_servicio text,
  horas_bloque integer,
  id_cotizacion_seleccionada text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

-- En la BD viva el segundo término es public.minuto_utc(fecha_programada::text).
CREATE UNIQUE INDEX trabajos_trabajador_minuto_activo_uidx
  ON trabajos (id_trabajador, fecha_programada)
  WHERE fecha_programada IS NOT NULL
    AND id_trabajador IS NOT NULL
    AND estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio');

CREATE TABLE propuestas_cotizacion (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  monto_total_clp integer NOT NULL,
  descripcion text NOT NULL,
  validez_hasta text,
  desglose text,
  estado text NOT NULL,
  creado_en text NOT NULL
);

CREATE TABLE pagos (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  id_orden_cambio text,
  tipo_pago text NOT NULL DEFAULT 'principal',
  monto numeric(12, 0) NOT NULL,
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
  alta_consumido_en timestamptz
);

CREATE UNIQUE INDEX pagos_un_principal_activo_uidx
  ON pagos (id_trabajo)
  WHERE tipo_pago = 'principal'
    AND estado IN ('pendiente', 'retenido', 'autorizado');

CREATE UNIQUE INDEX pagos_alta_jti_uidx
  ON pagos (alta_jti)
  WHERE alta_jti IS NOT NULL;

CREATE TABLE ordenes_cambio (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario),
  tipo text NOT NULL,
  titulo text NOT NULL,
  descripcion text NOT NULL,
  monto_clp integer NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente_cliente',
  id_pago text,
  creado_en text NOT NULL,
  respondido_en text
);

CREATE TABLE liquidaciones (
  id text PRIMARY KEY,
  id_pago text NOT NULL REFERENCES pagos (id),
  id_trabajo text NOT NULL REFERENCES trabajos (id),
  id_trabajador text,
  monto_clp numeric NOT NULL CHECK (monto_clp > 0),
  proveedor text NOT NULL DEFAULT 'manual'
    CHECK (proveedor IN ('manual', 'khipu', 'fintoc')),
  referencia_transferencia text NOT NULL,
  notas text,
  id_operador text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX liquidaciones_pago_uidx ON liquidaciones (id_pago);

CREATE TABLE metodos_pago_oneclick (
  id_usuario text PRIMARY KEY,
  username text NOT NULL,
  tbk_user text,
  tipo_tarjeta text,
  ultimos4 text,
  estado text NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'activa', 'rechazada')),
  token_inscripcion text,
  id_trabajo_pendiente text,
  url_inscripcion text,
  ticket_handoff text,
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX metodos_pago_oneclick_ticket_handoff_uidx
  ON metodos_pago_oneclick (ticket_handoff)
  WHERE ticket_handoff IS NOT NULL;

CREATE TABLE mensajes (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  id_remitente uuid NOT NULL REFERENCES perfiles (id),
  id_destinatario uuid NOT NULL REFERENCES perfiles (id),
  contenido text NOT NULL,
  tipo text NOT NULL DEFAULT 'texto',
  ruta_imagen text,
  leido integer NOT NULL DEFAULT 0,
  creado_en text NOT NULL
);

CREATE TABLE fotos_trabajo (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  ruta_foto text NOT NULL,
  tipo_medio text NOT NULL DEFAULT 'foto',
  imagen_webp bytea,
  creado_en text NOT NULL
);

CREATE TABLE calificaciones (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  id_usuario uuid REFERENCES perfiles (id),
  puntaje integer NOT NULL,
  comentario text,
  creado_en text NOT NULL,
  peso_confianza numeric(4, 3) NOT NULL DEFAULT 1,
  estado_revision text NOT NULL DEFAULT 'vigente',
  motivo_revision text,
  CONSTRAINT calificaciones_peso_confianza_chk CHECK (peso_confianza >= 0 AND peso_confianza <= 1),
  CONSTRAINT calificaciones_estado_revision_chk CHECK (estado_revision IN ('vigente', 'en_revision', 'excluida'))
);

CREATE TABLE calificaciones_cliente (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL UNIQUE REFERENCES trabajos (id) ON DELETE CASCADE,
  id_cliente uuid NOT NULL REFERENCES perfiles (id),
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario),
  puntaje smallint NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
  comentario text,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE disputas (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL REFERENCES trabajos (id) ON DELETE CASCADE,
  abierta_por uuid NOT NULL REFERENCES perfiles (id),
  motivo text NOT NULL,
  descripcion text,
  estado text NOT NULL,
  resolucion text,
  resuelta_por uuid REFERENCES perfiles (id),
  resuelta_en text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

CREATE TABLE cancelaciones_trabajo (
  id text PRIMARY KEY,
  id_trabajo text NOT NULL UNIQUE REFERENCES trabajos (id) ON DELETE CASCADE,
  cancelado_por uuid NOT NULL REFERENCES perfiles (id),
  motivo text NOT NULL,
  cancelado_en text NOT NULL
);

CREATE TABLE tickets_soporte (
  id text PRIMARY KEY,
  id_trabajo text REFERENCES trabajos (id),
  nombre_cliente text NOT NULL,
  nombre_trabajador text NOT NULL,
  asunto text NOT NULL,
  monto_escrow integer NOT NULL,
  estado text DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'resuelto')),
  creado_en timestamptz DEFAULT now()
);

CREATE TABLE notificaciones (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  tipo text NOT NULL,
  titulo text NOT NULL,
  cuerpo text NOT NULL,
  id_relacionado text,
  leido integer NOT NULL DEFAULT 0,
  creado_en text NOT NULL
);

CREATE TABLE suscripciones (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  tipo_plan text NOT NULL,
  estado text NOT NULL,
  fecha_inicio text NOT NULL,
  fecha_fin text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

CREATE TABLE codigos_restablecimiento (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id),
  codigo text NOT NULL,
  correo text NOT NULL,
  expira_en text NOT NULL,
  usado integer DEFAULT 0,
  creado_en text NOT NULL
);

CREATE TABLE consentimientos_usuario (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  version_consentimiento text NOT NULL,
  aceptado integer NOT NULL DEFAULT 0,
  aceptado_en text NOT NULL,
  direccion_ip text,
  agente_usuario text
);

CREATE TABLE bloqueos_usuario (
  id text PRIMARY KEY,
  id_bloqueador uuid NOT NULL REFERENCES perfiles (id),
  id_bloqueado uuid NOT NULL REFERENCES perfiles (id),
  creado_en text NOT NULL,
  UNIQUE (id_bloqueador, id_bloqueado)
);

CREATE TABLE reportes (
  id text PRIMARY KEY,
  id_reportante uuid NOT NULL REFERENCES perfiles (id),
  id_usuario_reportado uuid NOT NULL REFERENCES perfiles (id),
  motivo text NOT NULL,
  descripcion text,
  estado text NOT NULL DEFAULT 'pendiente',
  creado_en text NOT NULL
);

CREATE TABLE eventos_abuso (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  tipo_abuso text NOT NULL,
  conteo integer NOT NULL,
  detectado_en text NOT NULL,
  accion_tomada text,
  accion_tomada_en text,
  resuelto integer DEFAULT 0
);

CREATE TABLE acciones_pendientes (
  id text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES perfiles (id) ON DELETE CASCADE,
  tipo_accion text NOT NULL,
  tipo_entidad text NOT NULL,
  id_entidad text,
  datos text NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente_sync',
  conteo_reintentos integer DEFAULT 0,
  mensaje_error text,
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

CREATE TABLE registros_error_app (
  id text PRIMARY KEY,
  id_usuario uuid REFERENCES perfiles (id),
  tipo_error text NOT NULL DEFAULT 'error',
  mensaje text NOT NULL,
  traza_pila text,
  metadatos jsonb,
  estado text NOT NULL DEFAULT 'nuevo',
  version_app text,
  plataforma text,
  creado_en text NOT NULL
);

CREATE TABLE eventos_analitica (
  id text PRIMARY KEY,
  nombre_evento text NOT NULL,
  id_usuario uuid REFERENCES perfiles (id),
  rol text,
  marca_tiempo text NOT NULL,
  metadatos text
);

CREATE TABLE ubicacion_en_vivo (
  id_trabajo text PRIMARY KEY REFERENCES trabajos (id) ON DELETE CASCADE,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario) ON DELETE CASCADE,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  precision_metros double precision,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app_config (
  clave text PRIMARY KEY,
  valor text NOT NULL,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE banderas_funcionalidad (
  id text PRIMARY KEY,
  nombre_bandera text NOT NULL,
  habilitada integer NOT NULL DEFAULT 0,
  version_app text,
  rol text,
  id_usuario uuid REFERENCES perfiles (id),
  creado_en text NOT NULL,
  actualizado_en text NOT NULL
);

CREATE TABLE ranking_config (
  id text PRIMARY KEY DEFAULT 'default',
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
  pesos_senal jsonb NOT NULL DEFAULT '{}'::jsonb,
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ranking_config_unica CHECK (id = 'default')
);

CREATE TABLE senales_resena (
  id text PRIMARY KEY,
  id_calificacion text NOT NULL REFERENCES calificaciones (id) ON DELETE CASCADE,
  tipo_senal text NOT NULL,
  puntaje numeric NOT NULL,
  detalle text,
  estado text NOT NULL DEFAULT 'pendiente',
  resuelto_por uuid REFERENCES perfiles (id),
  resuelto_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_calificacion, tipo_senal)
);

CREATE TABLE ranking_aprendizaje (
  id text PRIMARY KEY,
  motivo text NOT NULL,
  pesos_antes jsonb NOT NULL,
  pesos_despues jsonb NOT NULL,
  metricas jsonb,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE eventos_ranking (
  id text PRIMARY KEY,
  id_trabajador uuid NOT NULL REFERENCES trabajadores (id_usuario),
  id_trabajo text REFERENCES trabajos (id),
  tipo_evento text NOT NULL,
  factores jsonb NOT NULL DEFAULT '{}'::jsonb,
  creado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE trabajos
  ADD CONSTRAINT trabajos_cotizacion_seleccionada_fkey
  FOREIGN KEY (id_cotizacion_seleccionada) REFERENCES propuestas_cotizacion (id);

ALTER TABLE pagos
  ADD CONSTRAINT pagos_orden_cambio_fkey
  FOREIGN KEY (id_orden_cambio) REFERENCES ordenes_cambio (id);

ALTER TABLE ordenes_cambio
  ADD CONSTRAINT ordenes_cambio_pago_fkey
  FOREIGN KEY (id_pago) REFERENCES pagos (id);

COMMENT ON TABLE perfiles IS 'Identidad de app = auth.users.id';
COMMENT ON COLUMN perfiles.reputacion_cliente IS 'Derivada: promedio de calificaciones_cliente.';
COMMENT ON TABLE trabajadores IS 'Ficha 1:1. Oferta 4NF en tablas hijas; JSON solo escritura. Agenda en trabajador_horarios.';
COMMENT ON COLUMN trabajadores.niveles_precio IS 'Escritura. Forma 4NF: trabajador_precios.';
COMMENT ON COLUMN trabajadores.servicios_personalizados IS 'Escritura. Forma 4NF: trabajador_servicios_extra.';
COMMENT ON COLUMN trabajadores.score_listado IS 'Orden del marketplace; no es la nota pública.';
COMMENT ON COLUMN trabajadores.es_elite IS 'GENERATED: calificacion ≥ 4.7 y trabajos_completados ≥ 5.';
COMMENT ON COLUMN trabajadores.radio_urbano_km IS 'Km alrededor de la base sin recargo de traslado.';
COMMENT ON TABLE trabajador_horarios IS 'Plantilla semanal {dia:1-7 ISO, hora:HH:MM}. Solo el profesional. El cliente usa horarios_libres_profesional.';
COMMENT ON TABLE paises IS 'País operativo. Hoy solo CL.';
COMMENT ON TABLE regiones IS 'Región administrativa chilena.';
COMMENT ON TABLE comunas IS 'Comuna de cobertura. PK slug = trabajos.id_comuna y trabajadores.id_comuna.';
COMMENT ON TABLE ubicacion_en_vivo IS 'GPS en vivo del pedido. 1:1 con trabajos.';
COMMENT ON TABLE app_config IS 'Interruptores de producto (demo_modo, admin_requiere_aal2).';
COMMENT ON COLUMN trabajadores.calificacion IS 'Derivada: promedio ponderado de calificaciones (trigger).';
COMMENT ON COLUMN trabajos.estado_pago IS 'Derivada: estado del pago principal (trigger).';
COMMENT ON TABLE trabajador_precios IS '4NF: un monto por código de tarifa. FK lógica a trabajadores.';
COMMENT ON TABLE trabajador_servicios_extra IS '4NF: extras tarifados (fijo | por_m2). FK lógica a trabajadores.';
COMMENT ON TABLE trabajos IS 'Pedido y ciclo de vida. Un minuto activo por profesional (índice parcial).';
COMMENT ON TABLE pagos IS 'Escrow Webpay/Oneclick; un principal vivo por trabajo. token_tbk no sale al cliente.';
COMMENT ON COLUMN pagos.origen_retorno IS 'Origen del navegador contrastado con la allowlist para webpay-commit.';
COMMENT ON COLUMN pagos.alta_jti IS 'Ticket de un solo uso para que el invitado cree su contraseña.';
COMMENT ON TABLE liquidaciones IS 'Comprobante de pago al profesional. Un pago → una liquidación.';
COMMENT ON COLUMN liquidaciones.id_trabajador IS 'text en la BD viva; no FK a trabajadores.id_usuario (uuid)';
COMMENT ON TABLE metodos_pago_oneclick IS 'Tarjeta inscrita Oneclick; PK text = auth.uid. Solo service_role.';
COMMENT ON TABLE trabajador_servicios IS 'N:M por slug categoria, no por servicios.id';
COMMENT ON TABLE cancelaciones_trabajo IS 'Como máximo una cancelación por trabajo (UNIQUE id_trabajo).';
COMMENT ON TABLE calificaciones IS 'Fuente de trabajadores.calificacion (trigger refrescar_calificacion_trabajador).';
COMMENT ON TABLE calificaciones_cliente IS 'Doble valoración: el profesional nota al cliente. 1:1 con el trabajo.';
COMMENT ON COLUMN fotos_trabajo.imagen_webp IS 'Evidencia fotográfica en WebP dentro de la fila.';
COMMENT ON TABLE ranking_config IS 'Una fila default. Pesos del listado marketplace.';
COMMENT ON TABLE senales_resena IS 'Cola de reseñas dudosas. Falso positivo baja el peso de la señal.';

COMMIT;
