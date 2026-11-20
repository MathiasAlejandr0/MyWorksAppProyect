# Estado del proyecto — MyWorksApp

Documento de referencia para **memoria de título**, **presentaciones universitarias**, **financiamiento** y **planificación técnica**.

**Última actualización:** 20 de noviembre de 2026, sobre `main` `08154dfc` de `nicoussj/Proyecto-Titulo-MyWorksApp` (merge del PR #81).  
**Versiones:** app Flutter 1.0.11+12 (`pubspec.yaml`); web 1.0.0 y consola 0.1.0 (`package.json`, `tauri.conf.json`).  
**Repositorio:** https://github.com/nicoussj/Proyecto-Titulo-MyWorksApp (el espejo `MathiasAlejandr0/MyWorksAppProyect` tiene un historial distinto y no se usa como fuente).

---

## Resumen ejecutivo

| Aspecto | Estado actual |
|---------|---------------|
| **Tipo de producto** | Monorepo: app móvil Flutter + web de clientes (React/Vite) + consola operativa de escritorio (Tauri 2 + React) + módulo `shared/` en TypeScript |
| **Backend** | Supabase (Auth + PostgreSQL + PostgREST + RLS + Realtime + Edge Functions + pg_cron) |
| **Web en producción** | https://myworksapp.cl y `www.myworksapp.cl` en Vercel (proyecto `myworksapp`); también responde https://myworksapp-cl.vercel.app |
| **Dominio y borde** | `myworksapp.cl` en Cloudflare (DNS y Turnstile). Cloudflare Email Routing para `soporte@myworksapp.cl`: **en configuración** |
| **Correo** | Supabase Auth usa el SMTP de Resend (dominio verificado, DKIM y SPF en `send.myworksapp.cl`, región sa-east-1, plan gratis de 100 correos al día). Remitente `no-responder@myworksapp.cl`, 13 plantillas en español |
| **Pagos** | Transbank Webpay Plus y Oneclick Mall en **ambiente de integración**: solo tarjetas de prueba, ningún cobro real |
| **Listo para producción / tiendas** | Parcial: falta Transbank en producción, push remoto desplegado y publicación en tiendas |
| **Documentación técnica en repo** | [README.md](README.md), [DEMO.md](DEMO.md), [INSTALL.md](INSTALL.md), [docs/casos_de_uso.md](docs/casos_de_uso.md), [docs/deploy_web.md](docs/deploy_web.md), [docs/ARQUITECTURA_MODALIDADES_COBRO.md](docs/ARQUITECTURA_MODALIDADES_COBRO.md) |

**Mensaje clave:** MyWorksApp demuestra un **marketplace de servicios del hogar** con roles duales (cliente y profesional), ciclo de vida de trabajos controlado en la base, pago retenido en garantía con Transbank en integración y una consola interna con segundo factor y bitácora inmutable.

### Inventario contado desde el código (`main` `08154dfc`)

| Elemento | Cantidad | Fuente |
|---|---|---|
| Migraciones SQL | 125 (primera `20250607000001`, última `20261120170000`) | `myworksapp_app/supabase/migrations/*.sql` |
| Edge Functions | 18 (más el código común `_shared/`) | `myworksapp_app/supabase/functions/` |
| Tablas del esquema `public` | 60: las 57 del snapshot del 17-nov (`docs/_schema_public.json`) más `auditoria_consola`, `rate_limit_ventana` y `direcciones_cliente`, creadas por migraciones del 20-nov | migraciones `20261120130000`, `20261120150000`, `20261120170000` |
| Vistas | 2: `encuestas_testing_con_puntaje` y `cobros_profesional` (`20261118053913`) | migraciones |
| Tipos ENUM | 1: `accion_auditoria_consola` (27 acciones) | `20261120130000_auditoria_consola.sql` |
| RPC de la consola `consola_*` | 17 | migraciones |
| Tareas pg_cron | 3: `mwa_webpay_reconcile` (cada 5 min), `mwa_expirar_pagos_abandonados` (cada 10 min) y `mwa_resolver_soporte_automatico` (cada 10 min) | migraciones `20261115060002`, `20261008000006`, `20261112000001` |
| Workflows de GitHub Actions | 6 | `.github/workflows/` |
| Casos de uso | 34 (CU-01 a CU-34) | `docs/casos_de_uso.md` |

Edge Functions en el repositorio: `definir-clave-invitado`, `guest-checkout`, `invitar-colaborador`, `oneclick-charge`, `oneclick-handoff`, `oneclick-return`, `send-push`, `soporte-automatico`, `webpay-commit`, `webpay-create`, `webpay-handoff`, `webpay-reconcile`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-refund-rejection`, `webpay-release`, `webpay-resolve-dispute` y `webpay-status`.

Según el reporte de despliegue del 20-nov, `send-push` y `soporte-automatico` **no están desplegadas** en el proyecto en vivo. No se pudo verificar desde el repositorio el estado de `oneclick-handoff` ni de `webpay-handoff`.

---

# Parte I — Arquitectura de software

## 1. Tipo de arquitectura utilizada

### Nombre formal

**Arquitectura modular por funcionalidades (Feature-First) con capas horizontales compartidas**, inspirada en **Clean Architecture** de forma **pragmática** (no estricta).

En informes académicos puede describirse como:

> *Arquitectura en capas híbrida: presentación organizada por features, con dominio, aplicación e infraestructura centralizados en un núcleo compartido (`core/`).*

### Diagrama conceptual

```
┌─────────────────────────────────────────────────────────────┐
│  CAPA DE PRESENTACIÓN (UI)                                  │
│  lib/features/*/presentation/  +  lib/core/widgets/         │
│  Páginas, widgets, providers Riverpod por módulo            │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  CAPA DE APLICACIÓN (casos de uso / orquestación)           │
│  lib/core/services/                                         │
│  JobBookingService, JobStateMachine, PricingService, etc.     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  CAPA DE DOMINIO (reglas de negocio puras)                  │
│  lib/core/domain/                                           │
│  PriceQuote, PricingConstants, catálogos de oficios         │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  CAPA DE DATOS (persistencia y APIs)                        │
│  lib/core/database/models/ + repositories/                  │
│  Mapeo Supabase ↔ modelos Dart                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  INFRAESTRUCTURA EXTERNA                                    │
│  Supabase Auth · PostgreSQL · PostgREST · RLS               │
└─────────────────────────────────────────────────────────────┘
```

### Estructura de carpetas (`lib/`)

```
lib/
├── main.dart                 # Arranque: Supabase + ProviderScope
├── app.dart                  # MaterialApp.router, tema, inicialización
├── bootstrap/
│   └── app_initializer.dart  # Health check, sesión, notificaciones
├── core/                     # Núcleo compartido (todas las capas no-UI)
│   ├── config/               # Supabase, credenciales demo
│   ├── database/
│   │   ├── models/           # Entidades de persistencia (28 modelos)
│   │   ├── repositories/     # Acceso a tablas Supabase
│   │   └── supabase_db.dart  # Cliente global
│   ├── domain/               # Reglas y constantes de negocio
│   ├── services/             # Lógica de aplicación (~50 servicios)
│   ├── router/               # GoRouter + redirects por auth/rol
│   ├── theme/ + design_system/
│   ├── widgets/              # Componentes reutilizables
│   └── utils/                # Constantes, validadores, logger
└── features/                 # Módulos por funcionalidad (solo UI)
    ├── auth/
    ├── user/
    ├── worker/
    ├── jobs/
    ├── chat/
    ├── ratings/
    ├── notifications/
    ├── settings/
    ├── gdpr/
    ├── onboarding/
    └── role_selector/
```

Cada feature sigue: `features/<módulo>/presentation/{pages, widgets, providers}`.

---

## 2. Por qué se eligió esta arquitectura

| Criterio | Decisión | Justificación |
|----------|----------|---------------|
| **Organización del código** | Feature-first en UI | Equipos pequeños y proyectos académicos escalan mejor cuando cada pantalla/flujo vive junto a su módulo (`user/`, `worker/`, `jobs/`). Facilita localizar cambios. |
| **Lógica compartida** | `core/` centralizado | Usuario y trabajador comparten jobs, pagos, chat y notificaciones. Duplicar dominio por feature generaría inconsistencias. |
| **Clean Architecture parcial** | Dominio + repos + servicios separados de UI | Permite cambiar Supabase por otro backend sin reescribir pantallas; las reglas de precios y estados quedan testeables en aislamiento. |
| **No Clean estricta** | Sin capas domain/data por feature ni use cases formales | MVP con plazos acotados: prioriza entrega funcional. La deuda técnica es consciente y documentada. |
| **Estado global mínimo** | Riverpod solo en auth y router | Reduce complejidad; el resto usa `setState` local. Adecuado para MVP; escalaría con más providers por feature. |
| **Backend BaaS** | Supabase | Auth, PostgreSQL, RLS y API REST sin montar servidor propio — ideal para prototipo universitario con camino a producción. |

### Patrones de diseño identificables

| Patrón | Dónde | Para qué |
|--------|-------|----------|
| **Repository** | `core/database/repositories/` | Abstrae acceso a datos (tablas Supabase) |
| **Singleton (servicios)** | `JobBookingService.instance`, `PaymentService.instance` | Punto único de orquestación |
| **State Machine** | `JobStateMachine` + `JobTransitionMatrix` | Transiciones válidas según modalidad de cobro |
| **Guard** | `PaymentGuard`, `PricingGuardService` | Validaciones antes de cambiar estado o cobrar |
| **Provider (Riverpod)** | `authProvider`, `routerProvider` | Estado reactivo de sesión y navegación |
| **DTO / Model** | `JobModel`, `PriceQuote` | Separación entre persistencia y reglas de negocio |

---

## 3. Stack tecnológico

| Capa | Tecnología | Versión / nota |
|------|------------|----------------|
| Framework UI | Flutter / Dart | SDK ≥ 3.0 |
| Estado | flutter_riverpod | ^3.4.3 |
| Navegación | go_router | ^18.0.1 |
| Backend | supabase_flutter | Auth + Postgres + PostgREST |
| Mapas | flutter_map + OpenFreeMap Positron (vectorial, sin clave, respaldo OSM) en la app; Leaflet + OpenFreeMap Positron (MapLibre, sin clave) en la web | Ubicación de trabajos y catálogo |
| Notificaciones | flutter_local_notifications, firebase_messaging y Edge `send-push` | Locales, Realtime y push si el build trae las claves FCM |
| Persistencia local | shared_preferences | Onboarding y preferencias |
| Seguridad | Supabase Auth y RLS | La contraseña la guarda Auth; no hay bcrypt en la app |
| Fuentes / UI | google_fonts, design system propio | Identidad naranja / azul marino |

---

## 4. Flujos de negocio principales (implementados)

### Invitación a trabajador con tarifa publicada (flujo actual destacado)

1. El cliente elige profesional, servicio y una hora publicada y libre (`horarios_libres_profesional`).
2. Paga con Webpay Plus u Oneclick (Edge Functions `webpay-create` / `webpay-commit` u `oneclick-charge`): el pago queda **retenido** y el trabajo queda `pendiente`.
3. El profesional acepta o rechaza; al aceptar avisa «voy en camino» y comparte su ubicación.
4. Para iniciar ingresa el PIN de 4 dígitos que ve solo el cliente; luego sube evidencia (fotos WebP o video) → `esperando_aprobacion_cliente`.
5. El cliente da conformidad (`cerrar_trabajo_conforme`) → trabajo `completado` y pago `liberado`. Sin respuesta y con evidencia, el pago se libera a las 48 h. El administrador registra después la transferencia al profesional.

### Otras modalidades de cobro

| Modalidad | Descripción | Estado |
|-----------|-------------|--------|
| `legacy` | Flujo histórico / invitación sin pago anticipado | ✅ |
| `fixed_price` | Precio fijo por SKU | ✅ |
| `hourly_block` | Bloque de horas prepagado | ✅ |
| `open_quote` | Cotización abierta (RFP) | ✅ |

Detalle en [docs/ARQUITECTURA_MODALIDADES_COBRO.md](docs/ARQUITECTURA_MODALIDADES_COBRO.md).

---

## 5. Lo implementado (inventario técnico)

### Plataforma

- Flutter multiplataforma (Android como objetivo principal; el proyecto también compila para iOS, Windows, macOS y web).
- **Web de clientes** (`myworksapp_web`, React 19 + Vite 8): rutas `/`, `/servicios`, `/servicios/:categoria`, `/profesional/:id`, `/pedido/:id`, `/pago/retorno`, `/cuenta`, `/trabaja`, `/terminos`, `/privacidad` y `/encuesta`; cualquier otra muestra el 404. Turnstile en el registro y en la compra como invitado.
- **Consola operativa** (`myworksapp_desktop`, Tauri 2 + React 19): 20 módulos de menú más «Mi cuenta»; deep link `myworksapp-admin://auth/callback`; segundo factor TOTP; código TOTP otra vez para mover dinero si el último tiene más de 5 minutos; cierre de sesión tras 15 minutos sin uso (aviso a los 13); actualizador con un par de claves nuevo.
- Módulo compartido TypeScript (`shared/`): auth, repositorios, chat y filtro de contacto, pagos, métricas, agenda, evidencia y tipos alineados con Flutter (la CI compara el dominio TS con el Dart).
- Supabase: autenticación, perfiles, trabajos, pagos, chat, notificaciones, calificaciones, disputas y bitácora de la consola.
- RLS activo en las 60 tablas de `public` (`rate_limit_ventana` no tiene políticas: solo la usa `service_role`).
- Límite de tasa global en Postgres (`rate_limit_consumir`) usado por `guest-checkout`, `definir-clave-invitado`, `webpay-create` y `oneclick-charge`.
- Bootstrap centralizado y health check del backend.

### Roles y módulos

| Módulo | Responsabilidad |
|--------|-----------------|
| `auth` | Login, registro, recuperación de contraseña |
| `user` | Home, listado de trabajadores, solicitud de servicio, perfil |
| `worker` | Dashboard, aceptar/rechazar, estadísticas, tarifas por oficio |
| `jobs` | Detalle, historial, evidencia, estados, cotizaciones |
| `chat` | Mensajería por trabajo |
| `ratings` | Calificación post-servicio |
| `notifications` | Centro de notificaciones |
| `gdpr` | Privacidad, términos, derechos del usuario |
| `payments`, `inbox`, `onboarding`, `role_selector`, `settings`, `admin` | Pagos y tarjeta inscrita, bandeja, primera vez, elección de rol, ajustes y vistas administrativas de la app |

### Servicios clave

`JobStateMachine`, `JobBookingService`, `PricingService`, `PaymentService`, `NotificationService`, `SessionManager`, `WorkerJobRejectionService`, `OpenQuoteNotificationService`, `DemoTourService`.

### Cuentas demo

| Rol | Email | Contraseña |
|-----|-------|------------|
| Cliente | `camila.soto@demo.myworksapp.cl` | (la entrega el equipo; no se publica) |
| Trabajadores | `*@demo.myworksapp.cl` (ej. `carmen.lagos@…`) | (la entrega el equipo; no se publica) |
| Administración | `admin.ops@demo.myworksapp.cl` | (la entrega el equipo; no se publica) |

Las cuentas `@demo.com` son legado: el administrador `admin@demo.com` está suspendido (auditoría 2026-10-05).

Las cuentas `@demo.myworksapp.cl` y `@demo.com` se marcan con `es_demo` (migración `20261120140000`). Con `app_config.demo_modo = 1`, que es el valor en vivo informado el 20-nov, siguen visibles en el catálogo con el aviso «Datos de demostración»; con otro valor se ocultan y no se pueden reservar ni cobrar.

---

## 6. Lo pendiente (brecha hacia producción)

| Área | Estado | Prioridad |
|------|--------|-----------|
| Pasarela de pago | Webpay exige `TBK_ENV`. Sin la variable el checkout falla. En vivo se usa `integration`. Producción sigue en `docs/RUNBOOK_TRANSBANK_PRODUCCION.md` | Alta |
| Liquidación al profesional | El administrador confirma la transferencia bancaria (`provider=manual`). Khipu y Fintoc responden 501 hasta tener contrato y claves | Alta |
| Notificaciones push remotas (FCM / APNs) | `send-push` y `firebase_messaging` están en el repo, pero `send-push` no está desplegada en vivo (reporte del 20-nov) | Media |
| Soporte automático con devolución | La tarea `mwa_resolver_soporte_automatico` corre en SQL, pero la Edge Function `soporte-automatico` no está desplegada en vivo (reporte del 20-nov) | Media |
| Captcha de Supabase Auth | **No activado**: activarlo rompería hoy el login de la app, la consola y la recuperación de clave. La web envía el token de Turnstile al registrarse, pero mientras el captcha de Auth esté apagado el servidor no lo valida en el registro. `guest-checkout` sí lo valida | Media |
| Correos transaccionales | Hoy solo salen los correos de Supabase Auth. Los de pago, reembolso y liberación están en la rama `cursor/correos-resend` (sin merge) | Media |
| Buzón de soporte | Cloudflare Email Routing para `soporte@myworksapp.cl`: en configuración | Baja |
| Textos legales | `/terminos` y `/privacidad` existen, pero dicen que el texto oficial aún no está publicado | Media |
| Chat en tiempo real | ✅ Supabase Realtime (`postgres_changes` sobre `mensajes`): app `chat_page.dart`, web `LiveChatWidget.tsx`. El cobro en garantía también se frena si la descripción, la dirección o los mensajes del cliente traen datos de contacto (`20261120120000`) | — |
| Evidencia del trabajo | Fotos en WebP (`fotos_trabajo_exigir_webp`, bucket privado `evidencias`) y videos de hasta 20 MB | — |
| Tests automatizados | CI en verde sobre `08154dfc` (Flutter, web, consola, Tauri en Windows y Gitleaks). En el box, el 20-nov: `shared/` 231 de 231 y consola 12 de 12 | ✅ |
| CI/CD (GitHub Actions) | Un solo `.github` en la raíz del repo, con actions fijadas por SHA | ✅ |
| Consola de escritorio | En uso con datos reales. La prueba del 20-nov (`08154df`) encontró 24 errores; el más grave es que el módulo «Profesionales» responde 403 y no se puede verificar a nadie desde la consola. El arreglo está en la rama `cursor/consola-bugs` (sin merge) | Alta |
| Instalador de la consola | El par de claves del actualizador es nuevo; la privada no está en el repo y va como secrets `TAURI_SIGNING_PRIVATE_KEY` y `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`. Quien tenga la versión anterior debe reinstalar una vez | Media |
| Publicación en tiendas | No publicada | Alta (al lanzar) |

## 7. En desarrollo (pendiente, no está en producción)

Estas ramas existen en `nicoussj/Proyecto-Titulo-MyWorksApp` pero **no tienen merge en `main`**. Nada de lo que contienen está desplegado:

| Rama | Qué agrega |
|---|---|
| `cursor/aviso-academico-duoc-v2` | Banner de proyecto académico Duoc UC y páginas `/aviso-legal`, `/terminos` y `/privacidad` con texto basado en la Ley 19.628 |
| `cursor/correos-resend` | Correos transaccionales desde Edge Functions (`_shared/email_layout.ts` y `email_send.ts`): pago recibido, alta de invitado, reembolso, pago liberado e invitación; flujo para definir la contraseña en la consola y la app |
| `cursor/consola-bugs` | Arreglo de los 24 errores de la consola encontrados en la prueba del 20-nov |

### Historial de migraciones (diagnóstico 9-nov-2026)

- Las migraciones de `myworksapp_app/supabase/migrations/` **no arrancan en una base vacía**. Se probó aplicándolas en orden sobre PostgreSQL 17 local con los esquemas `auth` y `storage` simulados, sin tocar el proyecto remoto.
- Primer fallo: `20250607000001_security_hardening_roles_profiles.sql` crea un trigger sobre `public.profiles` antes de que exista; la tabla recién la crea el baseline `20250907120000`.
- Moviendo esas migraciones después del baseline, falla `20250907120002` porque `public.is_admin()` no está en ninguna migración (solo en `schema_remote_dump.sql`).
- Usando `schema_remote_dump.sql` como migración inicial, falla `20260322000001` porque usa `public.pagos` antes de los renombres a español (`20260914000001`–`04`).
- Causa: el esquema real se construyó en parte con 24 versiones aplicadas en el remoto que no tienen `.sql` en el repo (lista en `myworksapp_app/supabase/MIGRATIONS_INVENTORY.md`). No se reconstruyen porque no hay fuente.
- Opción propuesta, **no aplicada**: un baseline nuevo con el esquema vivo (dump `public` de la v2.3), dejando las migraciones anteriores como historial. Requiere un `db dump` del remoto con autorización del dueño.

---

# Parte II — Guía para redactar el documento profesional

Esta sección es la **plantilla punto a punto** de cómo debe estructurarse y redactarse el informe/memoria del proyecto. Puedes copiarla como esqueleto de tu documento Word/PDF/LaTeX.

---

## Cómo usar esta guía

- Cada apartado indica: **qué incluir**, **extensión sugerida**, **tono** y **señales de calidad** (✓ = debe cumplirse).
- Las secciones van en orden académico estándar (portada → anexos).
- Adapta nombres de institución, autores y fechas en la portada.

---

## 0. Elementos previos a la portada

| Elemento | Contenido | Señales ✓ |
|----------|-----------|-----------|
| **Hoja de identificación** (si la exige la universidad) | Código del proyecto, carrera, campus, año académico | Datos oficiales, sin abreviaturas ambiguas |
| **Declaración de originalidad** | Autoría, uso de IA (si aplica), fuentes citadas | Honestidad académica explícita |

---

## 1. Portada

**Qué incluir (en este orden, centrado o según norma institucional):**

1. Logo de la universidad / institución.
2. Título del proyecto: **MyWorksApp — Plataforma móvil para conexión entre usuarios y trabajadores de oficios**.
3. Subtítulo (opcional): *Aplicación Flutter con backend Supabase*.
4. Tipo de documento: *Memoria de título* / *Informe de proyecto* / *Tesis*.
5. Nombre(s) del autor(es).
6. Nombre del tutor o profesor guía.
7. Carrera y facultad.
8. Ciudad y fecha (mes y año).

**Tono:** formal, sin adornos innecesarios.

**Señales ✓**
- [ ] El título describe el **problema** o **solución**, no solo la tecnología ("App Flutter" solo no basta).
- [ ] Máximo 12–15 palabras en el título principal.
- [ ] Misma tipografía que el resto del documento (Times New Roman 12 o la que exija la norma).

---

## 2. Página legal / dedicatoria (opcional)

- Dedicatoria breve (máx. 5 líneas) o epígrafe.
- Agradecimientos (tutor, familia, financiamiento universitario).

**Señales ✓**
- [ ] Separado de la portada; no mezclar con el índice.

---

## 3. Resumen / Abstract

**Extensión:** 150–250 palabras (español) + opcional 150 palabras en inglés.

**Qué incluir en un solo párrafo estructurado:**

1. **Contexto:** mercado de servicios del hogar y problemática (informalidad, falta de confianza, coordinación).
2. **Objetivo:** desarrollar un MVP que conecte clientes con profesionales verificables.
3. **Método:** desarrollo ágil, Flutter, Supabase, arquitectura modular por features.
4. **Resultados:** app funcional con dos roles, ciclo de trabajo, cobro con Webpay en integración y evidencia.
5. **Conclusión:** viabilidad del modelo; trabajo futuro (pagos reales, tiendas).

**Palabras clave (5–7):** marketplace de servicios, Flutter, Supabase, arquitectura modular, oficios, escrow, aplicación móvil.

**Señales ✓**
- [ ] Sin citas ni referencias en el resumen.
- [ ] Sin siglas sin definir (definir MVP, RLS, etc. la primera vez).
- [ ] Cifras concretas si las hay (ej. "8 categorías de servicio", "16 perfiles demo").

---

## 4. Índice general

**Qué incluir:**
- Todas las secciones y subsecciones con numeración decimal (1, 1.1, 1.1.1).
- Número de página alineado a la derecha.
- Índice de figuras (si hay ≥ 3 diagramas o capturas).
- Índice de tablas (si hay ≥ 3 tablas).
- Índice de anexos.

**Herramientas:** usar los estilos de título de Word/LaTeX para que el índice se genere automáticamente.

**Señales ✓**
- [ ] La numeración del índice coincide exactamente con los títulos en el cuerpo.
- [ ] No incluir la portada ni el índice en la numeración de páginas del contenido (según norma: páginas romanas i, ii, iii para preliminares y arábigas desde Introducción).

---

## 5. Índice de abreviaturas y siglas

| Sigla | Significado |
|-------|-------------|
| API | Application Programming Interface |
| BaaS | Backend as a Service |
| CRUD | Create, Read, Update, Delete |
| MVP | Producto Mínimo Viable |
| RLS | Row Level Security |
| UI / UX | Interfaz / Experiencia de usuario |
| GDPR | Reglamento General de Protección de Datos |

**Señales ✓**
- [ ] Orden alfabético.
- [ ] Primera mención en el texto: "Row Level Security (RLS)".

---

## 6. Introducción (Capítulo 1)

**Extensión sugerida:** 3–5 páginas.

### 6.1 Contexto y motivación

- Crecimiento de apps de servicios (Uber, Rappi, modelos tipo Angi/HomeAdvisor).
- En Chile: oficios del hogar con alta informalidad; necesidad de trazabilidad, precio referencial y confianza.
- Oportunidad de un marketplace **especializado en oficios** con evidencia de trabajo y pago post-aprobación.

### 6.2 Problema

Redactar como pregunta o afirmación medible, por ejemplo:

> *¿Cómo diseñar e implementar una aplicación móvil que permita a usuarios solicitar servicios del hogar y a trabajadores gestionar el ciclo completo del trabajo —desde la invitación hasta el cobro— con trazabilidad y seguridad de datos?*

### 6.3 Objetivo general

> Desarrollar un producto mínimo viable (MVP) multiplataforma que conecte clientes con trabajadores de oficios, gestionando solicitudes, estados del trabajo, comunicación y un flujo de pago con Transbank Webpay en ambiente de integración, con arquitectura escalable.

### 6.4 Objetivos específicos

1. Implementar autenticación y perfiles duales (usuario / trabajador).
2. Diseñar catálogo de servicios y tarifas configurables por el profesional.
3. Modelar el ciclo de vida del trabajo con máquina de estados y modalidades de cobro.
4. Integrar backend Supabase con políticas RLS.
5. Validar la experiencia de usuario mediante prototipo funcional y cuentas demo.

### 6.5 Alcance y limitaciones

**Dentro del alcance:** app móvil Flutter, backend Supabase, flujos demo, escrow con Webpay en integración, evidencia foto/video.

**Fuera del alcance (v1):** pasarela real, publicación en tiendas, panel admin, matching geográfico avanzado.

### 6.6 Metodología de desarrollo

- Desarrollo iterativo/incremental.
- Prototipado de UI con design system propio.
- Validación con datos demo y pruebas manuales en dispositivo.

### 6.7 Estructura del documento

Párrafo que describe qué contiene cada capítulo siguiente ("El Capítulo 2 presenta el marco teórico…").

**Señales ✓**
- [ ] Objetivos en infinitivo (Implementar, Diseñar, Integrar).
- [ ] Alcance delimitado con franqueza (lo que **no** se hizo).
- [ ] Sin describir aún la implementación en detalle (eso va en capítulos posteriores).

---

## 7. Marco teórico / Antecedentes (Capítulo 2)

**Extensión:** 8–15 páginas.

### Secciones recomendadas

| Sección | Contenido |
|---------|-----------|
| 2.1 Marketplaces de servicios | Modelos de dos lados, comisiones, garantía de pago |
| 2.2 Aplicaciones móviles multiplataforma | Flutter vs nativo; costo/beneficio |
| 2.3 Arquitecturas de software | Capas, Clean Architecture, feature-first (citar Martin, Fowler o fuentes académicas) |
| 2.4 Backend as a Service | Supabase, Firebase; comparación breve y justificación de elección |
| 2.5 Seguridad en apps | Auth, RLS, OWASP móvil, protección de datos personales |
| 2.6 Trabajos relacionados | 3–5 apps o papers similares; tabla comparativa |

**Señales ✓**
- [ ] Mínimo 10 referencias bibliográficas en todo el documento.
- [ ] Citas en formato APA o el que exija la universidad.
- [ ] La justificación de Supabase y Flutter debe basarse en criterios, no en preferencia personal.

---

## 8. Análisis y diseño (Capítulo 3)

**Extensión:** 15–25 páginas. **Es el capítulo técnico central.**

### 8.1 Requerimientos

**Funcionales (ejemplos):**
- RF-01: El usuario debe poder registrarse e iniciar sesión.
- RF-02: El usuario debe solicitar un servicio a un trabajador específico con fecha y ubicación.
- RF-03: El trabajador debe aceptar/rechazar y ver ubicación exacta tras aceptar.
- RF-04: El trabajador debe subir evidencia y solicitar cierre del trabajo.
- RF-05: El usuario debe aprobar la finalización y pagar con Webpay (ambiente de integración).

**No funcionales:**
- RNF-01: Tiempo de respuesta de pantallas < 2 s en red normal.
- RNF-02: Datos sensibles protegidos por RLS.
- RNF-03: UI en español (Chile), formato de fecha `es_CL`.

Presentar en **tabla** con ID, descripción, prioridad (Alta/Media/Baja).

### 8.2 Casos de uso

- Diagrama UML de casos de uso (actor Usuario, actor Trabajador, sistema Supabase).
- Descripción textual de 3–5 casos de uso prioritarios (flujo principal + alternativas).

### 8.3 Arquitectura del sistema

**Incluir obligatoriamente:**
1. Diagrama de capas (usar el de la Parte I de este documento).
2. Diagrama de despliegue: App Flutter ↔ Supabase (Auth, DB, PostgREST).
3. Tabla de módulos `features/` y su responsabilidad.
4. Explicación de por qué Feature-First + `core/` (copiar y adaptar sección 2 de Parte I).

### 8.4 Diseño de datos

- Diagrama entidad-relación (tablas: `perfiles`, `trabajadores`, `trabajos`, `pagos`, `notificaciones`, `mensajes`, `fotos_trabajo`, etc.).
- Descripción de campos clave: `jobs.status`, `jobs.pricing_mode`, `jobs.pricing_snapshot`.

### 8.5 Diseño de comportamiento

- Diagrama de estados del trabajo (`pending` → `accepted` → `in_progress` → `awaiting_client_approval` → `completed`).
- Referencia a `JobTransitionMatrix` y modalidades de cobro.

### 8.6 Diseño de interfaz

- Capturas de pantallas principales (welcome, home, solicitud, detalle job trabajador, aprobación cliente).
- Paleta de colores y componentes del design system.
- Criterios de accesibilidad aplicados.

**Señales ✓**
- [ ] Cada figura con pie: "Figura 3.2. Diagrama de capas de MyWorksApp. Fuente: elaboración propia."
- [ ] Requerimientos trazables: cada RF debe aparecer en implementación o pruebas.

---

## 9. Implementación (Capítulo 4)

**Extensión:** 15–30 páginas.

### Estructura sugerida

| Sección | Qué documentar |
|---------|----------------|
| 4.1 Entorno de desarrollo | Flutter SDK, VS Code/Android Studio, cuenta Supabase, Git |
| 4.2 Estructura del repositorio | Árbol de carpetas comentado |
| 4.3 Configuración de Supabase | Auth, tablas, RLS, migraciones aplicadas |
| 4.4 Capa de datos | Repositorios, modelos, ejemplo de consulta |
| 4.5 Capa de servicios | `JobStateMachine`, `JobBookingService`, flujo de invitación tier |
| 4.6 Capa de presentación | Riverpod, GoRouter, ejemplo de pantalla |
| 4.7 Integraciones | Mapas, geolocalización, notificaciones locales |
| 4.8 Fragmentos de código | 5–10 listados **relevantes**, máx. 15 líneas cada uno |

**Señales ✓**
- [ ] Código en anexo o listados numerados; no páginas enteras de código en el cuerpo.
- [ ] Explicar el **porqué** de cada decisión técnica relevante.
- [ ] Mencionar migración de SQLite local a Supabase si el informe cubre la evolución del proyecto.

---

## 10. Pruebas y validación (Capítulo 5)

**Extensión:** 5–10 páginas.

### Contenido

| Tipo | Qué incluir hoy (estado real) |
|------|-------------------------------|
| Pruebas manuales | Matriz: caso de prueba, pasos, resultado esperado, OK/Falla |
| Pruebas de integración | Login → solicitud → aceptación → evidencia → pago |
| Pruebas de regresión | Checklist antes de cada demo |
| Pruebas automatizadas | Corrida del 15-nov-2026: Flutter 174, Playwright 17 (1 omitida), shared 110, escritorio 2. Detalle en `docs/anexos/2026-11-15-pruebas/REGISTRO.md` |
| Usabilidad | Tour guiado, feedback informal de usuarios demo |

**Tabla de ejemplo:**

| ID | Caso | Rol | Resultado esperado | Estado |
|----|------|-----|-------------------|--------|
| P-01 | Solicitar armado muebles pequeños | Usuario | Job creado en `pending` | ✅ |
| P-02 | Aceptar y ver mapa cuadrado | Trabajador | Dirección + fecha visibles | ✅ |
| P-03 | Finalizar con evidencia | Trabajador | Estado `awaiting_client_approval` | ✅ |
| P-04 | Aprobar y pagar | Usuario | `completed` + pago Webpay (integración) | ✅ |

La tabla de arriba es el ejemplo del flujo ya demostrado antes. La matriz de esta fecha, con lo que se recorrió y lo que no, está en `docs/anexos/2026-11-15-pruebas/REGISTRO.md`. El cobro Webpay, el teléfono y el hub no se volvieron a ejecutar el 15 de noviembre.

**Señales ✓**
- [x] Honestidad: `flutter test` quedó en 174 pruebas el 15-nov-2026, más Playwright, shared y escritorio. No cubren un pago real ni el teléfono.
- [ ] Evidencia: capturas o fotos de la app en uso.

---

## 11. Resultados (Capítulo 6)

- Qué se logró respecto a cada objetivo específico (tabla objetivo ↔ evidencia).
- Métricas si existen: número de pantallas, tablas en BD, tiempos de build.
- Demo en video o capturas del flujo completo.
- Limitaciones encontradas (RLS, Webpay solo en integración, etc.).

**Señales ✓**
- [ ] No confundir "resultados" con "conclusiones".
- [ ] Incluir al menos una comparación **antes/después** o **esperado/obtenido**.

---

## 12. Conclusiones (Capítulo 7)

**Extensión:** 2–4 páginas.

### Estructura

1. **Síntesis** del trabajo (1 párrafo).
2. **Cumplimiento de objetivos** (uno por uno).
3. **Aprendizajes técnicos** (arquitectura, Supabase, Flutter).
4. **Aprendizajes de negocio** (modelo marketplace, escrow, confianza).
5. **Trabajo futuro** (pagos reales, push, tests, tiendas, admin).
6. **Reflexión final** (viabilidad, impacto social en formalización de oficios).

**Señales ✓**
- [ ] No introducir temas nuevos.
- [ ] Tono conclusivo, sin copiar el resumen literalmente.

---

## 13. Referencias bibliográficas

- Formato APA 7 (o norma institucional).
- Incluir: documentación oficial Flutter, Supabase, artículos sobre marketplaces, libros de arquitectura (ej. Martin, *Clean Architecture*).
- Mínimo recomendado: **15 fuentes** (libros, artículos, documentación oficial, normas).

**Señales ✓**
- [ ] Toda cita en el texto aparece en referencias.
- [ ] URLs con fecha de consulta.

---

## 14. Anexos

| Anexo | Contenido sugerido |
|-------|-------------------|
| A | Manual de instalación ([INSTALL.md](INSTALL.md)) |
| B | Guion de demostración ([DEMO.md](DEMO.md)) |
| C | Credenciales y datos demo |
| D | Listados de código completos |
| E | Scripts SQL / migraciones Supabase |
| F | Capturas de pantalla adicionales |
| G | Política de privacidad y términos (resumen) |

**Señales ✓**
- [ ] Cada anexo referenciado en el texto ("ver Anexo B").
- [ ] Numeración independiente (Figura A-1, Tabla B-2).

---

## 15. Checklist final antes de entregar

### Formato
- [ ] Márgenes, interlineado y fuente según norma universitaria.
- [ ] Numeración de páginas correcta (romanos / arábigos).
- [ ] Índice actualizado automáticamente.
- [ ] Figuras y tablas con título y fuente.

### Contenido técnico
- [ ] Arquitectura explicada con diagrama y justificación.
- [ ] Stack actualizado (Supabase, no solo SQLite).
- [ ] Flujo de negocio principal documentado paso a paso.
- [ ] RLS y seguridad mencionados.
- [ ] Limitaciones y trabajo futuro explícitos.

### Calidad académica
- [ ] Objetivos medibles y conclusiones alineadas.
- [ ] Referencias completas.
- [ ] Sin plagio; fuentes citadas.
- [ ] Ortografía y coherencia revisadas.

### Evidencia del producto
- [ ] Capturas o video de la app funcionando.
- [ ] Repositorio Git accesible (si la universidad lo permite).
- [ ] Instrucciones para reproducir la demo.

---

## Numeración sugerida del documento completo

```
PORTADA
DEDICATORIA (opcional)
RESUMEN / ABSTRACT
ÍNDICE
ÍNDICE DE ABREVIATURAS

1. INTRODUCCIÓN
2. MARCO TEÓRICO Y ANTECEDENTES
3. ANÁLISIS Y DISEÑO DEL SISTEMA
4. IMPLEMENTACIÓN
5. PRUEBAS Y VALIDACIÓN
6. RESULTADOS
7. CONCLUSIONES

REFERENCIAS BIBLIOGRÁFICAS
ANEXOS
```

---

## Frases modelo para copiar y adaptar

**Arquitectura (para el informe):**

> "MyWorksApp adopta una arquitectura modular por funcionalidades en la capa de presentación, complementada con un núcleo compartido (`core`) que concentra la lógica de dominio, los servicios de aplicación y el acceso a datos mediante repositorios sobre Supabase. Esta organización equilibra la separación de responsabilidades propia de Clean Architecture con la velocidad de desarrollo requerida en un MVP académico."

**Justificación de Supabase:**

> "Se seleccionó Supabase como Backend as a Service por integrar autenticación, base de datos PostgreSQL y API REST con políticas de seguridad a nivel de fila (RLS), reduciendo el tiempo de desarrollo de infraestructura propia y manteniendo un camino claro hacia un despliegue productivo."

**Flujo de cobro:**

> "El flujo de invitación directa al profesional contempla pago diferido: el cliente solicita sin prepagar; el trabajador ejecuta el servicio y registra evidencia fotográfica o audiovisual; el cliente aprueba la finalización y recién entonces se libera el pago retenido en garantía (escrow), cobrado con Transbank Webpay en ambiente de integración, alineado con modelos de confianza de marketplaces de servicios."

---

## Enlaces internos del repositorio

| Documento | Uso en el informe |
|-----------|-------------------|
| [README.md](README.md) | Descripción general y stack |
| [DEMO.md](DEMO.md) | Anexo: guion de demostración |
| [INSTALL.md](INSTALL.md) | Anexo: instalación |
| [docs/ARQUITECTURA_MODALIDADES_COBRO.md](docs/ARQUITECTURA_MODALIDADES_COBRO.md) | Cap. 3: modalidades de cobro |
| [myworksapp_app/pubspec.yaml](myworksapp_app/pubspec.yaml) | Cap. 4: dependencias |
| **Este archivo** | Cap. 3–4: arquitectura + plantilla del informe |

---

*Documento mantenido por el equipo de desarrollo de MyWorksApp. Actualizar al cerrar cada hito mayor (backend, pagos, tiendas).*
