# Solución — My Works App

**Estado del documento:** 2026-11-17, sobre `main` en `8b18b3f`. Las rutas son relativas a `MyWorksAppProyect/` (el monorepo de software), salvo que se indique otra cosa.

## Descripción de la solución

My Works App es una plataforma multiplataforma que conecta a personas que necesitan un oficio del hogar con profesionales independientes. Está formada por una app móvil Flutter (`myworksapp_app/`), una web React/Vite (`myworksapp_web/`) y una consola de escritorio Tauri (`myworksapp_desktop/`) que comparten un mismo backend en Supabase (Auth, PostgreSQL con RLS, Edge Functions y `pg_cron`) y un paquete común (`shared/`). El cliente busca y contrata desde la app o la web, e incluso puede comprar como invitado en la web; el profesional gestiona su perfil, su agenda y sus pedidos desde la app; y la administración y el equipo de soporte operan desde la consola de escritorio, con segundo factor de autenticación. La solución resuelve la desconfianza de los tiempos y los pagos al contratar un oficio. Por el lado de los tiempos, cada pedido sigue una máquina de estados y una agenda que no admite dos reservas activas del mismo profesional en el mismo minuto. Además, el trabajo se inicia con un PIN que muestra el cliente y puede seguirse con la ubicación en vivo del profesional. Por el lado de los pagos, el cliente paga con Transbank Webpay Plus u Oneclick sin que la plataforma capture el número de su tarjeta, el dinero queda retenido (escrow) hasta que el cliente da su conformidad o se resuelve una disputa, y cada liberación deja una liquidación registrada. Para elegir bien, el cliente compara profesionales por oficio, zona, precio y calificación, y el orden del listado se calcula con un puntaje de reputación que pondera la confianza de cada reseña. Webpay opera hoy en el ambiente de integración de Transbank (sin cobro comercial real), según el `README.md` de la raíz.

## Módulos que la implementan

Las columnas indican dónde está cada módulo. «Migraciones» son archivos de `myworksapp_app/supabase/migrations/`; «Edge Functions» están en `myworksapp_app/supabase/functions/`. Los casos de uso (CU) son los de `docs/casos_de_uso.md`.

### 1. Reservas y pedidos (CU-07, CU-11, CU-13 a CU-16, CU-20, CU-33)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `myworksapp_app/lib/features/user/presentation/pages/service_request_page.dart`, `quick_booking_page.dart`; `lib/features/jobs/` (detalle, línea de tiempo, evidencias, reagendamiento, cotizaciones, órdenes de cambio); `lib/core/services/job_booking_service.dart`, `job_service.dart`, `job_state_machine.dart`, `job_transition_matrix.dart`, `job_cancellation_service.dart`, `change_order_service.dart`, `quote_proposal_service.dart`; `lib/core/domain/booking_schedule.dart`, `reschedule_rules.dart`; `lib/core/widgets/design_system/service_pin_dialog.dart` |
| Web | `myworksapp_web/src/components/QuickBookingBar.tsx`, `TrackingDashboard.tsx`, `JobClientActions.tsx`, `JobEvidencePanel.tsx` |
| Compartido | `shared/src/jobs/` (`bookingSlot.ts`, `startPin.ts`, `reschedule.ts`, `clientActions.ts`, `statusCopy.ts`); `shared/src/scheduling/`; `shared/src/evidence/`; `shared/src/repositories/jobs.ts` |
| Base de datos | `20260929000001_transiciones_y_invitados.sql`, `20261009000002_transiciones_por_actor.sql`, `20261115180001_inicio_trabajo_requiere_pin.sql` (PIN de inicio), `20261115232900_reprogramar_trabajo.sql`, `20261115232858_disponibilidad_tras_trabajo.sql`; evidencias: `20261108000001_evidencia_webp.sql`, `20261115050002_bucket_evidencias.sql`, `20261115050008_evidencias_video_20mb.sql`; cotizaciones: `20261008000005_precios_cotizaciones_privacidad.sql`; órdenes de cambio: `20261109000002_orden_cambio_webpay.sql`. Tablas: `trabajos`, `fotos_trabajo`, `pines_inicio_trabajo`, `reprogramaciones_trabajo`, `ordenes_cambio`, `propuestas_cotizacion`, `cancelaciones_trabajo`, `acuerdos_trabajo`. |

### 2. Pagos con Transbank Webpay y Oneclick (CU-08, CU-09, CU-10, CU-15, CU-17, CU-20, CU-27)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/payments/presentation/pages/payment_screen.dart`, `payment_result_screen.dart`, `card_enrollment_page.dart`; `lib/core/services/payment_service.dart`, `payment_gateway_port.dart`, `transbank_webpay_gateway.dart`, `payment_guard.dart`; `lib/core/widgets/escrow_checkout_sheet.dart`, `webpay_webview_page.dart`; `lib/core/database/repositories/payment_repository.dart`, `payout_repository.dart` |
| Web | `myworksapp_web/src/components/PaymentCheckoutModal.tsx`, `GuestCheckoutForm.tsx`, `PaidReturnView.tsx` |
| Compartido | `shared/src/payments/` (`webpay.ts`, `oneclick.ts`, `guestCheckout.ts`, `checkoutReturn.ts`, `payout.ts`, `edgeError.ts`) |
| Edge Functions | Webpay: `webpay-create`, `webpay-handoff`, `webpay-commit`, `webpay-status`, `webpay-release`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-refund-rejection`, `webpay-resolve-dispute`, `webpay-reconcile`. Oneclick: `oneclick-handoff`, `oneclick-return`, `oneclick-charge`. Invitado: `guest-checkout`, `definir-clave-invitado`. Utilidades comunes: `_shared/tbk.ts`, `transbank_form.ts`, `webpay_return.ts`, `commit_guard.ts`, `refund_once.ts`, `reconcile_hold.ts`, `abandon_payment.ts`, `oneclick_charge.ts`. |
| Base de datos | `20260322000001_webpay_escrow_hardening.sql`, `20260922000001_reaffirm_webpay_harden.sql`, `20260923000001_liquidaciones_manuales.sql`, `20261001000001_reembolso_una_vez_y_cancelacion.sql`, `20261002000001_oneclick_tarjeta_guardada.sql`, `20261003000001_oneclick_cobro_seguro.sql`, `20261008000003_origen_retorno_pago.sql`, `20261008000006_pagos_abandonados_y_catalogo.sql`, `20261115050003_pago_por_confirmar.sql`, `20261115050005_pagos_cuenta_bancaria.sql`, `20261115060002_cron_webpay_reconcile.sql`, `20261115160001_reconcile_secret_vault.sql`. Tablas: `pagos`, `liquidaciones`, `metodos_pago_oneclick`, `cuentas_bancarias`. |
| Documentación | `docs/ARQUITECTURA_MODALIDADES_COBRO.md`, `docs/RUNBOOK_PAYOUT.md`, `docs/RUNBOOK_TRANSBANK_PRODUCCION.md` |

### 3. Búsqueda y catálogo de profesionales (CU-05, CU-06)

La web y la app muestran a los profesionales en el mismo orden, definido en un solo lugar, la RPC `listar_profesionales_catalogo`:

1. **Cercanía**: distancia entre la ubicación del cliente (GPS, dirección o mapa) y la base pública del profesional (redondeada a 2 decimales, unos 1 km), agrupada en bandas de 1 km (`floor` de la distancia haversine). Más cerca va primero. Sin ubicación del cliente o sin base del profesional, este criterio no aplica y ese profesional va al final.
2. **Calificación**: dentro de la misma banda, la nota pública más alta primero (0 si todavía no tiene reseñas).
3. **Precio**: con la misma nota, la tarifa de visita más baja primero (sin tarifa, o con tarifa 0, al final).
4. **Desempate**: el id del profesional, para que el orden sea estable al paginar.

Es el orden por defecto en las dos interfaces. La web y la app lo replican con el mismo comparador (`shared/src/catalogOrder.ts` y `lib/core/domain/catalog_order.dart`) para reordenar sin volver a consultar cuando el cliente cambia su ubicación, y ambos se prueban con los mismos casos (`shared/fixtures/catalog_order_cases.json`). Ordenar solo por precio o solo por calificación son vistas opcionales que desempatan con ese mismo orden.

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/user/presentation/pages/user_home_page.dart`, `worker_list_page.dart`, `worker_detail_page.dart`; `lib/features/user/presentation/widgets/worker_search_map.dart`, `time_slot_selector.dart`; `lib/core/services/worker_search_service.dart`, `matching_service.dart`, `pricing_service.dart`, `pricing_guard_service.dart`, `worker_reputation_service.dart`; `lib/core/domain/catalog_order.dart` |
| Web | `myworksapp_web/src/components/CategoriesCatalogView.tsx`, `SearchResultsView.tsx` (filtro por calificación mínima; orden por defecto cercanía, nota y precio, o solo precio o solo calificación), `src/catalogSort.ts`, `PremiumSearchMap.tsx`; `src/data/serviceCategories.ts`, `resolveServiceQuery.ts` |
| Compartido | `shared/src/catalog.ts`, `shared/src/catalogOrder.ts`, `shared/src/repositories/workers.ts`, `services.ts` |
| Base de datos | `20261008000006_pagos_abandonados_y_catalogo.sql` y `20261008000009_catalogo_verificado_y_pago_bloqueado.sql` (`categorias_con_disponibles`), `20261113000003_profesionales_ocupados.sql`, `20261113000002_catalogo_ubicacion_aproximada_anon.sql`, `20261108000005_trabajador_horarios.sql` (`horarios_libres_profesional`), `20261116044049_stats_profesional_fuente_unica.sql`, `20261117215046_catalogo_orden_cercania_nota_precio.sql` y `20261117215659_catalogo_orden_tarifa_cero_al_final.sql` (`listar_profesionales_catalogo`). Tablas: `servicios`, `trabajadores`, `trabajador_precios`, `trabajador_servicios`, `trabajador_horarios`, `portafolio_trabajador`. |

### 4. Calificaciones, reseñas y ranking por reputación (CU-18, CU-19)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/ratings/` (`rating_page.dart`, `rating_gate.dart`, `client_reputation_card.dart`, `rate_client_button.dart`); `lib/features/inbox/presentation/pages/my_ratings_page.dart`; `lib/features/user/presentation/widgets/worker_reviews_section.dart`; `lib/core/services/worker_reputation_service.dart`, `trust_score_service.dart`; `lib/core/database/repositories/rating_repository.dart`, `client_rating_repository.dart`, `ranking_repository.dart` |
| App (administración) | `lib/features/admin/presentation/pages/admin_ranking_page.dart` |
| Base de datos | `20261010000001_ranking_y_resenas.sql` (`evaluar_resena`, `aprender_pesos_ranking`), `20261025000001_revision_patrocinante.sql` (`calificar_cliente`), `20261115050004_calificacion_bidireccional.sql`. Tablas: `calificaciones`, `calificaciones_cliente`, `senales_resena`, `ranking_config`, `ranking_aprendizaje`, `eventos_ranking`. |
| Documentación | `docs/AUTOMATIZACION_RANKING_Y_RESENAS.md`, `docs/AUTOMATIZACION_PERFILES_TRABAJADOR.md` |

### 5. Chat sobre el trabajo (CU-23)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/chat/presentation/pages/chat_page.dart`, `conversations_page.dart`; `lib/core/database/repositories/message_repository.dart`; `lib/utils/content_filter.dart` |
| Web | `myworksapp_web/src/components/LiveChatWidget.tsx` |
| Compartido | `shared/src/chat/messages.ts` |
| Base de datos | `20261108000003_auditoria_horarios_chat.sql`; tabla `mensajes`; el bloqueo de datos de contacto en mensajes está en `20261025000001_revision_patrocinante.sql`. |

### 6. Disputas, acuerdos y soporte automático (CU-21, CU-22, CU-32, CU-34)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/jobs/presentation/widgets/dispute_section.dart`; `lib/features/inbox/presentation/pages/my_disputes_page.dart`; `lib/features/admin/presentation/pages/admin_disputes_page.dart`; `lib/core/services/dispute_service.dart`, `dispute_rules.dart` |
| Escritorio | `myworksapp_desktop/src/components/SupportWorkspace.tsx`, `AdminInboxPanel.tsx` |
| Compartido | `shared/src/repositories/disputes.ts` |
| Edge Functions | `soporte-automatico`, `webpay-resolve-dispute`; `_shared/dispute_guard.ts` |
| Base de datos | `20260930000001_cierre_conforme_y_disputa.sql`, `20261008000004_disputas_partes.sql`, `20261112000001_soporte_automatico.sql`, `20261115232852_disputas_solo_trabajos_activos.sql`, `20261115232902_consola_roles_soporte_qa.sql`. Tablas: `disputas`, `disputa_mensajes`, `acuerdos_trabajo`, `tickets_soporte`. |

### 7. Autenticación, roles y perfiles (CU-01 a CU-04, CU-25, CU-26)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/auth/` (inicio de sesión, registro, recuperación de contraseña, perfil); `lib/features/role_selector/`; `lib/features/worker/` (registro, perfil, tarifas, horario, verificación, zona de cobertura); `lib/features/gdpr/` (política de privacidad, términos y derechos del usuario); `lib/core/services/auth_service.dart`, `session_manager.dart`, `oauth_deep_link_service.dart`, `account_deletion_service.dart`, `gdpr_service.dart` |
| Web | `myworksapp_web/src/components/AuthModal.tsx`, `PasswordRecoveryModal.tsx`, `TurnstileWidget.tsx`; `src/context/AuthContext.tsx` |
| Escritorio | `myworksapp_desktop/src/authAccess.ts`, `components/DesktopLoginScreen.tsx`, `AdminMfaGate.tsx`, `InvitePasswordScreen.tsx`; `src/context/AuthContext.tsx` |
| Compartido | `shared/src/auth.ts`, `passwordPolicy.ts`, `emailDomain.ts`, `verification.ts`, `avatar.ts` |
| Edge Functions | `invitar-colaborador`, `definir-clave-invitado` |
| Base de datos | `20250607000001_security_hardening_roles_profiles.sql`, `20260917000001_auth_role_aliases_cliente_especialista.sql`, `20260914000005_rls_politicas_negocio.sql`, `20261005000001_verificacion_profesional.sql`, `20261008000002_perfiles_publicos_rpc.sql`, `20261115050007_verificacion_eventos.sql`. Tablas: `perfiles`, `trabajadores`, `consentimientos_usuario`, `bloqueos_usuario`, `verificacion_eventos`. |
| Documentación | `docs/MODELO_ENTIDAD_RELACION.md`, `docs/DICCIONARIO_BASE_DATOS.md`; en la raíz, `Documentos Guia/Autenticacion por Roles Cliente-Especialista - My Works App.docx` y `Documentos Guia/Politicas RLS - My Works App.docx` |

### 8. Geolocalización y mapas (CU-12, CU-13)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/core/map/app_map_tiles.dart` (OpenFreeMap Positron); `lib/core/services/user_location_service.dart`, `geocode_chile.dart`, `gps_publish_gate.dart`; `lib/features/jobs/presentation/widgets/worker_gps_publisher.dart`, `client_live_tracking.dart`, `job_location_preview_section.dart`; `lib/core/widgets/job_location_map.dart`, `location_picker_widget.dart`; `lib/features/worker/presentation/widgets/worker_base_location_card.dart`, `worker_urban_coverage_card.dart` |
| Web | `myworksapp_web/src/map/basemap.ts`, `src/geo/geocodeChile.ts`, `src/hooks/useLiveJobLocation.ts`, `src/components/LiveGpsTrackingMap.tsx`, `JobLocationMap.tsx` |
| Compartido | `shared/src/geo/` (`distance.ts`, `transport.ts`) |
| Base de datos | `20261006000001_gps_y_base_profesional.sql`, `20261009000001_catalogo_geografico.sql`, `20261023000001_radar_traslado.sql`, `20261023000002_catalogo_coords_y_tope_traslado.sql`, `20261101000001_catalogo_coords_reales.sql`. Tablas: `ubicacion_en_vivo`, `comunas`, `regiones`, `paises`. |

### 9. Notificaciones (CU-24)

| Capa | Archivos y carpetas |
|------|---------------------|
| App | `lib/features/notifications/presentation/pages/notifications_page.dart`; `lib/core/services/notification_service.dart`, `notification_realtime_service.dart`, `push_service.dart`, `push_notification_port.dart`, `notification_opt_in.dart`; `lib/core/widgets/notification_listener_scope.dart` |
| Compartido | `shared/src/repositories/notifications.ts` |
| Edge Functions | `send-push` (FCM, con `_shared/fcm.ts`). Con la app abierta los avisos llegan por Supabase Realtime; el push FCM queda apagado hasta configurar las variables `FCM_*` (ver `docs/PUSH_NOTIFICACIONES.md`). |
| Base de datos | `20261113000005_push_dispositivos.sql`, `20261116042604_notificar_nuevo_pedido.sql`. Tablas: `notificaciones`, `dispositivos_push`. |

### 10. Administración y consola de escritorio (CU-28 a CU-31, CU-34)

| Capa | Archivos y carpetas |
|------|---------------------|
| Escritorio (Tauri) | `myworksapp_desktop/src/App.tsx`; `src/components/` (`AdminMfaGate.tsx`, `ExecutiveWorkspace.tsx`, `ExecutivePeriodPanel.tsx`, `FinancialSettlementModal.tsx`, `PaymentAttentionBanner.tsx`, `JobScopeAdjustmentModal.tsx`, `DigitalContractModal.tsx`, `HumanResourcesWorkspace.tsx`, `SupportWorkspace.tsx`, `AuditTrailViewer.tsx`, `DevSecOpsWorkspace.tsx`); `src-tauri/` |
| App (páginas de administración) | `lib/features/admin/presentation/pages/` (panel, usuarios, profesionales, trabajos, disputas, pagos, reportes, banderas de funcionalidad, ranking, errores) |
| Compartido | `shared/src/repositories/metrics.ts`, `shared/src/metrics/period.ts`, `shared/src/invites/` |
| Edge Functions | `invitar-colaborador`, `webpay-release`, `webpay-reconcile`, `soporte-automatico` |
| Base de datos | `20260914000005_rls_politicas_negocio.sql` (`admin_metricas_resumen`), `20260924000001_thermos_security_fixes.sql` (`liberar_escrow_manual`), `20261005000002_security_lockdown_rpc.sql`, `20261115232902_consola_roles_soporte_qa.sql`. Tablas: `banderas_funcionalidad`, `registros_error_app`, `eventos_analitica`, `reportes`, `eventos_abuso`. |

### 11. Calidad, seguridad y operación

| Tema | Archivos y carpetas |
|------|---------------------|
| Integración continua | `.github/workflows/` en la raíz: `flutter_ci.yml`, `web_desktop_ci.yml`, `gitleaks.yml`, `commitlint.yml`, `scorecard.yml`, `supabase_keepalive.yml`; `.github/dependabot.yml` |
| Pruebas | `myworksapp_app/test/` (67 archivos), `shared/src/**/*.test.ts` y `supabase/functions/_shared/*.test.ts`, `myworksapp_desktop/src/authAccess.test.ts`, `myworksapp_web/e2e/` (Playwright) |
| Pruebas de carga, estrés y seguridad | `docs/pruebas/` (`k6/mwa_carga.js`, `seguridad/pruebas_seguridad.py`, `prueba_carga_rendimiento.md`, `estres_base_datos.md`, `seguridad_base_datos.md`) |
| Auditorías y modelo de datos | `docs/AUDITORIA_PROYECTO.md`, `docs/MODELO_ENTIDAD_RELACION.md`, `docs/DICCIONARIO_BASE_DATOS.md`, `docs/casos_de_uso.md`, `docs/uml/` |
| Código compartido y generación | `shared/src/domain.ts`, `scripts/generate-domain-dart.mjs`, `scripts/check-domain-drift.mjs`, `scripts/generate-app-colors.mjs`, `shared/design-tokens.json` |
