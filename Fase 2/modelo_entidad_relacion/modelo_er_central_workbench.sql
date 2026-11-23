-- MyWorksApp — modelo central para MySQL Workbench (MySQL 8 / InnoDB)
-- Catálogo vivo de public al 23-nov-2026 01:11 (America/Santiago),
-- base wxqrfcqifkfgawrnqmnj: 76 tablas, RLS en las 76, 94 claves foráneas.
-- Última migración aplicada: 20261123040924.
-- Archivo en el repositorio: 20261124050000_esquema_bcnf.sql.
-- Este archivo NO es el catálogo de 76 tablas. Es el modelo que se explica:
-- perfil, trabajador, dirección, tarjeta, trabajo, pago, orden de cambio,
-- fotos_trabajo, mensaje, calificación, disputa y auditoría.
-- El script histórico de 57 tablas sigue en modelo_er_mysql_workbench.sql.
-- El mapa de 60 tablas del informe es el anexo histórico.
-- Columnas leídas del catálogo (information_schema / pg_catalog), sin inventar.
-- Tipos: uuid → CHAR(36), text de clave o índice → VARCHAR(255)
-- (InnoDB no indexa TEXT sin prefijo y una FK no puede usar ese prefijo),
-- el resto del text → TEXT, numeric(p,s) → DECIMAL(p,s),
-- boolean → TINYINT(1), timestamptz → DATETIME(6), jsonb → JSON,
-- bytea y vector(384) → BLOB (Workbench no tiene pgvector).
-- Para el diagrama: File > Import > Reverse Engineer MySQL Create Script.
--
-- Fuera de este modelo, y por eso sin FOREIGN KEY aquí:
--   perfiles.id → auth.users(id)
--   trabajadores.id_comuna → comunas(id)
--   trabajos.id_servicio → servicios(id)
--   trabajos.id_comuna → comunas(id)
--   trabajos.id_cotizacion_seleccionada → propuestas_cotizacion(id)
-- mensajes.id_destinatario lo escribe solo el trigger mensajes_fijar_destinatario
-- en PostgreSQL. En este modelo queda como columna normal: Workbench no ejecuta
-- ese trigger, porque lee la tabla trabajos.
-- trabajadores.calificacion y trabajos_completados los iguala
-- trabajadores_z_cifras_desde_stats. score_listado solo lo cambia el recálculo.
-- es_elite es generada en la base viva y también en este script.

CREATE DATABASE IF NOT EXISTS myworksapp_central;
USE myworksapp_central;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `perfiles` (
  `id` CHAR(36) NOT NULL,
  `nombre` TEXT NOT NULL,
  `correo` TEXT,
  `rol` TEXT NOT NULL,
  `estado_cuenta` TEXT NOT NULL,
  `ruta_foto_perfil` TEXT,
  `creado_en` TEXT NOT NULL,
  `reputacion_cliente` DECIMAL(3,2),
  `calificaciones_cliente` INT NOT NULL,
  `telefono` TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajadores` (
  `id_usuario` CHAR(36) NOT NULL,
  `profesion` TEXT NOT NULL,
  `descripcion` TEXT,
  `calificacion` DECIMAL(4,2) NOT NULL,
  `disponible` INT NOT NULL,
  `tarifa_visita` DECIMAL(12,0) NOT NULL,
  `conteo_rechazos` INT NOT NULL,
  `precios_configurados` INT NOT NULL,
  `zona_trabajo` TEXT,
  `estado_verificacion` TEXT NOT NULL,
  `nota_verificacion` TEXT,
  `latitud_base` DOUBLE,
  `longitud_base` DOUBLE,
  -- PostgreSQL: numeric sin precisión declarada.
  `radio_servicio_km` DECIMAL(12,4) NOT NULL,
  `origen_base` TEXT,
  `score_listado` DECIMAL(8,4) NOT NULL,
  `prioridad_manual` INT NOT NULL,
  `score_desglose` JSON NOT NULL,
  `ranking_actualizado_en` DATETIME(6),
  `radio_urbano_km` DECIMAL(5,2) NOT NULL,
  `tarifa_fuera_radio_clp` INT NOT NULL,
  `trabajos_completados` INT NOT NULL,
  `es_elite` TINYINT(1) GENERATED ALWAYS AS ((COALESCE(`calificacion`, 0) >= 4.7) AND (`trabajos_completados` >= 5)) VIRTUAL,
  `id_comuna` TEXT,
  `usa_horario` TINYINT(1) NOT NULL,
  `pausa_por_trabajo` TINYINT(1) NOT NULL,
  `es_demo` TINYINT(1) NOT NULL,
  -- PostgreSQL: vector(384).
  `embedding` BLOB,
  `embedding_origen` TEXT,
  `sugerencia_validacion` JSON,
  PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `direcciones_cliente` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `etiqueta` TEXT NOT NULL,
  `direccion` TEXT NOT NULL,
  `creado_en` TEXT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `metodos_pago_oneclick` (
  `id_usuario` CHAR(36) NOT NULL,
  `username` TEXT NOT NULL,
  `tbk_user` TEXT,
  `tipo_tarjeta` TEXT,
  `ultimos4` TEXT,
  `estado` TEXT NOT NULL,
  `token_inscripcion` TEXT,
  `id_trabajo_pendiente` TEXT,
  `creado_en` DATETIME(6) NOT NULL,
  `actualizado_en` DATETIME(6) NOT NULL,
  `url_inscripcion` TEXT,
  `ticket_handoff` TEXT,
  `tbk_user_prev` TEXT,
  `username_prev` TEXT,
  `tipo_tarjeta_prev` TEXT,
  `ultimos4_prev` TEXT,
  PRIMARY KEY (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `trabajos` (
  `id` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36) NOT NULL,
  `id_trabajador` CHAR(36),
  `id_servicio` TEXT,
  `estado` TEXT NOT NULL,
  `direccion` TEXT NOT NULL,
  `latitud` DOUBLE,
  `longitud` DOUBLE,
  `descripcion` TEXT,
  `fecha_programada` TEXT,
  `metadatos_servicio` TEXT,
  `modalidad_cobro` TEXT,
  `estado_pago` TEXT,
  `id_comuna` TEXT,
  `instantanea_precio` TEXT,
  `id_sku_servicio` TEXT,
  `horas_bloque` INT,
  `id_cotizacion_seleccionada` TEXT,
  `creado_en` TEXT NOT NULL,
  `actualizado_en` TEXT NOT NULL,
  -- PostgreSQL: vector(384).
  `embedding` BLOB,
  `embedding_origen` TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pagos` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_orden_cambio` VARCHAR(255),
  `tipo_pago` TEXT NOT NULL,
  `monto` DECIMAL(12,0) NOT NULL,
  `moneda` TEXT NOT NULL,
  `estado` TEXT NOT NULL,
  `metodo_pago` TEXT,
  `id_transaccion` TEXT,
  `autorizado_en` TEXT,
  `liberado_en` TEXT,
  `reembolsado_en` TEXT,
  `creado_en` TEXT NOT NULL,
  `actualizado_en` TEXT NOT NULL,
  `ambiente` TEXT,
  `token_tbk` TEXT,
  `url_tbk` TEXT,
  `buy_order` TEXT,
  `handoff_consumido_en` DATETIME(6),
  `reembolso_solicitado_en` DATETIME(6),
  `orden_detalle_oneclick` TEXT,
  `cobro_reclamado_en` DATETIME(6),
  `origen_retorno` TEXT,
  `alta_nonce_hash` TEXT,
  `alta_jti` TEXT,
  `alta_consumido_en` DATETIME(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ordenes_cambio` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_trabajador` CHAR(36) NOT NULL,
  `tipo` TEXT NOT NULL,
  `titulo` TEXT NOT NULL,
  `descripcion` TEXT NOT NULL,
  `monto_clp` INT NOT NULL,
  `estado` TEXT NOT NULL,
  `id_pago` VARCHAR(255),
  `creado_en` TEXT NOT NULL,
  `respondido_en` TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fotos_trabajo` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `ruta_foto` TEXT NOT NULL,
  `creado_en` TEXT NOT NULL,
  `tipo_medio` TEXT NOT NULL,
  -- PostgreSQL: bytea.
  `imagen_webp` BLOB,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mensajes` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_remitente` CHAR(36) NOT NULL,
  `id_destinatario` CHAR(36) NOT NULL,
  `contenido` TEXT NOT NULL,
  `tipo` TEXT NOT NULL,
  `ruta_imagen` TEXT,
  `leido` INT NOT NULL,
  `creado_en` TEXT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `calificaciones` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `id_usuario` CHAR(36),
  `puntaje` INT NOT NULL,
  `comentario` TEXT,
  `creado_en` TEXT NOT NULL,
  `peso_confianza` DECIMAL(4,3) NOT NULL,
  `estado_revision` TEXT NOT NULL,
  `motivo_revision` TEXT,
  `direccion` VARCHAR(255) NOT NULL,
  `id_calificado` CHAR(36) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `calificaciones_trabajo_direccion_uidx` (`id_trabajo`, `direccion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `disputas` (
  `id` VARCHAR(255) NOT NULL,
  `id_trabajo` VARCHAR(255) NOT NULL,
  `abierta_por` CHAR(36) NOT NULL,
  `motivo` TEXT NOT NULL,
  `descripcion` TEXT,
  `estado` TEXT NOT NULL,
  `resolucion` TEXT,
  `resuelta_por` CHAR(36),
  `resuelta_en` TEXT,
  `creado_en` TEXT NOT NULL,
  `actualizado_en` TEXT NOT NULL,
  `origen` TEXT NOT NULL,
  `decision_sugerida` TEXT,
  `motivo_regla` TEXT,
  `vence_en` DATETIME(6),
  `prioridad` TEXT,
  `asignado_a` CHAR(36),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `auditoria_consola` (
  `id` CHAR(36) NOT NULL,
  `creado_en` DATETIME(6) NOT NULL,
  `id_actor` CHAR(36),
  `rol_actor` TEXT,
  -- PostgreSQL: tipo accion_auditoria_consola.
  `accion` VARCHAR(64) NOT NULL,
  `entidad` TEXT NOT NULL,
  `id_entidad` TEXT,
  `antes` JSON,
  `despues` JSON,
  `motivo` TEXT,
  `ip` TEXT,
  `user_agent` TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `trabajadores` ADD CONSTRAINT `trabajadores_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `direcciones_cliente` ADD CONSTRAINT `direcciones_cliente_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `metodos_pago_oneclick` ADD CONSTRAINT `metodos_pago_oneclick_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `trabajos` ADD CONSTRAINT `jobs_userId_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `trabajos` ADD CONSTRAINT `jobs_workerId_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `pagos` ADD CONSTRAINT `payments_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `pagos` ADD CONSTRAINT `pagos_id_orden_cambio_fkey` FOREIGN KEY (`id_orden_cambio`) REFERENCES `ordenes_cambio` (`id`) ON DELETE SET NULL;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `change_orders_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `ordenes_cambio_id_pago_fkey` FOREIGN KEY (`id_pago`) REFERENCES `pagos` (`id`) ON DELETE SET NULL;
ALTER TABLE `ordenes_cambio` ADD CONSTRAINT `ordenes_cambio_id_trabajador_fkey` FOREIGN KEY (`id_trabajador`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `fotos_trabajo` ADD CONSTRAINT `job_photos_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `mensajes` ADD CONSTRAINT `mensajes_id_destinatario_fkey` FOREIGN KEY (`id_destinatario`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `mensajes` ADD CONSTRAINT `mensajes_id_remitente_fkey` FOREIGN KEY (`id_remitente`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `mensajes` ADD CONSTRAINT `messages_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones` ADD CONSTRAINT `calificaciones_id_calificado_fkey` FOREIGN KEY (`id_calificado`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `calificaciones` ADD CONSTRAINT `calificaciones_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `calificaciones` ADD CONSTRAINT `ratings_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;
ALTER TABLE `disputas` ADD CONSTRAINT `disputas_abierta_por_fkey` FOREIGN KEY (`abierta_por`) REFERENCES `perfiles` (`id`) ON DELETE CASCADE;
ALTER TABLE `disputas` ADD CONSTRAINT `disputas_asignado_a_fkey` FOREIGN KEY (`asignado_a`) REFERENCES `perfiles` (`id`) ON DELETE NO ACTION;
ALTER TABLE `disputas` ADD CONSTRAINT `disputas_resuelta_por_fkey` FOREIGN KEY (`resuelta_por`) REFERENCES `perfiles` (`id`) ON DELETE SET NULL;
ALTER TABLE `disputas` ADD CONSTRAINT `disputes_jobId_fkey` FOREIGN KEY (`id_trabajo`) REFERENCES `trabajos` (`id`) ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;
