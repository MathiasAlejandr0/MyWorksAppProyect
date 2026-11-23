# Carta Gantt — My Works App
## Proyecto de Título PTY4614

**Institución:** Duoc UC — Sede Puerto Montt  
**Equipo:** Mathias Alejandro Jara Alvarado · Nicolas Chiguay · Gabriel Valderas  
**Última actualización:** 22 de noviembre de 2026, 23:07 hora de Chile  
**Estado:** Fase 3 en curso (Sprint 11). La ventana del Sprint 10 cerró ese día

---

## Resumen ejecutivo

Este documento presenta la planificación temporal completa del proyecto My Works App, desde su inicio en agosto de 2026 hasta su defensa en diciembre de 2026. El proyecto sigue metodología Scrum adaptada con 11 sprints organizados en 3 fases del Capstone PTY4614.

**Estado actual (22-nov-2026, 23:07 hora de Chile):**
- ✅ Ventana del Sprint 10 cerrada (Fase 2, desarrollo)
- 🔄 Fase 3 en curso: pruebas, informe final y demostración (Sprint 11)
- ✅ MVP técnico implementado y funcional
- ✅ Web en producción (https://myworksapp.cl). El paquete publicado a las 23:03 seguía siendo el anterior; el redespliegue queda pendiente
- ✅ 641 pruebas automatizadas pasando en el corte del 20-nov. Esta revisión no repitió esa corrida

---

## Línea de tiempo del proyecto

```
Agosto 2026          Septiembre 2026         Octubre 2026           Noviembre 2026        Diciembre 2026
│                    │                       │                      │                     │
├─ S1 ──┬─ S2 ──┬─ S3─┼─ S4 ───────┬─ S5 ───┼──────┬─ S6 ──────┬─ S7 ─────┬─ S8 ───────┬─ S9 ─┬─ S10 ─┬─ S11 ────────┤
│ Def.  │ Evid. │ Fase1│ Plan. Fase2│ BD +   │ Pagos│ Ubicación│ Agenda + │ Integr.   │ Cierre│ Defensa        │
│       │       │      │            │ Monorepo│ RLS  │ Valid.   │ Evidencia│ Pruebas   │ Fase2 │ Final          │
└───────┴───────┴──────┴────────────┴─────────┴──────┴──────────┴──────────┴───────────┴───────┴────────────────┘
10 ago                                                                                  20 nov              6 dic
```

---

## Fase 1: Definición del Proyecto (Semanas 1-4)

### Sprint 1: Definición del producto
**Fechas:** 10 – 16 de agosto de 2026  
**Duración:** 1 semana  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Levantamiento del problema | Equipo | Identificación de informalidad en servicios del hogar |
| Definición de alcance MVP | Product Owner | Documento de visión del producto |
| Identificación de actores (cliente, profesional, admin) | Equipo | Casos de uso preliminares |
| Selección de tecnologías (Flutter + Supabase) | Equipo | Stack tecnológico definido |
| Creación del repositorio GitHub | Nicolas Chiguay | Primer commit (2026-08-10) |

**Entregables:**
- ✅ Repositorio inicializado
- ✅ Documento de visión del producto
- ✅ Stack tecnológico definido

---

### Sprint 2: Evidencias de Fase 1
**Fechas:** 17 – 23 de agosto de 2026  
**Duración:** 1 semana  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Elaboración de documento de definición APT | Nicolas Chiguay y equipo | Entregable académico Fase 1 |
| Casos de uso iniciales | Equipo | 10 casos de uso definidos |
| Mockups de interfaz | Mathias Jara | Diseño de pantallas principales |
| Planificación inicial (Gantt v1) | Equipo | Primera carta Gantt |
| Evidencias individuales | Cada integrante | Diarios de reflexión |

**Entregables:**
- ✅ `Definicion Proyecto APT - Fase 1_ My Works App.docx`
- ✅ Mockups de interfaz
- ✅ Evidencias individuales Fase 1

---

### Sprint 3: Cierre de Fase 1
**Fechas:** 24 – 30 de agosto de 2026  
**Duración:** 1 semana  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Revisión y ajustes de documentación | Equipo | Documentación Fase 1 completa |
| Preparación de presentación Fase 1 | Equipo | Presentación lista |
| Entrega de Fase 1 | Equipo | ✅ Fase 1 aprobada |
| Planificación detallada Fase 2 | Product Owner | Backlog priorizado |

**Entregables:**
- ✅ Documentación Fase 1 completa
- ✅ Presentación Fase 1
- ✅ Backlog priorizado para Fase 2

---

## Fase 2: Desarrollo e Implementación (Semanas 5-18)

### Sprint 4: Planificación de Fase 2
**Fechas:** 31 de agosto – 13 de septiembre de 2026  
**Duración:** 2 semanas  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Refinamiento del Product Backlog | Product Owner | 25 historias de usuario priorizadas |
| Diseño de arquitectura de datos | Gabriel Valderas | Modelo ER con 60 tablas |
| Diseño de arquitectura de aplicación | Mathias Jara | Arquitectura Feature-First + capas |
| Configuración de Supabase | Gabriel Valderas | Proyecto Supabase creado |
| Carta Gantt actualizada (v2) | Nicolas Chiguay | `Capstone_Project.mpp` creado (13-sep) |

**Entregables:**
- ✅ Modelo Entidad-Relación completo
- ✅ Arquitectura de software definida
- ✅ `Capstone_Project.mpp` en repositorio
- ✅ Backlog refinado con 25 HU

---

### Sprint 5: Base de datos y monorepo
**Fechas:** 14 – 27 de septiembre de 2026  
**Duración:** 2 semanas  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Implementación de esquema PostgreSQL | Gabriel Valderas | 40 tablas iniciales creadas |
| Configuración de Row Level Security (RLS) | Gabriel Valderas | Políticas de seguridad por tabla |
| Estructura del monorepo | Mathias Jara | `myworksapp_app/`, `shared/` |
| Autenticación con Supabase Auth | Equipo | Login y registro funcionando |
| CI/CD con GitHub Actions | Equipo | Flutter CI configurado |
| Primera auditoría de seguridad | Gabriel Valderas | Documento `AUDITORIA_2026-09.md` |

**Entregables:**
- ✅ Base de datos con 40+ tablas
- ✅ RLS activo en todas las tablas
- ✅ Monorepo estructurado
- ✅ Autenticación funcional
- ✅ CI/CD operativo
- ✅ Auditoría de seguridad (septiembre)

---

### Sprint 6: Pago con garantía y reputación
**Fechas:** 28 de septiembre – 11 de octubre de 2026  
**Duración:** 2 semanas  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Integración Transbank Webpay Plus | Gabriel Valderas y Mathias Jara | Pago en ambiente de integración |
| Implementación de escrow (pago retenido) | Gabriel Valderas | Estados: retenido → liberado |
| Edge Functions para Webpay | Gabriel Valderas | 10 funciones Deno desplegadas |
| Sistema de calificaciones | Mathias Jara | Modelo 1-5 estrellas implementado |
| Cálculo de reputación | Gabriel Valderas | Algoritmo de puntaje de reputación |
| Máquina de estados del trabajo | Gabriel Valderas | `JobStateMachine` implementada |

**Entregables:**
- ✅ Webpay Plus funcionando (integración)
- ✅ Escrow implementado
- ✅ 10 Edge Functions (webpay-create, webpay-commit, etc.)
- ✅ Sistema de calificaciones funcional
- ✅ Algoritmo de reputación

---

### Sprint 7: Ubicación y validaciones
**Fechas:** 12 – 25 de octubre de 2026  
**Duración:** 2 semanas  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Integración de mapas (OpenFreeMap) | Mathias Jara | Mapas sin API key |
| Geolocalización del profesional | Mathias Jara | Ubicación en tiempo real |
| Catálogo con filtros geográficos | Mathias Jara | Búsqueda por cercanía |
| Validaciones de negocio | Gabriel Valderas | `PricingGuardService` |
| Sistema de disputas | Gabriel Valderas | Flujo de mediación |
| Segunda auditoría de seguridad | Gabriel Valderas | `AUDITORIA_2026-10-05.md` |

**Entregables:**
- ✅ Mapas integrados en app y web
- ✅ Geolocalización en tiempo real
- ✅ Catálogo con búsqueda geográfica
- ✅ Sistema de disputas funcional
- ✅ Auditoría de seguridad (octubre)

---

### Sprint 8: Agenda y evidencia
**Fechas:** 26 de octubre – 8 de noviembre de 2026  
**Duración:** 2 semanas  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Gestión de agenda del profesional | Mathias Jara | Horarios publicados y libres |
| Reserva de horas | Mathias Jara | Sistema de reservas funcional |
| Subida de evidencia (fotos/video) | Mathias Jara | Bucket privado + WebP |
| Chat en tiempo real | Mathias Jara | Supabase Realtime integrado |
| PIN de inicio de trabajo | Gabriel Valderas | Sistema de 4 dígitos |
| Notificaciones locales | Mathias Jara | `flutter_local_notifications` |

**Entregables:**
- ✅ Sistema de agenda completo
- ✅ Evidencia fotográfica/video
- ✅ Chat en tiempo real
- ✅ PIN de inicio implementado
- ✅ Notificaciones locales

---

### Sprint 9: Integración y pruebas
**Fechas:** 9 – 15 de noviembre de 2026  
**Duración:** 1 semana  
**Estado:** ✅ Completado

| Actividad | Responsable | Hito |
|-----------|-------------|------|
| Integración de todos los módulos | Equipo | Flujo completo funcionando |
| Pruebas automatizadas Flutter | Equipo | 174 tests implementados |
| Pruebas Playwright (web) | Equipo | 17 tests implementados |
| Pruebas TypeScript (shared) | Equipo | 110 tests implementados |
| Pruebas de carga y rendimiento | Equipo | Hasta 100 usuarios concurrentes |
| Documentación técnica | Nicolas Chiguay | 34 casos de uso documentados |
| Corrección de bugs críticos | Equipo | Issues prioritarios resueltos |

**Entregables:**
- ✅ 301 pruebas automatizadas (total)
- ✅ Pruebas de rendimiento documentadas
- ✅ Documentación técnica completa
- ✅ Bugs críticos resueltos

**Métricas del Sprint 9:**
- 97 commits en una semana
- Mayor intensidad de trabajo del proyecto
- Integración final de todos los componentes

---

### Sprint 10: Cierre de Fase 2
**Fechas:** 16 – 22 de noviembre de 2026  
**Duración:** 1 semana  
**Estado:** 🔄 En curso (al 20-nov)

| Actividad | Responsable | Estado | Hito |
|-----------|-------------|--------|------|
| Consola de escritorio (Tauri 2) | Mathias Jara y Nicolas Chiguay | ✅ Completado | 20 módulos operativos |
| Deploy web a producción | Mathias Jara | ✅ Completado | https://myworksapp.cl en vivo |
| Dominio y DNS | Equipo | ✅ Completado | Cloudflare configurado |
| Correos transaccionales (Resend) | Gabriel Valderas | ✅ Completado | SMTP configurado, 13 plantillas |
| Límite de tasa global | Gabriel Valderas | ✅ Completado | `rate_limit_consumir` implementado |
| Segundo factor (TOTP) en consola | Mathias Jara | ✅ Completado | Autenticación de dos factores |
| Prueba integral P-17 | Equipo | ✅ Completado | 641 de 641 pruebas pasando |
| Corrección H1 (alta profesionales) | Gabriel Valderas | Migración aplicada | `20261120180000` está en la base viva; el alta no se repitió el 22-11 |
| Arreglo bugs consola (24 errores) | Equipo | ⏳ En rama | `cursor/consola-bugs` |
| Páginas legales | Nicolas Chiguay | En `main` | Falta el despliegue de https://myworksapp.cl |
| Informe final PTY4614 | Nicolas Chiguay y equipo | ✅ Completado | Documento Word actualizado |
| Actualización de documentación Scrum | Nicolas Chiguay | ✅ Completado | Visión, backlog, sprint, retrospectiva |

**Entregables al 20-nov-2026:**
- ✅ Web en producción con dominio propio
- ✅ Consola de escritorio operativa (24 bugs pendientes)
- ✅ Correos transaccionales con Resend
- ✅ 641 pruebas automatizadas pasando
- ✅ Informe final actualizado
- Migración de H1 aplicada en la base viva el 22-11; el alta no se volvió a medir
- ⏳ 24 bugs de consola (rama sin merge)
- Páginas legales en `main`; el 22-11 a las 23:03 (hora de Chile) el sitio seguía sirviendo `/assets/index-dFwoI3u5.js`

Estos pendientes pasan a la Fase 3. No quedaron cerrados con el fin de la ventana del Sprint 10.

**Métricas del Sprint 10 (al 20-nov):**
- 86 commits (60 después del corte del 17-nov)
- 8 pull requests mergeados (#75 a #82)
- Web desplegada en producción
- Consola de escritorio completada

**Pendientes que pasan a la Fase 3:**
1. Mergear rama `cursor/consola-bugs` (arreglo de 24 errores)
2. Desplegar en Vercel el `main` que ya trae las páginas legales
3. La migración de H1 ya está en la base viva; falta repetir el alta de un profesional
4. Activar `INVITE_PROVIDER=resend`
5. Probar `soporte@myworksapp.cl` de punta a punta
6. Desplegar `send-push` (notificaciones remotas)
7. Programar llamada automática a `soporte-automatico`

---

## Fase 3: Cierre y Defensa (Semanas 19-20)

### Sprint 11: Defensa y entrega final
**Fechas:** 23 de noviembre – 6 de diciembre de 2026  
**Duración:** 2 semanas  
**Estado:** 🔄 En curso desde el 22 de noviembre de 2026, 23:07 hora de Chile (Fase 3: pruebas, informe final y demostración)

| Actividad | Responsable | Fecha objetivo |
|-----------|-------------|----------------|
| Aplicar correcciones finales | Equipo | 23-24 nov |
| Mergear ramas pendientes | Equipo | 25 nov |
| Pruebas finales de integración | Equipo | 26-27 nov |
| Preparación de presentación de defensa | Equipo | 28-30 nov |
| Ensayo de demostración | Equipo | 1-2 dic |
| Revisión final de informe | Nicolas Chiguay | 3 dic |
| Entrega de documentación final | Equipo | 4 dic |
| **DEFENSA DEL PROYECTO** | **Equipo** | **5-6 dic (estimado)** |

**Entregables Sprint 11:**
- 📅 Código final en `main` (sin ramas pendientes)
- 📅 Informe final PTY4614 revisado
- 📅 Presentación de defensa
- 📅 Video demostración del producto
- 📅 Guía de usuario final
- 📅 Documentación técnica completa

---

## Inventario técnico (al 20-nov-2026)

### Código y arquitectura

| Componente | Cantidad | Ubicación |
|------------|----------|-----------|
| Migraciones SQL | 125 | `myworksapp_app/supabase/migrations/` |
| Edge Functions | 18 | `myworksapp_app/supabase/functions/` |
| Tablas de base de datos | 60 | Esquema `public` en PostgreSQL |
| Casos de uso documentados | 34 | `MyWorksAppProyect/docs/casos_de_uso.md` |
| Historias de usuario | 25 | `docs/product_backlog.md` |
| Workflows CI/CD | 6 | `.github/workflows/` |
| Pruebas automatizadas | 641 | Flutter (174) + Playwright (17) + shared (231) + otros |

### Plataformas implementadas

| Plataforma | Tecnología | Estado | URL/Ubicación |
|------------|------------|--------|---------------|
| App móvil | Flutter 3.x | ✅ Funcional | `MyWorksAppProyect/myworksapp_app/` (v1.0.15+16) |
| Web de clientes | React 19 + Vite 8 | ✅ En producción | https://myworksapp.cl |
| Consola de escritorio | Tauri 2 + React 19 | ✅ Funcional | `MyWorksAppProyect/myworksapp_desktop/` (v0.1.0) |
| Backend | Supabase | ✅ En producción | PostgreSQL + Auth + Edge Functions |
| Módulo compartido | TypeScript | ✅ Funcional | `MyWorksAppProyect/shared/` |

### Servicios externos integrados

| Servicio | Propósito | Estado |
|----------|-----------|--------|
| Transbank Webpay Plus | Pago con tarjeta | ✅ Ambiente de integración |
| Transbank Oneclick | Pago con tarjeta inscrita | ✅ Ambiente de integración |
| Resend | Correo transaccional | ✅ En producción |
| Cloudflare | DNS + Turnstile | ✅ En producción |
| OpenFreeMap | Mapas vectoriales | ✅ En producción |
| Vercel | Hosting web | ✅ En producción |

---

## Hitos principales del proyecto

| # | Hito | Fecha | Sprint | Estado |
|---|------|-------|--------|--------|
| 1 | Inicio del proyecto | 10 ago 2026 | S1 | ✅ |
| 2 | Aprobación Fase 1 | 30 ago 2026 | S3 | ✅ |
| 3 | Carta Gantt v1 (archivo .mpp) | 13 sep 2026 | S4 | ✅ |
| 4 | Base de datos con RLS | 27 sep 2026 | S5 | ✅ |
| 5 | Primera auditoría de seguridad | 28 sep 2026 | S5 | ✅ |
| 6 | Integración Webpay Plus | 11 oct 2026 | S6 | ✅ |
| 7 | Segunda auditoría de seguridad | 5 oct 2026 | S7 | ✅ |
| 8 | Mapas integrados | 25 oct 2026 | S7 | ✅ |
| 9 | Chat en tiempo real | 8 nov 2026 | S8 | ✅ |
| 10 | 301 pruebas automatizadas | 15 nov 2026 | S9 | ✅ |
| 11 | Web en producción (myworksapp.cl) | 18 nov 2026 | S10 | ✅ |
| 12 | Consola de escritorio completa | 19 nov 2026 | S10 | ✅ |
| 13 | Correos con Resend | 20 nov 2026 | S10 | ✅ |
| 14 | **641 pruebas automatizadas** | **20 nov 2026** | **S10** | **✅** |
| 15 | Carta Gantt actualizada (este doc) | 20 nov 2026 | S10 | ✅ |
| 16 | Cierre de la ventana de Fase 2 | 22 nov 2026 | S10 | ✅ |
| 17 | Fase 3: pruebas, informe final y demostración | 22 nov 2026 | S11 | 🔄 |
| 18 | Defensa del proyecto | 5-6 dic 2026 | S11 | 📅 |

---

## Roles y responsabilidades

### Estructura del equipo

| Rol | Responsable | Funciones principales |
|-----|-------------|----------------------|
| Product Owner | Mathias Jara Alvarado | Priorización del backlog, visión del producto, contacto con stakeholders |
| Scrum Master | Mathias Jara Alvarado | Facilitación de ceremonias, remoción de impedimentos, coaching ágil |
| Desarrollador Backend/BD | Gabriel Valderas | Base de datos, RLS, Edge Functions, pagos, seguridad |
| Desarrollador Frontend | Mathias Jara Alvarado | App Flutter, web React, consola Tauri, UX/UI |
| Desarrollador Frontend/Docs | Nicolas Chiguay | Web, consola, UX, documentación, informe |

### Distribución de commits (main, al 17-nov)

| Desarrollador | Commits | Porcentaje | Período |
|--------------|---------|------------|---------|
| Mathias Jara | 144 | 65.2% | Ago-Nov 2026 |
| Gabriel Valderas | 47 | 21.3% | Ago-Nov 2026 |
| Nicolas Chiguay | 24 | 10.9% | Ago-Nov 2026 |
| Cursor Agent | 5 | 2.3% | Nov 2026 |
| Grok Bot | 1 | 0.5% | Nov 2026 |

---

## Metodología aplicada

### Framework: Scrum adaptado

- **Duración de sprints:** 1 semana (S1-S3, S9-S10) o 2 semanas (S4-S8, S11)
- **Equipo:** 3 integrantes (estudiantes Duoc UC)
- **Tablero:** GitHub Projects
- **Canal de comunicación:** Discord

### Ceremonias

| Ceremonia | Frecuencia | Momento | Duración aprox. |
|-----------|------------|---------|-----------------|
| Sprint Planning | Inicio de cada sprint | Lunes | 1-2 horas |
| Daily Scrum | Diaria | Días de trabajo | 15 minutos |
| Sprint Review | Fin de cada sprint | Fines de semana | 1-2 horas |
| Sprint Retrospective | Fin de cada sprint | Después de Review | 30-60 minutos |
| Backlog Refinement | Continuo | Antes de Planning | Variable |

### Definition of Done

Un incremento está "Done" cuando:
- ✅ El código funciona según los criterios de aceptación
- ✅ Está revisado (pull request)
- ✅ Está subido al repositorio (mergeado a `main`)
- ✅ Pasa los tests automatizados (CI en verde)
- ✅ Está documentado (README, docs técnicos)

---

## Riesgos y mitigación

### Riesgos identificados y gestionados

| Riesgo | Probabilidad | Impacto | Mitigación aplicada | Estado |
|--------|--------------|---------|---------------------|--------|
| Complejidad de RLS en Supabase | Alta | Alto | Auditorías de seguridad periódicas | ✅ Mitigado |
| Integración Transbank en producción | Media | Alto | Documentación detallada de runbook | ⏳ Pendiente |
| Capacidad y rendimiento | Media | Medio | Pruebas de carga documentadas | ⏳ Limitado |
| Retraso en desarrollo | Media | Alto | Sprints cortos, entregas incrementales | ✅ Mitigado |
| Falta de experiencia en tecnologías | Alta | Medio | Prototipado temprano, documentación | ✅ Mitigado |
| Dependencia de servicios externos | Baja | Alto | Ambientes de integración, fallbacks | ✅ Mitigado |

### Riesgos actuales (al 20-nov)

| Riesgo | Descripción | Plan de acción |
|--------|-------------|----------------|
| H1 (alta profesionales) | Fallo en producción con `generate_series` | Aplicar migración correctiva del parche |
| 24 bugs en consola | Errores encontrados en prueba del 20-nov | Mergear rama `cursor/consola-bugs` |
| Capacidad limitada | Degradación con ~100 usuarios | Optimizar catálogo, considerar CDN |
| Push notifications | `send-push` no desplegada | Desplegar función y probar |

---

## Métricas del proyecto

### Actividad de desarrollo

| Métrica | Valor | Fecha corte |
|---------|-------|-------------|
| Commits totales en `main` | 228 | 17-nov-2026 |
| Pull requests creadas | 74 | 17-nov-2026 |
| Pull requests mergeadas | 30 | 17-nov-2026 |
| Ramas activas | 2 (sin merge) | 20-nov-2026 |
| Issues cerrados | N/A | No se usan issues |

### Calidad del código

| Métrica | Valor | Fuente |
|---------|-------|--------|
| Pruebas automatizadas | 641 | P-17 (19-20 nov) |
| - Flutter | 174 | `flutter test` |
| - Playwright (web) | 17 | Playwright |
| - TypeScript (shared) | 231 | Jest |
| - Escritorio | 12 | Tauri tests |
| - SQL | 207 | pgTAP |
| CI/CD | ✅ En verde | GitHub Actions |
| Auditorías de seguridad | 4 | Sep, Oct, Nov (x2) |

### Documentación

| Tipo | Cantidad | Ubicación |
|------|----------|-----------|
| Documentos técnicos | 40+ | `MyWorksAppProyect/docs/` |
| Casos de uso | 34 | `casos_de_uso.md` |
| Runbooks | 5 | `RUNBOOK_*.md` |
| Documentos académicos | 10+ | `Fase 1/`, `Fase 2/` |

---

## Recursos y herramientas

### Desarrollo

| Herramienta | Propósito | Licencia |
|-------------|-----------|----------|
| Flutter SDK 3.x | Framework móvil | BSD-3 |
| React 19 | Framework web | MIT |
| Tauri 2 | Framework desktop | MIT/Apache |
| Supabase | Backend as a Service | Apache 2.0 |
| PostgreSQL 17 | Base de datos | PostgreSQL |
| TypeScript | Lenguaje compartido | Apache 2.0 |

### Gestión de proyecto

| Herramienta | Propósito | Costo |
|-------------|-----------|-------|
| GitHub | Repositorio y CI/CD | Gratis |
| GitHub Projects | Tablero Scrum | Gratis |
| Discord | Comunicación | Gratis |
| Microsoft Project | Carta Gantt original | Licencia institucional |

### Servicios en la nube

| Servicio | Plan | Costo mensual |
|----------|------|---------------|
| Supabase | Pro | ~USD $25 |
| Vercel | Hobby → Pro | ~USD $20 |
| Cloudflare | Free | USD $0 |
| Resend | Free | USD $0 (100 emails/día) |
| Transbank | Integración | USD $0 (ambiente prueba) |

**Costo total mensual estimado:** ~USD $45

---

## Brecha hacia producción comercial

### Pendientes técnicos

| Pendiente | Prioridad | Esfuerzo estimado | Bloqueante |
|-----------|-----------|-------------------|------------|
| Corregir H1 (alta profesionales) | 🔴 Crítica | 1 día | Sí |
| Transbank en producción | 🔴 Alta | 3-5 días | Sí |
| Mergear bugs de consola | 🟠 Alta | 2-3 días | No |
| Páginas legales finales | 🟡 Media | 1 día | No |
| Notificaciones push desplegadas | 🟡 Media | 1 día | No |
| Soporte automático programado | 🟡 Media | 1 día | No |
| Liquidación automática | 🟡 Media | 5-7 días | No |
| Optimización de capacidad | 🟠 Alta | 5-10 días | Parcial |
| Publicación en tiendas | 🔴 Alta | 10-15 días | Sí |

### Requisitos no técnicos

| Requisito | Estado | Responsable |
|-----------|--------|-------------|
| Constitución de empresa | ⏳ Pendiente | Equipo |
| Credenciales Transbank producción | ⏳ Pendiente | Empresa + Transbank |
| Políticas legales aprobadas | ⏳ En borrador | Equipo + asesoría legal |
| Piloto con usuarios reales | 📅 Post-defensa | Equipo |
| Cuentas en tiendas (Google/Apple) | ⏳ Pendiente | Empresa |

---

## Lecciones aprendidas

### Técnicas

1. **RLS en Supabase:** Complejo pero potente; requiere auditorías frecuentes
2. **Feature-First:** Escaló bien para equipo pequeño; `core/` evitó duplicación
3. **Supabase BaaS:** Aceleró desarrollo; Auth + RLS + Realtime sin backend propio
4. **Flutter multiplataforma:** Un código para Android/iOS; web y desktop limitados
5. **Transbank integración:** Documentación extensa pero ejemplos escasos

### De proceso

1. **Sprints cortos (1 sem):** Mejor feedback en Fase 1 y cierre (S9-S10)
2. **Sprints largos (2 sem):** Adecuados para desarrollo intenso (S4-S8)
3. **CI/CD temprano:** Evitó regresiones; Gitleaks detectó secretos
4. **Pull requests:** Mejoraron calidad; 30 merges con revisión
5. **Documentación continua:** Facilitó onboarding y entrega académica

### De negocio

1. **Escrow es clave:** Genera confianza en marketplace de servicios
2. **Verificación del profesional:** Esencial para seguridad del cliente
3. **Evidencia fotográfica:** Reduce disputas y protege ambas partes
4. **Chat con filtros:** Evita bypass de la plataforma
5. **Modelo de comisión:** 5% del profesional más 8% en órdenes de cambio

---

## Próximos pasos (post-Sprint 11)

### Inmediato (diciembre 2026)

- [ ] Defensa exitosa del proyecto de título
- [ ] Repetir el alta de un profesional (la migración de H1 ya está aplicada)
- [ ] Merge de `cursor/consola-bugs` y despliegue web del aviso académico, que ya está en `main`
- [ ] Activación de todas las funcionalidades pendientes

### Corto plazo (enero-marzo 2027)

- [ ] Constitución de empresa (SpA)
- [ ] Credenciales Transbank en producción
- [ ] Optimización de capacidad (catálogo)
- [ ] Liquidación automática (Khipu/Fintoc)
- [ ] Publicación en Google Play Store
- [ ] Publicación en Apple App Store

### Mediano plazo (abril-junio 2027)

- [ ] Piloto con 50 usuarios reales
- [ ] Marketing digital básico
- [ ] Monitoreo y métricas de negocio
- [ ] Soporte técnico 24/7
- [ ] Expansión a otras comunas

### Largo plazo (segundo semestre 2027)

- [ ] Escalamiento a otras regiones
- [ ] Nuevas categorías de servicio
- [ ] Programa de fidelización
- [ ] API pública para partners
- [ ] Modelo de suscripción para profesionales

---

## Conclusión

El proyecto My Works App ha cumplido exitosamente con los objetivos académicos del Capstone PTY4614, entregando un **MVP técnico completo y funcional** que demuestra la viabilidad de un marketplace de servicios del hogar con:

✅ **Arquitectura profesional** (Feature-First + Clean Architecture pragmática)  
✅ **Backend** (al 22-11-2026: 76 tablas en la base viva, todas con RLS; 133 archivos de migración en el repositorio)  
✅ **Multiplataforma** (móvil Flutter, web React, consola Tauri)  
✅ **Pagos protegidos** (Transbank Webpay con escrow)  
✅ **Calidad demostrada** (641 pruebas automatizadas)  
✅ **Producción funcional** (web en https://myworksapp.cl)  

El proyecto está **listo para la defensa** y tiene una **ruta clara hacia producción comercial** una vez resueltos los pendientes técnicos y no técnicos identificados.

---

## Referencias del proyecto

- **Repositorio:** https://github.com/nicoussj/Proyecto-Titulo-MyWorksApp
- **Web en producción:** https://myworksapp.cl
- **Documentación técnica:** `MyWorksAppProyect/docs/`
- **Estado del proyecto:** `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`
- **Guía de instalación:** `MyWorksAppProyect/INSTALL.md`
- **Guía de demostración:** `MyWorksAppProyect/DEMO.md`
- **Carta Gantt original:** `Capstone_Project.mpp` (13-sep-2026)

---

**Documento generado:** 20 de noviembre de 2026  
**Versión:** 2.0 (actualización completa sobre `main` `d9d2c7c`)  
**Autores:** Equipo My Works App — Duoc UC Puerto Montt  
**Próxima revisión:** Post-defensa (diciembre 2026)
