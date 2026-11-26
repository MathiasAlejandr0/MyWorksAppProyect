# My Works App — Proyecto de Título Profesional

**Institución:** Duoc UC — Sede Puerto Montt  
**Asignatura / programa:** Capstone PTY4614  
**Tipo de proyecto:** Proyecto de título profesional (desarrollo de software)  
**Equipo:** Mathias Alejandro Jara Alvarado · Nicolas Chiguay · Gabriel Valderas

---

## En resumen: qué es cada parte y dónde está

| Parte | Qué es | Dónde está |
|---|---|---|
| App móvil | App Flutter para clientes y profesionales (versión 1.0.15+16) | [`MyWorksAppProyect/myworksapp_app/`](MyWorksAppProyect/myworksapp_app/) |
| Web de clientes | Sitio React/Vite: buscar, reservar, pagar y seguir el pedido | [`MyWorksAppProyect/myworksapp_web/`](MyWorksAppProyect/myworksapp_web/), publicado en https://myworksapp.cl |
| Consola de escritorio | App Tauri para el equipo interno: pedidos, pagos, disputas, profesionales y equipo | [`MyWorksAppProyect/myworksapp_desktop/`](MyWorksAppProyect/myworksapp_desktop/) |
| Módulo compartido | Código TypeScript común a la web y la consola (sesión, pagos, chat, tipos) | [`MyWorksAppProyect/shared/`](MyWorksAppProyect/shared/) |
| Backend | Supabase: PostgreSQL con RLS. El 22-11-2026 la base viva tenía 76 tablas. El detalle y la forma normal están en el diccionario y en [`MyWorksAppProyect/docs/normalizacion.md`](MyWorksAppProyect/docs/normalizacion.md) | [`MyWorksAppProyect/myworksapp_app/supabase/`](MyWorksAppProyect/myworksapp_app/supabase/) |
| Documentación técnica | Casos de uso, diccionario de datos, guías de despliegue y pruebas | [`MyWorksAppProyect/docs/`](MyWorksAppProyect/docs/) |
| Índice de toda la documentación | Qué documento leer para cada tema | [`docs/INDICE.md`](docs/INDICE.md) |

## Contenido

- [1. Resumen del proyecto](#1-resumen-del-proyecto)
- [2. Objetivos](#2-objetivos)
- [3. Alcance del producto (qué entrega el título)](#3-alcance-del-producto-qué-entrega-el-título)
- [4. Arquitectura de software](#4-arquitectura-de-software)
- [5. Metodología de trabajo](#5-metodología-de-trabajo)
- [6. Criterios de diseño profesional aplicados](#6-criterios-de-diseño-profesional-aplicados)
- [7. Estructura del repositorio](#7-estructura-del-repositorio)
- [8. Cómo ejecutar (resumen)](#8-cómo-ejecutar-resumen)
- [9. Estado respecto al título y al producto](#9-estado-respecto-al-título-y-al-producto)
- [10. Autores](#10-autores)

---

## 1. Resumen del proyecto

**My Works App** es una plataforma digital multiplataforma que conecta **hogares y clientes** con **profesionales de oficios** (electricidad, gasfitería, armado, plomería, etc.) en Chile.

El proyecto de título aborda el problema de la **informalidad, la desconfianza y la falta de trazabilidad** en la contratación de servicios a domicilio: el cliente no siempre sabe a quién contratar, el profesional no siempre tiene un canal formal de demanda, y el pago suele quedar expuesto a incumplimientos.

La solución propuesta es un **ecosistema comercial** (app móvil, web y panel de escritorio) con:

- solicitud y agendamiento de visitas o urgencias;
- perfiles y roles (cliente, profesional, administración);
- **pago protegido (escrow de negocio)** mediante Transbank Webpay Plus y Oneclick;
- seguimiento del trabajo y herramientas operativas para el equipo interno.

El repositorio concentra los **entregables académicos Capstone** en la raíz y el **monorepo de software** dentro de [`MyWorksAppProyect/`](MyWorksAppProyect/).

---

## 2. Objetivos

Fuente oficial: informe final [`Fase 2/Myworksapp_Informe_Final_PTY4614.docx`](Fase%202/Myworksapp_Informe_Final_PTY4614.docx). Indicadores, metas y cumplimiento: [`docs/objetivos.md`](docs/objetivos.md).

**Objetivo general.** Desarrollar y validar, entre agosto y diciembre de 2026, una plataforma multiplataforma (aplicación móvil, sitio web y consola de escritorio) que permita a clientes de Puerto Montt elegir trabajadores de oficio según precio y calificación y contratarlos con pago protegido, de modo que en las pruebas con usuarios al menos el 80 % complete la contratación en menos de 10 minutos y el 100 % de los pagos de prueba quede retenido hasta la conformidad del cliente.

### Objetivos específicos

1. **OE1.** Modelo de datos relacional en Supabase/PostgreSQL, en tercera forma normal y con seguridad a nivel de fila (RLS).
2. **OE2.** Búsqueda y comparación de profesionales por oficio, comuna, precio y calificación en la app y la web, con el mismo orden: cercanía (bandas de 1 km), calificación y precio.
3. **OE3.** Pago con Transbank Webpay Plus y Oneclick (ambiente de integración), con el dinero retenido hasta la conformidad del cliente.
4. **OE4.** Ciclo de vida del trabajo (PIN de inicio, evidencia fotográfica, conformidad y reagendamiento) con una máquina de estados en la base.
5. **OE5.** Consola de escritorio para verificar profesionales y mediar disputas.
6. **OE6.** Validación con pruebas automatizadas, de carga y con usuarios (satisfacción y escala SUS).

### Enlaces

| Qué | Dónde |
|-----|-------|
| Web publicada (producción) | https://myworksapp.cl (también `www.myworksapp.cl` y https://myworksapp-cl.vercel.app) |
| Encuesta de prueba con usuarios (SUS) | https://myworksapp.cl/encuesta (en la app: inicio del cliente, «Encuesta de la prueba») |
| Guía de usuario | [`Fase 2/Guia_de_Usuario_MyWorksApp.pdf`](Fase%202/Guia_de_Usuario_MyWorksApp.pdf) |
| Demo paso a paso | [`MyWorksAppProyect/DEMO.md`](MyWorksAppProyect/DEMO.md) |
| Casos de uso (CU-01 a CU-34) | [`MyWorksAppProyect/docs/casos_de_uso.md`](MyWorksAppProyect/docs/casos_de_uso.md) |

---

## 3. Alcance del producto (qué entrega el título)

| Actor | Capacidad principal |
|-------|---------------------|
| **Cliente** | Buscar por oficio, ver el perfil público con reseñas, reservar una hora, pagar con Webpay Plus u Oneclick (o como invitado en la web), seguir el servicio, aprobar o rechazar cobros adicionales, dar conformidad y ejercer sus derechos sobre sus datos |
| **Profesional** | Gestionar trabajos, agenda, tarifas, evidencia y cobros desde la app móvil |
| **Administración / soporte / QA** | Operar desde la consola de escritorio (Tauri) con segundo factor TOTP: pedidos, disputas, pagos en garantía, liquidaciones, verificación, equipo y bitácora de auditoría |

**Fuera del alcance del MVP académico (documentado como pendiente):** Transbank en producción, liquidación bancaria automática (Khipu/Fintoc), firma electrónica de la Ley 19.799, publicación en tiendas y métricas de negocio reales.

---

## 4. Arquitectura de software

### En una frase

> **Monorepo multiplataforma** con arquitectura **cliente–servidor** sobre **Supabase (BaaS)**. Tres clientes (Flutter, web React/Vite y consola Tauri) usan el mismo backend (Auth, PostgreSQL con RLS, Realtime y Edge Functions). La web se publica en Vercel bajo el dominio propio `myworksapp.cl` (DNS en Cloudflare) y los correos de Supabase Auth salen por Resend. En móvil: organización **modular por features** con capas prácticas (UI → servicios → repositorios), inspirada en Clean Architecture de forma pragmática.

### Tipo de arquitectura

| Concepto | Qué es en este proyecto |
|----------|-------------------------|
| Cliente–servidor | Datos centralizados en la nube; las apps consultan Supabase |
| BaaS | Backend como servicio (Auth + Postgres + políticas RLS + Realtime) |
| Monorepo | Código de app, web, consola y `shared/` en un solo árbol (`MyWorksAppProyect/`) |
| Feature-First | En Flutter, pantallas por funcionalidad + `core/` compartido |
| Capas pragmáticas | Presentación → aplicación → dominio → infraestructura (repositorios) |
| Edge / serverless | Webpay, Oneclick, compra como invitado, reembolsos, liberación e invitaciones en 18 Edge Functions (Deno) |

### Diagrama

```text
┌─────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
│  App Flutter    │   │  Web (React/Vite)    │   │  Consola (Tauri 2)   │
│  Cliente /      │   │  Clientes, invitado  │   │  Admin / soporte /   │
│  profesional    │   │  myworksapp.cl       │   │  QA, TOTP, bitácora  │
└────────┬────────┘   └──────────┬───────────┘   └──────────┬───────────┘
         │                       │ shared/ (TypeScript)     │
         └───────────────┬───────┴──────────────────────────┘
                         ▼
        Supabase: Auth (SMTP Resend) · PostgreSQL + RLS · Realtime
                         │
                         ▼
        Edge Functions (Webpay, Oneclick, invitado, admin)
                         │
                         ▼
        Transbank (ambiente de integración)

Servicios de borde: Vercel (hosting web) · Cloudflare (DNS de myworksapp.cl,
Turnstile) · Resend (correo, dominio send.myworksapp.cl) · OpenFreeMap (mapas)
```

| Componente | Rol |
|------------|-----|
| `MyWorksAppProyect/myworksapp_app/` | App móvil Flutter (versión 1.0.15+16) |
| `MyWorksAppProyect/myworksapp_web/` | Web de clientes (sesión o invitado) |
| `MyWorksAppProyect/myworksapp_desktop/` | Consola operativa de escritorio (Tauri 2) |
| `MyWorksAppProyect/shared/` | Contratos TypeScript compartidos por la web y la consola |
| `MyWorksAppProyect/myworksapp_app/supabase/` | 133 archivos de migración y 18 Edge Functions en el repositorio. La base viva llega más lejos (`20261123020000`) |
| `Fase 1/`, `Fase 2/`, `Documentos Guia/` | Expediente académico Capstone |

Diccionario de datos: [`MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`](MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md). Estado técnico completo: [`MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`](MyWorksAppProyect/ESTADO_DEL_PROYECTO.md).

---

## 5. Metodología de trabajo

### En una frase

> **Scrum adaptado a un equipo de tres estudiantes**, orientado a un **MVP** y organizado por las **fases del Capstone PTY4614 (Duoc UC)**. Mathias Jara Alvarado es Product Owner y Scrum Master; el tablero está en GitHub Projects, el Daily Scrum se hace por Discord y la Sprint Review y la Retrospectiva, todos los fines de semana. Detalle y sprints: [`docs/metodologia.md`](docs/metodologia.md). Artefactos de la evaluación: [`docs/product_vision.md`](docs/product_vision.md), [`docs/product_backlog.md`](docs/product_backlog.md), [`docs/sprint_backlog.md`](docs/sprint_backlog.md), [`docs/retrospectiva.md`](docs/retrospectiva.md) y [`docs/requisitos_no_funcionales.md`](docs/requisitos_no_funcionales.md).

### Cómo trabajamos

| Práctica | En el proyecto |
|----------|----------------|
| Scrum adaptado | 11 sprints de 1 o 2 semanas reconstruidos desde el historial de GitHub; entregas por dominio: definición → backend/RLS → clientes → pagos → endurecimiento |
| MVP primero | Primero lo demostrable; pendientes explícitos (payout automático, Transbank en producción, tiendas) |
| Fases Capstone | Fase 1 definición; Fase 2 desarrollo, cerrada en su ventana el 22 de noviembre de 2026; Fase 3 vigente (pruebas, informe final y demostración). El software está en `MyWorksAppProyect/` |
| Calidad continua | CI, runbooks, diccionario BD, auditorías de seguridad |

Roles: Product Owner y Scrum Master, Mathias Jara Alvarado; equipo de desarrollo, Mathias Jara Alvarado, Gabriel Valderas y Nicolas Chiguay.

### Ciclo de una iteración

```text
Priorizar un flujo → acordar estados en BD → implementar (apps + Edge + SQL)
→ probar → documentar → commit / CI
```

---

## 6. Criterios de diseño profesional aplicados

- **Separación de secretos:** las claves de Transbank y del servidor solo viven en el backend (Edge / secrets de Supabase). Nadie del equipo las pone en la app que se instala en el celular.
- **Datos de la tarjeta de crédito/débito (PCI):** el usuario **no escribe el número de su tarjeta en My Works App**. Paga en la página oficial de **Transbank**.  
  En seguridad de pagos, al número de la tarjeta se le llama **PAN** (*Primary Account Number* = el número largo impreso en la tarjeta).  
  **En simple:** nosotros nunca pedimos ni guardamos ese número; Transbank lo maneja. Así reducimos el riesgo de fraude y cumplimos con buenas prácticas bancarias.
- **Escrow de negocio (plata “retenida”):** cuando Transbank confirma el cobro, el pago queda marcado como **retenido** en nuestra base. El profesional **no** recibe el dinero de inmediato: primero se completa el trabajo, el pago se libera y un administrador registra la transferencia. Eso da confianza al cliente.
- **Comisión:** el código cobra un 5 % del pago principal, con un mínimo de $1.000 y nunca más que el pago (`comision_servicio_clp`); se descuenta del monto del profesional. En una orden de cambio el cliente paga el monto más un 8 %.
- **Consola con mínimo privilegio:** las acciones con dinero y las invitaciones pasan por Edge Functions que llaman `is_admin()` con el JWT del usuario; cada acción queda en la bitácora inmutable `auditoria_consola`.
- **Invitado en la web:** si alguien reserva **sin** iniciar sesión, completa nombre, correo, teléfono y dirección, resuelve el desafío de Cloudflare Turnstile (validado en el servidor por `guest-checkout`) y luego va a Transbank. Si ya tiene sesión, paga en una ventana controlada **sin** abandonar My Works App.
- **Trazabilidad:** cada vez que se paga al profesional, queda un registro en la tabla `liquidaciones` (quién liquidó, cuánto, referencia de la transferencia). Sirve para auditoría académica y operativa.

---

## 7. Estructura del repositorio

| Ruta | Contenido |
|------|-----------|
| `Fase 1/` | Entregables y evidencias de definición del proyecto |
| `Fase 2/` | Informe, guía, pauta, presentación y demás entregables que la comisión lee en la Fase 3. No hay carpeta `Fase 3/` |
| `Documentos Guia/` | Guías e instructivos del programa |
| [`docs/Capstone_Project.mpp`](docs/Capstone_Project.mpp) | Planificación del proyecto (MS Project) |
| **`MyWorksAppProyect/`** | **Monorepo del producto** (app, web, desktop, shared, docs técnicos, CI) |
| `MyWorksAppProyect/docs/` | Casos de uso, diccionario BD, runbooks (Transbank, liquidación, despliegue web) y anexos de pruebas |
| [`docs/`](docs/) | Artefactos Scrum, carta Gantt, defensa y [índice](docs/INDICE.md) |
| [`MyWorksAppProyect/INSTALL.md`](MyWorksAppProyect/INSTALL.md) | Instalación y demo técnica |

### Documentos del título (dónde está cada uno)

El índice temático está en [`docs/INDICE.md`](docs/INDICE.md). Cada carpeta académica tiene un README corto.

**Informe y Fase 2**

- [`Fase 2/Myworksapp_Informe_Final_PTY4614.docx`](Fase%202/Myworksapp_Informe_Final_PTY4614.docx) y [`.pdf`](Fase%202/Myworksapp_Informe_Final_PTY4614.pdf) — informe final vigente
- [`Fase 2/Guia_de_Usuario_MyWorksApp.pdf`](Fase%202/Guia_de_Usuario_MyWorksApp.pdf) ([`.docx`](Fase%202/Guia_de_Usuario_MyWorksApp.docx))
- [`Fase 2/Casos_de_uso_MyWorksApp.docx`](Fase%202/Casos_de_uso_MyWorksApp.docx) y [`Anexo_A_Diccionario_de_tablas.md`](Fase%202/Anexo_A_Diccionario_de_tablas.md)
- [`Fase 2/Auditoria_BD_MyWorksApp.pdf`](Fase%202/Auditoria_BD_MyWorksApp.pdf) ([`.docx`](Fase%202/Auditoria_BD_MyWorksApp.docx))
- [`Fase 2/Prueba_de_carga_MyWorksApp.docx`](Fase%202/Prueba_de_carga_MyWorksApp.docx)
- [`Fase 2/Presentacion_final_MyWorksApp.pdf`](Fase%202/Presentacion_final_MyWorksApp.pdf) ([`.pptx`](Fase%202/Presentacion_final_MyWorksApp.pptx))
- [`Fase 2/Pauta_presentacion_demo.pdf`](Fase%202/Pauta_presentacion_demo.pdf)
- Diarios de reflexión Fase 2, guía 2.6, desarrollo 2.4, figuras y modelo ER: [`Fase 2/`](Fase%202/)

**Fase 1, guías y planificación**

- Definición del proyecto, guía del estudiante, pauta y presentación: [`Fase 1/Evidencias Grupales/`](Fase%201/Evidencias%20Grupales/)
- Autoevaluaciones y diarios (Chiguay, Jara, Valderas): [`Fase 1/Evidencias Individual/`](Fase%201/Evidencias%20Individual/)
- Guías del programa y plantilla de autoevaluación: [`Documentos Guia/`](Documentos%20Guia/)
- Carta Gantt: [`docs/CARTA_GANTT_ACTUALIZADA.md`](docs/CARTA_GANTT_ACTUALIZADA.md) y [`docs/Capstone_Project.mpp`](docs/Capstone_Project.mpp)

**Documentación de producto y estado**

- Cómo ejecutar y demostrar: [`INSTALL.md`](MyWorksAppProyect/INSTALL.md), [`DEMO.md`](MyWorksAppProyect/DEMO.md)
- Estado vigente del software: [`ESTADO_DEL_PROYECTO.md`](MyWorksAppProyect/ESTADO_DEL_PROYECTO.md)
- Casos de uso, diccionario, UML y runbooks: [`MyWorksAppProyect/docs/`](MyWorksAppProyect/docs/)
- Auditoría de la web (22-11-2026): [`AUDITORIA_WEB_22NOV2026.md`](MyWorksAppProyect/docs/AUDITORIA_WEB_22NOV2026.md)

---

## 8. Cómo ejecutar (resumen)

Detalle completo en [`MyWorksAppProyect/INSTALL.md`](MyWorksAppProyect/INSTALL.md).

```bash
# Web
cd MyWorksAppProyect/myworksapp_web && npm install && npm run dev

# Desktop
cd MyWorksAppProyect/myworksapp_desktop && npm install && npm run dev

# App Flutter
cd MyWorksAppProyect/myworksapp_app && flutter pub get && flutter run
```

Configurar variables Supabase según `.env.example` de web/desktop y `--dart-define` en Flutter.

---

## 9. Estado respecto al título y al producto

Estado al 22 de noviembre de 2026, 23:07 hora de Chile. La fase vigente es la Fase 3 (pruebas, informe final y demostración). `origin/main` está en `19d1da3`. El detalle está en `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`.

| Dimensión | Estado actual |
|-----------|----------------|
| Definición / evidencia Fase 1 | Presente en carpetas académicas; no se reescribe |
| Fase 2 (desarrollo) | Ventana cerrada el 22 de noviembre de 2026. El relato sigue en `Fase 2/` y en la carta Gantt |
| Fase 3 (vigente) | Pruebas, informe final y demostración. No hay plantilla de estudiante de esta fase en el repositorio |
| MVP técnico multiplataforma | Implementado (`MyWorksAppProyect/`) |
| Web en producción | Publicada en Vercel con dominio propio `myworksapp.cl` |
| Pagos Webpay Plus y Oneclick | Implementados en **ambiente de integración** (solo tarjetas de prueba) |
| Correo | Supabase Auth envía por SMTP de Resend desde `no-responder@myworksapp.cl` (13 plantillas en español); desde el 20-nov las Edge Functions envían los correos de pago recibido, alta de invitado, reembolso y pago liberado (PR #82) |
| Liquidación al profesional | Manual por administrador (automatización futura) |
| Lanzamiento comercial | Condicionado a empresa, credenciales de producción de Transbank y al piloto con usuarios |

**Pendiente de integrar o de publicar:** `cursor/consola-bugs` (24 errores de la consola del 20-11). El aviso académico ya está en `main`. Falta desplegar la web posterior al PR #100 y la función `oneclick-charge` que reanuda la orden de cambio. También pendientes: la invitación por Resend (`INVITE_PROVIDER=resend`) y la prueba de punta a punta de `soporte@myworksapp.cl`. Detalle en `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`.

---

## 10. Autores

Proyecto de título profesional desarrollado por el equipo indicado arriba, sede **Duoc UC Puerto Montt**, en el marco del Capstone **PTY4614**.

Para el estado técnico del monorepo, ver [`MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`](MyWorksAppProyect/ESTADO_DEL_PROYECTO.md).
