# Metodología de trabajo — My Works App

**Estado del documento:** 2026-11-17 (hora de Chile), sobre `main` en `514781d`. Roles, tablero, canal del Daily y cadencia de Review y Retrospectiva confirmados por Mathias Jara Alvarado el 2026-11-17.
**Convención:** `[completar]` marca un dato que el repositorio no permite afirmar. Cada dato inferido indica su fuente. Los nombres de usuario de Git y GitHub se tratan como identificadores, no como nombres reales, salvo cuando el propio repositorio los asocia a una persona. Las rutas son relativas a la raíz del repositorio.

## 1. Marco de trabajo

El marco de trabajo es **Scrum adaptado a un equipo de tres estudiantes**, dentro de las tres fases del Capstone PTY4614. Mathias Jara Alvarado es Product Owner y Scrum Master; el tablero es GitHub Projects; el Daily Scrum se hace por Discord; la Sprint Review y la Retrospectiva se hacen todos los fines de semana (confirmado por el equipo el 2026-11-17). Antecedentes en los documentos del proyecto:

- `Fase 1/Evidencias Grupales/Definicion Proyecto APT - Fase 1_ My Works App.docx`, sección 3.6: «Usamos sprints semanales (marco ágil) dentro de las tres fases APT, con repositorio GitHub público como evidencia».
- `Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx`: «sí sprints de entrega, recorte de alcance y Definition of Done (funciona, revisado y subido al repositorio)».
- `README.md`, sección «Metodología de trabajo»: Scrum adaptado, orientado a un MVP.

Ciclo de una iteración, según `README.md`: priorizar un flujo → acordar estados en la base de datos → implementar (apps, Edge Functions y SQL) → probar → documentar → commit y CI.

**Definition of Done** (`Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx`): el cambio funciona, está revisado y está subido al repositorio. En el repositorio, la revisión y la subida se apoyan en pull requests y en la integración continua (`.github/workflows/flutter_ci.yml`, `web_desktop_ci.yml`, `gitleaks.yml`, `commitlint.yml`).

## 2. Roles del equipo

| Rol Scrum | Quién | Fuente |
|-----------|-------|--------|
| Product Owner | Mathias Jara Alvarado | Confirmado por el equipo (2026-11-17). |
| Scrum Master | Mathias Jara Alvarado (también Product Owner) | Confirmado por el equipo (2026-11-17). En un equipo de tres estudiantes, un mismo integrante cumple ambos roles además de desarrollar. |
| Equipo de desarrollo | Mathias Alejandro Jara Alvarado, Nicolas Chiguay y Gabriel Valderas | `README.md`, campo Equipo; `Fase 1/Evidencias Grupales/Definicion Proyecto APT - Fase 1_ My Works App.docx`. |

Responsabilidades técnicas, según `Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx` (facilitadores del plan de trabajo):

| Integrante | Responsabilidad declarada |
|------------|---------------------------|
| Mathias Jara | Interfaces: app móvil Flutter, web PWA y consola de escritorio (junto con Nicolas Chiguay). Cobro con retención junto con Gabriel Valderas. |
| Gabriel Valderas | Datos, RLS y pagos. |
| Nicolas Chiguay | UX, flujos y documentación; informe de avance e informe final «y equipo». |

Identificadores en el historial de Git (`git log`, al 2026-11-17, 221 commits en `main`):

| Identificador de autor | Commits | Primer y último commit |
|------------------------|--------:|------------------------|
| Mathias (cuatro identidades de autor: `Mathias Jara`, `Mathias`, `Mathias Alejandro Jara Alvarado` con dos correos; cuenta de GitHub `MathiasAlejandr0`) | 144 | 2026-08-16 a 2026-11-16 |
| Gabriel (cuenta de GitHub `gabitopop`, autor «Gabriel») | 47 | 2026-08-14 a 2026-11-16 |
| Nicolas Chiguay (cuenta de GitHub `nicoussj`) | 24 | 2026-08-10 a 2026-11-10 |
| Cursor Agent (agente de código) | 5 | 2026-11-15 a 2026-11-16 |
| Grok Bot (asistente de código usado por Mathias, commit `2f3925c`) | 1 | 2026-11-15 |

La correspondencia entre las cuentas de GitHub y los nombres del equipo se infiere de los nombres de autor del historial y de `README.md`. Gabriel es el único autor cuyo historial no trae el apellido.

## 3. Sprints: duración y cantidad

**Criterio.** Los sprints se reconstruyeron desde el historial de GitHub (`nicoussj/Proyecto-Titulo-MyWorksApp`, rama `main`, 228 commits del 2026-08-10 al 2026-11-17 (corte en `514781d`), contados por fecha de autor en hora de Chile, y 30 merges de pull request):

1. Cada sprint va de lunes a domingo y cierra en fin de semana, donde se ubican los picos de entrega del historial (16-ago, 20-sep, 4-oct, 8-nov y 15-nov fueron domingos con entregas).
2. Un sprint empieza el lunes siguiente al cierre del anterior.
3. Las semanas con poca actividad en el repositorio no abren un sprint nuevo; se suman al sprint en curso, porque ese trabajo (diseño, documentos y evaluaciones) no queda necesariamente como commits.

Los commits acreditan entregas, no la realización de reuniones: el calendario es una reconstrucción documental. La cadencia de los eventos la confirmó el equipo (sección 5).

| Dato | Valor | Fuente |
|------|-------|--------|
| Duración del sprint | 1 semana en la Fase 1 (S1–S3) y en el cierre técnico (S9–S10); 2 semanas en el desarrollo (S4–S8) y en la preparación de la defensa (S11) | Historial de GitHub con el criterio anterior. La Fase 1 declaraba sprints semanales (`Fase 1/Evidencias Grupales/Definicion Proyecto APT - Fase 1_ My Works App.docx`, sección 3.6). |
| Número total de sprints | 11. Al 17-nov la tabla de abajo decía S10 en curso. Al 22 de noviembre de 2026, 23:07 hora de Chile, la ventana de S10 está cerrada y S11 es la Fase 3 en curso | Historial de GitHub y calendario de hitos. |
| Primer commit del repositorio | 2026-08-10 | `git log` (commit `2b5f923`, «Initial commit», autor Nicolas Chiguay). |
| Plan del Capstone | Semanas 1 a 18 | `Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx` (cronograma por actividad). |

| Sprint | Fechas | Semanas | Objetivo | Commits en `main` | Estado al 17-nov |
|--------|--------|--------:|----------|------------------:|------------------|
| S1 | 10 – 16 ago 2026 | 1 | Definir el producto | 9 | Terminado |
| S2 | 17 – 23 ago 2026 | 1 | Evidencias de la Fase 1 | 13 | Terminado |
| S3 | 24 – 30 ago 2026 | 1 | Cerrar la Fase 1 | 13 | Terminado |
| S4 | 31 ago – 13 sep 2026 | 2 | Planificar la Fase 2 | 2 | Terminado |
| S5 | 14 – 27 sep 2026 | 2 | Base de datos y monorepo | 18 | Terminado |
| S6 | 28 sep – 11 oct 2026 | 2 | Pago con garantía y reputación | 26 | Terminado |
| S7 | 12 – 25 oct 2026 | 2 | Ubicación y validaciones | 17 | Terminado |
| S8 | 26 oct – 8 nov 2026 | 2 | Agenda y evidencia | 7 | Terminado |
| S9 | 9 – 15 nov 2026 | 1 | Integración y pruebas | 97 | Terminado |
| S10 | 16 – 22 nov 2026 | 1 | Cierre de la Fase 2 | 26 | En curso |
| S11 | 23 nov – 6 dic 2026 | 2 | Defensa | — | Planificado |

Nota del 20-nov-2026: después del corte en `514781d` entraron 60 commits más a `main` hasta `d9d2c7c` (S10), entre ellos la consola nueva, la web en `myworksapp.cl`, el límite de tasa global y los correos transaccionales (PR #75 a #82). La tabla mantiene los conteos del corte del 17-nov.

Nota del 22 de noviembre de 2026, 23:07 hora de Chile. La ventana del Sprint 10 cerró ese día. La fase vigente es la Fase 3 (Sprint 11): pruebas, informe final y demostración. La columna «Estado al 17-nov» se conserva como corte histórico.

Plan por fases, según `Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx`:

| Actividad | Semanas | Responsable declarado |
|-----------|---------|-----------------------|
| Definición APT (guía, objetivos y Gantt) | 1 a 4 | Equipo (coord. Nicolas Chiguay) |
| Diseño e implementación de BD y RLS | 5 a 8 | Gabriel Valderas |
| App móvil Flutter | 5 a 14 | Mathias Jara |
| Página web PWA | 7 a 14 | Mathias Jara |
| Consola de escritorio | 8 a 14 | Mathias Jara y Nicolas Chiguay |
| Cobro con retención (escrow) | 8 a 14 | Gabriel Valderas y Mathias Jara |
| Pruebas del flujo crítico | 12 a 16 | Equipo |
| Informe de avance (Fase 2) | 9 a 10 | Nicolas Chiguay y equipo |
| Informe final y demo | 16 a 18 | Nicolas Chiguay y equipo |

Actividad real en el historial de Git (commits por semana ISO, `main`, hora de Chile): 2026-W33: 9; W34: 13; W35: 13; W36: 1; W37: 1; W38: 16; W39: 2; W40: 9; W41: 17; W42: 1; W43: 16; W44: 2; W45: 5; W46: 97; W47 (al 17-nov): 26. Es la base del criterio de sprints anterior.

Remediación en sprints numerados: `MyWorksAppProyect/docs/REMEDIACION_AUDITORIA.md` lista los sprints 1, 2, 3, 4, 5, 6, 6b y 7 de la remediación de la auditoría de septiembre de 2026, cada uno con sus tareas cumplidas. Esos sprints corresponden a esa remediación y no a todo el calendario del proyecto.

## 4. Product Backlog

Las historias se infieren de las funciones que existen en el código. La columna CU remite a `MyWorksAppProyect/docs/casos_de_uso.md`, donde cada caso trae su flujo y su trazabilidad a archivos. Los criterios de aceptación salen de las reglas de negocio RN-xx de la sección 7 de ese documento.

**Prioridad:** Alta, Media o Baja. Se infiere del alcance del MVP congelado en `Fase 2/2.4_DesarrolloProyecto_APT_MyWorksApp.docx` («flujo oficio–contrato–evidencia–pago»). El Product Owner (Mathias Jara Alvarado) ordena el backlog en GitHub Projects.

| ID | Historia de usuario | Criterios de aceptación | Prioridad | CU |
|----|---------------------|-------------------------|-----------|----|
| HU-01 | Como **visitante** quiero buscar profesionales por oficio, zona, precio y calificación para elegir a quien mejor se ajuste a lo que necesito. | El catálogo lista profesionales verificados con calificación y tarifa. La web filtra por calificación mínima y ordena por relevancia, precio o calificación. La app ordena por puntaje de reputación y cercanía. El mapa muestra a los profesionales. | Alta | CU-05 |
| HU-02 | Como **visitante** quiero ver el perfil de un profesional y sus horas libres para decidir cuándo contratarlo. | Se muestran las horas publicadas y libres de los próximos días (`horarios_libres_profesional`). Solo se muestran horas de profesionales disponibles. | Alta | CU-06 |
| HU-03 | Como **cliente** quiero solicitar un servicio y reservar una hora para que el profesional vaya en el momento acordado. | Solo se reservan horas publicadas y libres (RN-08). Si otra persona toma la hora, el pedido se rechaza y el cliente elige otra. El pedido queda en `esperando_pago` con la hora asociada. El servidor genera el PIN de inicio. | Alta | CU-07 |
| HU-04 | Como **cliente** quiero pagar con Webpay u Oneclick, con el dinero retenido, para estar seguro de que el profesional cobra solo cuando recibo el trabajo. | La plataforma no pide ni guarda el número de tarjeta (RN-09). El monto se valida en el servidor contra la tarifa (RN-10). Sin pago retenido no se acepta ni se inicia el trabajo (RN-03). | Alta | CU-08 |
| HU-05 | Como **cliente invitado** quiero comprar sin crear cuenta antes de pagar para contratar rápido desde la web. | El invitado entrega nombre, correo, teléfono y dirección y paga en Transbank. Después define su contraseña (mínimo 8 caracteres con letras y dígitos, RN-07). Hay límites de tasa por IP y por correo (RN-14). | Media | CU-09, CU-10 |
| HU-06 | Como **profesional** quiero aceptar o rechazar pedidos para gestionar mi carga de trabajo. | Solo el profesional del trabajo avanza los estados de ejecución (RN-01). Si rechaza un pedido con pago retenido, el pago se reembolsa. | Alta | CU-11 |
| HU-07 | Como **profesional** quiero avisar que voy en camino y compartir mi ubicación para que el cliente sepa cuándo llego. | La app publica la posición GPS solo en primer plano, como máximo cada 20 s o cada 40 m. El trabajo avanza a `en_camino`. Sin permiso de GPS el cliente ve «Sin GPS» y el trabajo avanza igual. El cliente ve la posición en un mapa en la app y en la web. | Media | CU-12, CU-13 |
| HU-08 | Como **profesional** quiero iniciar el trabajo con el PIN del cliente para dejar constancia de que llegué y empecé. | El PIN solo lo ve el cliente, en los estados `aceptado` y `en_camino` (RN-11). Cinco fallos bloquean 15 minutos y un acierto abre una ventana de 2 minutos (RN-12). | Alta | CU-14 |
| HU-09 | Como **profesional** quiero subir evidencia y finalizar el trabajo para respaldar lo que hice. | La evidencia se guarda en un depósito privado: fotos WebP y videos de hasta 20 MB (RN-16). No se puede finalizar sin evidencia. | Alta | CU-16 |
| HU-10 | Como **cliente** quiero dar mi conformidad para que se libere el pago al profesional. | El cierre lo hace el cliente, el sistema o el administrador (RN-02). Con 48 horas de silencio del cliente y evidencia presente, el pago se libera (RN-13). La liberación deja una fila en `liquidaciones`. | Alta | CU-17 |
| HU-11 | Como **cliente** quiero calificar al profesional para que otros elijan con mejor información. | Solo se califica un trabajo `completado` y sin disputa abierta, con 1 a 5 estrellas y una sola calificación por trabajo. La reseña recibe un peso de confianza y las dudosas pasan a revisión sin borrarse. La calificación actualiza el puntaje de reputación y el orden del listado. | Alta | CU-18 |
| HU-12 | Como **profesional** quiero calificar al cliente para que mi experiencia también quede registrada. | Existe una calificación del profesional al cliente por trabajo, que alimenta la reputación del cliente. | Baja | CU-19 |
| HU-13 | Como **cliente** quiero cancelar una solicitud con reembolso para no perder el dinero si el servicio no se realiza. | No se cancela con el pago retenido sin reembolsar antes (RN-05). El reembolso se hace una sola vez. | Media | CU-20 |
| HU-14 | Como **cliente o profesional** quiero abrir una disputa y proponer un acuerdo para resolver un desacuerdo sobre el trabajo. | Con una disputa activa, solo el administrador mueve el trabajo (RN-04). Un trabajo cerrado no admite disputas nuevas (RN-19). Las disputas simples de hasta $80.000 se cierran a las 24 horas (RN-13). | Media | CU-21, CU-22 |
| HU-15 | Como **cliente o profesional** quiero reagendar la visita para ajustarme a un imprevisto. | Se reagenda solo antes de `en_camino`, a una hora publicada y libre, con aceptación de la otra parte. El escrow no cambia (RN-17). | Media | CU-33 |
| HU-16 | Como **profesional** quiero solicitar un cobro adicional para cubrir trabajo extra que surge en el sitio. | El cliente aprueba la orden de cambio y la paga por Webpay. La tarifa de las órdenes de cambio es del 8 % (RN-06). | Media | CU-15 |
| HU-17 | Como **cliente o profesional** quiero conversar por el chat del trabajo para coordinar los detalles. | El chat bloquea datos de contacto (RN-15). Los mensajes llegan en tiempo real. | Media | CU-23 |
| HU-18 | Como **usuario** quiero recibir notificaciones para enterarme de los cambios de mi pedido. | Con la app abierta, los avisos llegan por Supabase Realtime. El push FCM se envía si están configuradas las variables `FCM_*`. | Media | CU-24 |
| HU-19 | Como **profesional** quiero completar mi perfil, tarifas, horario y verificación para aparecer en el catálogo y poder cobrar. | Solo un profesional verificado aparece como apto para cobrar. El horario semanal define las horas reservables. | Alta | CU-25, CU-26 |
| HU-20 | Como **profesional** quiero consultar mis cobros y registrar mi cuenta bancaria para recibir mi pago. | La app muestra los pagos y liquidaciones del profesional con bruto, comisión y neto; el total es neto. La cuenta bancaria se guarda en `cuentas_bancarias`. | Media | CU-27 |
| HU-21 | Como **visitante** quiero registrarme, iniciar sesión y recuperar mi contraseña para usar la plataforma con mi cuenta. | El registro y el inicio de sesión funcionan en app y web. La recuperación de contraseña envía un enlace por correo sin revelar si el correo existe. | Alta | CU-01, CU-02, CU-03 |
| HU-22 | Como **administrador** quiero entrar a la consola con segundo factor para operar la plataforma de forma segura. | La consola exige segundo factor. Solo el rol `administrador` mueve dinero, verifica, invita o ve métricas (RN-20). | Alta | CU-28 |
| HU-23 | Como **administrador** quiero verificar profesionales y liquidar sus pagos para mantener la confianza y cerrar el ciclo de pago. | El administrador cambia el estado de verificación. La liquidación manual guarda referencia, monto y estado de transferencia. | Alta | CU-29, CU-30 |
| HU-24 | Como **administrador** quiero invitar colaboradores internos con mínimo privilegio para repartir el soporte. | El invitado define su contraseña al activar su acceso. Los roles `soporte` y `qa` ven solo la cola de disputas. | Baja | CU-31, CU-34 |
| HU-25 | Como **usuario** quiero exportar o eliminar mi cuenta para ejercer mis derechos sobre mis datos. | La app ofrece exportar y eliminar la cuenta, con política de privacidad y términos visibles. | Baja | CU-04 |

## 5. Ceremonias

| Ceremonia | Qué consta en el repositorio | Fuente |
|-----------|------------------------------|--------|
| Sprint Planning | Al inicio de cada sprint (lunes), el Product Owner ordena el tablero de GitHub Projects y el equipo selecciona las historias del sprint. | Confirmado por el equipo (2026-11-17); tablero en GitHub Projects. |
| Daily Scrum | Por Discord, en los días de trabajo: qué hice, qué haré y qué me bloquea. | Confirmado por el equipo (2026-11-17). |
| Sprint Review | Todos los fines de semana: demostración del incremento al equipo y, en los hitos, al profesor patrocinante. | Confirmado por el equipo (2026-11-17). Coincide con los picos de entrega de los domingos en el historial (sección 3). |
| Sprint Retrospective | Todos los fines de semana, después de la Review. Los diarios de reflexión de cada fase complementan la retrospectiva individual. | Confirmado por el equipo (2026-11-17); `Fase 1/Evidencias Individual/`; diarios de reflexión de la Fase 2 en `Fase 2/`. |
| Refinamiento del backlog | En el tablero de GitHub Projects, a cargo del Product Owner, antes de cada Sprint Planning. | Confirmado por el equipo (2026-11-17). |

Evidencia de revisión de código en el repositorio: GitHub registra 74 pull requests en `nicoussj/Proyecto-Titulo-MyWorksApp` (consulta a la API de GitHub el 2026-11-17). De ellos, 40 los abrió `dependabot[bot]`, 32 la cuenta `MathiasAlejandr0` y 2 la cuenta `nicoussj`. El repositorio no tiene issues. La rama principal registra 30 merges de pull request (`git log --merges`, corte en `514781d`).

## 6. Herramienta de tablero

| Dato | Valor | Fuente |
|------|-------|--------|
| Tablero Scrum o Kanban | GitHub Projects | Confirmado por el equipo (2026-11-17). |
| Carta Gantt | Archivo [`Capstone_Project.mpp`](Capstone_Project.mpp) (formato de Microsoft Project, por su extensión) | Commit `363a0f7`, 2026-09-13, autor Nicolas Chiguay, mensaje «Adjunto Carta Gantt». |
| Seguimiento del trabajo | Ramas y pull requests en GitHub, con mensajes de commit validados por `commitlint` | `.github/workflows/commitlint.yml`; `MyWorksAppProyect/commitlint.config.mjs`. |
| Backlog en el repositorio | `Fase 2/historias_de_usuario.txt` (dos historias narrativas) y `MyWorksAppProyect/docs/casos_de_uso.md` (34 casos de uso) | Archivos del repositorio. |
| Canal de comunicación del equipo | Discord (Daily Scrum y coordinación) | Confirmado por el equipo (2026-11-17). |

## 7. Lista de datos pendientes (`[completar]`)

Quedan sin respaldo en el repositorio las actas con fecha y asistentes de cada evento. Los demás datos de las versiones anteriores (Product Owner, Scrum Master, duración y número de sprints, tablero, canal del Daily, Review, Retrospectiva y refinamiento) quedaron completos el 2026-11-17.
