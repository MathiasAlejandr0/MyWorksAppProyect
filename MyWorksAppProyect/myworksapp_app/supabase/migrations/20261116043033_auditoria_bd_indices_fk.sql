-- Auditoría de base de datos 2026-11-16 (4/5): índices de las nuevas claves foráneas.
--
-- La migración de integridad agregó 24 claves foráneas. Sin un índice en la
-- columna hija, cada DELETE/UPDATE de la fila padre (por ejemplo, borrar una
-- cuenta en perfiles o un trabajo) recorre la tabla hija completa para aplicar
-- ON DELETE CASCADE / SET NULL, y bloquea más tiempo. El linter de Supabase
-- (unindexed_foreign_keys) lo marca. Se crea un índice B-tree por columna.

CREATE INDEX IF NOT EXISTS idx_banderas_funcionalidad_id_usuario_fkey ON public.banderas_funcionalidad (id_usuario);
CREATE INDEX IF NOT EXISTS idx_bloqueos_usuario_id_bloqueado_fkey ON public.bloqueos_usuario (id_bloqueado);
CREATE INDEX IF NOT EXISTS idx_calificaciones_id_usuario_fkey ON public.calificaciones (id_usuario);
CREATE INDEX IF NOT EXISTS idx_calificaciones_cliente_id_cliente_fkey ON public.calificaciones_cliente (id_cliente);
CREATE INDEX IF NOT EXISTS idx_calificaciones_cliente_id_trabajador_fkey ON public.calificaciones_cliente (id_trabajador);
CREATE INDEX IF NOT EXISTS idx_cancelaciones_trabajo_cancelado_por_fkey ON public.cancelaciones_trabajo (cancelado_por);
CREATE INDEX IF NOT EXISTS idx_codigos_restablecimiento_id_usuario_fkey ON public.codigos_restablecimiento (id_usuario);
CREATE INDEX IF NOT EXISTS idx_disputas_abierta_por_fkey ON public.disputas (abierta_por);
CREATE INDEX IF NOT EXISTS idx_disputas_resuelta_por_fkey ON public.disputas (resuelta_por);
CREATE INDEX IF NOT EXISTS idx_eventos_analitica_id_usuario_fkey ON public.eventos_analitica (id_usuario);
CREATE INDEX IF NOT EXISTS idx_eventos_ranking_id_trabajo_fkey ON public.eventos_ranking (id_trabajo);
CREATE INDEX IF NOT EXISTS idx_intentos_pin_inicio_id_usuario_fkey ON public.intentos_pin_inicio (id_usuario);
CREATE INDEX IF NOT EXISTS idx_mensajes_id_remitente_fkey ON public.mensajes (id_remitente);
CREATE INDEX IF NOT EXISTS idx_ordenes_cambio_id_pago_fkey ON public.ordenes_cambio (id_pago);
CREATE INDEX IF NOT EXISTS idx_ordenes_cambio_id_trabajador_fkey ON public.ordenes_cambio (id_trabajador);
CREATE INDEX IF NOT EXISTS idx_pagos_id_orden_cambio_fkey ON public.pagos (id_orden_cambio);
CREATE INDEX IF NOT EXISTS idx_reportes_id_reportante_fkey ON public.reportes (id_reportante);
CREATE INDEX IF NOT EXISTS idx_reportes_id_usuario_reportado_fkey ON public.reportes (id_usuario_reportado);
CREATE INDEX IF NOT EXISTS idx_reprogramaciones_trabajo_propuesta_por_fkey ON public.reprogramaciones_trabajo (propuesta_por);
CREATE INDEX IF NOT EXISTS idx_reprogramaciones_trabajo_respondida_por_fkey ON public.reprogramaciones_trabajo (respondida_por);
CREATE INDEX IF NOT EXISTS idx_senales_resena_resuelto_por_fkey ON public.senales_resena (resuelto_por);
CREATE INDEX IF NOT EXISTS idx_tickets_soporte_id_trabajo_fkey ON public.tickets_soporte (id_trabajo);
CREATE INDEX IF NOT EXISTS idx_trabajos_id_cotizacion_seleccionada_fkey ON public.trabajos (id_cotizacion_seleccionada);
CREATE INDEX IF NOT EXISTS idx_verificacion_eventos_id_actor_fkey ON public.verificacion_eventos (id_actor);
