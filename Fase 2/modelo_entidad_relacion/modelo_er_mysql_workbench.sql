-- MyWorksApp — modelo entidad-relación (MySQL 8 / MySQL Workbench)
-- Generado desde la BD viva wxqrfcqifkfgawrnqmnj (migración 20261116044049).
-- Solo estructura (tablas, PK, UNIQUE, FK). Sin RLS, funciones ni datos.
-- Para el diagrama: MySQL Workbench > File > Import > Reverse Engineer MySQL Create Script.

CREATE DATABASE IF NOT EXISTS myworksapp;
USE myworksapp;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `acciones_pendientes` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `tipo_accion` VARCHAR(255) NOT NULL,
  `tipo_entidad` VARCHAR(255) NOT NULL,
  `id_entidad` VARCHAR(255),
  `datos` TEXT NOT NULL,
  `estado` VARCHAR(255) NOT NULL,
  `conteo_reintentos` INT,
  `mensaje_error` TEXT,
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `acuerdos_trabajo` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `tipo` VARCHAR(255) NOT NULL,
  `propuesto_por` CHAR(36) NOT NULL,
  `acepta_cliente` TINYINT(1),
  `acepta_trabajador` TINYINT(1),
  `estado` VARCHAR(255) NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  `aplicado_en` DATETIME(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `app_config` (
  `clave` VARCHAR(255) NOT NULL,
  `valor` TEXT NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `banderas_funcionalidad` (
  `id` VARCHAR(255) NOT NULL,
  `nombre_bandera` VARCHAR(255) NOT NULL,
  `habilitada` INT NOT NULL,
  `version_app` VARCHAR(255),
  `rol` VARCHAR(255),
  `id_usuario` CHAR(36),
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bloqueos_pin_inicio` (
  `id_trabajo` VARCHAR(255) NOT NULL,
  `fallos` INT NOT NULL,
  `bloqueado_hasta` DATETIME(6),
  `pin_ok_hasta` DATETIME(6),
  `pin_ok_usuario` CHAR(36),
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id_trabajo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bloqueos_usuario` (
  `id` VARCHAR(255) NOT NULL,
  `id_bloqueador` CHAR(36) NOT NULL,
  `id_bloqueado` CHAR(36) NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bloqueos_usuario_1` (`id_bloqueador`, `id_bloqueado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `calificaciones` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36),
  `puntaje` INT NOT NULL,
  `comentario` TEXT,
  `creado_en` VARCHAR(255) NOT NULL,
  `peso_confianza` DECIMAL(4,3) NOT NULL,
  `estado_revision` VARCHAR(255) NOT NULL,
  `motivo_revision` VARCHAR(255),
  `direccion` VARCHAR(255) NOT NULL,
  `id_calificado` CHAR(36) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_calificaciones_1` (`id_trabajo`, `direccion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `calificaciones_cliente` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_cliente` CHAR(36) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `puntaje` SMALLINT NOT NULL,
  `comentario` TEXT,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_calificaciones_cliente_1` (`id_trabajo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cancelaciones_trabajo` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `cancelado_por` CHAR(36) NOT NULL,
  `motivo` VARCHAR(255) NOT NULL,
  `cancelado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cancelaciones_trabajo_1` (`id_trabajo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `codigos_restablecimiento` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `codigo` VARCHAR(255) NOT NULL,
  `correo` VARCHAR(255) NOT NULL,
  `expira_en` VARCHAR(255) NOT NULL,
  `usado` INT,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `comunas` (
  `id` VARCHAR(255) NOT NULL,
  `id_region` VARCHAR(255) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `latitud` DOUBLE,
  `longitud` DOUBLE,
  `activa` INT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `configuraciones_servicio` (
  `id` VARCHAR(255) NOT NULL,
  `id_servicio` VARCHAR(255) NOT NULL,
  `esquema_config` TEXT NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_configuraciones_servicio_1` (`id_servicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `consentimientos_usuario` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `version_consentimiento` VARCHAR(255) NOT NULL,
  `aceptado` INT NOT NULL,
  `aceptado_en` VARCHAR(255) NOT NULL,
  `direccion_ip` VARCHAR(255),
  `agente_usuario` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cuentas_bancarias` (
  `id_usuario` CHAR(36) NOT NULL,
  `banco` VARCHAR(255) NOT NULL,
  `tipo_cuenta` VARCHAR(255) NOT NULL,
  `numero_cuenta` VARCHAR(255) NOT NULL,
  `rut_titular` VARCHAR(255) NOT NULL,
  `nombre_titular` VARCHAR(255) NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dispositivos_push` (
  `token` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `plataforma` VARCHAR(255) NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `disputa_mensajes` (
  `id` VARCHAR(255) NOT NULL,
  `id_disputa` VARCHAR(255) NOT NULL,
  `id_autor` CHAR(36),
  `cuerpo` TEXT NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `disputas` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `abierta_por` CHAR(36) NOT NULL,
  `motivo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `estado` VARCHAR(255) NOT NULL,
  `resolucion` TEXT,
  `resuelta_por` CHAR(36),
  `resuelta_en` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  `origen` VARCHAR(255) NOT NULL,
  `decision_sugerida` VARCHAR(255),
  `motivo_regla` VARCHAR(255),
  `vence_en` DATETIME(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `eventos_abuso` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `tipo_abuso` VARCHAR(255) NOT NULL,
  `conteo` INT NOT NULL,
  `detectado_en` VARCHAR(255) NOT NULL,
  `accion_tomada` VARCHAR(255),
  `accion_tomada_en` VARCHAR(255),
  `resuelto` INT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `eventos_analitica` (
  `id` VARCHAR(255) NOT NULL,
  `nombre_evento` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36),
  `rol` VARCHAR(255),
  `marca_tiempo` VARCHAR(255) NOT NULL,
  `metadatos` TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `eventos_ranking` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `id_trabajo` VARCHAR(255),
  `tipo_evento` VARCHAR(255) NOT NULL,
  `factores` JSON NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fotos_trabajo` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `ruta_foto` VARCHAR(255) NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  `tipo_medio` VARCHAR(255) NOT NULL,
  `imagen_webp` LONGBLOB,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `impulsos` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `tipo_impulso` VARCHAR(255) NOT NULL,
  `fecha_inicio` VARCHAR(255) NOT NULL,
  `fecha_fin` VARCHAR(255) NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `intentos_pin_inicio` (
  `id` BIGINT NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36),
  `resultado` VARCHAR(255) NOT NULL,
  `intentos_restantes` INT NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `liquidaciones` (
  `id` VARCHAR(255) NOT NULL,
  `id_pago` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_trabajador` VARCHAR(255),
  `monto_clp` DECIMAL(14,4) NOT NULL,
  `proveedor` VARCHAR(255) NOT NULL,
  `referencia_transferencia` VARCHAR(255) NOT NULL,
  `notas` TEXT,
  `id_operador` VARCHAR(255) NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  `estado_transferencia` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_liquidaciones_1` (`id_pago`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mensajes` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_remitente` CHAR(36) NOT NULL,
  `id_destinatario` CHAR(36) NOT NULL,
  `contenido` TEXT NOT NULL,
  `tipo` VARCHAR(255) NOT NULL,
  `ruta_imagen` VARCHAR(255),
  `leido` INT NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `metodos_pago_oneclick` (
  `id_usuario` CHAR(36) NOT NULL,
  `username` VARCHAR(255) NOT NULL,
  `tbk_user` VARCHAR(255),
  `tipo_tarjeta` VARCHAR(255),
  `ultimos4` VARCHAR(255),
  `estado` VARCHAR(255) NOT NULL,
  `token_inscripcion` VARCHAR(255),
  `id_trabajo_pendiente` VARCHAR(255),
  `creado_en` DATETIME(6) NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  `url_inscripcion` TEXT,
  `ticket_handoff` VARCHAR(255),
  PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `notificaciones` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `tipo` VARCHAR(255) NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `cuerpo` TEXT NOT NULL,
  `id_relacionado` VARCHAR(255),
  `leido` INT NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ordenes_cambio` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `tipo` VARCHAR(255) NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT NOT NULL,
  `monto_clp` INT NOT NULL,
  `estado` VARCHAR(255) NOT NULL,
  `id_pago` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `respondido_en` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pagos` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_orden_cambio` VARCHAR(255),
  `tipo_pago` VARCHAR(255) NOT NULL,
  `monto` DECIMAL(12,0) NOT NULL,
  `moneda` VARCHAR(255) NOT NULL,
  `estado` VARCHAR(255) NOT NULL,
  `metodo_pago` VARCHAR(255),
  `id_transaccion` VARCHAR(255),
  `autorizado_en` VARCHAR(255),
  `liberado_en` VARCHAR(255),
  `reembolsado_en` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  `ambiente` VARCHAR(255),
  `token_tbk` VARCHAR(255),
  `url_tbk` TEXT,
  `buy_order` VARCHAR(255),
  `handoff_consumido_en` DATETIME(6),
  `reembolso_solicitado_en` DATETIME(6),
  `orden_detalle_oneclick` TEXT,
  `cobro_reclamado_en` DATETIME(6),
  `origen_retorno` VARCHAR(255),
  `alta_nonce_hash` VARCHAR(255),
  `alta_jti` VARCHAR(255),
  `alta_consumido_en` DATETIME(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `paises` (
  `id` VARCHAR(255) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `iso2` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_paises_1` (`iso2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `perfiles` (
  `id` CHAR(36) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `correo` VARCHAR(255),
  `rol` VARCHAR(255) NOT NULL,
  `estado_cuenta` VARCHAR(255) NOT NULL,
  `ruta_foto_perfil` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `reputacion_cliente` DECIMAL(3,2),
  `calificaciones_cliente` INT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pines_inicio_trabajo` (
  `id_trabajo` VARCHAR(255) NOT NULL,
  `pin` VARCHAR(255) NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id_trabajo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `portafolio_trabajador` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `ruta_foto` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `creado_en` VARCHAR(255) NOT NULL,
  `tipo_medio` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `propuestas_cotizacion` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `monto_total_clp` INT NOT NULL,
  `descripcion` TEXT NOT NULL,
  `validez_hasta` VARCHAR(255),
  `desglose` TEXT,
  `estado` VARCHAR(255) NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ranking_aprendizaje` (
  `id` VARCHAR(255) NOT NULL,
  `motivo` VARCHAR(255) NOT NULL,
  `pesos_antes` JSON NOT NULL,
  `pesos_despues` JSON NOT NULL,
  `metricas` JSON,
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ranking_config` (
  `id` VARCHAR(255) NOT NULL,
  `peso_calificacion` DECIMAL(14,4) NOT NULL,
  `peso_completados` DECIMAL(14,4) NOT NULL,
  `peso_rechazos` DECIMAL(14,4) NOT NULL,
  `peso_verificacion` DECIMAL(14,4) NOT NULL,
  `peso_impulso` DECIMAL(14,4) NOT NULL,
  `peso_recencia` DECIMAL(14,4) NOT NULL,
  `peso_confianza` DECIMAL(14,4) NOT NULL,
  `prior_bayes` DECIMAL(14,4) NOT NULL,
  `n_bayes` DECIMAL(14,4) NOT NULL,
  `umbral_revision` DECIMAL(14,4) NOT NULL,
  `umbral_auto_excluir` DECIMAL(14,4) NOT NULL,
  `aprendizaje_activo` INT NOT NULL,
  `tasa_aprendizaje` DECIMAL(14,4) NOT NULL,
  `pesos_senal` JSON NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `regiones` (
  `id` VARCHAR(255) NOT NULL,
  `id_pais` VARCHAR(255) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `codigo_oficial` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `registros_error_app` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36),
  `tipo_error` VARCHAR(255) NOT NULL,
  `mensaje` TEXT NOT NULL,
  `traza_pila` TEXT,
  `metadatos` JSON,
  `estado` VARCHAR(255) NOT NULL,
  `version_app` VARCHAR(255),
  `plataforma` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `reportes` (
  `id` VARCHAR(255) NOT NULL,
  `id_reportante` CHAR(36) NOT NULL,
  `id_usuario_reportado` CHAR(36) NOT NULL,
  `motivo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `estado` VARCHAR(255) NOT NULL,
  `creado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `reprogramaciones_trabajo` (
  `id` CHAR(36) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `propuesta_por` CHAR(36) NOT NULL,
  `rol_proponente` VARCHAR(255) NOT NULL,
  `fecha_anterior` DATETIME(6) NOT NULL,
  `fecha_propuesta` DATETIME(6) NOT NULL,
  `motivo` VARCHAR(255),
  `estado` VARCHAR(255) NOT NULL,
  `respondida_por` CHAR(36),
  `respondida_en` DATETIME(6),
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `senales_resena` (
  `id` VARCHAR(255) NOT NULL,
  `id_calificacion` VARCHAR(255) NOT NULL,
  `tipo_senal` VARCHAR(255) NOT NULL,
  `puntaje` DECIMAL(14,4) NOT NULL,
  `detalle` TEXT,
  `estado` VARCHAR(255) NOT NULL,
  `resuelto_por` CHAR(36),
  `resuelto_en` DATETIME(6),
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_senales_resena_1` (`id_calificacion`, `tipo_senal`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `servicios` (
  `id` VARCHAR(255) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `categoria` VARCHAR(255) NOT NULL,
  `activo` INT NOT NULL,
  `requiere_certificacion` INT NOT NULL,
  `modelo_precio` VARCHAR(255) NOT NULL,
  `aviso_legal` TEXT,
  `creado_en` VARCHAR(255),
  `actualizado_en` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `suscripciones` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `tipo_plan` VARCHAR(255) NOT NULL,
  `estado` VARCHAR(255) NOT NULL,
  `fecha_inicio` VARCHAR(255) NOT NULL,
  `fecha_fin` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tickets_soporte` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255),
  `nombre_cliente` VARCHAR(255) NOT NULL,
  `nombre_trabajador` VARCHAR(255) NOT NULL,
  `asunto` VARCHAR(255) NOT NULL,
  `monto_escrow` INT NOT NULL,
  `estado` VARCHAR(255),
  `creado_en` DATETIME(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajador_horarios` (
  `id_usuario` CHAR(36) NOT NULL,
  `horarios` JSON NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  `id` CHAR(36) NOT NULL,
  `dia_semana` SMALLINT,
  `hora_inicio` TIME,
  `hora_fin` TIME,
  `activo` TINYINT(1),
  `creado_en` DATETIME(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_trabajador_horarios_1` (`id_usuario`, `dia_semana`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajador_precios` (
  `id_usuario` CHAR(36) NOT NULL,
  `codigo` VARCHAR(255) NOT NULL,
  `monto_clp` DECIMAL(12,0) NOT NULL,
  PRIMARY KEY (`id_usuario`, `codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajador_servicios` (
  `id_trabajador` CHAR(36) NOT NULL,
  `categoria_servicio` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id_trabajador`, `categoria_servicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajador_servicios_extra` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `subtitulo` VARCHAR(255) NOT NULL,
  `monto_clp` DECIMAL(12,0) NOT NULL,
  `unidad` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id_usuario`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajadores` (
  `id_usuario` CHAR(36) NOT NULL,
  `profesion` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `calificacion` DECIMAL(4,2) NOT NULL,
  `disponible` INT NOT NULL,
  `tarifa_visita` DECIMAL(12,0) NOT NULL,
  `categoria_servicio` VARCHAR(255) NOT NULL,
  `niveles_precio` JSON NOT NULL,
  `conteo_rechazos` INT NOT NULL,
  `servicios_personalizados` JSON NOT NULL,
  `precios_configurados` INT NOT NULL,
  `zona_trabajo` VARCHAR(255),
  `estado_verificacion` VARCHAR(255) NOT NULL,
  `nota_verificacion` TEXT,
  `latitud_base` DOUBLE,
  `longitud_base` DOUBLE,
  `radio_servicio_km` DECIMAL(14,4) NOT NULL,
  `origen_base` VARCHAR(255),
  `score_listado` DECIMAL(8,4) NOT NULL,
  `prioridad_manual` INT NOT NULL,
  `score_desglose` JSON NOT NULL,
  `ranking_actualizado_en` DATETIME(6),
  `radio_urbano_km` DECIMAL(5,2) NOT NULL,
  `tarifa_fuera_radio_clp` INT NOT NULL,
  `trabajos_completados` INT NOT NULL,
  `es_elite` TINYINT(1),
  `id_comuna` VARCHAR(255),
  `id_region` VARCHAR(255),
  `usa_horario` TINYINT(1) NOT NULL,
  `pausa_por_trabajo` TINYINT(1) NOT NULL,
  PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajos` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `id_trabajador` CHAR(36),
  `id_servicio` VARCHAR(255),
  `estado` VARCHAR(255) NOT NULL,
  `direccion` VARCHAR(255) NOT NULL,
  `latitud` DOUBLE,
  `longitud` DOUBLE,
  `descripcion` TEXT,
  `fecha_programada` VARCHAR(255),
  `metadatos_servicio` TEXT,
  `modalidad_cobro` VARCHAR(255),
  `estado_pago` VARCHAR(255),
  `id_comuna` VARCHAR(255),
  `instantanea_precio` TEXT,
  `id_sku_servicio` VARCHAR(255),
  `horas_bloque` INT,
  `id_cotizacion_seleccionada` VARCHAR(255),
  `creado_en` VARCHAR(255) NOT NULL,
  `actualizado_en` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ubicacion_en_vivo` (
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `latitud` DOUBLE NOT NULL,
  `longitud` DOUBLE NOT NULL,
  `precision_metros` DOUBLE,
  `actualizado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id_trabajo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `verificacion_eventos` (
  `id` CHAR(36) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `estado` VARCHAR(255) NOT NULL,
  `nota` TEXT,
  `id_actor` CHAR(36),
  `creado_en` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `acciones_pendientes` ADD CONSTRAINT `pending_actions_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `acuerdos_trabajo` ADD CONSTRAINT `acuerdos_trabajo_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `acuerdos_trabajo` ADD CONSTRAINT `acuerdos_trabajo_propuesto_por_fkey` FOREIGN KEY (`propuesto_por`) REFERENCES `perfiles` (`id`) ON DELETE NO ACTION;
ALTER TABLE `banderas_funcionalidad` ADD CONSTRAINT `banderas_funcionalidad_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `bloqueos_pin_inicio` ADD CONSTRAINT `bloqueos_pin_inicio_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `bloqueos_usuario` ADD CONSTRAINT `bloqueos_usuario_id_bloqueado_fkey` FOREIGN KEY (`id_bloqueado`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `bloqueos_usuario` ADD CONSTRAINT `bloqueos_usuario_id_bloqueador_fkey` FOREIGN KEY (`id_bloqueador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones` ADD CONSTRAINT `calificaciones_id_calificado_fkey` FOREIGN KEY (`id_calificado`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones` ADD CONSTRAINT `calificaciones_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `calificaciones` ADD CONSTRAINT `ratings_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones_cliente` ADD CONSTRAINT `calificaciones_cliente_id_cliente_fkey` FOREIGN KEY (`id_cliente`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones_cliente` ADD CONSTRAINT `calificaciones_cliente_id_trabajador_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones_cliente` ADD CONSTRAINT `calificaciones_cliente_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `cancelaciones_trabajo` ADD CONSTRAINT `cancelaciones_trabajo_cancelado_por_fkey` FOREIGN KEY (`cancelado_por`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `cancelaciones_trabajo` ADD CONSTRAINT `job_cancellations_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `codigos_restablecimiento` ADD CONSTRAINT `codigos_restablecimiento_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `comunas` ADD CONSTRAINT `comunas_id_region_fkey` FOREIGN KEY (`id_region`) REFERENCES `regiones` (`id`) ON DELETE NO ACTION;
ALTER TABLE `configuraciones_servicio` ADD CONSTRAINT `service_configs_serviceId_fkey` FOREIGN KEY (`id_servicio`) REFERENCES `servicios` (`id`) ON DELETE CASCADE;
ALTER TABLE `consentimientos_usuario` ADD CONSTRAINT `user_consents_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `cuentas_bancarias` ADD CONSTRAINT `cuentas_bancarias_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `dispositivos_push` ADD CONSTRAINT `dispositivos_push_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `disputa_mensajes` ADD CONSTRAINT `disputa_mensajes_id_autor_fkey` FOREIGN KEY (`id_autor`) REFERENCES `perfiles` (`id`) ON DELETE NO ACTION;
ALTER TABLE `disputa_mensajes` ADD CONSTRAINT `disputa_mensajes_id_disputa_fkey` FOREIGN KEY (`id_disputa`) REFERENCES `disputas` (`id`) ON DELETE CASCADE;
ALTER TABLE `disputas` ADD CONSTRAINT `disputas_abierta_por_fkey` FOREIGN KEY (`abierta_por`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `disputas` ADD CONSTRAINT `disputas_resuelta_por_fkey` FOREIGN KEY (`resuelta_por`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `disputas` ADD CONSTRAINT `disputes_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `eventos_abuso` ADD CONSTRAINT `abuse_events_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `eventos_analitica` ADD CONSTRAINT `eventos_analitica_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `eventos_ranking` ADD CONSTRAINT `eventos_ranking_id_trabajador_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `eventos_ranking` ADD CONSTRAINT `eventos_ranking_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE SET NULL;
ALTER TABLE `fotos_trabajo` ADD CONSTRAINT `job_photos_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `impulsos` ADD CONSTRAINT `boosts_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `intentos_pin_inicio` ADD CONSTRAINT `intentos_pin_inicio_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `intentos_pin_inicio` ADD CONSTRAINT `intentos_pin_inicio_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `liquidaciones` ADD CONSTRAINT `liquidaciones_id_pago_fkey` FOREIGN KEY (`id_pago`) REFERENCES `pagos` (`id`) ON DELETE NO ACTION;
ALTER TABLE `liquidaciones` ADD CONSTRAINT `liquidaciones_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE NO ACTION;
ALTER TABLE `mensajes` ADD CONSTRAINT `mensajes_id_destinatario_fkey` FOREIGN KEY (`id_destinatario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `mensajes` ADD CONSTRAINT `mensajes_id_remitente_fkey` FOREIGN KEY (`id_remitente`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `mensajes` ADD CONSTRAINT `messages_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `metodos_pago_oneclick` ADD CONSTRAINT `metodos_pago_oneclick_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `notificaciones` ADD CONSTRAINT `notifications_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `change_orders_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `ordenes_cambio_id_pago_fkey` FOREIGN KEY (`id_pago`) REFERENCES `pagos` (`id`) ON DELETE SET NULL;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `ordenes_cambio_id_trabajador_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `pagos` ADD CONSTRAINT `pagos_id_orden_cambio_fkey` FOREIGN KEY (`id_orden_cambio`) REFERENCES `ordenes_cambio` (`id`) ON DELETE SET NULL;
ALTER TABLE `pagos` ADD CONSTRAINT `payments_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `pines_inicio_trabajo` ADD CONSTRAINT `pines_inicio_trabajo_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `portafolio_trabajador` ADD CONSTRAINT `worker_portfolio_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `propuestas_cotizacion` ADD CONSTRAINT `quote_proposals_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `propuestas_cotizacion` ADD CONSTRAINT `quote_proposals_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `regiones` ADD CONSTRAINT `regiones_id_pais_fkey` FOREIGN KEY (`id_pais`) REFERENCES `paises` (`id`) ON DELETE NO ACTION;
ALTER TABLE `registros_error_app` ADD CONSTRAINT `app_error_logs_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE NO ACTION;
ALTER TABLE `reportes` ADD CONSTRAINT `reportes_id_reportante_fkey` FOREIGN KEY (`id_reportante`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `reportes` ADD CONSTRAINT `reportes_id_usuario_reportado_fkey` FOREIGN KEY (`id_usuario_reportado`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `reprogramaciones_trabajo` ADD CONSTRAINT `reprogramaciones_propuesta_por_fkey` FOREIGN KEY (`propuesta_por`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `reprogramaciones_trabajo` ADD CONSTRAINT `reprogramaciones_respondida_por_fkey` FOREIGN KEY (`respondida_por`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `reprogramaciones_trabajo` ADD CONSTRAINT `reprogramaciones_trabajo_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `senales_resena` ADD CONSTRAINT `senales_resena_id_calificacion_fkey` FOREIGN KEY (`id_calificacion`) REFERENCES `calificaciones` (`id`) ON DELETE CASCADE;
ALTER TABLE `senales_resena` ADD CONSTRAINT `senales_resena_resuelto_por_fkey` FOREIGN KEY (`resuelto_por`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `suscripciones` ADD CONSTRAINT `subscriptions_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `tickets_soporte` ADD CONSTRAINT `tickets_soporte_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajador_horarios` ADD CONSTRAINT `trabajador_horarios_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `trabajadores` (`id_usuario`) ON DELETE CASCADE;
ALTER TABLE `trabajador_precios` ADD CONSTRAINT `trabajador_precios_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `trabajadores` (`id_usuario`) ON DELETE CASCADE;
ALTER TABLE `trabajador_servicios` ADD CONSTRAINT `worker_services_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `trabajador_servicios_extra` ADD CONSTRAINT `trabajador_servicios_extra_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `trabajadores` (`id_usuario`) ON DELETE CASCADE;
ALTER TABLE `trabajadores` ADD CONSTRAINT `trabajadores_id_comuna_fkey` FOREIGN KEY (`id_comuna`) REFERENCES `comunas` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajadores` ADD CONSTRAINT `trabajadores_id_region_fkey` FOREIGN KEY (`id_region`) REFERENCES `regiones` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajadores` ADD CONSTRAINT `trabajadores_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `trabajos` ADD CONSTRAINT `jobs_serviceId_fkey` FOREIGN KEY (`id_servicio`) REFERENCES `servicios` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajos` ADD CONSTRAINT `jobs_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `trabajos` ADD CONSTRAINT `jobs_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajos` ADD CONSTRAINT `trabajos_id_comuna_fkey` FOREIGN KEY (`id_comuna`) REFERENCES `comunas` (`id`) ON DELETE SET NULL;
ALTER TABLE `trabajos` ADD CONSTRAINT `trabajos_id_cotizacion_seleccionada_fkey` FOREIGN KEY (`id_cotizacion_seleccionada`) REFERENCES `propuestas_cotizacion` (`id`) ON DELETE SET NULL;
ALTER TABLE `ubicacion_en_vivo` ADD CONSTRAINT `ubicacion_en_vivo_id_trabajo_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `ubicacion_en_vivo` ADD CONSTRAINT `ubicacion_en_vivo_trabajador_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `trabajadores` (`id_usuario`) ON DELETE CASCADE;
ALTER TABLE `verificacion_eventos` ADD CONSTRAINT `verificacion_eventos_id_actor_fkey` FOREIGN KEY (`id_actor`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `verificacion_eventos` ADD CONSTRAINT `verificacion_eventos_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;

-- Relaciones lógicas (sin FOREIGN KEY física en la BD real):
--   liquidaciones(id_trabajador) -> perfiles(id): profesional liquidado; text que guarda el uuid del perfil
--   liquidaciones(id_operador) -> perfiles(id): administrador que confirmó la transferencia; text con uuid o 'sistema'
--   metodos_pago_oneclick(id_trabajo_pendiente) -> trabajos(id): trabajo que espera la inscripción Oneclick para cobrarse
--   bloqueos_pin_inicio(pin_ok_usuario) -> perfiles(id): usuario que validó el PIN (ventana pin_ok_hasta)
--   trabajos(id_trabajador, id_sku_servicio) -> trabajador_precios(id_usuario, codigo): SKU de precio elegido; también admite 'tier_<n>', por eso no es FK
--   trabajador_servicios(categoria_servicio) -> servicios(categoria): categoría ofrecida; servicios.categoria no es única

SET FOREIGN_KEY_CHECKS = 1;
