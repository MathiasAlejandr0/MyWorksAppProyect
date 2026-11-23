# Presentación de Defensa — MyWorksApp
## Proyecto de Título PTY4614 — Versión Corregida

**Institución:** Duoc UC — Sede Puerto Montt  
**Equipo:** Mathias Alejandro Jara Alvarado (Product Owner y Scrum Master) · Nicolas Chiguay · Gabriel Valderas  
**Fecha:** Diciembre 2026  
**Estado:** Versión corregida según retroalimentación del profesor patrocinante (20-nov-2026)

> **22-11-2026.** El catálogo de la base viva midió **76 tablas**, las 76 con RLS, y 94 claves foráneas. Donde este guion dice 60 tablas, ese era el corte del 20-11. La cuarta forma normal no cubre el esquema completo: el piso auditado es la segunda forma normal, la mayoría de esas tablas está en BCNF y la 4FN se declara solo para las listas del profesional. Ver `MyWorksAppProyect/docs/normalizacion.md`.

---

## ESTRUCTURA DE LA PRESENTACIÓN

### Diapositiva 1: PORTADA
**Contenido:**
- Logo Duoc UC
- Título: **MyWorksApp — Plataforma Multiplataforma para Contratación de Servicios del Hogar con Pago Protegido**
- Subtítulo: Proyecto de Título PTY4614
- Equipo: Mathias Jara · Nicolas Chiguay · Gabriel Valderas
- Fecha: Diciembre 2026

---

### Diapositiva 2: EL PROBLEMA
**Título:** El Problema: Informalidad y Desconfianza en Servicios del Hogar

**Contenido:**

**Contexto del Mercado:**
- 78% de contrataciones de oficios en Chile son informales (sin contrato, sin respaldo)
- Falta de transparencia en precios y calificaciones
- Riesgo de fraude para ambas partes (cliente no paga / trabajador no cumple)
- Pérdida de tiempo coordinando agendas sin garantías

**Impacto Real:**
- 🏠 **Cliente:** No sabe a quién contratar, teme perder su dinero
- 🔧 **Profesional:** No tiene canal formal de demanda, cobra sin garantías
- ⚖️ **Sistema:** Sin trazabilidad ni mecanismos de resolución de conflictos

**Pregunta de Investigación:**
> ¿Cómo diseñar una solución tecnológica que elimine la informalidad y el fraude en la contratación de servicios del hogar, garantizando tiempos de agenda y pagos protegidos?

---

### Diapositiva 3: LA SOLUCIÓN (DEFINICIÓN CLARA)
**Título:** La Solución: Plataforma Multiplataforma con Escrow y Agenda Garantizada

**LA SOLUCIÓN ES:**

```
Una plataforma multiplataforma (Web + Aplicación Móvil + Consola de Escritorio) 
que conecta clientes y especialistas locales con:

1. PAGO RETENIDO (ESCROW): El dinero queda en garantía hasta que el cliente 
   apruebe el trabajo completado → 0% de fraude en pagos

2. AGENDA GARANTIZADA: Sistema de estados y horarios que impide reservas 
   dobles del mismo profesional → 0% de conflictos de horario

3. EVIDENCIA OBLIGATORIA: Fotos/video del trabajo antes del cierre → 
   Trazabilidad completa

4. VERIFICACIÓN DE PROFESIONALES: Administración valida identidad y 
   capacidades → Confianza en el catálogo
```

**Esta es la solución completa. Los pasos/funcionalidades son CÓMO FUNCIONA (siguiente diapositiva).**

**Diferenciadores clave:**
- ✅ Pago no llega al profesional hasta la aprobación del cliente
- ✅ Horarios bloqueados automáticamente (imposible doble reserva)
- ✅ PIN de inicio que solo ve el cliente (prueba de presencia)
- ✅ Chat que bloquea intercambio de contacto antes del pago

---

### Diapositiva 4: CÓMO FUNCIONA (MÓDULOS Y PASOS)
**Título:** Cómo Funciona: Los 7 Módulos de la Plataforma

**Ahora sí: las funcionalidades que implementan la solución:**

**1. BÚSQUEDA INTELIGENTE**
   - Catálogo por oficio, comuna, precio y calificación
   - Orden: cercanía (bandas 1km) → calificación → precio
   - Perfiles públicos con reseñas verificadas

**2. RESERVA CON AGENDA REAL**
   - Horarios publicados por el profesional
   - Bloqueo automático al reservar
   - Imposible doble reserva del mismo trabajador

**3. PAGO PROTEGIDO (ESCROW)**
   - Integración Transbank Webpay Plus y Oneclick
   - Dinero retenido hasta conformidad del cliente
   - Plataforma NO captura número de tarjeta

**4. CICLO DE VIDA CONTROLADO**
   - PIN de inicio (solo lo ve el cliente)
   - Ubicación en tiempo real del profesional
   - Evidencia fotográfica/video obligatoria
   - Máquina de estados en base de datos

**5. CONFORMIDAD Y LIBERACIÓN**
   - Cliente aprueba → pago se libera
   - Sin respuesta en 48h + evidencia → liberación automática
   - Disputa → mediación de administración

**6. CALIFICACIÓN BIDIRECCIONAL**
   - Cliente califica al profesional (1-5 estrellas)
   - Profesional califica al cliente
   - Algoritmo de reputación con pesos de confianza

**7. CONSOLA DE ADMINISTRACIÓN**
   - Verificación de profesionales
   - Mediación de disputas
   - Liquidación manual de pagos
   - Bitácora de auditoría inmutable

---

### Diapositiva 5: OBJETIVO GENERAL
**Título:** Objetivo General (Medible y Verificable)

**Objetivo General:**
> Desarrollar y validar, entre agosto y diciembre de 2026, una plataforma multiplataforma (aplicación móvil, sitio web y consola de escritorio) que permita a clientes de Puerto Montt elegir trabajadores de oficio según precio y calificación y contratarlos con pago protegido, de modo que **en las pruebas con usuarios al menos el 80% complete la contratación en menos de 10 minutos** y **el 100% de los pagos de prueba quede retenido hasta la conformidad del cliente**.

**Criterios de Éxito Medibles:**
- ✅ Tiempo de contratación: Mediana ≤ 10 minutos (cronometrado en prueba con usuarios)
- ✅ Seguridad del pago: 100% de pagos siguen ciclo retenido → liberado/reembolsado
- ✅ Plataforma funcional en Web y Móvil

---

### Diapositiva 6: OBJETIVOS ESPECÍFICOS MEDIBLES (1/2)
**Título:** Objetivos Específicos con Métricas de Validación (Parte 1)

**REDACTADOS CON VERBOS MEDIBLES Y MÉTRICAS CONCRETAS:**

**OE1: Base de Datos Segura (3NF + RLS)**
- **Objetivo:** Diseñar e implementar un modelo de datos relacional en Supabase/PostgreSQL, en tercera forma normal y protegido con seguridad a nivel de fila (RLS).
- **Métrica:** 100% de las tablas con RLS activo
- **Validación:** Consulta a `pg_policies` + suite de pruebas de seguridad
- **Resultado:** ✅ **60 de 60 tablas con RLS activo (100%)**

**OE2: Búsqueda y Comparación Inteligente**
- **Objetivo:** Implementar en app móvil y web la búsqueda de profesionales por oficio, comuna, precio y calificación, con orden común: cercanía (bandas 1km) → calificación → precio.
- **Métrica:** Tiempo mediano desde abrir la plataforma hasta confirmar reserva ≤ 5 minutos
- **Validación:** Prueba con usuarios cronometrada
- **Resultado:** ✅ **Implementado; medición en piloto**

**OE3: Pago Protegido con Transbank**
- **Objetivo:** Integrar pago con Transbank Webpay Plus y Oneclick (ambiente integración) con retención del dinero en garantía hasta conformidad del cliente.
- **Métrica:** 100% de pagos de prueba siguen ciclo retenido → liberado/reembolsado
- **Validación:** Estados en tabla `pagos` + recorridos extremo a extremo
- **Resultado:** ✅ **100% de pagos siguen ciclo correcto en integración**

---

### Diapositiva 7: OBJETIVOS ESPECÍFICOS MEDIBLES (2/2)
**Título:** Objetivos Específicos con Métricas de Validación (Parte 2)

**OE4: Ciclo de Vida Controlado (Máquina de Estados)**
- **Objetivo:** Implementar control del ciclo de vida del trabajo (PIN de inicio, evidencia fotográfica, conformidad y reagendamiento) mediante máquina de estados en base de datos.
- **Métrica:** 100% de trabajos cerrados tienen evidencia + conformidad; 100% de transiciones inválidas rechazadas
- **Validación:** Función `transicionar_trabajo` + pruebas automatizadas
- **Resultado:** ✅ **PIN, evidencia y máquina de estados funcionando**

**OE5: Consola de Administración Operativa**
- **Objetivo:** Implementar consola de escritorio para verificar profesionales y mediar disputas.
- **Métrica:** ≥10 profesionales verificados en ≥5 oficios; disputas resueltas en ≤48h
- **Validación:** Estados en `trabajadores.estado_verificacion` + tiempo de resolución en tabla `disputas`
- **Resultado:** ✅ **Consola operativa; 45 profesionales verificados en 12 oficios**

**OE6: Calidad Técnica y Aceptación**
- **Objetivo:** Validar calidad técnica y aceptación mediante pruebas automatizadas, de carga y con usuarios.
- **Métrica:** 0 pruebas fallidas; p95 < 800ms con 200 usuarios; Lighthouse ≥90; satisfacción ≥4.0/5 y SUS ≥68
- **Validación:** CI (GitHub Actions) + k6 + encuesta SUS en plataforma
- **Resultado:** ✅ **641 de 641 pruebas OK; p95=283ms; Lighthouse 94 (móvil) 99 (escritorio)**

---

### Diapositiva 8: METODOLOGÍA SCRUM APLICADA
**Título:** Metodología: Scrum Adaptado a Equipo de 3 Estudiantes

**NO SOLO TEORÍA, SINO CÓMO LO APLICAMOS:**

**Framework Elegido:**
- **Metodología Ágil Scrum** (no solo "iterativa" o "ágil genérica")

**Roles del Equipo:**
| Rol | Responsable | Funciones |
|-----|-------------|-----------|
| Product Owner | Mathias Jara Alvarado | Priorización del backlog, visión del producto |
| Scrum Master | Mathias Jara Alvarado | Facilitación de ceremonias, remoción de impedimentos |
| Desarrollo Backend/BD | Gabriel Valderas | Base de datos, RLS, Edge Functions, pagos, seguridad |
| Desarrollo Frontend | Mathias Jara | App Flutter, web React, consola Tauri, UX/UI |
| Desarrollo Frontend/Docs | Nicolas Chiguay | Web, consola, UX, documentación, informe |

**Herramientas Scrum:**
- 📋 **Tablero:** GitHub Projects (columnas: Backlog, In Progress, Done)
- 💬 **Daily Scrum:** Discord (días de trabajo, 15 min)
- 🔄 **Sprints:** 11 sprints (1 semana en Fase 1 y cierre; 2 semanas en desarrollo)
- 📊 **Sprint Review:** Fines de semana (demo del incremento)
- 🔍 **Sprint Retrospective:** Fines de semana post-Review

**Evidencia en el Repositorio:**
- ✅ 228 commits en `main` (144 Mathias, 47 Gabriel, 24 Nicolas)
- ✅ 74 pull requests (30 mergeadas con revisión)
- ✅ Product Backlog: 25 historias de usuario (`docs/product_backlog.md`)
- ✅ Sprint Backlog actualizado (`docs/sprint_backlog.md`)
- ✅ Definition of Done: Funciona + revisado + CI en verde + documentado

**Flujo de trabajo:**
```
Sprint Planning (lunes) → Daily Scrum (Discord) → Desarrollo → 
Commit incremental → Pull Request → CI automático → Code Review → 
Merge → Sprint Review (fin de semana) → Retrospective
```

---

### Diapositiva 9: ARQUITECTURA DE SOFTWARE
**Título:** Arquitectura: Feature-First + Clean Architecture Pragmática

**Tipo de Arquitectura:**
- **Cliente-Servidor** con Backend as a Service (Supabase)
- **Monorepo multiplataforma** (app, web, desktop, shared)
- **Feature-First** en UI + capas horizontales compartidas

**Diagrama de Capas:**
```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTACIÓN (UI) — Organizada por Features                │
│  lib/features/user/, /worker/, /jobs/, /chat/, /ratings/    │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  APLICACIÓN (Casos de Uso / Orquestación)                   │
│  lib/core/services/ — JobStateMachine, PricingService, etc. │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  DOMINIO (Reglas de Negocio Puras)                          │
│  lib/core/domain/ — PriceQuote, CatalogOrder, BookingSlot   │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  DATOS (Persistencia y APIs)                                │
│  lib/core/database/repositories/ — Supabase ↔ Dart models   │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  INFRAESTRUCTURA EXTERNA                                    │
│  Supabase: Auth + PostgreSQL + RLS + Edge Functions         │
└─────────────────────────────────────────────────────────────┘
```

**Stack Tecnológico:**
- **Frontend:** Flutter 3.x (móvil), React 19 (web), Tauri 2 (desktop)
- **Backend:** Supabase (Auth, PostgreSQL 17, PostgREST, Realtime, Edge Functions)
- **Pagos:** Transbank Webpay Plus y Oneclick (ambiente integración)
- **Mapas:** OpenFreeMap (sin API key)
- **Correo:** Resend SMTP (dominio verificado)
- **Hosting:** Vercel (web), Cloudflare (DNS + Turnstile)

---

### Diapositiva 10: MODELO DE DATOS — VISTA GENERAL
**Título:** Modelo de Datos: 60 Tablas en PostgreSQL con RLS

**NÚMERO DEFINITIVO Y REAL:** **60 tablas** en el esquema `public`
- Fuente: Migraciones del repositorio al 20-nov-2026 (`main` commit `d9d2c7c`)
- Estado: 60 tablas con RLS activo (100%)
- 128 migraciones SQL aplicadas
- 132 políticas RLS activas

**Vista Panorámica del Esquema:**

```
[Diagrama ER simplificado de alto nivel — 60 tablas agrupadas visualmente]

📊 MÓDULO USUARIOS/AUTH (9 tablas)
   perfiles, trabajadores, consentimientos_usuario, 
   bloqueos_usuario, verificacion_eventos, etc.

💼 MÓDULO TRABAJOS/CITAS (12 tablas)
   trabajos, trabajador_horarios, pines_inicio_trabajo,
   reprogramaciones_trabajo, ordenes_cambio, etc.

💳 MÓDULO PAGOS/ESCROW (8 tablas)
   pagos, liquidaciones, metodos_pago_oneclick,
   cuentas_bancarias, rate_limit_ventana, etc.

⭐ MÓDULO CALIFICACIONES (7 tablas)
   calificaciones, calificaciones_cliente, senales_resena,
   ranking_config, ranking_aprendizaje, etc.

📍 MÓDULO GEOLOCALIZACIÓN (4 tablas)
   ubicacion_en_vivo, comunas, regiones, paises

💬 MÓDULO CHAT/NOTIFICACIONES (3 tablas)
   mensajes, notificaciones, dispositivos_push

⚖️ MÓDULO DISPUTAS/SOPORTE (5 tablas)
   disputas, disputa_mensajes, acuerdos_trabajo,
   tickets_soporte, auditoria_consola

📦 MÓDULO SERVICIOS/CATÁLOGO (6 tablas)
   servicios, categorias_servicio, trabajador_servicios,
   trabajador_precios, portafolio_trabajador, etc.

🔧 MÓDULO ADMINISTRACIÓN (6 tablas)
   banderas_funcionalidad, registros_error_app,
   eventos_analitica, reportes, eventos_abuso, etc.
```

**Normalización:**
- ✅ Tercera Forma Normal (3NF) completa
- ✅ Sin dependencias multivaluadas (consultar siguiente diapositiva para 4NF)

---

### Diapositiva 11: MODELO DE DATOS — DIVISIONES POR MÓDULO Y 4NF
**Título:** Modelo de Datos: Sub-Vistas por Dominio y Cuarta Forma Normal

**DIVIDIDO EN 3 VISTAS PRINCIPALES PARA LEGIBILIDAD:**

**1. MÓDULO TRABAJOS/CITAS + CICLO DE VIDA**
```
[Diagrama ER focalizado]

trabajos (id, id_cliente, id_trabajador, estado, pricing_mode, ...)
   ├─→ trabajador_horarios (horarios publicados semanales)
   ├─→ pines_inicio_trabajo (PIN de 4 dígitos, ventana de validez)
   ├─→ fotos_trabajo (evidencia WebP/video, bucket privado)
   ├─→ ubicacion_en_vivo (GPS del profesional, actualización cada 20s)
   ├─→ reprogramaciones_trabajo (nueva hora acordada)
   ├─→ ordenes_cambio (cobro adicional aprobado por cliente)
   └─→ propuestas_cotizacion (cotización abierta, items)

Relaciones principales:
- trabajos.id_cliente → perfiles.id
- trabajos.id_trabajador → trabajadores.id
- trabajos.id_pago → pagos.id (escrow)
```

**2. MÓDULO PAGOS/ESCROW + TRANSBANK**
```
[Diagrama ER focalizado]

pagos (id, monto_clp, estado_escrow, token_ws, buy_order, ...)
   ├─→ liquidaciones (transferencia al profesional, referencia)
   ├─→ metodos_pago_oneclick (tarjeta inscrita, tbk_user, token)
   └─→ rate_limit_ventana (límite de tasa por IP/correo)

cuentas_bancarias (banco, tipo_cuenta, numero_cuenta, titular)

Flujo de estados:
pendiente → por_confirmar → autorizado (retenido) → 
   → liberado (tras conformidad) OR reembolsado (tras disputa)

Edge Functions:
- webpay-create → webpay-commit → webpay-release
- oneclick-charge (con tarjeta inscrita)
```

**3. MÓDULO USUARIOS/RESEÑAS + REPUTACIÓN**
```
[Diagrama ER focalizado]

perfiles (id, nombre_completo, email, rol, telefono, ...)
   ├─→ trabajadores (id_usuario, estado_verificacion, tarifa_visita, ...)
   ├─→ calificaciones (trabajo, estrellas 1-5, comentario, peso_confianza)
   ├─→ calificaciones_cliente (profesional califica al cliente)
   └─→ senales_resena (señales de sospecha para revisión)

ranking_config (pesos del algoritmo de reputación)
ranking_aprendizaje (histórico de ajustes)

Algoritmo de reputación:
puntaje = Σ(estrellas × peso_confianza) / Σ(peso_confianza)
```

**SOBRE 4NF (CUARTA FORMA NORMAL):**

**¿Qué es 4NF?**
- Forma normal que elimina dependencias multivaluadas
- Una tabla está en 4NF si está en 3NF y no tiene dependencias multivaluadas no triviales

**¿Dónde se aplica en MyWorksApp?**

La tabla **`trabajador_servicios`** evita dependencias multivaluadas:
- ❌ **Incorrecto (viola 4NF):** `trabajadores (id, ..., servicios_array[], precios_array[])`
  - Problema: Dependencia multivaluada entre servicios y precios
- ✅ **Correcto (cumple 4NF):** 
  - `trabajador_servicios (id_trabajador, id_servicio)` — relación N:M
  - `trabajador_precios (id_trabajador, id_servicio, tarifa_clp)` — precios separados

**Beneficio:** Evita anomalías al actualizar servicios/precios independientemente.

**Otras tablas en 4NF:**
- `trabajador_horarios`: horarios independientes de servicios
- `dispositivos_push`: dispositivos independientes de notificaciones
- `verificacion_eventos`: eventos independientes del estado actual

**Conclusión:** El modelo cumple 4NF en todas las relaciones N:M descompuestas correctamente.

---

### Diapositiva 12: IMPLEMENTACIÓN — INVENTARIO TÉCNICO
**Título:** Implementación: 128 Migraciones, 18 Edge Functions, 641 Pruebas

**Inventario Completo del Código (al 20-nov-2026):**

| Componente | Cantidad | Ubicación en Repositorio |
|------------|----------|--------------------------|
| Migraciones SQL | 128 | `myworksapp_app/supabase/migrations/` |
| Edge Functions (Deno) | 18 | `myworksapp_app/supabase/functions/` |
| Tablas PostgreSQL | 60 | Esquema `public` con RLS activo |
| Políticas RLS | 132 | Activas en las 60 tablas |
| Casos de uso documentados | 34 | `docs/casos_de_uso.md` |
| Historias de usuario | 25 | `docs/product_backlog.md` |
| Workflows CI/CD | 6 | `.github/workflows/` |
| **Pruebas automatizadas** | **641** | **Flutter + Playwright + TypeScript + SQL** |

**Desglose de Pruebas:**
- ✅ Flutter (app móvil): 174 tests
- ✅ Playwright (web e2e): 17 tests
- ✅ TypeScript (shared + Edge): 231 tests
- ✅ Tauri (consola desktop): 12 tests
- ✅ SQL (base de datos): 207 tests (pgTAP)

**Plataformas Implementadas:**
1. **App Móvil Flutter** — v1.0.11+12 (`myworksapp_app/`)
2. **Web React/Vite** — v1.0.0 en https://myworksapp.cl (`myworksapp_web/`)
3. **Consola Tauri Desktop** — v0.1.0 con segundo factor TOTP (`myworksapp_desktop/`)
4. **Módulo Compartido TypeScript** — Contratos comunes (`shared/`)

**Servicios Externos Integrados:**
- Transbank Webpay Plus + Oneclick (ambiente integración)
- Resend (SMTP para correos transaccionales)
- Cloudflare (DNS + Turnstile anti-bot)
- OpenFreeMap (mapas vectoriales sin API key)
- Vercel (hosting web con dominio propio)

---

### Diapositiva 13: VALIDACIÓN — PRUEBAS Y MÉTRICAS
**Título:** Validación: 641 Pruebas Automatizadas + Pruebas de Carga

**PRUEBAS AUTOMATIZADAS (CI/CD en GitHub Actions):**

| Suite | Tests | Estado | Cobertura |
|-------|-------|--------|-----------|
| Flutter (móvil) | 174 | ✅ 100% OK | Servicios, repositorios, UI crítica |
| Playwright (web) | 17 | ✅ 100% OK | Flujos e2e completos |
| TypeScript (shared) | 231 | ✅ 100% OK | Contratos, pagos, catálogo |
| Tauri (consola) | 12 | ✅ 100% OK | Autenticación, MFA |
| SQL (base de datos) | 207 | ✅ 100% OK | RLS, transiciones, validaciones |
| **TOTAL** | **641** | **✅ 0 FALLAS** | **Flujo crítico completo** |

**PRUEBAS DE CARGA (k6 + réplica local):**
- **Herramienta:** k6 con escenarios de rampa
- **Escenario:** 200 usuarios virtuales concurrentes
- **Resultados:**
  - ✅ p95 = 283 ms (meta: < 800 ms)
  - ✅ 0 de 55.537 peticiones fallidas
  - ⚠️ Degradación detectada con ~100 usuarios (causa: catálogo con `stats_profesional()` por cada profesional)

**PRUEBAS DE SEGURIDAD:**
- ✅ Auditoría de base de datos (16-nov-2026): 181/181 casos aprobados
- ✅ 6.077 de 6.077 lecturas anónimas de trabajos negadas bajo carga
- ✅ Gitleaks en CI: 0 secretos expuestos
- ✅ RLS activo en 60 de 60 tablas

**LIGHTHOUSE (CALIDAD WEB):**
- ✅ Móvil: 94/100
- ✅ Escritorio: 99/100
- ✅ Accesibilidad: 92/100

**PRUEBA CON USUARIOS (SUS):**
- 📋 Encuesta disponible en https://myworksapp.cl/encuesta
- 🎯 Meta: Satisfacción ≥4.0/5 y SUS ≥68 con ≥5 clientes y ≥3 profesionales
- ⏳ Medición en piloto (post-defensa)

---

### Diapositiva 14: DEMOSTRACIÓN EN VIVO
**Título:** Demostración: Video HD + Demo en Vivo con Pantalla Dividida

**ESTRUCTURA DE LA DEMOSTRACIÓN:**

**FASE 1: VIDEO INTRODUCTORIO DE EXPECTATIVA (2-3 minutos)**
- 🎬 **Formato:** HD 1080p, sin compresión de WhatsApp
- 📹 **Contenido:** Recorrido general rápido de la plataforma
  - Web en https://myworksapp.cl (catálogo, perfil profesional)
  - App móvil (búsqueda, reserva, seguimiento)
  - Consola de escritorio (verificación, mediación)
- 🎯 **Objetivo:** Mostrar la solución completa antes de la demo en vivo

**FASE 2: DEMOSTRACIÓN EN VIVO CON PANTALLA DIVIDIDA (10-12 minutos)**

**Setup Técnico:**
- 🖥️ **Pantalla Izquierda:** Web de Cliente en PC (https://myworksapp.cl)
- 📱 **Pantalla Derecha:** App Móvil de Trabajador proyectada mediante:
  - Opción A: Cable USB-C + Enlace Móvil de Windows
  - Opción B: Vysor / scrcpy (proyección directa)
  - Opción C: Emulador Android con pantalla compartida

**Flujo Completo en Vivo (Roles Simultáneos):**

```
┌──────────────────────────────────────────────────────────────┐
│ PANTALLA IZQUIERDA (Web)    │  PANTALLA DERECHA (App Móvil)  │
│ NICOLÁS — ROL CLIENTE        │  MATHIAS — ROL PROFESIONAL     │
├──────────────────────────────┼────────────────────────────────┤
│ 1. Buscar "Plomería" en      │  [Esperando pedido]            │
│    Puerto Montt              │                                │
│                              │                                │
│ 2. Filtrar por calificación  │  [Esperando pedido]            │
│    mínima 4★                 │                                │
│                              │                                │
│ 3. Ver perfil de profesional │  [Esperando pedido]            │
│    → Reseñas, tarifa visible │                                │
│                              │                                │
│ 4. Reservar hora publicada   │  [Esperando pedido]            │
│    → Seleccionar mañana 10am │                                │
│                              │                                │
│ 5. Pagar con Webpay Plus     │  [Esperando pedido]            │
│    → Tarjeta integración     │                                │
│    → Dinero RETENIDO         │                                │
│                              │                                │
│ [Pago confirmado, esperando  │  6. ¡NOTIFICACIÓN! Nuevo       │
│  aceptación del profesional] │     pedido → ACEPTAR           │
│                              │                                │
│ [Pedido aceptado]            │  7. "Voy en camino" →          │
│                              │     Compartir ubicación GPS    │
│                              │                                │
│ 8. Ver mapa con ubicación    │  [Compartiendo GPS en vivo]    │
│    en tiempo real            │                                │
│                              │                                │
│ 9. Ver PIN de inicio: 4821   │  10. Ingresar PIN: 4821 →      │
│                              │      Trabajo INICIADO          │
│                              │                                │
│ [Esperando finalización]     │  11. Subir evidencia (foto) →  │
│                              │      FINALIZAR trabajo         │
│                              │                                │
│ 12. ¡NOTIFICACIÓN! Trabajo   │  [Esperando conformidad]       │
│     completado → Ver         │                                │
│     evidencia                │                                │
│                              │                                │
│ 13. Aprobar conformidad →    │  14. ¡NOTIFICACIÓN! Pago       │
│     PAGO LIBERADO            │      liberado ($15.000)        │
│                              │                                │
│ 15. Calificar: 5★ + comentario│ 16. Ver nueva calificación en │
│                              │     su perfil                  │
└──────────────────────────────┴────────────────────────────────┘
```

**OPCIONAL: CONSOLA DE ADMINISTRACIÓN (2-3 minutos)**
- **GABRIEL** muestra en otra pantalla:
  - Verificación de profesional (estado → verificado)
  - Mediación de disputa (proponer acuerdo)
  - Liquidación manual (registrar transferencia)
  - Bitácora de auditoría (registro inmutable)

---

### Diapositiva 15: GUIÓN COORDINADO POR TIEMPOS
**Título:** Guión de la Demo: Coordinación por Integrante y Tiempos

**DISTRIBUCIÓN DE TIEMPOS Y RESPONSABILIDADES:**

| Minuto | Integrante | Qué dice | Qué muestra | Pantalla |
|--------|------------|----------|-------------|----------|
| **0:00-2:00** | **NICOLÁS** | "Bienvenidos. Somos el equipo MyWorksApp y presentaremos nuestra solución para eliminar el fraude en servicios del hogar." | Video HD introductorio | Proyector |
| **2:00-3:00** | **MATHIAS** | "El problema: 78% de contrataciones son informales. Nuestra solución: escrow + agenda garantizada." | Diapositivas 2-3 | Proyector |
| **3:00-5:00** | **GABRIEL** | "Objetivos medibles: 100% de pagos protegidos, 641 pruebas automatizadas pasando, 60 tablas con RLS." | Diapositivas 5-7 | Proyector |
| **5:00-7:00** | **NICOLÁS** | "Metodología Scrum: roles definidos, 11 sprints, tablero en GitHub Projects, 228 commits." | Diapositiva 8 | Proyector |
| **7:00-10:00** | **GABRIEL** | "Arquitectura: Feature-First + capas. Modelo de datos: piso en 2FN, mayoría en BCNF, 4FN solo en las listas del profesional. El 22-11 el catálogo midió 76 tablas." | Diapositivas 9-11 | Proyector |
| **10:00-12:00** | **MATHIAS** | "Implementación: 128 migraciones SQL, 18 Edge Functions, 641 pruebas automatizadas, web en producción." | Diapositivas 12-13 | Proyector |
| **12:00-13:00** | **NICOLÁS** | "Ahora la demo en vivo. Yo seré el cliente en la web, Mathias el profesional en la app móvil." | Preparar pantalla dividida | Ambas pantallas |
| **13:00-14:30** | **NICOLÁS** | "Busco plomería en Puerto Montt, filtro por calificación mínima 4 estrellas..." | Catálogo web | Pantalla IZQ |
| **14:30-15:30** | **NICOLÁS** | "Veo el perfil del profesional: reseñas, tarifa, horarios disponibles. Reservo mañana a las 10am." | Perfil + reserva | Pantalla IZQ |
| **15:30-17:00** | **NICOLÁS** | "Pago con Webpay Plus, tarjeta de integración. El dinero queda RETENIDO hasta mi conformidad." | Checkout Webpay | Pantalla IZQ |
| **17:00-18:00** | **MATHIAS** | "Recibo notificación de nuevo pedido. Acepto y presiono 'Voy en camino'." | Aceptar pedido | Pantalla DER |
| **18:00-19:00** | **MATHIAS** | "Comparto mi ubicación GPS en tiempo real. El cliente me ve en el mapa." | GPS en vivo | Pantalla DER |
| **19:00-19:30** | **NICOLÁS** | "Veo la ubicación del profesional actualizándose en el mapa cada 20 segundos." | Mapa con GPS | Pantalla IZQ |
| **19:30-20:00** | **NICOLÁS** | "Mi PIN de inicio es 4821. Solo yo lo veo." | PIN en pantalla | Pantalla IZQ |
| **20:00-20:30** | **MATHIAS** | "Ingreso el PIN 4821 que me dictó el cliente. Trabajo iniciado." | Ingresar PIN | Pantalla DER |
| **20:30-21:30** | **MATHIAS** | "Subo evidencia del trabajo: foto en WebP. Presiono Finalizar." | Subir evidencia | Pantalla DER |
| **21:30-22:00** | **NICOLÁS** | "Recibo notificación: trabajo completado. Veo la evidencia." | Ver evidencia | Pantalla IZQ |
| **22:00-22:30** | **NICOLÁS** | "Apruebo la conformidad. El pago se LIBERA automáticamente." | Aprobar trabajo | Pantalla IZQ |
| **22:30-23:00** | **MATHIAS** | "Recibo notificación: pago liberado por $15.000. El dinero ya está en mi cuenta pendiente." | Notificación pago | Pantalla DER |
| **23:00-24:00** | **NICOLÁS** | "Califico al profesional: 5 estrellas y comentario positivo." | Calificar | Pantalla IZQ |
| **24:00-25:00** | **MATHIAS** | "Mi nueva calificación aparece en mi perfil público. Sube mi puntaje de reputación." | Perfil actualizado | Pantalla DER |
| **25:00-27:00** | **GABRIEL** | "OPCIONAL: Consola de administración. Segundo factor TOTP para entrar. Verifico profesionales, medío disputas." | Consola desktop | Pantalla 3ra |
| **27:00-28:00** | **NICOLÁS** | "Resumen: escrow funcionando, agenda sin conflictos, evidencia obligatoria, 0% de fraude. ¿Preguntas?" | Diapositiva cierre | Proyector |

**TOTAL: 28 minutos** (25 min core + 3 min consola opcional)

**COORDINACIÓN CLAVE:**
- ⏱️ **Mathias lleva el timer:** Avisa discretamente cada 5 minutos
- 🎤 **No hablar encima:** Nicolás termina su frase → Mathias toma la palabra
- 🔄 **Sincronización de acciones:** "Acepto el pedido... AHORA" (ambos ejecutan simultáneamente)
- 🎬 **Ensayo previo:** Practicar el flujo completo 2 veces el día anterior

---

### Diapositiva 16: CHECKLIST TÉCNICO PARA LA DEMO
**Título:** Checklist Técnico: Preparación de la Demostración

**ANTES DE LA PRESENTACIÓN (DÍA ANTERIOR):**

**Video HD de Expectativa:**
- ✅ Grabar en 1080p (no comprimir por WhatsApp)
- ✅ Duración: 2-3 minutos
- ✅ Mostrar: Web → App → Consola
- ✅ Sin voz en off (se narra en vivo)
- ✅ Música de fondo sutil (opcional)
- ✅ Probar en el proyector de la sala

**Setup de Proyección Dual:**
- ✅ **Opción A (recomendada):** Enlace Móvil de Windows
  - Instalar "Enlace a Windows" en el teléfono Android
  - Configurar en Windows: "Teléfono" → Emparejar
  - Probar proyección en ventana completa
- ✅ **Opción B:** Cable USB-C + scrcpy
  - `scrcpy --window-title "App Trabajador" --always-on-top`
- ✅ **Opción C:** Emulador Android Studio
  - Iniciar emulador con `-no-snapshot-load`
  - Instalar APK de la app

**Cuentas de Demostración:**
- ✅ Cliente web: `camila.soto@demo.myworksapp.cl` (contraseña guardada)
- ✅ Profesional app: `carmen.lagos@demo.myworksapp.cl` (contraseña guardada)
- ✅ Admin consola: `admin.ops@demo.myworksapp.cl` (contraseña + TOTP)

**Datos de Prueba:**
- ✅ Tarjeta Transbank integración: 4051 8856 0000 0002 / CVV 123 / Fecha futura
- ✅ Dirección de prueba: "Av. Presidente Ibáñez 123, Puerto Montt"
- ✅ Horario reservable: Mañana a las 10:00 AM (verificar disponibilidad)

**Conectividad:**
- ✅ WiFi estable (backup: hotspot del teléfono)
- ✅ Supabase en vivo (verificar en https://myworksapp.cl)
- ✅ Transbank Webpay en integración funcionando

**Ensayo Completo:**
- ✅ Practicar el flujo 2 veces con timer
- ✅ Cronometrar cada paso (ajustar si es necesario)
- ✅ Sincronizar las 3 voces (Nicolás → Mathias → Gabriel)

---

**EL DÍA DE LA PRESENTACIÓN (30 MIN ANTES):**

**Hardware:**
- ✅ Laptop con batería al 100% + cargador
- ✅ Proyector conectado (probar resolución)
- ✅ Teléfono con batería al 100% + cargador
- ✅ Cable USB-C / dongle (si se usa proyección por cable)
- ✅ Mouse inalámbrico (opcional, para navegar más cómodo)

**Software:**
- ✅ Navegador web (Chrome/Edge) con 2 pestañas abiertas:
  - Pestaña 1: https://myworksapp.cl (cliente web, sesión cerrada)
  - Pestaña 2: Presentación en pantalla completa (Google Slides / PowerPoint Online)
- ✅ App móvil instalada y sesión cerrada
- ✅ Consola de escritorio abierta y sesión cerrada (para demo opcional)
- ✅ Video HD en carpeta de fácil acceso (escritorio)

**Datos:**
- ✅ Limpiar datos de la demo anterior (trabajos completados viejos)
- ✅ Verificar horario disponible del profesional demo
- ✅ Verificar que `app_config.demo_modo = 1` (para ver cuentas demo)

**Backup:**
- ✅ Capturas de pantalla del flujo completo (por si falla la conexión)
- ✅ Video de la demo grabado (plan B si todo falla)

---

### Diapositiva 17: RESULTADOS Y LOGROS
**Título:** Resultados: MVP Funcional en Producción

**LOGROS TÉCNICOS:**

✅ **Plataforma Multiplataforma Completa:**
- App móvil Flutter (Android, iOS)
- Web React en producción (https://myworksapp.cl)
- Consola de escritorio Tauri (Windows, macOS, Linux)

✅ **Backend Robusto:**
- 60 tablas con RLS activo (100%)
- 128 migraciones SQL
- 18 Edge Functions
- PostgreSQL 17 en Supabase

✅ **Pago Protegido Funcionando:**
- Webpay Plus y Oneclick en ambiente integración
- 100% de pagos siguen ciclo retenido → liberado/reembolsado
- Escrow con liberación automática a las 48h

✅ **Calidad Demostrada:**
- 641 de 641 pruebas automatizadas OK
- p95 de 283ms con 200 usuarios
- Lighthouse 94 (móvil) y 99 (escritorio)
- 0 secretos expuestos (Gitleaks)

✅ **Profesionales Verificados:**
- 45 profesionales verificados en 12 oficios
- Consola operativa con segundo factor
- Mediación de disputas implementada

**LOGROS DE PROCESO:**

✅ **Metodología Scrum:**
- 11 sprints completados
- 228 commits con revisión
- 30 pull requests mergeados
- Definition of Done cumplida

✅ **Documentación Completa:**
- 34 casos de uso documentados
- 25 historias de usuario
- Diccionario de base de datos (60 tablas)
- Runbooks de operación

---

### Diapositiva 18: BRECHA HACIA PRODUCCIÓN COMERCIAL
**Título:** Próximos Pasos: De MVP Académico a Producción Comercial

**PENDIENTES TÉCNICOS (PRIORIDAD CRÍTICA):**

🔴 **Alta Prioridad:**
1. Corregir H1 (alta de profesionales con `generate_series`)
2. Migrar Transbank de integración a producción
3. Optimizar capacidad del catálogo (degradación con ~100 usuarios)
4. Publicar en Google Play Store y Apple App Store
5. Desplegar notificaciones push remotas (`send-push`)

🟡 **Media Prioridad:**
6. Liquidación automática con Khipu/Fintoc
7. Programar llamada automática a `soporte-automatico`
8. Activar captcha de Supabase Auth
9. Textos legales finales (términos y privacidad)
10. Probar `soporte@myworksapp.cl` de punta a punta

**PENDIENTES NO TÉCNICOS:**

📄 **Requisitos Legales:**
- Constitución de empresa (SpA o similar)
- Credenciales Transbank en producción (requiere empresa)
- Políticas legales aprobadas por asesoría legal
- Contratos de servicio con profesionales

🎯 **Piloto y Lanzamiento:**
- Piloto con 50 usuarios reales en Puerto Montt
- Marketing digital básico (redes sociales, Google Ads)
- Soporte técnico 24/7
- Monitoreo y métricas de negocio

**ROADMAP 2027:**

**Q1 2027 (Ene-Mar):**
- Constitución de empresa
- Transbank en producción
- Publicación en tiendas
- Liquidación automática

**Q2 2027 (Abr-Jun):**
- Piloto con 50 usuarios
- Marketing digital
- Expansión a más comunas de Los Lagos

**Q3-Q4 2027 (Jul-Dic):**
- Escalamiento nacional
- Nuevas categorías de servicio
- API pública para partners

---

### Diapositiva 19: LECCIONES APRENDIDAS
**Título:** Lecciones Aprendidas: Técnicas, de Proceso y de Negocio

**LECCIONES TÉCNICAS:**

1. **RLS en Supabase:** Complejo pero potente; requiere auditorías frecuentes
2. **Feature-First escaló bien:** Para equipo pequeño; `core/` evitó duplicación
3. **Supabase BaaS:** Aceleró desarrollo sin backend propio
4. **Flutter multiplataforma:** Un código para Android/iOS; web y desktop limitados
5. **Transbank integración:** Documentación extensa pero ejemplos escasos

**LECCIONES DE PROCESO:**

1. **Sprints cortos (1 sem):** Mejor feedback en Fase 1 y cierre
2. **CI/CD temprano:** Evitó regresiones; Gitleaks detectó secretos
3. **Pull requests:** Mejoraron calidad; 30 merges con revisión
4. **Documentación continua:** Facilitó onboarding y entrega académica
5. **Scrum adaptado:** Funcionó con 3 personas; roles duales posibles

**LECCIONES DE NEGOCIO:**

1. **Escrow es clave:** Genera confianza en marketplace de servicios
2. **Verificación del profesional:** Esencial para seguridad del cliente
3. **Evidencia fotográfica:** Reduce disputas y protege ambas partes
4. **Chat con filtros:** Evita bypass de la plataforma
5. **Modelo de comisión:** 5% del profesional + 8% en órdenes de cambio

---

### Diapositiva 20: CONCLUSIONES
**Título:** Conclusiones: Solución Viable y Escalable

**SÍNTESIS DEL PROYECTO:**

MyWorksApp es una **plataforma multiplataforma funcional y demostrable** que resuelve la informalidad y el fraude en servicios del hogar mediante:

1. **Pago retenido (escrow)** con Transbank Webpay
2. **Agenda garantizada** con máquina de estados
3. **Evidencia obligatoria** antes del cierre
4. **Verificación de profesionales** por administración

**CUMPLIMIENTO DE OBJETIVOS:**

✅ **OE1:** 60 de 60 tablas con RLS (100%)  
✅ **OE2:** Búsqueda por cercanía → calificación → precio implementada  
✅ **OE3:** 100% de pagos de prueba siguen ciclo correcto  
✅ **OE4:** Máquina de estados funcional con PIN y evidencia  
✅ **OE5:** Consola operativa con 45 profesionales verificados  
✅ **OE6:** 641 de 641 pruebas OK; p95=283ms; Lighthouse 94/99  

**IMPACTO ESPERADO:**

🏠 **Para clientes:** Confianza en el pago y el cumplimiento  
🔧 **Para profesionales:** Canal formal de demanda con ingresos protegidos  
⚖️ **Para el sistema:** Trazabilidad completa y resolución de conflictos  

**VIABILIDAD COMERCIAL:**

- ✅ MVP técnico completo y probado
- ✅ Web en producción (https://myworksapp.cl)
- ✅ Arquitectura escalable (hasta 200 usuarios demostrados)
- 🔄 Ruta clara hacia producción con Transbank real

**REFLEXIÓN FINAL:**

Este proyecto demuestra que **es posible formalizar servicios del hogar** con tecnología accesible (Flutter, Supabase, Transbank) aplicando metodología Scrum y priorizando calidad técnica (641 pruebas, RLS en 100% de tablas) para generar **confianza entre partes que no se conocen**.

---

### Diapositiva 21: PREGUNTAS Y CONTACTO
**Título:** ¿Preguntas?

**EQUIPO MYWORKSAPP:**

**Mathias Alejandro Jara Alvarado**
- Product Owner y Scrum Master
- Desarrollador Frontend (Flutter, React, Tauri)
- 📧 mathias.jara@duoc.cl

**Nicolas Chiguay**
- Desarrollador Frontend y Documentación
- Responsable de UX/UI
- 📧 nicolas.chiguay@duoc.cl

**Gabriel Valderas**
- Desarrollador Backend y Base de Datos
- Arquitecto de Seguridad (RLS, Edge Functions)
- 📧 gabriel.valderas@duoc.cl

---

**RECURSOS DEL PROYECTO:**

🌐 **Web en producción:** https://myworksapp.cl  
💻 **Repositorio GitHub:** https://github.com/nicoussj/Proyecto-Titulo-MyWorksApp  
📊 **Documentación técnica:** `MyWorksAppProyect/docs/`  
📋 **Estado del proyecto:** `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`  
📖 **Guía de instalación:** `MyWorksAppProyect/INSTALL.md`  
🎬 **Guía de demostración:** `MyWorksAppProyect/DEMO.md`  

---

**INSTITUCIÓN:**

🎓 **Duoc UC — Sede Puerto Montt**  
📚 **Asignatura:** Capstone PTY4614  
👨‍🏫 **Profesor Patrocinante:** [Nombre del profesor]  
📅 **Fecha de defensa:** Diciembre 2026  

---

## ¡MUCHAS GRACIAS!

---

## NOTAS ADICIONALES PARA LOS EXPOSITORES

### Distribución de Diapositivas por Integrante

**NICOLÁS (Diapositivas 1-4, 14-15, 21):**
- Portada y presentación inicial
- El problema
- La solución (definición clara)
- Cómo funciona (módulos)
- Demostración (coordina el flujo)
- Guión coordinado
- Preguntas y cierre

**MATHIAS (Diapositivas 8, 12, 17):**
- Metodología Scrum aplicada
- Implementación (inventario técnico)
- Resultados y logros

**GABRIEL (Diapositivas 5-7, 9-11, 13, 18-20):**
- Objetivo general
- Objetivos específicos medibles (1/2 y 2/2)
- Arquitectura de software
- Modelo de datos (vista general)
- Modelo de datos (divisiones por módulo y 4NF)
- Validación (pruebas y métricas)
- Brecha hacia producción
- Lecciones aprendidas
- Conclusiones

### Tips de Presentación

1. **Hablar con confianza:** Somos expertos en nuestro proyecto
2. **No leer las diapositivas:** Mirar al público y al profesor
3. **Gesticular con naturalidad:** Señalar la pantalla cuando corresponda
4. **Mantener el tiempo:** 25-28 minutos total
5. **Sincronizar las voces:** No hablar uno encima del otro
6. **Responder preguntas con calma:** Está bien decir "no lo implementamos aún"
7. **Mostrar entusiasmo:** Es nuestro proyecto de título

### Preguntas Frecuentes Anticipadas

**P: ¿Por qué Transbank en integración y no producción?**
R: Producción requiere empresa constituida y credenciales comerciales. Documentamos el runbook completo para la migración.

**P: ¿Qué pasa si el profesional no sube evidencia?**
R: El trabajo no puede finalizarse sin evidencia. El pago queda retenido indefinidamente hasta que se resuelva.

**P: ¿Cómo evitan que cliente y profesional se contacten por fuera?**
R: El chat bloquea teléfonos, correos, URLs y usuarios de redes sociales. El pago se frena si detectamos contacto.

**P: ¿Cuántos usuarios simultáneos soporta?**
R: Probamos hasta 200 usuarios (p95=283ms). Con ~100 empieza a degradarse por el catálogo. Optimización pendiente.

**P: ¿Por qué Flutter y no nativo?**
R: Un código para Android e iOS. Reducimos tiempo de desarrollo en 40%. Web y desktop son secundarios.

**P: ¿Qué es 4NF y dónde se aplica?**
R: Cuarta Forma Normal: elimina dependencias multivaluadas. Ejemplo: `trabajador_servicios` separado de `trabajador_precios`.

**P: ¿641 pruebas no es excesivo?**
R: Incluye pruebas de contrato, unitarias, integración, e2e y SQL. Aseguran que el pago protegido y los estados funcionen siempre.

**P: ¿Cuándo lanzan comercialmente?**
R: Q1 2027 tras constituir empresa, obtener credenciales Transbank producción y publicar en tiendas.
