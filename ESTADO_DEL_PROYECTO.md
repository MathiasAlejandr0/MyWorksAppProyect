# Estado del proyecto — MyWorksApp

Documento de referencia para **memoria de título**, **presentaciones universitarias**, **financiamiento** y **planificación técnica**.

**Última actualización:** junio 2026  
**Versión de producto:** 1.0.0 (MVP con backend Supabase)  
**Repositorio:** https://github.com/MathiasAlejandr0/MyWorksAppProyect

---

## Resumen ejecutivo

| Aspecto | Estado actual |
|---------|---------------|
| **Tipo de producto** | MVP móvil multiplataforma (Flutter) |
| **Backend** | Supabase (Auth + PostgreSQL + PostgREST + RLS) |
| **Modo de operación** | Cliente-servidor: datos centralizados en la nube |
| **Listo para demo en vivo** | Sí (usuario y trabajador en dispositivos distintos o mismo dispositivo) |
| **Listo para producción / App Store** | Parcial — falta pasarela real, push remoto, CI/CD y tests automatizados |
| **Documentación técnica en repo** | Sí ([README.md](README.md), [DEMO.md](DEMO.md), [INSTALL.md](INSTALL.md), [docs/ARQUITECTURA_MODALIDADES_COBRO.md](docs/ARQUITECTURA_MODALIDADES_COBRO.md)) |

**Mensaje clave:** MyWorksApp demuestra un **marketplace de servicios del hogar** con roles duales (cliente y profesional), ciclo de vida de trabajos, modalidades de cobro, escrow simulado y arquitectura preparada para escalar a producción.

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
| Estado | flutter_riverpod | ^2.4.9 |
| Navegación | go_router | ^13.0.0 |
| Backend | supabase_flutter | Auth + Postgres + PostgREST |
| Mapas | google_maps_flutter + OpenStreetMap estático (desktop) | Ubicación de trabajos |
| Notificaciones | flutter_local_notifications | Locales; push remoto pendiente |
| Persistencia local | shared_preferences, flutter_secure_storage | Onboarding, tokens |
| Seguridad | bcrypt, RLS en Supabase | Contraseñas y políticas por tabla |
| Fuentes / UI | google_fonts, design system propio | Identidad naranja / azul marino |

---

## 4. Flujos de negocio principales (implementados)

### Invitación a trabajador con tarifa publicada (flujo actual destacado)

1. Usuario elige profesional y tipo de trabajo (ej. muebles pequeños/medianos/grandes con precio del trabajador).
2. Solicitud con ubicación (mapa), fecha/hora y descripción opcional → job `pending` en Supabase.
3. Trabajador acepta o rechaza → al aceptar ve mapa cuadrado, dirección y agenda.
4. Trabajador inicia trabajo → sube evidencia (foto y/o video) → estado `awaiting_client_approval`.
5. Usuario revisa evidencia → aprueba y paga (escrow **simulado**) → trabajo `completed` y pago liberado al trabajador.

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

- Flutter multiplataforma (Android, iOS, Windows, macOS, Web parcial).
- Supabase: autenticación, perfiles, trabajos, pagos, chat, notificaciones, ratings.
- RLS (Row Level Security) en tablas expuestas.
- Bootstrap centralizado y health check del backend.
- Design system y tour guiado no invasivo.

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

### Servicios clave

`JobStateMachine`, `JobBookingService`, `PricingService`, `PaymentService`, `NotificationService`, `SessionManager`, `WorkerJobRejectionService`, `OpenQuoteNotificationService`, `DemoTourService`.

### Cuentas demo

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Trabajadores | `*@demo.com` (ej. armadores IKEA) | `demo123` |

---

## 6. Lo pendiente (brecha hacia producción)

| Área | Estado | Prioridad |
|------|--------|-----------|
| Pasarela de pago real (Webpay, Stripe, etc.) | Mock / escrow simulado | Alta |
| Notificaciones push remotas (FCM / APNs) | Solo locales | Alta |
| Chat en tiempo real (WebSockets / Realtime) | Polling / local | Media |
| Supabase Storage para fotos y videos | Rutas locales del dispositivo | Media |
| Tests automatizados (`test/` vacío) | Sin suite Dart | Media |
| CI/CD (GitHub Actions) | Manual | Media |
| Panel de administración web | No existe | Baja |
| Publicación en tiendas | No publicada | Alta (al lanzar) |

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
4. **Resultados:** app funcional con dos roles, ciclo de trabajo, cobro simulado y evidencia.
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

> Desarrollar un producto mínimo viable (MVP) multiplataforma que conecte clientes con trabajadores de oficios, gestionando solicitudes, estados del trabajo, comunicación y un flujo de pago simulado con arquitectura escalable.

### 6.4 Objetivos específicos

1. Implementar autenticación y perfiles duales (usuario / trabajador).
2. Diseñar catálogo de servicios y tarifas configurables por el profesional.
3. Modelar el ciclo de vida del trabajo con máquina de estados y modalidades de cobro.
4. Integrar backend Supabase con políticas RLS.
5. Validar la experiencia de usuario mediante prototipo funcional y cuentas demo.

### 6.5 Alcance y limitaciones

**Dentro del alcance:** app móvil Flutter, backend Supabase, flujos demo, escrow simulado, evidencia foto/video.

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
- RF-05: El usuario debe aprobar la finalización y ejecutar el pago simulado.

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

- Diagrama entidad-relación (tablas: `profiles`, `workers`, `jobs`, `payments`, `notifications`, `messages`, `job_photos`, etc.).
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
| Pruebas automatizadas | **Pendiente** — documentar como trabajo futuro |
| Usabilidad | Tour guiado, feedback informal de usuarios demo |

**Tabla de ejemplo:**

| ID | Caso | Rol | Resultado esperado | Estado |
|----|------|-----|-------------------|--------|
| P-01 | Solicitar armado muebles pequeños | Usuario | Job creado en `pending` | ✅ |
| P-02 | Aceptar y ver mapa cuadrado | Trabajador | Dirección + fecha visibles | ✅ |
| P-03 | Finalizar con evidencia | Trabajador | Estado `awaiting_client_approval` | ✅ |
| P-04 | Aprobar y pagar | Usuario | `completed` + pago mock | ✅ |

**Señales ✓**
- [ ] Honestidad: indicar que no hay `flutter test` automatizado aún.
- [ ] Evidencia: capturas o fotos de la app en uso.

---

## 11. Resultados (Capítulo 6)

- Qué se logró respecto a cada objetivo específico (tabla objetivo ↔ evidencia).
- Métricas si existen: número de pantallas, tablas en BD, tiempos de build.
- Demo en video o capturas del flujo completo.
- Limitaciones encontradas (RLS, pagos mock, etc.).

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

> "El flujo de invitación directa al profesional contempla pago diferido: el cliente solicita sin prepagar; el trabajador ejecuta el servicio y registra evidencia fotográfica o audiovisual; el cliente aprueba la finalización y recién entonces se procesa el pago simulado en garantía (escrow), alineado con modelos de confianza de marketplaces de servicios."

---

## Enlaces internos del repositorio

| Documento | Uso en el informe |
|-----------|-------------------|
| [README.md](README.md) | Descripción general y stack |
| [DEMO.md](DEMO.md) | Anexo: guion de demostración |
| [INSTALL.md](INSTALL.md) | Anexo: instalación |
| [docs/ARQUITECTURA_MODALIDADES_COBRO.md](docs/ARQUITECTURA_MODALIDADES_COBRO.md) | Cap. 3: modalidades de cobro |
| [myworksapp/pubspec.yaml](myworksapp/pubspec.yaml) | Cap. 4: dependencias |
| **Este archivo** | Cap. 3–4: arquitectura + plantilla del informe |

---

*Documento mantenido por el equipo de desarrollo de MyWorksApp. Actualizar al cerrar cada hito mayor (backend, pagos, tiendas).*
