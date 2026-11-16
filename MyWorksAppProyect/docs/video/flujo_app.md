# MyWorksApp — Flujo real de la app (fuente para el video)

Extraído del código en `main` (commit `310f00b`, repo `nicoussj/Proyecto-Titulo-MyWorksApp`, carpeta `MyWorksAppProyect/`) y de la base en vivo (`wxqrfcqifkfgawrnqmnj`, solo lectura). Rutas relativas a `MyWorksAppProyect/`.
Las capturas están en `/workspace/mwa_video/screens/` (ver índice al final).

> Regla de oro para el video: **todo lo que aparece aquí existe en el código**. Lo que no está aquí, no se muestra.

---

## 0. Qué es y quién lo usa

- **Marketplace de servicios del hogar para Chile** (gasfitería, electricidad, armado, limpieza, pintura, jardinería, cerrajería, construcción, soporte técnico, mudanza, climatización, plomería). Lista de categorías: `myworksapp_web/src/data/serviceCategories.ts`, captura `web_05_categorias.png`.
- **Tres clientes, un backend** (README.md §Arquitectura):
  - **App móvil Flutter** (`myworksapp_app`): cliente **y** profesional (rol «Especialista»). Android principal.
  - **Web React/Vite** (`myworksapp_web`): **solo clientes** («Esta web es solo para clientes que buscan un oficio. Los trabajadores usan la app móvil; el equipo interno, el panel de escritorio.» — `components/AuthModal.tsx`).
  - **Escritorio Tauri** (`myworksapp_desktop`): **consola de administración** («Consola operativa — Supervisa. Gestiona. Resuelve.»).
  - Backend: **Supabase** (Auth + PostgreSQL con RLS + Edge Functions en Deno). Pagos: **Transbank Webpay Plus / Oneclick en modo integración (pruebas)**.
- Nombre visible de marca: **«My Works App»** (`myworksapp_app/lib/core/utils/constants.dart` → `appBrandDisplayName`).

## 1. Marca (valores exactos del código)

| Token | Hex | Fuente |
|---|---|---|
| Naranja marca (CTA, acento 10 %) | `#FF5E03` | `shared/design-tokens.json` → `brandOrange` |
| Naranja vibrante (gradientes) | `#FF7A18` | `brandOrangeVibrant` |
| Naranja oscuro (pressed) | `#D9530F` | `lib/core/theme/app_colors.dart` |
| Azul marino (confianza, escrow) | `#00205B` | `brandNavy` |
| Fondo canvas oscuro | `#070B12` → `#0B1424` (degradado) | `bgCanvasDark`, `bgCanvasDarkAlt` |
| Superficie / elevada | `#121A2A` / `#172033` | `bgSurfaceDark`, `bgElevatedDark` |
| Verde éxito / verificado | `#2F9E64` | `emerald` |
| Rojo error / cancelado | `#E23D35` | `crimsonError` |
| Ámbar pendiente | `#C9A227` | `app_colors.dart` → `warning` |
| Azul info | `#4C8DDB` | `app_colors.dart` → `info` |
| Texto principal / secundario (oscuro) | `#F7F8FA` / `#A8B2C0` | `textMainDark`, `textMutedDark` |
| Fondo claro | `#F7F5F2` | `bgDominantLight` |

- Regla de color declarada en el código: **60-30-10** (60 % canvas neutro oscuro, 30 % navy/slate, 10 % naranja solo para CTA y focos) — comentario de `app_colors.dart`.
- Atmósfera web: resplandor radial naranja arriba a la izquierda sobre canvas `#070B12` (`myworksapp_web/src/index.css`, `--atmosphere`). Sombra «glow» naranja `rgba(255,94,3,0.32)`.
- Radios: 10 / 14 / 22 px, píldora 9999 (`design-tokens.json`).
- **Tipografía**: web y escritorio usan **DM Sans** (400/500/600/700, Google Fonts — `myworksapp_web/index.html`, `myworksapp_desktop/src/index.css`). La app Flutter no define fuente: usa la del sistema (Roboto en Android). Títulos de marca en la app: peso 800.
- **Logo**: monograma «MW» blanco sobre dos rectángulos redondeados superpuestos, **naranja `#FF5E03` atrás‑derecha y navy `#00205B` adelante‑izquierda**. Archivos: `shared/brand/mark.svg` (= `myworksapp_web/public/brand/mark.svg` = `myworksapp_app/assets/brand/mark.svg`). Copia en `/workspace/mwa_video/brand/mark.svg` y PNG 2048 px `brand/mark_2048.png`. En la app el logo se dibuja con `CustomPaint` (`core/widgets/design_system/app_brand_logo.dart`).
- Imágenes de categoría reales: `myworksapp_web/public/categories/*.webp` y `myworksapp_app/assets/images/services/*.png` → copiadas en `brand/categorias/`. Foto hero de la app: `assets/images/welcome_hero.jpg`.
- ⚠️ `docs/mockups/*` (copiados en `brand/mockups_diseno/`) son **mockups conceptuales**, no la app real: usan otro naranja (`#F0782A`), nombres inventados y hasta montos en euros (€2.845). **No usarlos como pantallas reales.**

---

## 2. Rol CLIENTE

### 2.1 Entrada, registro e inicio de sesión

**App móvil** (rutas en `lib/core/router/app_router.dart`, constantes en `lib/core/utils/constants.dart`):
1. **Onboarding** (`features/onboarding/presentation/pages/onboarding_page.dart`), 4 láminas con botones «Omitir / Anterior / Siguiente / Comenzar»:
   «Bienvenido a My Works App» → «Ubicación automática» → «Profesionales calificados» → «Comunicación directa». Capturas `app_01_onboarding_1..4.png`.
2. **Bienvenida** (`role_selector/.../welcome_page.dart`): «Soluciones profesionales para tu hogar», chips Armado / Electricidad / Plomería, botón **«Comenzar Ahora»**. `app_02_bienvenida.png`.
3. **Iniciar sesión** (`auth/.../login_page.dart`): selector de rol **Cliente / Especialista**, correo + contraseña, **«Entrar»**, «¿No tienes cuenta? Regístrate», «¿Olvidaste tu contraseña?». `app_03_login.png`.
4. **Crear tu cuenta** (`auth/.../register_page.dart`): «¿Cómo quieres usar My Works App?» (Cliente = «Busco servicios profesionales»; Especialista = «Ofrezco servicios profesionales» — `core/domain/user_role.dart`), nombre completo, correo, contraseña + confirmar, casilla obligatoria de **Términos y Condiciones y Política de Privacidad**, botón **«Registrarse»**. `app_04_registro.png`.
   - Regla de contraseña: **mínimo 8 caracteres, con al menos una letra y un número** (texto en la web y `supabase/config.toml`).
   - Hay botones sociales (Google/Apple) en el código (`social_auth_buttons.dart`; en la web «Continuar con Google / Continuar con Apple»).

**Web**: barra superior «Servicios · Cómo funciona · Ingresar · Registrarse». Modal «ACCESO CLIENTES → Iniciar sesión / Crear cuenta» (`components/AuthModal.tsx`). Capturas `web_02_login.png`, `web_03_registro.png`, `web16x9_03_login.png`.
- Se puede **comprar sin cuenta** (checkout de invitado, ver 2.4).

### 2.2 Portada y búsqueda

**Web — portada** (`views/LandingHome.tsx`, `web16x9_01_portada.png`):
- Titular: **«My Works App / Profesionales de confianza / para tu hogar»** (las dos líneas centrales en naranja).
- Bajada: «Conectamos tu hogar con gasfíteres, electricistas, pintores y otros oficios. Rápido y con el pago retenido hasta tu conformidad.»
- Botones **«Buscar servicio →»** (naranja) y **«▶ Cómo funciona»**.
- Tarjetas flotantes sobre la foto: «Confianza verificada — **Verificados** — Cédula revisada antes de cobrar» y «Llegada estimada — **En vivo** — El mapa sigue al profesional en camino».
- «CATEGORÍAS POPULARES» (Armado, Electricidad, Plomería, Gasfitería).
- **«CÓMO FUNCIONA — Simple. Seguro. Confiable.»** con 3 pasos: **01 CREA TU CUENTA** · **02 BUSCA Y COMPARA** · **03 RESERVA Y RECIBE** («El pago queda protegido. Sigues el servicio hasta la entrega.»). Lema: «Catálogo de oficios • Pago retenido • Tú das la conformidad». `web16x9_02_como_funciona.png`.
- «VER TODAS LAS CATEGORÍAS» → catálogo de 12 oficios (`web_05_categorias.png`). Una categoría sin profesionales verificados se oculta.
- Con sesión el saludo es «Hola, {Nombre}» y aparece **«Mis pedidos»** y la campana de notificaciones.

**Web — resultados + mapa** (`components/SearchResultsView.tsx`, `components/PremiumSearchMap.tsx`; `web16x9_04_busqueda_mapa.png`, `web16x9_05_filtro_calificacion.png`, `mob_04_busqueda_mapa.png`):
- Encabezado «Encuentra profesionales. Reserva con confianza.» y buscador de texto («plomería»).
- **Filtros**: «Calificación mínima» (Cualquiera / 4.5 y más / 4.0 y más / 3.5 y más) y «Disponibilidad — Disponible ahora». **Ordenar por**: Relevancia / Precio / Calificación.
- Tarjeta de profesional (datos reales en vivo, Puerto Montt): foto, nombre, oficio, **nota ★ (p. ej. 4.9)**, **N trabajos**, «Hasta 12 km sin extra de traslado. Más lejos, recargo por km.», **«Desde $32.000 / visita»**, chip verde «Disponible ahora», insignia **«Élite»** para el destacado del mes.
- **Mapa Leaflet** con pines naranjas; leyenda «Profesionales cerca · Élite del mes · Tu trabajo · Área sin extra de traslado». Al elegir un profesional se dibuja un **círculo de cobertura** (radio sin recargo) y un globo «Mateo Oyarzo · Gasfíter · Élite · ★ 4.9 · desde $32.000 · Hasta 12 km cubre sin extra de traslado».
- Ubicación del trabajo: caja «Calle, barrio o ciudad» + **«Buscar»**, botón **«Usar GPS»** u «o marca el punto en el mapa».
- Recargo de traslado por km fuera del radio (`shared` → `transportSurcharge`, `withinTravelRange`).

**App — inicio cliente** (`features/user/presentation/pages/user_home_page.dart`): «¿Qué necesitas hoy?», «Buscar servicios...», «Servicios disponibles», pestañas Inicio / Mis Proyectos / Mensajes / Perfil.
**App — lista de profesionales** (`worker_list_page.dart`, `worker_search_map.dart`): modos **«Búsqueda Inteligente»** (mapa) y **«Lista Manual»**, «Selecciona tu ciudad», «Usar GPS», «Élite del mes», «Disponible ahora / Ocupado», filtro «Calificación mín.» y «Ordenar por».

### 2.3 Perfil del profesional y horarios libres

- **App — «Perfil del trabajador»** (`worker_detail_page.dart`): «Sobre mí», «Especialidad», **portafolio** (fotos y videos, «Transformación Destacada (Antes vs Después)» con slider), **«Cobertura en el mapa»**, **«Opiniones de clientes»** (`worker_reviews_section.dart`), botón **«Crear solicitud de servicio»**.
- **Horarios**: solo se ofrecen horas **publicadas por el profesional y todavía libres** (RPC `horarios_libres_profesional`, `shared/src/repositories/workers.ts`). Texto app: «Solo se muestran las horas que el profesional publicó y que siguen libres.» (`time_slot_selector.dart`).
- **Web — «RESERVA RÁPIDA»** (`components/QuickBookingBar.tsx`, `web16x9_06_profesional_reserva_rapida.png`): «¿Cuándo necesitas el servicio?», «Elige una hora publicada por el profesional. Cada bloque aparece una sola vez.», selector «lunes | 16 de noviembre, 09:00…» (bloques 09:00, 11:00, 14:00, 16:00, 18:00 en el profesional de la captura), resumen «$32.000 / visita», botón **«Continuar con la reserva →»**.
- **App — «Agendar visita»** (`quick_booking_page.dart`): Fecha de visita, Horario, Dirección, «Notas (opcional)», botón **«Continuar al pago»**. Alternativa «Solicitar Servicio» (`service_request_page.dart`) con descripción (mín. 10 caracteres), ubicación en mapa y cuestionario de forma de cobro.

### 2.4 Pago Webpay (retenido = garantía)

Patrón (README §Dinero): **la app nunca pide ni guarda el número de tarjeta**; se paga en Transbank. El commit deja el pago **`retenido`**; se **libera** al profesional solo con la conformidad del cliente (o por plazo/disputa). Comisión de plataforma **15 %** (`shared/src/metrics/period.ts`).

**Web con sesión** (`components/PaymentCheckoutModal.tsx`, `web_e2e_09_confirmar_pedido_con_sesion.png`): diálogo **«Confirmar pedido»**, total **«32.000 CLP»**, aviso «El pago queda retenido — El monto queda retenido hasta que recibas el trabajo.», botón **«Continuar a Webpay · CLP 32.000»** («Creando pedido y abriendo Webpay…»). El trabajo se crea recién al pagar.
**Web sin sesión** (`components/GuestCheckoutForm.tsx`, `web16x9_07_checkout_invitado.png`): «Pedido sin sesión — **Datos para la visita**»: nombre completo, correo, teléfono (+56 9…), dirección del trabajo; verificación anti‑robots Cloudflare Turnstile; botón **«Continuar a Webpay · CLP 32.000»**. Al volver pagado: **«Crea tu contraseña»** para quedar con cuenta.
**App** (`core/widgets/escrow_checkout_sheet.dart`, `payments/.../payment_screen.dart`, `card_enrollment_page.dart`): «Pago Webpay — Confirmar pedido — **Primera confirmación: el monto queda retenido en Transbank. Se libera solo cuando recibas conforme el trabajo.**». Opciones: **Oneclick** («Inscribir tarjeta en Transbank», luego «Confirmar con tarjeta») o **«Pagar en Transbank sin guardar tarjeta»** (Webpay Plus dentro de un WebView). Captura de la pantalla de tarjeta: `app_e2e_tarjeta_oneclick.png`.
**Transbank (integración)**: formulario Webpay real de pruebas (`web_e2e_10_webpay_formulario.png`, `web_e2e_11_webpay_tarjeta_prueba.png` con la Visa de prueba pública 4051 8856 0044 6623), página de banco de prueba (`web_e2e_12_webpay_banco_prueba.png`, `web_e2e_12b_webpay_autorizar.png`).
**Resultado**: Edge Function `webpay-commit` → pago `retenido`, trabajo `pendiente`. App: «**Pago retenido en garantía** — El cobro fue aprobado y los fondos quedan en garantía hasta que el especialista ejecute el servicio.» (`payment_result_screen.dart`). Web: «Pedido confirmado / Pago recibido / Pago protegido» (`PaidReturnView.tsx`).
**Cancelar en Webpay**: la portada muestra «Pago cancelado. No se realizó ningún cargo.», pago `anulado`, trabajo `cancelado` (`web_e2e_15_pago_cancelado.png`; DEMO.md §4).
Reconciliación automática: cron `mwa_webpay_reconcile` cada 5 min (`webpay-reconcile`); pedidos `esperando_pago` sin garantía se cierran a los 30 min (cron `mwa_expirar_pagos_abandonados`, cada 10 min).

### 2.5 Seguimiento del trabajo (estados)

Línea de tiempo (`features/jobs/presentation/widgets/job_status_timeline.dart`; etiquetas en `job_detail_helpers.dart` y `shared/src/jobs/statusCopy`):

**Pendiente → Aceptado → En camino → En Curso → Pendiente de aprobación → Completado**
(terminales: Cancelado / Expirado / No asistió; estados previos posibles: Pago pendiente, Esperando cotizaciones).

- **Web — seguimiento** (`components/TrackingDashboard.tsx`, `web_e2e_13_seguimiento_pin_inicio.png`): título del servicio, ID del pedido, dirección, recuadro **«Llegada»** (minutos estimados a **28 km/h**, «sin tráfico en vivo»; «Sin GPS» si aún no hay posición), ficha «TRABAJADOR» con ★ y trabajos, «ESTADO ACTUAL», **«PIN PARA INICIAR — 3 6 3 3 — Díselo al profesional cuando llegue. Sin este PIN no puede dejar el trabajo en curso.»**, «Evidencia», **«Abrir chat»**, «Ver detalles del pago». Se refresca cada 8 s (`App.tsx`).
- **App — «Detalles del Trabajo»**: misma información + tarjeta **«PIN para iniciar»** con botón copiar («PIN copiado») (`client_start_pin_card.dart`) y **«Ubicación en vivo»** (`client_live_tracking.dart`).
- El PIN solo se muestra al **cliente** y solo en `aceptado` / `en_camino` (`shared/src/jobs/startPin.ts` → `START_PIN_VISIBLE_STATUSES`); al iniciar el trabajo desaparece.

### 2.6 Conformidad, liberación y calificación

- Cuando el profesional termina, el trabajo queda **«Pendiente de aprobación»** con la evidencia (fotos/videos en depósito privado, enlace temporal).
- **App** (`job_detail_client_approval_card.dart`): «Ver evidencia (fotos y videos)», **«Segunda confirmación: recibo conforme»** → diálogo «Recibo conforme» → **«Liberar fondos»** → «Trabajo recibido conforme. Los fondos quedaron liberados.»; o **«No estoy conforme»** → «Abrir ticket».
- **Web**: botón **«Recibo conforme»** → «Liberando el pago…» → **«Pago liberado — Recibiste conforme. El pago retenido quedó liberado.»** (`web_e2e_14_pago_liberado.png`). RPC `cerrar_trabajo_conforme`. **No es un segundo cargo.**
- Si el cliente no responde en **48 h** (valor en vivo `soporte_plazo_silencio_horas = 48`) y hay evidencia, el sistema libera solo («El cliente no respondió dentro del plazo. El pago queda liberado.» — cron `mwa_resolver_soporte_automatico`).
- **Calificar** (solo app, `ratings/presentation/pages/rating_page.dart`): «Calificar Trabajo — ¿Cómo fue tu experiencia?» estrellas 1‑5, «Comentario (opcional)», **«Enviar Calificación»**. Bloqueada si hay disputa abierta. Las notas alimentan el ranking y el «Élite del mes».

### 2.7 Cancelación, rechazo y disputas

- **Cliente cancela** solo mientras está **Pendiente** («Cancelar Solicitud» → «¿Estás seguro…?» → «Sí, cancelar»). Si había pago retenido se devuelve a la tarjeta (`webpay-refund-cancellation`).
- **Profesional rechaza** un pedido pendiente («Rechazar» → «Sí, rechazar») → reembolso automático a la tarjeta y trabajo cancelado (`webpay-refund-rejection`).
- **Disputa** («Abrir disputa», app y web): el pago **sigue retenido**. «Resolver entre ustedes»: **Aceptar la entrega / Pedir que lo rehaga / Anular y devolver el pago**; la otra parte confirma o rechaza. Casos simples se cierran solos al vencer el plazo (24 h, montos hasta $80.000); conducta, reincidencia o montos altos los ve una persona en la consola (`webpay-resolve-dispute`).
- No existe «reprogramar» en ningún cliente (verificado en E2E del 15‑nov).

### 2.8 Chat y notificaciones

- **Chat por trabajo** (app `chat/presentation/pages/chat_page.dart`, «Mensajes» en `conversations_page.dart`; web `LiveChatWidget.tsx` «Abrir chat», «Escribe un mensaje...»). Tiempo real con Supabase Realtime.
- **Notificaciones**: centro «Notificaciones» con «Marcar todas como leídas» (app), campana en la web. Push FCM opcional (`docs/PUSH_NOTIFICACIONES.md`; apagado si no hay variables `FCM_*`).

---

## 3. Rol PROFESIONAL («Especialista», solo app móvil)

1. **Registro** como Especialista → **«Completa tu perfil»** (`worker/.../worker_register_page.dart`): profesión, zona de trabajo, «Descripción profesional».
2. **Verificación** (`worker_verification_card.dart`): «RUT, oficio y comuna» o foto del documento → **«Enviar a revisión»** → estados Pendiente / **En revisión** / **Verificado** / Rechazado. «Hasta entonces no apareces como verificado.» Sin verificación no puede cobrar («Este profesional todavía no está verificado para cobrar»).
3. **Tarifas** (`worker_pricing_setup_page.dart`): «Configura tus precios», servicios de la app y adicionales, cobro por m² para «Proyecto grande», **«Guardar tarifas»**.
4. **Horario semanal** (`worker_schedule_page.dart`): Lunes…Domingo, «Usar este horario», **«Guardar horario»**. De aquí salen los bloques libres que ve el cliente.
5. **Panel del profesional** (`worker_home_page.dart`): «Tu disponibilidad» (interruptor «Activar disponibilidad» / «Estás disponible para nuevos trabajos»), «Resumen de trabajos» (pendientes, en curso, finalizados), accesos rápidos «Nuevo trabajo · Mi agenda · Ingresos · Historial», «Mis cobros», «Calificaciones», «Disputas», «Mensajes».
6. **Recibe un pedido** (tarjeta PENDIENTE) → «Ver detalles del trabajo». Ve la **reputación del cliente** antes de decidir. Botones **«Aceptar Trabajo»** / **«Rechazar»** (`job_detail_actions_section.dart`).
7. **«Voy en camino»** → la app publica su GPS **solo en primer plano**, como máximo **cada 20 s o 40 m** (`core/services/gps_publish_gate.dart`; «Compartiendo ubicación en primer plano. Se detiene si cierras la app o termina el trabajo.» — `worker_gps_publisher.dart`). El cliente ve el pin moverse.
8. **«Iniciar trabajo»** (botón visible en *En camino*) → diálogo **«Iniciar trabajo — Pide al cliente el PIN de 4 dígitos que aparece en su pedido y escríbelo aquí.»** con teclado numérico y 4 puntos, botón **«Confirmar PIN»** (`core/widgets/design_system/service_pin_dialog.dart`, `jobs/.../job_detail_status.dart`).
   - Servidor (`supabase/migrations/20261115180001_inicio_trabajo_requiere_pin.sql`): PIN aleatorio de 4 dígitos por trabajo, tabla privada; el profesional **no puede leerlo**. `intentar_pin_inicio` valida; PIN correcto abre una ventana de **2 minutos** para pasar a `en_curso`. **5 intentos fallidos → bloqueo de 15 minutos** («Demasiados intentos fallidos. Espera 15 minutos para volver a ingresar el PIN.»). Un UPDATE directo a `en_curso` está bloqueado por trigger. Solo el admin puede saltarse el PIN.
9. **En Curso**: GPS sigue activo, chat, **«Subir evidencia»** (`job_photos_page.dart`: «Tomar foto», «Elegir foto de galería», «Elegir video»; «Sube al menos una foto o un video del trabajo realizado»). Sin evidencia no puede finalizar. En bloques por hora: «Solicitar horas extra»; cobro adicional con «Solicitar cobro adicional» (el cliente «Aprobar y pagar»).
10. **«Finalizar Trabajo»** (o «Finalizar y enviar evidencia») → estado **Pendiente de aprobación**.
11. Tras la conformidad: **«Calificar al cliente»** («Esta nota queda en el perfil del cliente. No mueve el pago.»).
12. **Mis cobros / Liquidaciones** (`worker_payouts_page.dart`): cuenta bancaria (Banco, tipo de cuenta, RUT del titular), montos «Por pagar» / «Pendiente de transferencia» / «Transferido». La transferencia al profesional hoy es **manual** registrada por un admin. **Estadísticas** (`statistics_page.dart`).

---

## 4. Rol ADMINISTRADOR (consola de escritorio)

`myworksapp_desktop` (React + Tauri; ventana nativa Windows/macOS/Linux; también en `http://127.0.0.1:3001`).
1. **Login** «Consola operativa — Supervisa. Gestiona. Resuelve.» con «Seguridad empresarial · Visibilidad en tiempo real · Control de acceso basado en roles», «Conexión cifrada TLS 1.3 · Acceso solo con rol administrador · Sesión protegida» (`components/DesktopLoginScreen.tsx`; `desk_01_login_consola.png`).
2. **Segundo factor obligatorio** (TOTP con app autenticadora, QR la primera vez): «Confirma que eres el administrador» (`AdminMfaGate.tsx`). En vivo `admin_requiere_aal2 = 1`.
3. **Panel ejecutivo**: **GMV**, **Comisión (15 %)**, Ticket promedio, **CSAT**, Trabajos completados/activos, Disputas abiertas; períodos 24 horas / 7 días / 30 días / 90 días; «Pagos en custodia», «Cobros que requieren atención» (`ExecutiveWorkspace.tsx`, `ExecutivePeriodPanel.tsx`).
4. **Trabajadores**: lista real; los «En revisión» traen **«Aprobar» / «Rechazar»** (verificación).
5. **Soporte y disputas**: «Centro de Mediación», tickets con expediente y evidencia; «Resolución del pago retenido» — liberar al profesional o devolver a la tarjeta (`SupportWorkspace.tsx`). «Liquidación manual» al profesional (`FinancialSettlementModal.tsx`).
6. **Seguridad (DevSecOps)**: salud del sistema, latencia de Supabase, controles de calidad que corren en GitHub Actions (`DevSecOpsWorkspace.tsx`).
7. **RRHH**: «Directorio de empleados», «Invitar colaborador» (roles soporte / QA) (`HumanResourcesWorkspace.tsx`).
- La app Flutter también trae pantallas admin (`features/admin/...`: usuarios, trabajadores, trabajos, disputas, pagos, ranking, feature flags), pero la consola oficial es la de escritorio.
- ⚠️ `DigitalContractModal.tsx` dice explícitamente «DEMO — no es firma electrónica legal (Ley 19.799)»: no presentarlo como contrato legal.

---

## 5. Seguridad que vale la pena contar (real)

- RLS en todas las tablas expuestas; cambios de estado solo por RPC `transicionar_trabajo` (se revocó UPDATE/DELETE directo sobre `trabajos`).
- PIN de inicio (ver 3.8), GPS solo en primer plano, evidencia en depósito privado con enlaces temporales.
- MFA para administradores, Turnstile anti‑bots en el checkout de invitado, reconciliación automática de pagos cada 5 min.
- Pruebas: CI (analyze/test Flutter, lint/build web y escritorio), pruebas RLS SQL, E2E Playwright del 15‑nov (PIN + Webpay) y pruebas de carga k6 (`docs/RUNBOOK_CAPACIDAD_CARGA.md`).

---

## 6. Dudas / cosas a confirmar antes de producir

1. **Mapa base de la web**: CARTO hoy responde «API KEY REQUIRED» en todas las baldosas (`VITE_CARTO_BASEMAPS_KEY` vacío en `.env.local`). Las capturas `web16x9_*` y `mob_*` se tomaron **sustituyendo** las baldosas por OpenStreetMap estándar (las mismas que usa la app Flutter, `core/map/app_map_tiles.dart`). Las capturas `web_e2e_13/14` muestran la marca de agua: en el video, reemplazar el fondo del mapa. **Recomendación: poner una clave CARTO (o cambiar a OSM) antes de la presentación.**
2. Leyenda del mapa web se superpone al texto «3 en el mapa · plomería» (detalle visual menor; en la animación, recrear la leyenda limpia).
3. No hay capturas reales de las pantallas **con sesión** de la app Flutter (panel del profesional, diálogo PIN, detalle del trabajo) ni de la consola **después** del MFA: requieren contraseña de las cuentas demo (el archivo local ya no existe) y TOTP del admin. Se describen desde el código; para el video recrearlas como mockups fieles (textos exactos de este documento) o grabarlas en el emulador.
4. `demo_modo = 0` en vivo, pero el login de la app sigue listando «Cuentas demo» al elegir Especialista (`app_03b_login_especialista.png`, lista local de `demo_credentials.dart`). No mostrar esa lista en el video.
5. La app y la web hablan de «Especialista» (rol en la app) y «Trabajador/Profesional» (textos). En el video usar **«profesional»** en la voz y respetar la etiqueta exacta en pantalla.
6. Precios y nombres de las capturas son datos de prueba (Puerto Montt, p. ej. Mateo Oyarzo $32.000). Usarlos tal cual o rotular «datos de demostración».

---

## 7. Índice de capturas (`/workspace/mwa_video/screens/`)

Reales tomadas hoy (15‑nov‑2026, web local contra Supabase en vivo, sin crear datos):
- `web16x9_01_portada.png` — portada (3200×1800, 16:9)
- `web16x9_02_como_funciona.png` — sección «Cómo funciona»
- `web16x9_03_login.png` — modal de inicio de sesión
- `web16x9_04_busqueda_mapa.png` — resultados «plomería» + mapa
- `web16x9_05_filtro_calificacion.png` — filtro «4.5 y más»
- `web16x9_06_profesional_reserva_rapida.png` — profesional elegido + círculo de cobertura + barra «Reserva rápida»
- `web16x9_07_checkout_invitado.png` — «Datos para la visita» (sin sesión)
- `web_01_portada.png`, `web_01b_portada_completa.png`, `web_02_login.png`, `web_03_registro.png`, `web_04_como_funciona.png`, `web_05_categorias.png` — 1280×900
- `mob_01_portada*.png`, `mob_03_login.png`, `mob_04_busqueda_mapa.png`, `mob_06_profesional_reserva_rapida.png`, `mob_07_checkout_invitado.png` — web en teléfono (390×844 @2x) para el corte 9:16
- `app_01_onboarding_1..4.png`, `app_02_bienvenida.png`, `app_03_login.png`, `app_03b_login_especialista.png` (no usar: lista demo), `app_04_registro.png` — app Flutter real (build web de la misma app), 412×892 @2.6x
- `desk_01_login_consola.png` — consola de escritorio, login

Reales de la corrida E2E del 15‑nov (pedido de prueba ya limpiado; mapa con marca de agua CARTO):
- `web_e2e_09_confirmar_pedido_con_sesion.png`, `web_e2e_10_webpay_formulario.png`, `web_e2e_11_webpay_tarjeta_prueba.png`, `web_e2e_12_webpay_banco_prueba.png`, `web_e2e_12b_webpay_autorizar.png`, `web_e2e_13_seguimiento_pin_inicio.png`, `web_e2e_14_pago_liberado.png`, `web_e2e_15_pago_cancelado.png`, `app_e2e_tarjeta_oneclick.png`

Marca: `/workspace/mwa_video/brand/` (`mark.svg`, `mark_2048.png`, `logo-mark.png`, `app_icon_desktop.png`, `design-tokens.json/.css`, `welcome_hero.jpg`, `categorias/`, `duoc-uc-logo.png`, `mockups_diseno/` = conceptuales).

---

## 8. Actualizaciones (15-nov-2026, 22:00 hora de Chile)

- **URL pública (CTA del video):** `https://myworksapp-cl.vercel.app` (responde 200).
- **Botón de pago web:** con sesión «Confirmar pedido · CLP 32.000» (`PaymentCheckoutModal`, captura `web_e2e_09` / `E2E/A_01`); invitado «Continuar a Webpay · CLP 32.000» (`GuestCheckoutForm`, `web16x9_07`). Corrige la línea de §2.4 que atribuía «Continuar a Webpay» al flujo con sesión.
- **Cifras de Mateo** (detalle en `fix_cifras_mateo.md`):
  - «★ 4.9 (0 trabajos)» en el seguimiento web: **corregido en producción** (commit `0fd5f44`; lee los trabajos completados reales y muestra «Nuevo» si la nota es 0). Hay que recapturar `E2E/C_08`, `C_16` y `C_17`.
  - Nota 4.9 vs 5.0 y contador de trabajos: vienen del seed de demostración sin reseñas reales. **PR pendiente** para respaldar el seed con trabajos y reseñas reales.
  - «↑ 12 % vs. mes anterior»: era un **valor fijo** (`worker_earnings_summary.dart`, `growthPercent = 12`). El mismo PR lo cambia por el crecimiento real.
  - Hasta el merge + deploy + seed: no mostrar estas cifras en primer plano y no usar `W_22`.
