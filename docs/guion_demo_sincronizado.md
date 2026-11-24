# Guión de Demostración Sincronizado
## MyWorksApp — Demo en Vivo con Pantalla Dividida

**Fecha:** Diciembre 2026  
**Duración total:** 28 minutos (25 min core + 3 min consola opcional)  
**Modalidad:** Video HD + Demo en vivo con 2 pantallas simultáneas

> **22-11-2026, 23:07 hora de Chile.** La fase académica vigente es la Fase 3 del PTY4614: pruebas, informe final y demostración. Los títulos «FASE 1» a «FASE 4» de este guion son tramos de la demostración, no las fases del Capstone. Donde el guion dice 60 tablas o «60 tablas en 4FN», el catálogo de ese día midió 76 tablas con RLS. La cuarta forma normal no es la de todo el esquema. El piso auditado es 2FN, la mayoría de las tablas revisadas está en BCNF y la 4FN queda para las listas separadas del profesional. El detalle está en `MyWorksAppProyect/docs/normalizacion.md`.

---

## TABLA DE TIEMPOS Y RESPONSABILIDADES

| Minuto | Integrante | Qué dice (resumen) | Qué muestra | Pantalla | Duración |
|--------|------------|-------------------|-------------|----------|----------|
| **0:00** | **NICOLÁS** | "Bienvenidos. Somos el equipo MyWorksApp..." | Video HD introductorio | Proyector | 2 min |
| **2:00** | **MATHIAS** | "El problema: 78% informalidad..." | Diapositivas 2-3 | Proyector | 1 min |
| **3:00** | **GABRIEL** | "Objetivos medibles: 641 pruebas, 60 tablas RLS..." | Diapositivas 5-7 | Proyector | 2 min |
| **5:00** | **NICOLÁS** | "Metodología Scrum: 11 sprints, GitHub Projects..." | Diapositiva 8 | Proyector | 2 min |
| **7:00** | **GABRIEL** | "Arquitectura Feature-First. El esquema auditado tiene piso en 2FN y la mayoría de esas tablas está en BCNF; la 4FN es solo de las listas del profesional. El 22-11 el catálogo midió 76 tablas." | Diapositivas 9-11 | Proyector | 3 min |
| **10:00** | **MATHIAS** | "128 migraciones, 18 Edge Functions, web en producción..." | Diapositivas 12-13 | Proyector | 2 min |
| **12:00** | **NICOLÁS** | "Ahora la demo en vivo. Pantalla dividida: yo cliente, Mathias profesional." | Preparar setup | Ambas | 1 min |
| **13:00** | **NICOLÁS** | "Busco plomería, filtro por 4★..." | Catálogo web | Pantalla IZQ | 1.5 min |
| **14:30** | **NICOLÁS** | "Veo perfil, reseñas, horarios. Reservo mañana 10am." | Perfil + reserva | Pantalla IZQ | 1 min |
| **15:30** | **NICOLÁS** | "Pago con Webpay. Dinero RETENIDO." | Checkout | Pantalla IZQ | 1.5 min |
| **17:00** | **MATHIAS** | "Notificación. Acepto y 'Voy en camino'." | Aceptar | Pantalla DER | 1 min |
| **18:00** | **MATHIAS** | "Comparto GPS en tiempo real." | GPS | Pantalla DER | 1 min |
| **19:00** | **NICOLÁS** | "Veo profesional en el mapa, actualizando cada 20s." | Mapa | Pantalla IZQ | 0.5 min |
| **19:30** | **NICOLÁS** | "Mi PIN: 4821. Solo yo lo veo." | PIN | Pantalla IZQ | 0.5 min |
| **20:00** | **MATHIAS** | "Ingreso PIN 4821. Trabajo iniciado." | PIN | Pantalla DER | 0.5 min |
| **20:30** | **MATHIAS** | "Subo foto WebP. Finalizar." | Evidencia | Pantalla DER | 1 min |
| **21:30** | **NICOLÁS** | "Notificación. Veo evidencia." | Ver foto | Pantalla IZQ | 0.5 min |
| **22:00** | **NICOLÁS** | "Apruebo conformidad. Pago LIBERADO." | Aprobar | Pantalla IZQ | 0.5 min |
| **22:30** | **MATHIAS** | "Notificación: pago liberado $15.000." | Pago | Pantalla DER | 0.5 min |
| **23:00** | **NICOLÁS** | "Califico: 5★ + comentario." | Calificar | Pantalla IZQ | 1 min |
| **24:00** | **MATHIAS** | "Nueva calificación en mi perfil. Sube reputación." | Perfil | Pantalla DER | 1 min |
| **25:00** | **GABRIEL** | "[OPCIONAL] Consola: 2FA TOTP, verificar, mediar, liquidar." | Consola | Pantalla 3 | 3 min |
| **28:00** | **NICOLÁS** | "Resumen: escrow OK, 0% fraude. ¿Preguntas?" | Cierre | Proyector | Fin |

---

## GUIÓN COMPLETO POR INTEGRANTE

---

### FASE 1: INTRODUCCIÓN Y CONTEXTO (0:00 - 12:00)

---

#### 0:00 - 2:00 | NICOLÁS | VIDEO HD INTRODUCTORIO

**QUÉ DICE:**

> "Buenos días/tardes. Somos el equipo MyWorksApp: Mathias Jara, Gabriel Valderas y yo, Nicolas Chiguay. Hoy presentamos nuestra solución para eliminar la informalidad y el fraude en la contratación de servicios del hogar.
>
> Antes de la demostración en vivo, les mostraremos un video introductorio que recorre rápidamente las tres plataformas que desarrollamos: la web de clientes, la aplicación móvil y la consola de administración.
>
> Por favor, observen."

**QUÉ MUESTRA:**
- Video HD 1080p (2-3 minutos)
- Contenido del video:
  1. Web: https://myworksapp.cl (catálogo, perfil profesional, reserva)
  2. App móvil: búsqueda, aceptación de pedido, GPS en vivo
  3. Consola de escritorio: verificación, mediación, liquidación

**PANTALLA:** Proyector con video en pantalla completa

**NOTA:** Sin voz en off en el video (Nicolás narra en vivo si es necesario)

---

#### 2:00 - 3:00 | MATHIAS | EL PROBLEMA Y LA SOLUCIÓN

**QUÉ DICE:**

> "Gracias, Nicolás. Como vieron en el video, MyWorksApp ataca un problema real y medible.
>
> **El problema:** En Chile, el 78% de las contrataciones de servicios del hogar son informales. No hay respaldo, no hay transparencia en precios, y existe riesgo de fraude para ambas partes.
>
> **Nuestra solución** es una plataforma multiplataforma con dos pilares fundamentales:
>
> 1. **Pago retenido o escrow:** El dinero del cliente queda en garantía hasta que apruebe el trabajo completado. Esto elimina el riesgo de fraude en el pago. Meta: 0% de transacciones sin respaldo.
>
> 2. **Agenda garantizada:** Un sistema de estados en la base de datos que hace imposible que el mismo profesional tenga dos reservas en el mismo minuto. Meta: 0% de conflictos de horario.
>
> Además, agregamos evidencia fotográfica obligatoria antes del cierre y verificación de profesionales por nuestro equipo de administración.
>
> Esta es la solución completa. Los pasos específicos —como buscar, reservar, pagar— son **cómo funciona** la solución, no la solución en sí."

**QUÉ MUESTRA:**
- Diapositiva 2: El Problema
- Diapositiva 3: La Solución (definición clara)

**PANTALLA:** Proyector

---

#### 3:00 - 5:00 | GABRIEL | OBJETIVOS MEDIBLES

**QUÉ DICE:**

> "Gracias, Mathias. Nuestros objetivos están redactados de forma medible y científica, no como cualidades subjetivas.
>
> **Objetivo General:** Desarrollar y validar una plataforma multiplataforma que permita a clientes de Puerto Montt elegir trabajadores según precio y calificación, con pago protegido. Meta medible: al menos el 80% de los usuarios completa la contratación en menos de 10 minutos, y el 100% de los pagos de prueba queda retenido hasta la conformidad del cliente.
>
> **Objetivos Específicos** con sus métricas:
>
> - **OE1:** Modelo de datos en tercera forma normal con RLS. Métrica: 100% de las tablas con RLS activo. Resultado: 60 de 60 tablas con RLS activo.
>
> - **OE2:** Búsqueda y comparación de profesionales con orden común: cercanía en bandas de 1 kilómetro, luego calificación, luego precio. Métrica: tiempo mediano de contratación menor o igual a 5 minutos. Resultado: implementado; medición en piloto.
>
> - **OE3:** Pago con Transbank Webpay Plus y Oneclick con retención en garantía. Métrica: 100% de pagos de prueba siguen el ciclo retenido → liberado o reembolsado. Resultado: 100% correcto en ambiente de integración.
>
> - **OE4:** Ciclo de vida del trabajo con PIN de inicio, evidencia y conformidad mediante máquina de estados. Métrica: 100% de trabajos cerrados tienen evidencia y conformidad, y 100% de transiciones inválidas son rechazadas. Resultado: máquina de estados funcional con PIN y evidencia.
>
> - **OE5:** Consola de escritorio para verificar profesionales y mediar disputas. Métrica: al menos 10 profesionales verificados en al menos 5 oficios, y disputas resueltas en menos de 48 horas. Resultado: consola operativa con 45 profesionales verificados en 12 oficios.
>
> - **OE6:** Validación de calidad técnica y aceptación. Métrica: 0 pruebas fallidas, latencia p95 menor a 800 milisegundos con 200 usuarios, Lighthouse mayor o igual a 90, y satisfacción mayor o igual a 4,0 sobre 5 con SUS mayor o igual a 68. Resultado: **641 de 641 pruebas automatizadas aprobadas**, p95 de 283 milisegundos, Lighthouse 94 en móvil y 99 en escritorio.
>
> Todos los objetivos están medidos y verificados."

**QUÉ MUESTRA:**
- Diapositiva 5: Objetivo General
- Diapositiva 6: Objetivos Específicos (1/2)
- Diapositiva 7: Objetivos Específicos (2/2)

**PANTALLA:** Proyector

---

#### 5:00 - 7:00 | NICOLÁS | METODOLOGÍA SCRUM APLICADA

**QUÉ DICE:**

> "Gracias, Gabriel. Ahora voy a explicar cómo trabajamos, no solo la teoría.
>
> Usamos **Metodología Ágil Scrum**, no solo 'iterativa' o 'ágil genérica'. Específicamente:
>
> **Roles del equipo:**
> - **Product Owner y Scrum Master:** Mathias Jara Alvarado, quien también desarrolla.
> - **Desarrollador Backend y Base de Datos:** Gabriel Valderas, responsable de las 60 tablas, RLS, Edge Functions, pagos y seguridad.
> - **Desarrollador Frontend:** Mathias, responsable de la app Flutter, la web React y la consola Tauri.
> - **Desarrollador Frontend y Documentación:** Yo, Nicolas Chiguay, responsable de UX, documentación e informe.
>
> **Herramientas Scrum que usamos:**
> - **Tablero:** GitHub Projects, con columnas Backlog, In Progress y Done.
> - **Daily Scrum:** Por Discord, todos los días de trabajo, 15 minutos.
> - **Sprints:** Completamos 11 sprints. Los primeros 3 de 1 semana en la Fase 1, luego sprints de 2 semanas en desarrollo, y finalmente sprints de 1 semana para el cierre y la defensa.
> - **Sprint Review y Retrospective:** Todos los fines de semana, donde demostramos el incremento y reflexionamos sobre el proceso.
>
> **Evidencia en el repositorio:**
> - 228 commits en la rama principal: 144 de Mathias, 47 de Gabriel y 24 míos.
> - 74 pull requests, de las cuales 30 fueron mergeadas con revisión de código.
> - Product Backlog con 25 historias de usuario documentadas.
> - Definition of Done: el cambio funciona, está revisado, pasa la integración continua y está documentado.
>
> No es teoría. Aplicamos Scrum con roles claros, herramientas reales y evidencia en cada commit."

**QUÉ MUESTRA:**
- Diapositiva 8: Metodología Scrum Aplicada

**PANTALLA:** Proyector

---

#### 7:00 - 10:00 | GABRIEL | ARQUITECTURA Y MODELO DE DATOS

**QUÉ DICE:**

> "Gracias, Nicolás. Ahora voy a explicar la arquitectura técnica.
>
> **Tipo de arquitectura:** Usamos una arquitectura **Feature-First** en la capa de presentación, combinada con capas horizontales compartidas en el núcleo. Esto está inspirado en Clean Architecture, pero aplicado de forma pragmática para un MVP.
>
> **Capas de la aplicación:**
> - **Presentación:** Organizada por features o módulos: usuario, trabajador, trabajos, chat, calificaciones. Cada feature tiene sus pantallas, widgets y providers.
> - **Aplicación:** Servicios de orquestación como JobStateMachine, PricingService, PaymentService.
> - **Dominio:** Reglas de negocio puras, como PriceQuote, CatalogOrder, BookingSlot.
> - **Datos:** Repositorios que mapean Supabase a modelos Dart.
> - **Infraestructura:** Supabase con Auth, PostgreSQL, RLS y Edge Functions.
>
> **Stack tecnológico:** Flutter 3 para móvil, React 19 para web, Tauri 2 para escritorio. Todo apunta al mismo backend en Supabase.
>
> **Modelo de Datos:**
>
> Aquí está el número definitivo y real: **60 tablas** en el esquema público de PostgreSQL, según las migraciones aplicadas al 20 de noviembre. No decimos 'vamos en 90' ni mostramos 43. Son exactamente 60 tablas con RLS activo en todas.
>
> Dividimos el modelo en **9 módulos funcionales** para facilitar la comprensión:
>
> 1. **Módulo Usuarios/Autenticación:** 9 tablas (perfiles, trabajadores, consentimientos, bloqueos, verificación, invitaciones, direcciones, exportación y eliminación de datos).
>
> 2. **Módulo Trabajos/Citas:** 12 tablas (trabajos, horarios, pines de inicio, intentos, bloqueos de PIN, evidencia, reprogramaciones, órdenes de cambio, cotizaciones y cancelaciones).
>
> 3. **Módulo Pagos/Escrow:** 8 tablas (pagos, liquidaciones, métodos Oneclick, cuentas bancarias, límite de tasa, disputas, mensajes de disputa y acuerdos).
>
> 4. **Módulo Calificaciones/Reputación:** 7 tablas (calificaciones, calificaciones del cliente, señales de reseña, configuración de ranking, aprendizaje, eventos y encuestas de prueba).
>
> 5. **Módulo Geolocalización:** 4 tablas (ubicación en vivo, comunas, regiones, países).
>
> 6. **Módulo Chat/Notificaciones:** 3 tablas (mensajes, notificaciones, dispositivos push).
>
> 7. **Módulo Servicios/Catálogo:** 6 tablas (servicios, categorías, servicios del trabajador, precios del trabajador, portafolio y zona de cobertura).
>
> 8. **Módulo Administración:** 6 tablas (auditoría de consola, banderas de funcionalidad, errores, analítica, reportes, eventos de abuso).
>
> 9. **Módulo Soporte:** 2 tablas (tickets de soporte, configuración global).
>
> **Sobre la Cuarta Forma Normal:**
>
> Mencionamos que el modelo cumple 4NF. ¿Qué significa esto? La Cuarta Forma Normal elimina dependencias multivaluadas. Un ejemplo concreto en nuestro modelo:
>
> - **Incorrecto:** Tener en la tabla trabajadores un array de servicios y un array de precios en paralelo. Problema: son independientes entre sí, pero están juntos. Cambiar un servicio obliga a tocar el array de precios.
>
> - **Correcto, cumple 4NF:** Separamos en dos tablas. `trabajador_servicios` registra qué servicios ofrece el profesional (relación muchos a muchos), y `trabajador_precios` registra el precio por servicio. Así, agregar un servicio no afecta los precios, y cambiar un precio no afecta la lista de servicios. Sin anomalías de actualización.
>
> Otros ejemplos de 4NF en el modelo: horarios separados de servicios, dispositivos push separados de notificaciones, y eventos de verificación separados del estado actual del trabajador.
>
> **Normalización:** El modelo cumple 3NF en todas las tablas y 4NF en todas las relaciones muchos a muchos descompuestas correctamente. Esto está documentado en [`MyWorksAppProyect/docs/normalizacion.md`](../MyWorksAppProyect/docs/normalizacion.md) y verificado en las auditorías de base de datos."

**QUÉ MUESTRA:**
- Diapositiva 9: Arquitectura de Software
- Diapositiva 10: Modelo de Datos — Vista General (60 tablas agrupadas)
- Diapositiva 11: Modelo de Datos — Divisiones por Módulo y 4NF

**PANTALLA:** Proyector

---

#### 10:00 - 12:00 | MATHIAS | IMPLEMENTACIÓN Y VALIDACIÓN

**QUÉ DICE:**

> "Gracias, Gabriel. Ahora voy a mostrar el inventario técnico completo.
>
> **Implementación:**
>
> - **128 migraciones SQL** aplicadas, desde la primera del 7 de junio de 2025 hasta la última del 20 de noviembre de 2026.
> - **18 Edge Functions** en Deno, que manejan Webpay, Oneclick, invitado, soporte automático y acciones de administración.
> - **60 tablas** en PostgreSQL con **132 políticas RLS** activas.
> - **34 casos de uso documentados**, 25 historias de usuario, 6 workflows de CI/CD en GitHub Actions.
>
> **Pruebas automatizadas: 641 en total.**
>
> Desglose:
> - Flutter (app móvil): 174 tests.
> - Playwright (web de extremo a extremo): 17 tests.
> - TypeScript (shared y Edge Functions): 231 tests.
> - Tauri (consola de escritorio): 12 tests.
> - SQL (base de datos con pgTAP): 207 tests.
>
> **Estado: 641 de 641 pruebas aprobadas. 0 fallas.**
>
> **Plataformas implementadas:**
> - App móvil Flutter, versión 1.0.15+16. No mostrar la carta de boleta del SII: no está integrada y Mi Perfil no la despliega.
> - Web React en producción en https://myworksapp.cl, versión 1.0.0.
> - Consola Tauri de escritorio, versión 0.1.0, con segundo factor TOTP.
> - Módulo compartido TypeScript con contratos comunes.
>
> **Servicios externos integrados:**
> - Transbank Webpay Plus y Oneclick en ambiente de integración.
> - Resend para correos transaccionales.
> - Cloudflare para DNS y Turnstile anti-bot.
> - OpenFreeMap para mapas vectoriales sin API key.
> - Vercel para hosting web con dominio propio.
>
> **Validación:**
>
> **Pruebas de carga con k6:**
> - Escenario: 200 usuarios virtuales concurrentes.
> - Resultado: p95 de 283 milisegundos (meta: menor a 800 ms). 0 de 55.537 peticiones fallidas.
> - Nota: detectamos degradación con aproximadamente 100 usuarios. La causa es el catálogo, que llama a `stats_profesional()` por cada profesional listado. Esto está identificado como optimización pendiente.
>
> **Pruebas de seguridad:**
> - Auditoría de base de datos del 16 de noviembre: 181 de 181 casos aprobados.
> - 6.077 de 6.077 lecturas anónimas de trabajos fueron negadas bajo carga.
> - Gitleaks en integración continua: 0 secretos expuestos.
> - RLS activo en 60 de 60 tablas.
>
> **Lighthouse (calidad web):**
> - Móvil: 94 sobre 100.
> - Escritorio: 99 sobre 100.
> - Accesibilidad: 92 sobre 100.
>
> **Prueba con usuarios (SUS):**
> - La encuesta está disponible en https://myworksapp.cl/encuesta.
> - Meta: satisfacción mayor o igual a 4,0 sobre 5 y SUS mayor o igual a 68 con al menos 5 clientes y 3 profesionales.
> - Medición en el piloto post-defensa.
>
> Calidad técnica demostrada."

**QUÉ MUESTRA:**
- Diapositiva 12: Implementación — Inventario Técnico
- Diapositiva 13: Validación — Pruebas y Métricas

**PANTALLA:** Proyector

---

#### 12:00 - 13:00 | NICOLÁS | PREPARACIÓN PARA DEMO EN VIVO

**QUÉ DICE:**

> "Gracias, Mathias. Ahora viene la parte más importante: la demostración en vivo.
>
> Vamos a proyectar **dos pantallas simultáneamente**. A la izquierda, yo voy a operar como cliente desde la web en mi PC. A la derecha, Mathias va a operar como profesional desde la aplicación móvil, que proyectaremos con Enlace Móvil de Windows [o 'con cable USB-C' o 'con el emulador', según el setup].
>
> Van a ver el flujo completo desde el nacimiento del problema hasta la liberación del pago, **en tiempo real, sin cortes**.
>
> Yo soy Camila Soto, una clienta de Puerto Montt que necesita un plomero urgente. Mathias es Carmen Lagos, una profesional de plomería verificada que está disponible.
>
> Comencemos."

**QUÉ MUESTRA:**
- Preparar pantalla dividida:
  - Pantalla izquierda: Navegador en https://myworksapp.cl (sesión cerrada)
  - Pantalla derecha: App móvil proyectada (sesión cerrada)

**PANTALLA:** Ambas pantallas visibles

---

### FASE 2: DEMOSTRACIÓN EN VIVO (13:00 - 25:00)

---

#### 13:00 - 14:30 | NICOLÁS | BÚSQUEDA Y FILTROS (Pantalla Izquierda)

**QUÉ DICE:**

> "Estoy en la página principal de MyWorksApp. Voy a buscar 'Plomería' en Puerto Montt.
>
> [Escribe en el buscador: 'Plomería']
>
> Ahora veo el catálogo de profesionales. Voy a filtrar por calificación mínima de 4 estrellas.
>
> [Aplica filtro: calificación ≥ 4★]
>
> Perfecto. Veo varios profesionales ordenados por cercanía, luego por calificación, luego por precio. Aquí aparece Carmen Lagos con 5 estrellas y tarifa de visita de $15.000.
>
> Voy a ver su perfil."

**QUÉ MUESTRA:**
- Web: https://myworksapp.cl
- Búsqueda: "Plomería"
- Filtro: Calificación ≥ 4★
- Catálogo con profesionales ordenados
- Clic en perfil de Carmen Lagos

**PANTALLA:** Izquierda (web)

---

#### 14:30 - 15:30 | NICOLÁS | PERFIL Y RESERVA (Pantalla Izquierda)

**QUÉ DICE:**

> "Estoy en el perfil de Carmen Lagos. Veo su calificación de 5 estrellas, sus reseñas de clientes anteriores, su portafolio con fotos de trabajos anteriores, y sus horarios disponibles.
>
> Veo que tiene disponibilidad mañana a las 10 de la mañana. Voy a reservar esa hora.
>
> [Selecciona: Mañana 10:00 AM]
>
> Ingreso mi dirección: Avenida Presidente Ibáñez 123, Puerto Montt. Describo el problema: 'Gotera en el baño, urgente'.
>
> [Escribe dirección y descripción]
>
> Confirmo la reserva. Ahora me pide el pago."

**QUÉ MUESTRA:**
- Perfil de Carmen Lagos: foto, calificación, reseñas, portafolio, horarios
- Selección de hora: Mañana 10:00 AM
- Formulario: dirección + descripción del problema
- Botón "Confirmar reserva"
- Pantalla de checkout

**PANTALLA:** Izquierda (web)

---

#### 15:30 - 17:00 | NICOLÁS | PAGO CON WEBPAY (Pantalla Izquierda)

**QUÉ DICE:**

> "Ahora voy a pagar con Webpay Plus. La plataforma me muestra el monto total: $15.000 de tarifa de visita.
>
> Observen: **no ingreso mi tarjeta en MyWorksApp**. Voy a ser redirigida a la página oficial de Transbank.
>
> [Clic en 'Pagar con Webpay']
>
> Estoy en la página de Transbank. Voy a usar la tarjeta de integración de prueba.
>
> [Ingresa: 4051 8856 0000 0002 / CVV 123 / Fecha futura]
>
> Confirmo el pago.
>
> [Espera confirmación]
>
> Perfecto. Transbank me devuelve a MyWorksApp. El pago fue autorizado y el dinero está **retenido en garantía**. Carmen no recibe el dinero todavía. Solo se liberará cuando yo apruebe el trabajo completado.
>
> El estado del trabajo es 'Esperando aceptación del profesional'."

**QUÉ MUESTRA:**
- Checkout de MyWorksApp con monto total
- Redirección a Webpay (página oficial de Transbank)
- Ingreso de tarjeta de prueba
- Confirmación de Transbank
- Retorno a MyWorksApp con pago autorizado
- Estado: "Esperando aceptación"

**PANTALLA:** Izquierda (web)

**NOTA:** Mathias se prepara en la pantalla derecha.

---

#### 17:00 - 18:00 | MATHIAS | ACEPTACIÓN Y "VOY EN CAMINO" (Pantalla Derecha)

**QUÉ DICE:**

> "Yo soy Carmen Lagos, la profesional de plomería. En mi celular recibo una notificación: 'Nuevo pedido de Camila Soto'.
>
> Abro la app y veo los detalles: gotera en el baño, mañana a las 10 AM, dirección en Avenida Presidente Ibáñez 123, pago ya autorizado de $15.000.
>
> Voy a aceptar el pedido.
>
> [Clic en 'Aceptar']
>
> Ahora el trabajo está en estado 'Aceptado'. Voy a avisar que voy en camino.
>
> [Clic en 'Voy en camino']
>
> Perfecto. Ahora voy a compartir mi ubicación GPS en tiempo real para que la clienta sepa dónde estoy."

**QUÉ MUESTRA:**
- App móvil: Notificación de nuevo pedido
- Detalle del trabajo: dirección, descripción, monto
- Botón "Aceptar" → confirmación
- Botón "Voy en camino" → GPS se activa
- Indicador: "Compartiendo ubicación"

**PANTALLA:** Derecha (app móvil)

---

#### 18:00 - 19:00 | MATHIAS | COMPARTIR GPS (Pantalla Derecha)

**QUÉ DICE:**

> "La app está publicando mi ubicación GPS cada 20 segundos. Esto solo ocurre mientras la app está en primer plano, para proteger mi privacidad.
>
> Camila, la clienta, puede ver mi posición en su mapa en tiempo real."

**QUÉ MUESTRA:**
- App móvil: Mapa con ubicación del profesional (punto naranja/azul)
- Indicador de actualización: "Última actualización: hace 5 segundos"
- Ruta (opcional, si está implementada)

**PANTALLA:** Derecha (app móvil)

---

#### 19:00 - 19:30 | NICOLÁS | VER UBICACIÓN EN MAPA (Pantalla Izquierda)

**QUÉ DICE:**

> "En mi pantalla web, veo el mapa con la ubicación de Carmen actualizándose cada 20 segundos.
>
> [Señala el mapa]
>
> Veo que está cerca. Además, veo mi PIN de inicio: **4821**. Este PIN solo yo lo veo. Carmen va a necesitarlo para demostrar que llegó a mi domicilio y que voy a iniciar el trabajo."

**QUÉ MUESTRA:**
- Web: Mapa con ubicación del profesional en tiempo real
- PIN de inicio: **4821** (destacado, solo visible para el cliente)

**PANTALLA:** Izquierda (web)

---

#### 19:30 - 20:00 | NICOLÁS | MOSTRAR PIN (Pantalla Izquierda)

**QUÉ DICE:**

> "El PIN es **4821**. Solo yo lo veo. Carmen no puede iniciar el trabajo sin este código."

**QUÉ MUESTRA:**
- Web: PIN de inicio en grande: **4821**

**PANTALLA:** Izquierda (web)

**NOTA:** Mathias se prepara para ingresar el PIN.

---

#### 20:00 - 20:30 | MATHIAS | INGRESAR PIN (Pantalla Derecha)

**QUÉ DICE:**

> "Llegué al domicilio de Camila. Ella me dicta el PIN: 4-8-2-1.
>
> [Ingresa en la app: 4 8 2 1]
>
> Confirmo. El trabajo ahora está en estado 'En progreso'. La plataforma registró que llegué y que Camila autorizó el inicio."

**QUÉ MUESTRA:**
- App móvil: Pantalla de ingreso de PIN (4 dígitos)
- Ingreso: 4 → 8 → 2 → 1
- Confirmación: "PIN correcto. Trabajo iniciado."
- Estado: "En progreso"

**PANTALLA:** Derecha (app móvil)

---

#### 20:30 - 21:30 | MATHIAS | SUBIR EVIDENCIA Y FINALIZAR (Pantalla Derecha)

**QUÉ DICE:**

> "Terminé de reparar la gotera. Ahora voy a subir evidencia del trabajo.
>
> [Clic en 'Subir evidencia']
>
> Voy a tomar una foto del baño reparado.
>
> [Toma foto o selecciona imagen pregrabada]
>
> La foto se sube en formato WebP, que es más liviano y seguro. La evidencia se guarda en un depósito privado de Supabase.
>
> [Espera que la foto se suba]
>
> Perfecto. Ahora voy a finalizar el trabajo.
>
> [Clic en 'Finalizar trabajo']
>
> El trabajo pasa a estado 'Esperando aprobación del cliente'. El pago sigue retenido hasta que Camila apruebe."

**QUÉ MUESTRA:**
- App móvil: Botón "Subir evidencia"
- Cámara o galería (toma de foto)
- Miniatura de la foto subida (imagen WebP)
- Botón "Finalizar trabajo"
- Confirmación: "Trabajo finalizado. Esperando aprobación del cliente."
- Estado: "Esperando aprobación"

**PANTALLA:** Derecha (app móvil)

---

#### 21:30 - 22:00 | NICOLÁS | VER EVIDENCIA (Pantalla Izquierda)

**QUÉ DICE:**

> "Recibo una notificación: 'Trabajo completado por Carmen Lagos'.
>
> Veo la evidencia que Carmen subió: la foto del baño reparado.
>
> [Abre la imagen en pantalla completa]
>
> Todo se ve bien. Voy a aprobar la conformidad."

**QUÉ MUESTRA:**
- Web: Notificación de trabajo completado
- Galería de evidencia (foto del baño)
- Imagen en pantalla completa
- Botón "Aprobar conformidad"

**PANTALLA:** Izquierda (web)

---

#### 22:00 - 22:30 | NICOLÁS | APROBAR CONFORMIDAD (Pantalla Izquierda)

**QUÉ DICE:**

> "Voy a aprobar.
>
> [Clic en 'Aprobar conformidad']
>
> Perfecto. El trabajo pasa a estado 'Completado' y **el pago se libera automáticamente**.
>
> Carmen ahora tiene el dinero en su cuenta pendiente de liquidación. El administrador registrará después la transferencia bancaria."

**QUÉ MUESTRA:**
- Web: Clic en "Aprobar conformidad"
- Confirmación: "Pago liberado. Trabajo completado."
- Estado: "Completado"
- Botón para calificar

**PANTALLA:** Izquierda (web)

---

#### 22:30 - 23:00 | MATHIAS | NOTIFICACIÓN DE PAGO LIBERADO (Pantalla Derecha)

**QUÉ DICE:**

> "Recibo una notificación: 'Pago liberado: $15.000'.
>
> El dinero ya está en mi cuenta pendiente. Veo el monto bruto de $15.000, la comisión de plataforma de $750 (5%), y mi monto neto de $14.250.
>
> El administrador va a registrar la transferencia bancaria en los próximos días."

**QUÉ MUESTRA:**
- App móvil: Notificación de pago liberado
- Pantalla de pagos: monto bruto, comisión (5%), neto
- Estado: "Liquidación pendiente"

**PANTALLA:** Derecha (app móvil)

---

#### 23:00 - 24:00 | NICOLÁS | CALIFICAR (Pantalla Izquierda)

**QUÉ DICE:**

> "Ahora voy a calificar a Carmen.
>
> Le doy 5 estrellas y escribo un comentario: 'Excelente trabajo, muy profesional y rápida'.
>
> [Selecciona 5 estrellas, escribe comentario]
>
> Envío la calificación."

**QUÉ MUESTRA:**
- Web: Pantalla de calificación (1-5 estrellas)
- Selección: 5 estrellas
- Textarea: "Excelente trabajo, muy profesional y rápida"
- Botón "Enviar calificación"
- Confirmación: "Calificación enviada. Gracias por tu feedback."

**PANTALLA:** Izquierda (web)

---

#### 24:00 - 25:00 | MATHIAS | VER NUEVA CALIFICACIÓN (Pantalla Derecha)

**QUÉ DICE:**

> "Recibo una notificación: 'Nueva calificación de Camila Soto: 5 estrellas'.
>
> Voy a mi perfil y veo que la nueva reseña ya aparece en mi historial. Mi puntaje de reputación subió y mi orden en el catálogo mejoró.
>
> Esta calificación va a ayudar a futuros clientes a elegirme con más confianza."

**QUÉ MUESTRA:**
- App móvil: Notificación de nueva calificación
- Perfil del profesional: nueva reseña visible
- Puntaje de reputación actualizado (ej. 4.8 → 4.9)

**PANTALLA:** Derecha (app móvil)

**FIN DE LA DEMO PRINCIPAL**

---

### FASE 3: CONSOLA DE ADMINISTRACIÓN (OPCIONAL, 25:00 - 28:00)

---

#### 25:00 - 28:00 | GABRIEL | CONSOLA DE ESCRITORIO (Pantalla 3 o proyector)

**QUÉ DICE:**

> "Opcionalmente, voy a mostrar la consola de administración.
>
> Esta es una aplicación de escritorio construida con Tauri 2. Solo el equipo interno tiene acceso.
>
> Para entrar, necesito un segundo factor de autenticación. Voy a usar mi aplicación TOTP.
>
> [Ingresa email y contraseña, luego código TOTP de 6 dígitos]
>
> Estoy dentro. La consola tiene 20 módulos de menú. Voy a mostrar tres funciones clave:
>
> **1. Verificación de profesionales:**
>
> [Navega a 'Profesionales']
>
> Veo la lista de profesionales registrados. Carmen Lagos ya está verificada. Si hubiera un profesional nuevo, yo podría revisar su documentación y cambiar su estado de 'Pendiente' a 'Verificado'. Solo los profesionales verificados aparecen en el catálogo público.
>
> **2. Mediación de disputas:**
>
> [Navega a 'Disputas']
>
> Si un cliente o un profesional abre una disputa, aparece aquí. Yo puedo leer los mensajes de ambas partes, proponer un acuerdo o resolver la disputa manualmente. Con una disputa activa, solo el administrador puede mover el trabajo.
>
> **3. Liquidación manual:**
>
> [Navega a 'Pagos']
>
> Veo los pagos liberados que están pendientes de liquidación. Selecciono el pago de Carmen Lagos de $14.250. Ingreso el número de referencia de la transferencia bancaria que hice, por ejemplo '123456789'.
>
> [Ingresa referencia y confirma]
>
> La consola me pide el código TOTP otra vez porque es una acción con dinero.
>
> [Ingresa código TOTP]
>
> Perfecto. La liquidación queda registrada en la tabla `liquidaciones` con mi usuario, la fecha, el monto y la referencia. Esto queda en la bitácora de auditoría, que es inmutable. Nadie puede borrar ni modificar este registro.
>
> Esta consola garantiza que todas las acciones críticas queden trazadas y auditables."

**QUÉ MUESTRA:**
- Consola de escritorio Tauri:
  1. Pantalla de login con segundo factor TOTP
  2. Dashboard con 20 módulos de menú
  3. Módulo "Profesionales": lista con estados de verificación
  4. Módulo "Disputas": lista de disputas abiertas y resueltas
  5. Módulo "Pagos": lista de pagos liberados pendientes de liquidación
  6. Formulario de liquidación: referencia de transferencia + confirmación TOTP
  7. Confirmación: "Liquidación registrada"

**PANTALLA:** Pantalla 3 (o proyector)

---

### FASE 4: CIERRE (28:00)

---

#### 28:00 | NICOLÁS | RESUMEN Y PREGUNTAS

**QUÉ DICE:**

> "Gracias, Gabriel.
>
> **Resumen de lo que acabamos de ver:**
>
> - El cliente buscó, reservó y pagó con Webpay Plus. El dinero quedó **retenido en garantía** (escrow).
> - El profesional aceptó, compartió su GPS en tiempo real y llegó al domicilio.
> - El trabajo se inició con un **PIN de 4 dígitos** que solo el cliente conocía, garantizando la presencia.
> - El profesional subió **evidencia fotográfica** antes de finalizar.
> - El cliente aprobó la conformidad y el **pago se liberó automáticamente**.
> - El profesional recibió su pago neto (bruto menos comisión de 5%).
> - El cliente calificó al profesional, actualizando su reputación en el catálogo.
> - Opcionalmente, vieron la consola de administración con segundo factor, verificación, mediación y liquidación.
>
> **Resultados medibles:**
> - 0% de fraude en pagos: todo pago queda retenido hasta la conformidad.
> - 0% de conflictos de horario: imposible doble reserva del mismo profesional.
> - 641 de 641 pruebas automatizadas aprobadas.
> - Web en producción en https://myworksapp.cl.
>
> MyWorksApp demuestra que **es posible formalizar servicios del hogar** con tecnología accesible, generando confianza entre partes que no se conocen.
>
> Estamos listos para responder sus preguntas."

**QUÉ MUESTRA:**
- Diapositiva de cierre con logo y contacto

**PANTALLA:** Proyector

---

## COORDINACIÓN Y SINCRONIZACIÓN

### Reglas de coordinación

1. **Mathias lleva el timer:** Tiene un cronómetro visible (celular o reloj). Avisa discretamente cada 5 minutos.

2. **No hablar encima:** Esperar a que el anterior termine su frase antes de tomar la palabra. Señal: el que termina mira al siguiente y asiente.

3. **Sincronización de acciones:** Cuando Nicolás dice "Confirmo la reserva", ambos ejecutan simultáneamente: Nicolás hace clic en "Pagar" y Mathias abre la app para recibir la notificación.

4. **Backup si algo falla:**
   - Si la conexión falla: mostrar capturas de pantalla del flujo completo (preparadas de antemano).
   - Si la app se cuelga: usar el video de la demo grabado (plan B).
   - Si el proyector falla: continuar sin demo en vivo y explicar el flujo verbalmente con las diapositivas.

5. **Ensayo previo:** Practicar el flujo completo **2 veces** el día anterior con timer. Ajustar tiempos si es necesario.

---

## PREGUNTAS FRECUENTES ANTICIPADAS

| Pregunta | Respuesta corta | Quién responde |
|----------|----------------|----------------|
| ¿Por qué Transbank en integración y no producción? | Producción requiere empresa constituida y credenciales comerciales. Documentamos el runbook completo para la migración. | GABRIEL |
| ¿Qué pasa si el profesional no sube evidencia? | El trabajo no puede finalizarse sin evidencia. El pago queda retenido indefinidamente hasta que se resuelva. | MATHIAS |
| ¿Cómo evitan que cliente y profesional se contacten por fuera? | El chat bloquea teléfonos, correos, URLs y usuarios de redes sociales. El pago se frena si detectamos contacto en la descripción o dirección. | GABRIEL |
| ¿Cuántos usuarios simultáneos soporta? | Probamos hasta 200 usuarios (p95=283ms). Con ~100 empieza a degradarse por el catálogo. Optimización pendiente. | MATHIAS |
| ¿Por qué Flutter y no nativo? | Un código para Android e iOS. Reducimos tiempo de desarrollo en 40%. Web y desktop son secundarios. | MATHIAS |
| ¿Qué es 4NF y dónde se aplica? | Cuarta Forma Normal: elimina dependencias multivaluadas. Ejemplo: `trabajador_servicios` separado de `trabajador_precios`. | GABRIEL |
| ¿641 pruebas no es excesivo? | Incluye pruebas de contrato, unitarias, integración, e2e y SQL. Aseguran que el pago protegido y los estados funcionen siempre. | GABRIEL |
| ¿Cuándo lanzan comercialmente? | Q1 2027 tras constituir empresa, obtener credenciales Transbank producción y publicar en tiendas. | NICOLÁS |

---

**FIN DEL GUIÓN**

---

**Documento generado:** 20 de noviembre de 2026  
**Versión:** 1.0 (final para defensa)  
**Autores:** Equipo MyWorksApp — Duoc UC Puerto Montt
