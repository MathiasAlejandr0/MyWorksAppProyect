#!/usr/bin/env python3
"""Safe bulk rename of DB map keys and table names in Flutter database layer."""
from pathlib import Path

ROOT = Path(r"d:\MyWorksAppProyect\myworksapp_app\lib")

COL = [
    ("accountStatus", "estado_cuenta"),
    ("profilePhotoPath", "ruta_foto_perfil"),
    ("serviceMetadata", "metadatos_servicio"),
    ("pricingSnapshot", "instantanea_precio"),
    ("selectedQuoteId", "id_cotizacion_seleccionada"),
    ("hourlyBlockHours", "horas_bloque"),
    ("serviceSkuId", "id_sku_servicio"),
    ("requiresCertification", "requiere_certificacion"),
    ("pricingConfigured", "precios_configurados"),
    ("customServices", "servicios_personalizados"),
    ("pricingTiers", "niveles_precio"),
    ("serviceCategory", "categoria_servicio"),
    ("rejectionCount", "conteo_rechazos"),
    ("legalDisclaimer", "aviso_legal"),
    ("pricingModel", "modelo_precio"),
    ("pricingMode", "modalidad_cobro"),
    ("paymentStatus", "estado_pago"),
    ("scheduledDate", "fecha_programada"),
    ("changeOrderId", "id_orden_cambio"),
    ("paymentType", "tipo_pago"),
    ("paymentMethod", "metodo_pago"),
    ("transactionId", "id_transaccion"),
    ("authorizedAt", "autorizado_en"),
    ("releasedAt", "liberado_en"),
    ("refundedAt", "reembolsado_en"),
    ("receiverId", "id_destinatario"),
    ("senderId", "id_remitente"),
    ("imagePath", "ruta_imagen"),
    ("relatedId", "id_relacionado"),
    ("reportedUserId", "id_usuario_reportado"),
    ("reporterId", "id_reportante"),
    ("montoTotalClp", "monto_total_clp"),
    ("validezHasta", "validez_hasta"),
    ("respondedAt", "respondido_en"),
    ("paymentId", "id_pago"),
    ("montoClp", "monto_clp"),
    ("photoPath", "ruta_foto"),
    ("mediaType", "tipo_medio"),
    ("cancelledBy", "cancelado_por"),
    ("cancelledAt", "cancelado_en"),
    ("errorType", "tipo_error"),
    ("stackTrace", "traza_pila"),
    ("appVersion", "version_app"),
    ("abuseType", "tipo_abuso"),
    ("detectedAt", "detectado_en"),
    ("actionTakenAt", "accion_tomada_en"),
    ("actionTaken", "accion_tomada"),
    ("isResolved", "resuelto"),
    ("actionType", "tipo_accion"),
    ("entityType", "tipo_entidad"),
    ("entityId", "id_entidad"),
    ("retryCount", "conteo_reintentos"),
    ("errorMessage", "mensaje_error"),
    ("blockerId", "id_bloqueador"),
    ("blockedUserId", "id_bloqueado"),
    ("consentVersion", "version_consentimiento"),
    ("acceptedAt", "aceptado_en"),
    ("ipAddress", "direccion_ip"),
    ("userAgent", "agente_usuario"),
    ("flagName", "nombre_bandera"),
    ("isEnabled", "habilitada"),
    ("planType", "tipo_plan"),
    ("startDate", "fecha_inicio"),
    ("endDate", "fecha_fin"),
    ("boostType", "tipo_impulso"),
    ("eventName", "nombre_evento"),
    ("configSchema", "esquema_config"),
    ("isAvailable", "disponible"),
    ("visitFee", "tarifa_visita"),
    ("workZone", "zona_trabajo"),
    ("isActive", "activo"),
    ("openedBy", "abierta_por"),
    ("resolvedBy", "resuelta_por"),
    ("resolvedAt", "resuelta_en"),
    ("createdAt", "creado_en"),
    ("updatedAt", "actualizado_en"),
    ("comunaId", "id_comuna"),
    ("workerId", "id_trabajador"),
    ("serviceId", "id_servicio"),
    ("userId", "id_usuario"),
    ("jobId", "id_trabajo"),
    ("isRead", "leido"),
    # simple fields last
    ("description", "descripcion"),
    ("profession", "profesion"),
    ("latitude", "latitud"),
    ("longitude", "longitud"),
    ("address", "direccion"),
    ("category", "categoria"),
    ("platform", "plataforma"),
    ("metadata", "metadatos"),
    ("resolution", "resolucion"),
    ("comment", "comentario"),
    ("content", "contenido"),
    ("message", "mensaje"),
    ("reason", "motivo"),
    ("title", "titulo"),
    ("score", "puntaje"),
    ("amount", "monto"),
    ("currency", "moneda"),
    ("timestamp", "marca_tiempo"),
    ("password", "password"),
    ("email", "correo"),
    ("name", "nombre"),
    ("role", "rol"),
    ("body", "cuerpo"),
    ("count", "conteo"),
    ("data", "datos"),
    ("type", "tipo"),
    ("status", "estado"),
    ("accepted", "aceptado"),
]

TABLES = [
    ("'profiles'", "'perfiles'"),
    ("'workers'", "'trabajadores'"),
    ("'services'", "'servicios'"),
    ("'jobs'", "'trabajos'"),
    ("'payments'", "'pagos'"),
    ("'messages'", "'mensajes'"),
    ("'disputes'", "'disputas'"),
    ("'notifications'", "'notificaciones'"),
    ("'ratings'", "'calificaciones'"),
    ("'reports'", "'reportes'"),
    ("'quote_proposals'", "'propuestas_cotizacion'"),
    ("'change_orders'", "'ordenes_cambio'"),
    ("'job_photos'", "'fotos_trabajo'"),
    ("'worker_portfolio'", "'portafolio_trabajador'"),
    ("'worker_services'", "'trabajador_servicios'"),
    ("'job_cancellations'", "'cancelaciones_trabajo'"),
    ("'app_error_logs'", "'registros_error_app'"),
    ("'abuse_events'", "'eventos_abuso'"),
    ("'pending_actions'", "'acciones_pendientes'"),
    ("'user_blocks'", "'bloqueos_usuario'"),
    ("'user_consents'", "'consentimientos_usuario'"),
    ("'feature_flags'", "'banderas_funcionalidad'"),
    ("'subscriptions'", "'suscripciones'"),
    ("'boosts'", "'impulsos'"),
    ("'analytics_events'", "'eventos_analitica'"),
    ("'service_configs'", "'configuraciones_servicio'"),
    ("workers_userId_fkey", "trabajadores_id_usuario_fkey"),
]

DIRS = [
    ROOT / "core" / "database",
]


def replace_quoted_keys(text: str) -> str:
    for old, new in COL:
        text = text.replace(f"'{old}'", f"'{new}'")
    for a, b in TABLES:
        text = text.replace(a, b)
    return text


def main():
    n = 0
    for d in DIRS:
        for path in d.rglob("*.dart"):
            orig = path.read_text(encoding="utf-8")
            text = replace_quoted_keys(orig)
            if text != orig:
                path.write_text(text, encoding="utf-8")
                n += 1
                print(path.relative_to(ROOT))
    # realtime service
    rt = ROOT / "core" / "services" / "notification_realtime_service.dart"
    if rt.exists():
        t = rt.read_text(encoding="utf-8")
        t2 = t.replace("table: 'notifications'", "table: 'notificaciones'")
        t2 = t2.replace("notifications:", "notificaciones:")
        t2 = replace_quoted_keys(t2)
        if t2 != t:
            rt.write_text(t2, encoding="utf-8")
            n += 1
            print(rt.relative_to(ROOT))
    print(f"changed {n}")


if __name__ == "__main__":
    main()
