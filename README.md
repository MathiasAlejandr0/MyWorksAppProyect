# My Works App — Proyecto de Título Profesional

**Institución:** Duoc UC — Sede Puerto Montt  
**Asignatura / programa:** Capstone PTY4614  
**Tipo de proyecto:** Proyecto de título profesional (desarrollo de software)  
**Equipo:** Mathias Alejandro Jara Alvarado · Nicolas Chiguay · Gabriel Valderas

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
| Web publicada | https://myworksapp-cl.vercel.app |
| Encuesta de prueba con usuarios (SUS) | https://myworksapp-cl.vercel.app/encuesta (en la app: inicio del cliente, «Encuesta de la prueba») |
| Guía de usuario | [`Fase 2/Guia_de_Usuario_MyWorksApp.pdf`](Fase%202/Guia_de_Usuario_MyWorksApp.pdf) |
| Demo paso a paso | [`MyWorksAppProyect/DEMO.md`](MyWorksAppProyect/DEMO.md) |

---

## 3. Alcance del producto (qué entrega el título)

| Actor | Capacidad principal |
|-------|---------------------|
| **Cliente** | Buscar oficio, solicitar visita/urgencia, pagar con Webpay Plus u Oneclick, seguir el servicio y dar conformidad |
| **Profesional** | Gestionar trabajos y perfil desde la app móvil |
| **Administración / soporte** | Operar desde el hub desktop: métricas, disputas, liquidación manual del escrow |

**Fuera de alcance inmediato del MVP académico-comercial (documentado como pendiente):** MFA obligatorio, payout bancario automatizado (Khipu/Fintoc), firma electrónica legal Ley 19.799, métricas de negocio reales en producción.

---

## 4. Arquitectura de software

### En una frase

> **Monorepo multiplataforma** con arquitectura **cliente–servidor** sobre **Supabase (BaaS)**. Tres clientes (Flutter, web React/Vite, desktop Tauri) usan el mismo backend (Auth, PostgreSQL, RLS, Edge Functions). En móvil: organización **modular por features** con capas prácticas (UI → servicios → repositorios), inspirada en Clean Architecture de forma pragmática.

### Tipo de arquitectura

| Concepto | Qué es en este proyecto |
|----------|-------------------------|
| Cliente–servidor | Datos centralizados en la nube; las apps consultan Supabase |
| BaaS | Backend como servicio (Auth + Postgres + políticas RLS) |
| Monorepo | Código de app, web, desktop y `shared/` en un solo árbol (`MyWorksAppProyect/`) |
| Feature-First | En Flutter, pantallas por funcionalidad + `core/` compartido |
| Capas pragmáticas | Presentación → aplicación → dominio → infraestructura (repositorios) |
| Edge / serverless | Webpay y guest-checkout en Edge Functions (no en el dispositivo) |

### Diagrama

```text
┌─────────────────┐   ┌─────────────────┐   ┌──────────────────────┐
│  App Flutter    │   │  Web (Vite)     │   │  Desktop (Tauri)     │
│  Cliente /      │   │  Landing +      │   │  Admin / soporte /   │
│  profesional    │   │  checkout web   │   │  ejecutivo            │
└────────┬────────┘   └────────┬────────┘   └──────────┬───────────┘
         │                     │                         │
         └──────────┬──────────┴──────────┬──────────────┘
                    ▼                     ▼
            shared/ (TypeScript)    Supabase (Auth + DB + RLS)
                    │                     │
                    └──────────┬──────────┘
                               ▼
                    Edge Functions Webpay / guest-checkout
                               ▼
                         Transbank (integración)
```

| Componente | Rol |
|------------|-----|
| `MyWorksAppProyect/myworksapp_app/` | App móvil Flutter |
| `MyWorksAppProyect/myworksapp_web/` | Canal web (sesión o invitado) |
| `MyWorksAppProyect/myworksapp_desktop/` | Hub operativo |
| `MyWorksAppProyect/shared/` | Contratos TS compartidos |
| `MyWorksAppProyect/myworksapp_app/supabase/` | Migraciones y Edge Functions |
| `Fase 1/`, `Fase 2/`, `Documentos Guia/` | Expediente académico Capstone |

Diccionario de datos (fácil de explicar): [`MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`](MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md).

---

## 5. Metodología de trabajo

### En una frase

> **Scrum adaptado a un equipo de tres estudiantes**, orientado a un **MVP** y organizado por las **fases del Capstone PTY4614 (Duoc UC)**. Mathias Jara Alvarado es Product Owner y Scrum Master; el tablero está en GitHub Projects, el Daily Scrum se hace por Discord y la Sprint Review y la Retrospectiva, todos los fines de semana. Detalle y sprints: [`docs/metodologia.md`](docs/metodologia.md). Artefactos de la evaluación: [`docs/product_vision.md`](docs/product_vision.md), [`docs/product_backlog.md`](docs/product_backlog.md), [`docs/sprint_backlog.md`](docs/sprint_backlog.md), [`docs/retrospectiva.md`](docs/retrospectiva.md) y [`docs/requisitos_no_funcionales.md`](docs/requisitos_no_funcionales.md).

### Cómo trabajamos

| Práctica | En el proyecto |
|----------|----------------|
| Scrum adaptado | 11 sprints de 1 o 2 semanas reconstruidos desde el historial de GitHub; entregas por dominio: definición → backend/RLS → clientes → pagos → endurecimiento |
| MVP primero | Primero lo demostrable; pendientes explícitos (MFA, payout automático, prod Transbank) |
| Fases Capstone | Fase 1 definición del proyecto; Fase 2 y siguientes con evidencias; software en `MyWorksAppProyect/` |
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
- **Escrow de negocio (plata “retenida”):** cuando Transbank confirma el cobro, el pago queda marcado como **retenido** en nuestra base. El profesional **no** recibe el dinero de inmediato: primero se completa el trabajo y un administrador registra la transferencia. Eso da confianza al cliente.
- **Invitado en la web:** si alguien pide una urgencia **sin** iniciar sesión, completa nombre/correo/teléfono/dirección y luego va a Transbank. Si ya tiene sesión, paga en una ventana controlada **sin** abandonar My Works App.
- **Trazabilidad:** cada vez que se paga al profesional, queda un registro en la tabla `liquidaciones` (quién liquidó, cuánto, referencia de la transferencia). Sirve para auditoría académica y operativa.

---

## 7. Estructura del repositorio

| Ruta | Contenido |
|------|-----------|
| `Fase 1/` | Entregables y evidencias de definición del proyecto |
| `Fase 2/` | Entregables de la siguiente fase Capstone |
| `Documentos Guia/` | Guías e instructivos del programa |
| `Capstone_Project.mpp` | Planificación del proyecto |
| **`MyWorksAppProyect/`** | **Monorepo del producto** (app, web, desktop, shared, docs técnicos, CI) |
| `MyWorksAppProyect/docs/` | Runbooks (Transbank, liquidación) y diccionario BD |
| `MyWorksAppProyect/INSTALL.md` | Instalación y demo técnica |

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

| Dimensión | Estado actual |
|-----------|----------------|
| Definición / evidencia Fase 1 | Presente en carpetas académicas |
| MVP técnico multiplataforma | Implementado (`MyWorksAppProyect/`) |
| Pagos Webpay Plus y Oneclick (integración) | Implementado (Edge + clientes) |
| Liquidación al profesional | Manual por admin (automatización futura) |
| Lanzamiento comercial | Condicionado a empresa, credenciales de producción de Transbank y al piloto con usuarios |

---

## 10. Autores

Proyecto de título profesional desarrollado por el equipo indicado arriba, sede **Duoc UC Puerto Montt**, en el marco del Capstone **PTY4614**.

Para el estado técnico del monorepo, ver [`MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`](MyWorksAppProyect/ESTADO_DEL_PROYECTO.md).
