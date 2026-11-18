# My Works App: prompts de video premium «Guía rápida · Cómo se usa». App, Web y Escritorio

**Para:** el diseñador gráfico / motion designer
**Versión:** v1 · 16-nov-2026, 00:40 (hora de Chile). Complementa (no reemplaza) al brief del *speech* `prompt_video_cinematografico_v2.md`. Índice: `LEEME.md`.
**Qué son:** tres videos **tutoriales premium**, uno por plataforma, que enseñan **cómo se usa** cada pieza con pasos numerados. Público: usuarios reales y la comisión de evaluación de la universidad.
**Fuentes de verdad:** `flujo_app.md` (comportamiento y textos exactos), capturas de `screens/` y `e2e_live_2026-11-15/` (en este documento, `E2E/`), marca en `brand/`. Si algo no está en esas fuentes, **no va en el video**. Si una captura y `flujo_app.md` no coinciden, manda la captura y se avisa.
**Slogan oficial (end cards):** «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» (Presentación final Capstone, slide 1).
**CTA:** `myworksapp-cl.vercel.app` + QR a https://myworksapp-cl.vercel.app

| Video | 16:9 | 9:16 | Escenas 16:9 | Escenas [R] (recreadas) |
|---|---|---|---|---|
| **A · App móvil** (cliente + profesional) | **90 s** (87 s + end card 3 s) | 45 s | 17 | A5, A6 (parcial), A7, A8 (parcial), A10 (parcial), A16 |
| **B · Web** (solo clientes) | **78 s** (75 s + end card 3 s) | 40 s | 11 | ninguna (B10 usa recortes reales) |
| **C · Escritorio** (consola admin) | **72 s** (69 s + end card 3 s) | 30 s | 10 | C3, C4, C5, C6 (parcial), C7, C8, C9 |

> ⚠️ **Disco del box:** el espacio libre fluctúa entre **~95 MB y ~1,8 GB** (16-nov, 00:35–00:45, hora de Chile). **No renderizar masters** hasta liberar espacio (cada máster pide ~300–500 MB). Este documento es solo texto.

**Leyenda:** **[R]** = pantalla **recreada** como mockup fiel (no hay captura real): solo con los textos exactos de `flujo_app.md`, KPI y montos en «—» o con el rótulo «Datos de demostración», y una marca discreta «Interfaz recreada» en la esquina de 14 px al 60 %. **[C]** = captura real compuesta o recortada (sin alterar textos ni montos).

---

## BLOQUE DE ESTILO COMÚN (se repite tal cual en las tres secciones)

```
ESTILO COMÚN — MY WORKS APP · GUÍAS RÁPIDAS (premium)
- Formato: 16:9 máster 3840×2160, entrega 1920×1080, 30 fps; corte 9:16 1080×1920. MP4 H.264 High, yuv420p, +faststart. Subtítulos QUEMADOS en todas las versiones (DM Sans 600, 44 px en 1080p, blanco #F7F8FA sobre caja #121A2A al 85 %, radio 14 px, máx. 2 líneas, 42 caracteres por línea) + .srt aparte.
- Nivel: premium de festival de motion design, nunca plantilla genérica. Interfaz REAL flotando en un espacio 3D oscuro dentro de dispositivos sin marca (teléfono Android, notebook, monitor), profundidad de campo, luz de borde naranja, reflejos suaves en el vidrio. Cámara virtual: dolly-in lentos, órbitas de 10–15°, rack focus, match cuts (el botón tocado se convierte en la siguiente pantalla) y whip pans cortos con desenfoque naranja entre capítulos. Ease-out cúbico de 250–450 ms; sin rebotes exagerados sobre la interfaz; nada de transiciones tipo PowerPoint; máx. 3 destellos por segundo.
- Marca (valores del código): naranja #FF5E03 (solo CTA y focos, 10 %), naranja vibrante #FF7A18 (gradientes), navy #00205B (confianza / pago retenido, 30 %), canvas oscuro degradado #070B12 → #0B1424 (60 %), superficies #121A2A / #172033, verde éxito #2F9E64, rojo error #E23D35, ámbar pendiente #C9A227, azul info #4C8DDB, texto #F7F8FA / #A8B2C0. Halo radial naranja arriba a la izquierda (glow rgba(255,94,3,0.32)). Regla 60-30-10. Radios 10/14/22 px, botones píldora, íconos lineales tipo Lucide de 2 px.
- Tipografía agregada: DM Sans (títulos 700 con tracking −1 %, cuerpo 500/600). Las capturas no se re-tipografían (la app móvil usa Roboto).
- Logo: «MW» blanco sobre dos rectángulos redondeados, navy adelante-izquierda y naranja atrás-derecha (brand/mark.svg, brand/mark_2048.png). Nombre siempre «My Works App». No redibujarlo ni deformarlo.
- Formato GUÍA: cada paso abre con una etiqueta «Paso N» (píldora naranja #FF5E03, DM Sans 700, texto blanco) + título corto del paso (DM Sans 600, 56 px) en la esquina superior izquierda, y un contador de progreso fino abajo (N de total). Tarjetas de capítulo de 0,8 s (fondo navy #00205B, título DM Sans 700). Callouts: línea naranja de 2 px + etiqueta DM Sans 600 sobre caja #121A2A al 90 %, radio 14 px; máx. 2 a la vez, ~7 palabras, sincronizados con la voz. Toques = anillo sutil que se expande. Legibilidad: plano general de 0,5–1 s y luego zoom al elemento que nombra la voz (texto a leer ≥ 28 px en 1080p); el resto se oscurece al 40 %.
- Divertido de ver pero fiel: el humor vive en las tomas de vida real y en el ritmo (beats musicales en cada «Paso»), nunca alterando la interfaz. Sin frases de vendedor ni promesas no medidas («en segundos», «la mejor app»). Sin cifras de negocio.
- Voz: presentador/a chileno/a neutro-profesional de 30–45 años, cálido, claro, ritmo de tutorial (2,0–2,4 palabras/s). Trata al espectador de «tú». Pronunciación: My Works App /mái uórks ap/, Webpay /uébpei/, Transbank /tránsbank/. Un WAV por escena, 48 kHz / 24 bit, 0,3 s de aire. Recomendado locutor humano; TTS solo como guía de tiempos.
- Música y sonido: score cinematográfico-electrónico 100–115 BPM con licencia comercial guardada; un acento suave en cada «Paso N»; SFX discretos (taps, whoosh, candado del pago retenido, ding de éxito). Ducking −12 dB bajo la voz. Mezcla −14 LUFS (web) / −16 LUFS (sala), picos ≤ −1 dBTP.
- PRECISIÓN (obligatoria): solo pantallas reales de screens/ y e2e_live_2026-11-15/ (se pueden recortar, ampliar, separar en capas o desenfocar, sin alterar textos, montos ni estados). Lo que no tiene captura se recrea [R] con los textos exactos de flujo_app.md y KPI en «—» o «Datos de demostración». Datos de demostración (Puerto Montt): cliente «Andrés P.», profesional «Mateo Oyarzo · Gasfíter», servicio «Reparación de fuga de agua y cambio de llaves o grifería», $32.000 por visita. Rótulo fijo pequeño: «Datos de demostración · Transbank en ambiente de integración». La tarjeta Visa de prueba pública de Transbank (4051 8856 0044 6623) puede verse.
- Cifras de Mateo (hasta merge + deploy + seed): NO zoom, callout ni mención de voz a su nota, su contador de trabajos ni al «↑ 12 % vs. mes anterior»; NO usar W_22; desenfocar «Ganancias totales», el porcentaje y el chip de nota en W_05b; la ficha «TRABAJADOR» de las capturas web se desenfoca (o se usan las recapturas de C_08/C_16/C_17). Si hace falta un valor, chip ámbar «valores unificados pendientes».
- NO mostrar: la lista «Cuentas demo» (app_03b, W_01), correos o contraseñas reales, el botón «Feedback de la prueba» (A_18/A_18b), el globo «Guía profesional» (W_02), comentarios «(prueba E2E)», el estado crudo «esperando_pago» (A_19), mapas con la marca de agua CARTO «API KEY REQUIRED» (web_e2e_13/14), los mockups de brand/mockups_diseno/, el contrato digital como firma legal (es DEMO, Ley 19.799), reprogramar/reagendar, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, transferencia automática al profesional, push «Nueva solicitud», IA, videollamadas, seguros.
- Tomas de vida real (IA de video) solo para ambientar: nunca generar interfaz con IA. Bloque común: «cinematic, 35mm anamorphic look, shallow depth of field, dark moody interior, warm orange rim light (#FF5E03) and deep navy shadows (#00205B), photorealistic, no text, no logos, no readable screens, no UI». 3–5 s, sin miradas a cámara, personajes consistentes.
- END CARD (3 s quieto para escanear): logo al centro + slogan «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» + «myworksapp-cl.vercel.app» + QR estático a https://myworksapp-cl.vercel.app (pie «Proyecto de título · Duoc UC» opcional, pendiente de decisión de Mathias).
- Entregables por video: 16:9 1080p (y 4K) con subtítulos quemados; 16:9 sin voz con subtítulos (para presentar en vivo); 9:16 con subtítulos quemados; .srt; stems de voz, música y SFX; proyecto fuente (Remotion, /workspace/mwa_video/remotion/).
```

---

# A · APP MÓVIL (Flutter): «Guía rápida · App My Works App»

**Duración:** 16:9 de **90 s** (87 s + end card 3 s) · 9:16 de **45 s**. **17 escenas.** Dos capítulos: **Cliente** (7 pasos) y **Profesional** (7 pasos).

### A.1 Prompt maestro (pegable en el brief o en el agente de Remotion; NO en generadores de IA)

```
Produce un video tutorial premium de 90 segundos, 16:9, «Guía rápida · App My Works App»: enseña paso a paso cómo se usa la app móvil (Android, Flutter) en sus dos roles. My Works App es un marketplace chileno de servicios para el hogar en el que el pago queda retenido en Transbank hasta que el cliente da la conformidad.

ESTRUCTURA
- Apertura (9 s): una persona llega a su casa y encuentra la llave rota y una fuga (toma real) → toma el teléfono → título «Guía rápida · App móvil» sobre el logo, y las láminas reales de onboarding se abren en abanico.
- Capítulo 1 · Cliente (7 pasos): Paso 1 Crea tu cuenta · Paso 2 Busca un profesional · Paso 3 Revisa el perfil y elige hora · Paso 4 Paga con Webpay (queda retenido) · Paso 5 Sigue el trabajo y entrega el PIN · Paso 6 Da la conformidad y se libera el pago · Paso 7 Califica.
- Capítulo 2 · Profesional (7 pasos): Paso 1 Entra como Especialista y completa tu perfil · Paso 2 Acepta el pedido · Paso 3 Voy en camino · Paso 4 Pide el PIN · Paso 5 Sube evidencia · Paso 6 Finaliza y califica al cliente · Paso 7 Revisa tus cobros.
- Cierre (4 s): el teléfono gira, el logo se asienta, end card.
- Un objeto visual guía todo el video: una ficha naranja (el pago) que entra a un cofre navy con candado en el Paso 4, espera en la esquina y en el Paso 6 se vuelve verde con la etiqueta «Liberado» (no vuela al profesional: la transferencia la registra un administrador). En el capítulo 2, la barra de estados Pendiente · Aceptado · En camino · En Curso · Pendiente de aprobación · Completado avanza como un marcador (hecho = verde ✓, actual = naranja pulsando, futuro = gris).
- Las pantallas marcadas [R] en el guion se recrean como mockups fieles con los textos exactos indicados y el sello «Interfaz recreada».

ESTILO COMÚN — MY WORKS APP · GUÍAS RÁPIDAS (premium)
- Formato: 16:9 máster 3840×2160, entrega 1920×1080, 30 fps; corte 9:16 1080×1920. MP4 H.264 High, yuv420p, +faststart. Subtítulos QUEMADOS en todas las versiones (DM Sans 600, 44 px en 1080p, blanco #F7F8FA sobre caja #121A2A al 85 %, radio 14 px, máx. 2 líneas, 42 caracteres por línea) + .srt aparte.
- Nivel: premium de festival de motion design, nunca plantilla genérica. Interfaz REAL flotando en un espacio 3D oscuro dentro de dispositivos sin marca (teléfono Android, notebook, monitor), profundidad de campo, luz de borde naranja, reflejos suaves en el vidrio. Cámara virtual: dolly-in lentos, órbitas de 10–15°, rack focus, match cuts (el botón tocado se convierte en la siguiente pantalla) y whip pans cortos con desenfoque naranja entre capítulos. Ease-out cúbico de 250–450 ms; sin rebotes exagerados sobre la interfaz; nada de transiciones tipo PowerPoint; máx. 3 destellos por segundo.
- Marca (valores del código): naranja #FF5E03 (solo CTA y focos, 10 %), naranja vibrante #FF7A18 (gradientes), navy #00205B (confianza / pago retenido, 30 %), canvas oscuro degradado #070B12 → #0B1424 (60 %), superficies #121A2A / #172033, verde éxito #2F9E64, rojo error #E23D35, ámbar pendiente #C9A227, azul info #4C8DDB, texto #F7F8FA / #A8B2C0. Halo radial naranja arriba a la izquierda (glow rgba(255,94,3,0.32)). Regla 60-30-10. Radios 10/14/22 px, botones píldora, íconos lineales tipo Lucide de 2 px.
- Tipografía agregada: DM Sans (títulos 700 con tracking −1 %, cuerpo 500/600). Las capturas no se re-tipografían (la app móvil usa Roboto).
- Logo: «MW» blanco sobre dos rectángulos redondeados, navy adelante-izquierda y naranja atrás-derecha (brand/mark.svg, brand/mark_2048.png). Nombre siempre «My Works App». No redibujarlo ni deformarlo.
- Formato GUÍA: cada paso abre con una etiqueta «Paso N» (píldora naranja #FF5E03, DM Sans 700, texto blanco) + título corto del paso (DM Sans 600, 56 px) en la esquina superior izquierda, y un contador de progreso fino abajo (N de total). Tarjetas de capítulo de 0,8 s (fondo navy #00205B, título DM Sans 700). Callouts: línea naranja de 2 px + etiqueta DM Sans 600 sobre caja #121A2A al 90 %, radio 14 px; máx. 2 a la vez, ~7 palabras, sincronizados con la voz. Toques = anillo sutil que se expande. Legibilidad: plano general de 0,5–1 s y luego zoom al elemento que nombra la voz (texto a leer ≥ 28 px en 1080p); el resto se oscurece al 40 %.
- Divertido de ver pero fiel: el humor vive en las tomas de vida real y en el ritmo (beats musicales en cada «Paso»), nunca alterando la interfaz. Sin frases de vendedor ni promesas no medidas («en segundos», «la mejor app»). Sin cifras de negocio.
- Voz: presentador/a chileno/a neutro-profesional de 30–45 años, cálido, claro, ritmo de tutorial (2,0–2,4 palabras/s). Trata al espectador de «tú». Pronunciación: My Works App /mái uórks ap/, Webpay /uébpei/, Transbank /tránsbank/. Un WAV por escena, 48 kHz / 24 bit, 0,3 s de aire. Recomendado locutor humano; TTS solo como guía de tiempos.
- Música y sonido: score cinematográfico-electrónico 100–115 BPM con licencia comercial guardada; un acento suave en cada «Paso N»; SFX discretos (taps, whoosh, candado del pago retenido, ding de éxito). Ducking −12 dB bajo la voz. Mezcla −14 LUFS (web) / −16 LUFS (sala), picos ≤ −1 dBTP.
- PRECISIÓN (obligatoria): solo pantallas reales de screens/ y e2e_live_2026-11-15/ (se pueden recortar, ampliar, separar en capas o desenfocar, sin alterar textos, montos ni estados). Lo que no tiene captura se recrea [R] con los textos exactos de flujo_app.md y KPI en «—» o «Datos de demostración». Datos de demostración (Puerto Montt): cliente «Andrés P.», profesional «Mateo Oyarzo · Gasfíter», servicio «Reparación de fuga de agua y cambio de llaves o grifería», $32.000 por visita. Rótulo fijo pequeño: «Datos de demostración · Transbank en ambiente de integración». La tarjeta Visa de prueba pública de Transbank (4051 8856 0044 6623) puede verse.
- Cifras de Mateo (hasta merge + deploy + seed): NO zoom, callout ni mención de voz a su nota, su contador de trabajos ni al «↑ 12 % vs. mes anterior»; NO usar W_22; desenfocar «Ganancias totales», el porcentaje y el chip de nota en W_05b; la ficha «TRABAJADOR» de las capturas web se desenfoca (o se usan las recapturas de C_08/C_16/C_17). Si hace falta un valor, chip ámbar «valores unificados pendientes».
- NO mostrar: la lista «Cuentas demo» (app_03b, W_01), correos o contraseñas reales, el botón «Feedback de la prueba» (A_18/A_18b), el globo «Guía profesional» (W_02), comentarios «(prueba E2E)», el estado crudo «esperando_pago» (A_19), mapas con la marca de agua CARTO «API KEY REQUIRED» (web_e2e_13/14), los mockups de brand/mockups_diseno/, el contrato digital como firma legal (es DEMO, Ley 19.799), reprogramar/reagendar, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, transferencia automática al profesional, push «Nueva solicitud», IA, videollamadas, seguros.
- Tomas de vida real (IA de video) solo para ambientar: nunca generar interfaz con IA. Bloque común: «cinematic, 35mm anamorphic look, shallow depth of field, dark moody interior, warm orange rim light (#FF5E03) and deep navy shadows (#00205B), photorealistic, no text, no logos, no readable screens, no UI». 3–5 s, sin miradas a cámara, personajes consistentes.
- END CARD (3 s quieto para escanear): logo al centro + slogan «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» + «myworksapp-cl.vercel.app» + QR estático a https://myworksapp-cl.vercel.app (pie «Proyecto de título · Duoc UC» opcional, pendiente de decisión de Mathias).
- Entregables por video: 16:9 1080p (y 4K) con subtítulos quemados; 16:9 sin voz con subtítulos (para presentar en vivo); 9:16 con subtítulos quemados; .srt; stems de voz, música y SFX; proyecto fuente (Remotion, /workspace/mwa_video/remotion/).
```

### A.2 Tomas de vida real (IA de video; agregar el bloque común de tomas)

| Toma | Prompt | Uso |
|---|---|---|
| AT1 Llega a casa | A woman in her 30s opens her front door at dusk carrying grocery bags, hears water, stops; warm hallway light, face partially in shadow. | A1 |
| AT2 La fuga | Close-up of a broken chrome kitchen faucet spraying a thin jet of water, a puddle spreading on the dark countertop, a dish towel soaking; slightly comedic timing. | A1 |
| AT3 Al teléfono | Over-the-shoulder of the same woman picking up a smartphone (screen facing away from camera) next to the leaking sink, determined expression. | A1 → A2 |
| AT4 El especialista | Tracking shot from behind of a tradesman with a tool bag walking to a house door at golden hour, face not visible. | A12 |
| AT5 Arreglado | Hands with a wrench tightening a new faucet; the last drop hangs, wobbles and does not fall. | A14 |

⚠️ Revisar manos, herramientas y caras. Si un teléfono muestra algo legible, se descarta la toma.

### A.3 Guion por escenas 16:9 (90 s)

Rutas sin prefijo en `screens/`; `E2E/…` en `e2e_live_2026-11-15/`.

| # | Tiempo | Visual (captura real / toma) | Locución | Texto en pantalla | Animación | Sonido |
|---|---|---|---|---|---|---|
| **APERTURA** |||||||
| A1 | 0:00–0:04 (4 s) | AT1 → AT2 → AT3 | «Llegas a casa… y la llave decidió rendirse.» (8 pal) | — | Corte en el beat al chorro; push-in al teléfono. | Agua; piano + sub-bass. |
| A2 | 0:04–0:09 (5 s) | `app_01_onboarding_1..4.png` en abanico 3D → `app_02_bienvenida.png` («Soluciones profesionales para tu hogar», «Comenzar Ahora») | «Esta es la guía rápida de My Works App, en el teléfono.» (11) | **«Guía rápida · App móvil»** · «Cliente y profesional» | Las 4 láminas se despliegan como cartas y se apilan; tap en «Comenzar Ahora». | Whoosh; tap. |
| **CAPÍTULO 1 · CLIENTE** (tarjeta 0,8 s dentro de A3) |||||||
| A3 | 0:09–0:15 (6 s) | `E2E/S_05_app_registro.png` («Crea tu cuenta», **Cliente** seleccionado) → `app_04_registro.png` (casilla Términos, «Registrarse») | «Paso uno: crea tu cuenta como cliente. La contraseña lleva ocho caracteres, con letras y números.» (16) | **Paso 1 · Crea tu cuenta** · «Cliente: busco servicios profesionales» · «Mín. 8 caracteres, letra y número» | Zoom al selector Cliente / Especialista; check en la casilla; match cut desde «Registrarse». | Tap; acento de paso. |
| A4 | 0:15–0:21 (6 s) | [C] `E2E/A_18b_home.png` («¡Hola de nuevo, Andrés!», «¿Qué necesitas hoy?», «Buscar servicios...»; **tapar «Feedback de la prueba»** con el fondo) → `app_mapa_openfreemap.png` (mapa real de Puerto Montt) con overlay [R] de la cabecera «Búsqueda Inteligente / Lista Manual», «Usar GPS», «Disponible ahora» | «Paso dos: busca el servicio y mira en el mapa quién está cerca y disponible.» (14) | **Paso 2 · Busca** · «Búsqueda Inteligente o Lista Manual» | Tecleo «plomería» en el buscador; los pines caen escalonados en el mapa. Sin tarjetas con nota ni trabajos. | Tecleo; pops. |
| A5 [R] | 0:21–0:27 (6 s) | **[R] «Perfil del trabajador»** (Mateo Oyarzo · Gasfíter; secciones «Sobre mí», «Especialidad», «Cobertura en el mapa», «Opiniones de clientes» sin nota visible; botón «Crear solicitud de servicio») → **[R] «Agendar visita»** (Fecha de visita, Horario, Dirección, «Notas (opcional)», «Continuar al pago»; nota «Solo se muestran las horas que el profesional publicó y que siguen libres.») | «Paso tres: revisa su perfil y elige una de las horas que el profesional publicó y siguen libres.» (17) | **Paso 3 · Perfil y hora** · «Solo horas publicadas y libres» | Scroll suave por el perfil; los bloques horarios aparecen uno a uno; pulso en «Continuar al pago». | Tap. |
| A6 ★ [R parcial] | 0:27–0:34 (7 s) | **[R]** hoja «Pago Webpay — Confirmar pedido — Primera confirmación: el monto queda retenido en Transbank. Se libera solo cuando recibas conforme el trabajo.» con «Pagar en Transbank sin guardar tarjeta» → real `app_e2e_tarjeta_oneclick.png` («Inscribe tu tarjeta una vez», «Inscribir tarjeta») como alternativa Oneclick (1,5 s) → [C] tarjeta flotante con `E2E/A_03_webpay_tarjeta.png` (Transbank, 1 s, fuera del teléfono) → la ficha entra al cofre | «Paso cuatro: pagas en Transbank. La app no guarda tu tarjeta y los treinta y dos mil pesos quedan retenidos.» (19) | **Paso 4 · Paga** · **«Pago RETENIDO»** · chip «Transbank · integración (pruebas)» | Rack focus a «Primera confirmación»; la ficha naranja cae al cofre navy y suena el candado; el cofre queda en miniatura en la esquina. | Drop musical; candado. |
| A7 [R parcial] | 0:34–0:41 (7 s) | Real `E2E/A_31a_arriba.png` («Detalles del Trabajo», línea de tiempo, «Pago: retenido») → **[R]** tarjeta «PIN para iniciar» (PIN **7083**, botón copiar → «PIN copiado») + «Ubicación en vivo» sobre el mapa real de A_31a | «Paso cinco: sigue el trabajo en la línea de tiempo. Cuando llegue, dale tu PIN de cuatro dígitos.» (17) | **Paso 5 · Sigue y entrega el PIN** · «Solo tú ves el PIN» | La línea de tiempo se ilumina; los 4 dígitos aparecen con pop; tap en copiar → toast. | Blip; teclas. |
| A8 ★ [R parcial] | 0:41–0:47 (6 s) | **[R]** tarjeta «Ver evidencia (fotos y videos)» + «Segunda confirmación: recibo conforme» → diálogo «Recibo conforme» → «Liberar fondos» → toast «Trabajo recibido conforme. Los fondos quedaron liberados.» → real `E2E/A_20_detalle_completado.png` (recuadro «¿Problema con el trabajo?», «Abrir disputa», «Calificar Trabajo») | «Paso seis: revisa la evidencia y confirma "recibo conforme". Recién ahí se libera el pago.» (14) | **Paso 6 · Conformidad** · «Se libera con tu conformidad» · «¿No conforme? Abre una disputa» | El cofre se abre, la ficha se vuelve verde «Liberado»; zoom breve a «Abrir disputa». | Clímax; ding + monedas suaves. |
| A9 | 0:47–0:51 (4 s) | `E2E/A_21b_calificacion_llena.png` («Calificar Trabajo», 5 ★; recortar comentario «(prueba E2E)») → `E2E/A_22_calificacion_enviada.png` | «Paso siete: califica. Tu nota alimenta el ranking.» (8) | **Paso 7 · Califica** | Las estrellas se llenan una a una. | Ding ascendente ×5. |
| **CAPÍTULO 2 · PROFESIONAL** (tarjeta 0,8 s dentro de A10; whip pan) |||||||
| A10 [R parcial] | 0:51–0:57 (6 s) | `app_03_login.png` (zoom al selector **Especialista**; sin la lista de cuentas) → [C] `E2E/W_05b_panel_ocupado.png` recortado a «Completa tu perfil (50%) · 3 pasos pendientes» (desenfocar chip de nota y «Ganancias totales») → **[R]** mini-tarjetas en abanico: «Completa tu perfil» (profesión, zona de trabajo, «Descripción profesional»), verificación «Enviar a revisión» (Pendiente / En revisión / Verificado), «Guardar tarifas», «Guardar horario» | «Ahora, el profesional. Paso uno: entra como especialista, completa tu perfil, verifícate y publica tu horario.» (17) | **Paso 1 · Perfil y verificación** · «Sin verificación no se cobra» | Las 4 tarjetas [R] salen de la barra de progreso y se ordenan como checklist. | Whoosh; ticks. |
| A11 | 0:57–1:02 (5 s) | `E2E/W_04_pro_detalle_pendiente.png` («Aceptar Trabajo» / «Rechazar», «Reputación como cliente») → `E2E/W_05a_tras_aceptar.png` | «Paso dos: revisa el pedido y la reputación del cliente, y acepta.» (12) | **Paso 2 · Acepta** · «Si rechazas: reembolso a la tarjeta» | Aparece la barra de estados → **Aceptado**. | Tap; ding corto. |
| A12 | 1:02–1:06 (4 s) | AT4 (1 s) → `E2E/W_07a_tras_en_camino.png` («En camino», «Ubicación compartida con el cliente de este pedido.») | «Paso tres: toca "voy en camino" y el cliente te ve en el mapa.» (12) | **Paso 3 · Voy en camino** · «GPS solo con la app abierta» | Barra → **En camino**; el pin avanza a saltos (cada 20 s o 40 m). | Whoosh; blips. |
| A13 ★ | 1:06–1:13 (7 s) | `E2E/W_09_pro_pin_dialogo.png` («Iniciar trabajo — Pide al cliente el PIN de 4 dígitos…», «Confirmar PIN») → inserto `E2E/W_10_pro_pin_incorrecto.png` → `E2E/W_11_pro_pin_correcto_en_curso.png` | «Paso cuatro: pide el PIN al cliente. Sin él no puedes iniciar, y cinco errores bloquean quince minutos.» (17) | **Paso 4 · PIN** · «5 intentos fallidos → 15 min de bloqueo» | Error = shake rojo de 3 ciclos; acierto = check verde; barra → **En Curso**. | Teclas; buzz; ding. |
| A14 | 1:13–1:18 (5 s) | AT5 (1 s) → `E2E/W_12a_finalizar_sin_evidencia.png` → `E2E/W_13_pro_menu_evidencia.png` («Tomar foto · Elegir foto de galería · Elegir video») → `E2E/W_14_pro_evidencia_subida.png` (desenfocar miniatura de prueba) | «Paso cinco: sube fotos o video. Sin evidencia, no se finaliza.» (10) | **Paso 5 · Evidencia** · «Sin evidencia no se finaliza» | El menú sube desde abajo; obturador. | Obturador. |
| A15 | 1:18–1:22 (4 s) | `E2E/W_15a_confirmar_finalizar.png` → `E2E/W_24b_form_lleno.png` («Calificar al cliente — … No mueve el pago.»; recortar comentarios de prueba) | «Paso seis: finaliza y califica al cliente.» (7) | **Paso 6 · Finaliza** · «Pendiente de aprobación» | Barra → **Pendiente de aprobación** (ámbar) → **Completado** (verde) cuando el cliente confirma. | Ding. |
| A16 [R] | 1:22–1:26 (4 s) | **[R] «Mis cobros»**: cuenta bancaria (Banco, tipo de cuenta, RUT del titular, todo «—»), columnas «Por pagar» / «Pendiente de transferencia» / «Transferido» con «—» + rótulo «Datos de demostración» | «Paso siete: registra tu cuenta y sigue tus cobros. La transferencia la registra la administración.» (15) | **Paso 7 · Cobros** · «Transferencia registrada por un administrador» | La ficha verde «Liberado» se desliza a «Pendiente de transferencia». | Monedas suaves. |
| **CIERRE** |||||||
| A17 | 1:26–1:30 (1 s + end card 3 s) | Teléfono gira 180° → logo → end card | «My Works App.» (3) | End card (slogan + URL + QR) | El logo se asienta en el beat. | Resolución musical. |

**Locución:** ~232 palabras en 87 s (≈2,3 pal/s).

### A.4 Locución completa

> **[A1]** Llegas a casa… y la llave decidió rendirse.
> **[A2]** Esta es la guía rápida de My Works App, en el teléfono.
> **[A3]** Paso uno: crea tu cuenta como cliente. La contraseña lleva ocho caracteres, con letras y números.
> **[A4]** Paso dos: busca el servicio y mira en el mapa quién está cerca y disponible.
> **[A5]** Paso tres: revisa su perfil y elige una de las horas que el profesional publicó y siguen libres.
> **[A6]** Paso cuatro: pagas en Transbank. La app no guarda tu tarjeta y los treinta y dos mil pesos quedan retenidos.
> **[A7]** Paso cinco: sigue el trabajo en la línea de tiempo. Cuando llegue, dale tu PIN de cuatro dígitos.
> **[A8]** Paso seis: revisa la evidencia y confirma «recibo conforme». Recién ahí se libera el pago.
> **[A9]** Paso siete: califica. Tu nota alimenta el ranking.
> **[A10]** Ahora, el profesional. Paso uno: entra como especialista, completa tu perfil, verifícate y publica tu horario.
> **[A11]** Paso dos: revisa el pedido y la reputación del cliente, y acepta.
> **[A12]** Paso tres: toca «voy en camino» y el cliente te ve en el mapa.
> **[A13]** Paso cuatro: pide el PIN al cliente. Sin él no puedes iniciar, y cinco errores bloquean quince minutos.
> **[A14]** Paso cinco: sube fotos o video. Sin evidencia, no se finaliza.
> **[A15]** Paso seis: finaliza y califica al cliente.
> **[A16]** Paso siete: registra tu cuenta y sigue tus cobros. La transferencia la registra la administración.
> **[A17]** My Works App.

### A.5 Corte 9:16 (45 s)

Zona segura 250 px arriba / 300 px abajo; teléfono a pantalla casi completa; «Paso N» arriba.

| # | Tiempo | Visual | Locución | Texto |
|---|---|---|---|---|
| AV1 | 0:00–0:04 | AT2 vertical (la fuga) | «¿Fuga en casa? Así se usa My Works App.» (8) | «Guía rápida · App» |
| AV2 | 0:04–0:09 | `E2E/S_05_app_registro.png` | «Crea tu cuenta como cliente.» (5) | Paso 1 · Cuenta |
| AV3 | 0:09–0:14 | [C] `E2E/A_18b_home.png` (sin «Feedback de la prueba») → `app_mapa_openfreemap.png` | «Busca y elige un profesional cercano.» (6) | Paso 2 · Busca |
| AV4 | 0:14–0:20 | [R] hoja «Primera confirmación…» → cofre | «Paga en Transbank: el monto queda retenido.» (7) | Paso 3 · Pago RETENIDO |
| AV5 | 0:20–0:25 | [R] tarjeta «PIN para iniciar» 7083 → `E2E/W_09` | «Al llegar, entrega tu PIN.» (5) | Paso 4 · PIN |
| AV6 | 0:25–0:30 | `E2E/W_13` → `E2E/W_14` | «El profesional sube evidencia.» (4) | Paso 5 · Evidencia |
| AV7 | 0:30–0:36 | [R] «Recibo conforme» → «Liberar fondos» | «Confirmas "recibo conforme" y se libera el pago.» (8) | Paso 6 · Conformidad |
| AV8 | 0:36–0:41 | `E2E/A_21b_calificacion_llena.png` | «Y se califican.» (3) | Paso 7 · Califica |
| AV9 | 0:41–0:45 | End card vertical | «My Works App.» (3) | URL + QR |

---

# B · WEB (React/Vite, solo clientes): «Guía rápida · myworksapp-cl.vercel.app»

**Duración:** 16:9 de **78 s** (75 s + end card 3 s) · 9:16 de **40 s**. **11 escenas**, 7 pasos + «Si algo cambia».
**Alcance:** la web es **solo para clientes** («Esta web es solo para clientes que buscan un oficio. Los trabajadores usan la app móvil; el equipo interno, el panel de escritorio.»). **Reagendar NO se muestra:** `flujo_app.md` §2.7 dice «No existe "reprogramar" en ningún cliente (verificado en E2E del 15-nov)». Si el Programador confirma que ya existe (CU-33), primero hay que actualizar `flujo_app.md` y capturarlo. **Calificar** se hace solo en la app (se dice en una línea, sin mostrar calificación web).

### B.1 Prompt maestro

```
Produce un video tutorial premium de 78 segundos, 16:9, «Guía rápida · My Works App en la web» (myworksapp-cl.vercel.app): enseña paso a paso cómo un cliente pide un profesional desde el navegador, con o sin cuenta, paga en Transbank Webpay con el pago retenido y lo libera con «Recibo conforme».

ESTRUCTURA
- Apertura (9 s): toma real de una persona que encuentra una fuga y abre su notebook → la portada real en un notebook 3D flotante, título «Guía rápida · Web».
- 7 pasos: Paso 1 Entra o crea tu cuenta (opcional) · Paso 2 Busca en el mapa y filtra · Paso 3 Elige profesional y hora (Reserva rápida) · Paso 4 Confirma: con sesión o como invitado · Paso 5 Paga en Webpay · Paso 6 Sigue la llegada y entrega el PIN · Paso 7 Da la conformidad.
- «Si algo cambia» (8 s): cancelación con reembolso y disputa con el pago retenido.
- Cierre: el notebook se cierra suave hacia el logo → end card.
- Motivo visual: la misma ficha naranja (pago) entra al cofre navy en el Paso 5 y se vuelve verde «Liberado» en el Paso 7. Cursor real con anillo de clic, nunca mano dibujada. En el Paso 4, pantalla dividida «Con sesión | Sin sesión».
- Las capturas web se presentan en un notebook genérico 3D; para planos verticales se usan las capturas móviles mob_*.

ESTILO COMÚN — MY WORKS APP · GUÍAS RÁPIDAS (premium)
- Formato: 16:9 máster 3840×2160, entrega 1920×1080, 30 fps; corte 9:16 1080×1920. MP4 H.264 High, yuv420p, +faststart. Subtítulos QUEMADOS en todas las versiones (DM Sans 600, 44 px en 1080p, blanco #F7F8FA sobre caja #121A2A al 85 %, radio 14 px, máx. 2 líneas, 42 caracteres por línea) + .srt aparte.
- Nivel: premium de festival de motion design, nunca plantilla genérica. Interfaz REAL flotando en un espacio 3D oscuro dentro de dispositivos sin marca (teléfono Android, notebook, monitor), profundidad de campo, luz de borde naranja, reflejos suaves en el vidrio. Cámara virtual: dolly-in lentos, órbitas de 10–15°, rack focus, match cuts (el botón tocado se convierte en la siguiente pantalla) y whip pans cortos con desenfoque naranja entre capítulos. Ease-out cúbico de 250–450 ms; sin rebotes exagerados sobre la interfaz; nada de transiciones tipo PowerPoint; máx. 3 destellos por segundo.
- Marca (valores del código): naranja #FF5E03 (solo CTA y focos, 10 %), naranja vibrante #FF7A18 (gradientes), navy #00205B (confianza / pago retenido, 30 %), canvas oscuro degradado #070B12 → #0B1424 (60 %), superficies #121A2A / #172033, verde éxito #2F9E64, rojo error #E23D35, ámbar pendiente #C9A227, azul info #4C8DDB, texto #F7F8FA / #A8B2C0. Halo radial naranja arriba a la izquierda (glow rgba(255,94,3,0.32)). Regla 60-30-10. Radios 10/14/22 px, botones píldora, íconos lineales tipo Lucide de 2 px.
- Tipografía agregada: DM Sans (títulos 700 con tracking −1 %, cuerpo 500/600). Las capturas no se re-tipografían (la app móvil usa Roboto).
- Logo: «MW» blanco sobre dos rectángulos redondeados, navy adelante-izquierda y naranja atrás-derecha (brand/mark.svg, brand/mark_2048.png). Nombre siempre «My Works App». No redibujarlo ni deformarlo.
- Formato GUÍA: cada paso abre con una etiqueta «Paso N» (píldora naranja #FF5E03, DM Sans 700, texto blanco) + título corto del paso (DM Sans 600, 56 px) en la esquina superior izquierda, y un contador de progreso fino abajo (N de total). Tarjetas de capítulo de 0,8 s (fondo navy #00205B, título DM Sans 700). Callouts: línea naranja de 2 px + etiqueta DM Sans 600 sobre caja #121A2A al 90 %, radio 14 px; máx. 2 a la vez, ~7 palabras, sincronizados con la voz. Toques = anillo sutil que se expande. Legibilidad: plano general de 0,5–1 s y luego zoom al elemento que nombra la voz (texto a leer ≥ 28 px en 1080p); el resto se oscurece al 40 %.
- Divertido de ver pero fiel: el humor vive en las tomas de vida real y en el ritmo (beats musicales en cada «Paso»), nunca alterando la interfaz. Sin frases de vendedor ni promesas no medidas («en segundos», «la mejor app»). Sin cifras de negocio.
- Voz: presentador/a chileno/a neutro-profesional de 30–45 años, cálido, claro, ritmo de tutorial (2,0–2,4 palabras/s). Trata al espectador de «tú». Pronunciación: My Works App /mái uórks ap/, Webpay /uébpei/, Transbank /tránsbank/. Un WAV por escena, 48 kHz / 24 bit, 0,3 s de aire. Recomendado locutor humano; TTS solo como guía de tiempos.
- Música y sonido: score cinematográfico-electrónico 100–115 BPM con licencia comercial guardada; un acento suave en cada «Paso N»; SFX discretos (taps, whoosh, candado del pago retenido, ding de éxito). Ducking −12 dB bajo la voz. Mezcla −14 LUFS (web) / −16 LUFS (sala), picos ≤ −1 dBTP.
- PRECISIÓN (obligatoria): solo pantallas reales de screens/ y e2e_live_2026-11-15/ (se pueden recortar, ampliar, separar en capas o desenfocar, sin alterar textos, montos ni estados). Lo que no tiene captura se recrea [R] con los textos exactos de flujo_app.md y KPI en «—» o «Datos de demostración». Datos de demostración (Puerto Montt): cliente «Andrés P.», profesional «Mateo Oyarzo · Gasfíter», servicio «Reparación de fuga de agua y cambio de llaves o grifería», $32.000 por visita. Rótulo fijo pequeño: «Datos de demostración · Transbank en ambiente de integración». La tarjeta Visa de prueba pública de Transbank (4051 8856 0044 6623) puede verse.
- Cifras de Mateo (hasta merge + deploy + seed): NO zoom, callout ni mención de voz a su nota, su contador de trabajos ni al «↑ 12 % vs. mes anterior»; NO usar W_22; desenfocar «Ganancias totales», el porcentaje y el chip de nota en W_05b; la ficha «TRABAJADOR» de las capturas web se desenfoca (o se usan las recapturas de C_08/C_16/C_17). Si hace falta un valor, chip ámbar «valores unificados pendientes».
- NO mostrar: la lista «Cuentas demo» (app_03b, W_01), correos o contraseñas reales, el botón «Feedback de la prueba» (A_18/A_18b), el globo «Guía profesional» (W_02), comentarios «(prueba E2E)», el estado crudo «esperando_pago» (A_19), mapas con la marca de agua CARTO «API KEY REQUIRED» (web_e2e_13/14), los mockups de brand/mockups_diseno/, el contrato digital como firma legal (es DEMO, Ley 19.799), reprogramar/reagendar, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, transferencia automática al profesional, push «Nueva solicitud», IA, videollamadas, seguros.
- Tomas de vida real (IA de video) solo para ambientar: nunca generar interfaz con IA. Bloque común: «cinematic, 35mm anamorphic look, shallow depth of field, dark moody interior, warm orange rim light (#FF5E03) and deep navy shadows (#00205B), photorealistic, no text, no logos, no readable screens, no UI». 3–5 s, sin miradas a cámara, personajes consistentes.
- END CARD (3 s quieto para escanear): logo al centro + slogan «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» + «myworksapp-cl.vercel.app» + QR estático a https://myworksapp-cl.vercel.app (pie «Proyecto de título · Duoc UC» opcional, pendiente de decisión de Mathias).
- Entregables por video: 16:9 1080p (y 4K) con subtítulos quemados; 16:9 sin voz con subtítulos (para presentar en vivo); 9:16 con subtítulos quemados; .srt; stems de voz, música y SFX; proyecto fuente (Remotion, /workspace/mwa_video/remotion/).
```

### B.2 Tomas de vida real

| Toma | Prompt | Uso |
|---|---|---|
| BT1 Fuga en el baño | Close-up of water dripping fast from under a bathroom sink pipe onto dark tiles, a bucket placed underneath, comedic plink rhythm. | B1 |
| BT2 Notebook | A man in his 40s sits on a sofa at night and opens a laptop (screen facing away from camera), warm lamp light, the bucket blurred in the background. | B1 → B2 |
| BT3 El timbre | Over-the-shoulder shot of a front door opening to a tradesman with a tool bag, faces out of focus, warm interior light. | B8 |

### B.3 Guion por escenas 16:9 (78 s)

| # | Tiempo | Visual | Locución | Texto en pantalla | Animación | Sonido |
|---|---|---|---|---|---|---|
| **APERTURA** |||||||
| B1 | 0:00–0:04 (4 s) | BT1 → BT2 | «Una fuga, un balde… y un notebook.» (6) | — | Cada gota cae en el beat; push-in al notebook. | Plink rítmico; piano. |
| B2 | 0:04–0:09 (5 s) | `web16x9_01_portada.png` («Profesionales de confianza para tu hogar», «Buscar servicio →», tarjetas «Verificados» y «En vivo») | «Así se pide un profesional desde la web de My Works App.» (11) | **«Guía rápida · Web»** · «Solo para clientes» | El notebook entra en órbita de 12°; las tarjetas flotantes se separan en capas (parallax). | Whoosh grave. |
| B3 | 0:09–0:15 (6 s) | `web16x9_03_login.png` (modal «ACCESO CLIENTES → Iniciar sesión / Crear cuenta») → `web_03_registro.png` | «Paso uno, opcional: entra o crea tu cuenta. También puedes pedir sin registrarte.» (13) | **Paso 1 · Entra (opcional)** · «También sin cuenta» | El modal sube con blur del fondo; sin escribir correos ni contraseñas reales. | Tap. |
| B4 | 0:15–0:22 (7 s) | `web16x9_04_busqueda_mapa.png` («Encuentra profesionales. Reserva con confianza.», «plomería» + mapa) → `web16x9_05_filtro_calificacion.png` («4.5 y más») | «Paso dos: escribe el oficio, mira el mapa y filtra por calificación o disponibilidad.» (14) | **Paso 2 · Busca y filtra** · «Disponible ahora» · «Calificación mínima» | Pines con rebote escalonado; clic en «4.5 y más». Encuadre de tarjetas en **nombre + precio + «Disponible ahora»**, sin nota ni trabajos de Mateo. | Pops; clic. |
| B5 | 0:22–0:29 (7 s) | `web16x9_06_profesional_reserva_rapida.png` (círculo de cobertura, «RESERVA RÁPIDA», «lunes \| 16 de noviembre, 09:00», «$32.000 / visita», «Continuar con la reserva →»; desenfocar el globo del mapa que trae la nota) | «Paso tres: elige al profesional, revisa su cobertura y toma una hora publicada que sigue libre.» (16) | **Paso 3 · Reserva rápida** · «Hasta 12 km sin extra de traslado» | El círculo escala 0→1; los bloques 09:00 / 11:00 / 14:00 / 16:00 / 18:00 se encienden; pulso en el botón. | Whoosh; clic. |
| B6 ★ | 0:29–0:38 (9 s) | Pantalla dividida: izquierda **Con sesión** `web_e2e_09_confirmar_pedido_con_sesion.png` («Confirmar pedido», «El pago queda retenido», botón **«Confirmar pedido · CLP 32.000»**); derecha **Sin sesión** `web16x9_07_checkout_invitado.png` («Pedido sin sesión — Datos para la visita», Turnstile, botón **«Continuar a Webpay · CLP 32.000»**) → inserto [C] `E2E/G_04_crear_clave.png` recortado SOLO al bloque «Crea tu contraseña» (no mostrar «Juana Coll» ni la referencia) | «Paso cuatro: con sesión, confirmas el pedido. Sin sesión, completas los datos de la visita y, al volver pagado, creas tu contraseña.» (22) | **Paso 4 · Confirma** · «Con sesión» / «Sin sesión» · «El pago queda retenido» | Split con máscara de 22 px; cada botón pulsa a su turno; el inserto entra desde el lado invitado. | Clics. |
| B7 ★ | 0:38–0:46 (8 s) | `E2E/A_02_webpay_inicio.png` (Webpay, $32.000) → `web_e2e_11_webpay_tarjeta_prueba.png` (Visa de prueba pública) → `web_e2e_12b_webpay_autorizar.png` → [C] `E2E/A_06_confirmacion_pedido.png` («Pendiente de aceptación»; desenfocar la ficha «TRABAJADOR») → la ficha entra al cofre | «Paso cinco: pagas en Webpay de Transbank. Los treinta y dos mil pesos quedan retenidos en garantía.» (16) | **Paso 5 · Paga en Webpay** · **«Pago RETENIDO»** · chip «Transbank · integración (pruebas)» | Rack focus del formulario al monto; candado del cofre; el cofre queda en la esquina. | Drop musical; candado. |
| B8 | 0:46–0:54 (8 s) | BT3 (1 s) → **recaptura** `E2E/C_08_cliente_en_camino_eta.png` («Llegada 1 min · A 0.5 km. Estimación a 28 km/h, sin tráfico en vivo.», «PIN PARA INICIAR» 7083, «Abrir chat») | «Paso seis: sigue la llegada en el mapa. Cuando toque el timbre, dale el PIN; sin él, no puede iniciar.» (19) | **Paso 6 · Llegada y PIN** · «Estimación a 28 km/h, sin tráfico en vivo» | Zoom a «Llegada»; los 4 dígitos con pop. Sin zoom a la ficha «TRABAJADOR». **No usar `web_e2e_13`** (PIN 3633 y marca CARTO). | Timbre; teclas. |
| B9 ★ | 0:54–1:02 (8 s) | **recaptura** `E2E/C_16_cliente_ve_evidencia.png` («Esperando tu conformidad», evidencia, «Recibo conforme») → **recaptura** `E2E/C_17_cliente_pago_liberado.png` («Pago liberado — Recibiste conforme. El pago retenido quedó liberado.») | «Paso siete: revisa la evidencia y toca "Recibo conforme". Recién ahí se libera el pago, y no es un segundo cargo.» (20) | **Paso 7 · Conformidad** · «No es un segundo cargo» · «Sin respuesta en 48 h y con evidencia: se libera solo» | Clic; el cofre se abre y la ficha se vuelve verde «Liberado». Desenfocar la miniatura de evidencia de prueba. | Clímax; ding + monedas. |
| B10 | 1:02–1:10 (8 s) | «Si algo cambia»: [C] `E2E/C_34_web_cliente_cancelado.png` recortado al bloque «Trabajo anulado — El trabajo se anuló y el cobro retenido no se entregó al profesional.» (**no mostrar la ficha «TRABAJADOR»: dice ★ 5.0 (0 trabajos)**) → `E2E/C_35_disputa_form.png` → `E2E/C_36_disputa_abierta.png` («Disputa abierta. El pago sigue retenido.») | «¿Algo cambió? Si está pendiente, cancelas y vuelve a tu tarjeta. En disputa, el pago sigue retenido.» (17) | **«Si algo cambia»** · «Cancelar: vuelve a tu tarjeta» · «Disputa: el pago sigue retenido» | Dos tarjetas que se voltean como fichas; la ficha del pago queda navy (retenida) en la disputa. | Whoosh; clic. |
| **CIERRE** |||||||
| B11 | 1:10–1:18 (5 s + end card 3 s) | El notebook se cierra hacia el logo → end card | «La calificación la haces en la app. My Works App: pago protegido hasta tu conformidad.» (14) | «Calificación: en la app» → end card (slogan + URL + QR) | El logo se asienta en el beat. | Resolución musical. |

**Locución:** ~176 palabras en 75 s (≈2,3 pal/s; ninguna escena pasa de 2,8).

### B.4 Locución completa

> **[B1]** Una fuga, un balde… y un notebook.
> **[B2]** Así se pide un profesional desde la web de My Works App.
> **[B3]** Paso uno, opcional: entra o crea tu cuenta. También puedes pedir sin registrarte.
> **[B4]** Paso dos: escribe el oficio, mira el mapa y filtra por calificación o disponibilidad.
> **[B5]** Paso tres: elige al profesional, revisa su cobertura y toma una hora publicada que sigue libre.
> **[B6]** Paso cuatro: con sesión, confirmas el pedido. Sin sesión, completas los datos de la visita y, al volver pagado, creas tu contraseña.
> **[B7]** Paso cinco: pagas en Webpay de Transbank. Los treinta y dos mil pesos quedan retenidos en garantía.
> **[B8]** Paso seis: sigue la llegada en el mapa. Cuando toque el timbre, dale el PIN; sin él, no puede iniciar.
> **[B9]** Paso siete: revisa la evidencia y toca «Recibo conforme». Recién ahí se libera el pago, y no es un segundo cargo.
> **[B10]** ¿Algo cambió? Si está pendiente, cancelas y vuelve a tu tarjeta. En disputa, el pago sigue retenido.
> **[B11]** La calificación la haces en la app. My Works App: pago protegido hasta tu conformidad.

### B.5 Corte 9:16 (40 s) — usa las capturas móviles `mob_*`

| # | Tiempo | Visual | Locución | Texto |
|---|---|---|---|---|
| BV1 | 0:00–0:04 | BT1 vertical → `mob_01_portada.png` | «Pide un profesional desde la web.» (6) | «Guía rápida · Web» |
| BV2 | 0:04–0:10 | `mob_04_busqueda_mapa.png` (sin nota ni trabajos) | «Busca y filtra en el mapa.» (6) | Paso 1 · Busca |
| BV3 | 0:10–0:16 | `mob_06_profesional_reserva_rapida.png` | «Elige una hora libre.» (4) | Paso 2 · Reserva |
| BV4 | 0:16–0:22 | `mob_07_checkout_invitado.png` («Continuar a Webpay · CLP 32.000») → cofre | «Incluso sin cuenta: pagas en Webpay y queda retenido.» (9) | Paso 3 · Pago RETENIDO |
| BV5 | 0:22–0:28 | Recorte vertical de la recaptura `E2E/C_08` (Llegada + PIN 7083) | «Al llegar, le das tu PIN.» (5) | Paso 4 · PIN |
| BV6 | 0:28–0:35 | Recorte vertical de la recaptura `E2E/C_17` (toast «Pago liberado») + cofre verde | «"Recibo conforme": recién ahí se libera.» (6) | Paso 5 · Conformidad |
| BV7 | 0:35–0:40 | End card vertical | «My Works App.» (3) | URL + QR |

---

# C · ESCRITORIO (Tauri, consola de administración): «Guía rápida · Consola operativa»

**Duración:** 16:9 de **72 s** (69 s + end card 3 s) · 9:16 de **30 s**. **10 escenas**, 8 pasos.
**Captura real disponible:** solo el login (`desk_01_login_consola.png`, `E2E/S_04_admin_escritorio_login.png`). **Todo lo posterior al doble factor es [R]** con los textos exactos de `flujo_app.md` §4; KPI en «—» y rótulo «Datos de demostración». Texto que no aparezca en `flujo_app.md` no se escribe: esos elementos van como bloques de UI sin etiqueta o desenfocados. Ideal antes del máster: grabar la consola real con una cuenta admin + TOTP (lo hace Mathias, sin mostrar credenciales).

### C.1 Prompt maestro

```
Produce un video tutorial premium de 72 segundos, 16:9, «Guía rápida · Consola operativa de My Works App»: enseña cómo el equipo interno usa la aplicación de escritorio (Tauri; ventana nativa Windows/macOS/Linux) para supervisar la operación: entrar con doble factor, leer el panel ejecutivo, verificar profesionales, mediar disputas y resolver el pago retenido, registrar la liquidación manual al profesional, revisar la seguridad y gestionar al equipo.

ESTRUCTURA
- Apertura (5 s): toma real de un escritorio de operaciones de noche (monitor sin pantalla legible) → la ventana real de login en un monitor 3D, título «Guía rápida · Consola de escritorio».
- 8 pasos: Paso 1 Inicia sesión · Paso 2 Doble factor · Paso 3 Panel ejecutivo · Paso 4 Verifica profesionales · Paso 5 Media disputas · Paso 6 Resuelve el pago retenido y liquida · Paso 7 Seguridad · Paso 8 Equipo (RRHH).
- Cierre: la ventana se reduce a ícono (brand/app_icon_desktop.png) → end card.
- Tono: sobrio, de «sala de control». Cámara más lenta que en los otros videos (dolly de 6–8 % por escena), una sola órbita en la apertura. La barra lateral de la consola actúa como índice: el ítem del paso actual se ilumina en naranja.
- Las pantallas posteriores al doble factor son mockups fieles [R]: estructura de consola oscura (#070B12 → #0B1424, tarjetas #121A2A, DM Sans), SOLO con los textos exactos indicados; todo valor numérico «—»; sello «Interfaz recreada» y rótulo «Datos de demostración». No inventar nombres de botones, cifras ni personas: filas de listas con nombres desenfocados.

ESTILO COMÚN — MY WORKS APP · GUÍAS RÁPIDAS (premium)
- Formato: 16:9 máster 3840×2160, entrega 1920×1080, 30 fps; corte 9:16 1080×1920. MP4 H.264 High, yuv420p, +faststart. Subtítulos QUEMADOS en todas las versiones (DM Sans 600, 44 px en 1080p, blanco #F7F8FA sobre caja #121A2A al 85 %, radio 14 px, máx. 2 líneas, 42 caracteres por línea) + .srt aparte.
- Nivel: premium de festival de motion design, nunca plantilla genérica. Interfaz REAL flotando en un espacio 3D oscuro dentro de dispositivos sin marca (teléfono Android, notebook, monitor), profundidad de campo, luz de borde naranja, reflejos suaves en el vidrio. Cámara virtual: dolly-in lentos, órbitas de 10–15°, rack focus, match cuts (el botón tocado se convierte en la siguiente pantalla) y whip pans cortos con desenfoque naranja entre capítulos. Ease-out cúbico de 250–450 ms; sin rebotes exagerados sobre la interfaz; nada de transiciones tipo PowerPoint; máx. 3 destellos por segundo.
- Marca (valores del código): naranja #FF5E03 (solo CTA y focos, 10 %), naranja vibrante #FF7A18 (gradientes), navy #00205B (confianza / pago retenido, 30 %), canvas oscuro degradado #070B12 → #0B1424 (60 %), superficies #121A2A / #172033, verde éxito #2F9E64, rojo error #E23D35, ámbar pendiente #C9A227, azul info #4C8DDB, texto #F7F8FA / #A8B2C0. Halo radial naranja arriba a la izquierda (glow rgba(255,94,3,0.32)). Regla 60-30-10. Radios 10/14/22 px, botones píldora, íconos lineales tipo Lucide de 2 px.
- Tipografía agregada: DM Sans (títulos 700 con tracking −1 %, cuerpo 500/600). Las capturas no se re-tipografían (la app móvil usa Roboto).
- Logo: «MW» blanco sobre dos rectángulos redondeados, navy adelante-izquierda y naranja atrás-derecha (brand/mark.svg, brand/mark_2048.png). Nombre siempre «My Works App». No redibujarlo ni deformarlo.
- Formato GUÍA: cada paso abre con una etiqueta «Paso N» (píldora naranja #FF5E03, DM Sans 700, texto blanco) + título corto del paso (DM Sans 600, 56 px) en la esquina superior izquierda, y un contador de progreso fino abajo (N de total). Tarjetas de capítulo de 0,8 s (fondo navy #00205B, título DM Sans 700). Callouts: línea naranja de 2 px + etiqueta DM Sans 600 sobre caja #121A2A al 90 %, radio 14 px; máx. 2 a la vez, ~7 palabras, sincronizados con la voz. Toques = anillo sutil que se expande. Legibilidad: plano general de 0,5–1 s y luego zoom al elemento que nombra la voz (texto a leer ≥ 28 px en 1080p); el resto se oscurece al 40 %.
- Divertido de ver pero fiel: el humor vive en las tomas de vida real y en el ritmo (beats musicales en cada «Paso»), nunca alterando la interfaz. Sin frases de vendedor ni promesas no medidas («en segundos», «la mejor app»). Sin cifras de negocio.
- Voz: presentador/a chileno/a neutro-profesional de 30–45 años, cálido, claro, ritmo de tutorial (2,0–2,4 palabras/s). Trata al espectador de «tú». Pronunciación: My Works App /mái uórks ap/, Webpay /uébpei/, Transbank /tránsbank/. Un WAV por escena, 48 kHz / 24 bit, 0,3 s de aire. Recomendado locutor humano; TTS solo como guía de tiempos.
- Música y sonido: score cinematográfico-electrónico 100–115 BPM con licencia comercial guardada; un acento suave en cada «Paso N»; SFX discretos (taps, whoosh, candado del pago retenido, ding de éxito). Ducking −12 dB bajo la voz. Mezcla −14 LUFS (web) / −16 LUFS (sala), picos ≤ −1 dBTP.
- PRECISIÓN (obligatoria): solo pantallas reales de screens/ y e2e_live_2026-11-15/ (se pueden recortar, ampliar, separar en capas o desenfocar, sin alterar textos, montos ni estados). Lo que no tiene captura se recrea [R] con los textos exactos de flujo_app.md y KPI en «—» o «Datos de demostración». Datos de demostración (Puerto Montt): cliente «Andrés P.», profesional «Mateo Oyarzo · Gasfíter», servicio «Reparación de fuga de agua y cambio de llaves o grifería», $32.000 por visita. Rótulo fijo pequeño: «Datos de demostración · Transbank en ambiente de integración». La tarjeta Visa de prueba pública de Transbank (4051 8856 0044 6623) puede verse.
- Cifras de Mateo (hasta merge + deploy + seed): NO zoom, callout ni mención de voz a su nota, su contador de trabajos ni al «↑ 12 % vs. mes anterior»; NO usar W_22; desenfocar «Ganancias totales», el porcentaje y el chip de nota en W_05b; la ficha «TRABAJADOR» de las capturas web se desenfoca (o se usan las recapturas de C_08/C_16/C_17). Si hace falta un valor, chip ámbar «valores unificados pendientes».
- NO mostrar: la lista «Cuentas demo» (app_03b, W_01), correos o contraseñas reales, el botón «Feedback de la prueba» (A_18/A_18b), el globo «Guía profesional» (W_02), comentarios «(prueba E2E)», el estado crudo «esperando_pago» (A_19), mapas con la marca de agua CARTO «API KEY REQUIRED» (web_e2e_13/14), los mockups de brand/mockups_diseno/, el contrato digital como firma legal (es DEMO, Ley 19.799), reprogramar/reagendar, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, transferencia automática al profesional, push «Nueva solicitud», IA, videollamadas, seguros.
- Tomas de vida real (IA de video) solo para ambientar: nunca generar interfaz con IA. Bloque común: «cinematic, 35mm anamorphic look, shallow depth of field, dark moody interior, warm orange rim light (#FF5E03) and deep navy shadows (#00205B), photorealistic, no text, no logos, no readable screens, no UI». 3–5 s, sin miradas a cámara, personajes consistentes.
- END CARD (3 s quieto para escanear): logo al centro + slogan «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» + «myworksapp-cl.vercel.app» + QR estático a https://myworksapp-cl.vercel.app (pie «Proyecto de título · Duoc UC» opcional, pendiente de decisión de Mathias).
- Entregables por video: 16:9 1080p (y 4K) con subtítulos quemados; 16:9 sin voz con subtítulos (para presentar en vivo); 9:16 con subtítulos quemados; .srt; stems de voz, música y SFX; proyecto fuente (Remotion, /workspace/mwa_video/remotion/).
```

### C.2 Tomas de vida real

| Toma | Prompt | Uso |
|---|---|---|
| CT1 Sala de control | Slow dolly toward a minimal desk at night with a single large monitor glowing orange and navy (screen not readable), a coffee cup, a hand reaching for the mouse; calm, focused mood. | C1 |
| CT2 Autenticador | Close-up of a hand holding a smartphone next to a keyboard (screen facing away), the person glances at it and types; shallow depth of field. | C3 |

### C.3 Guion por escenas 16:9 (72 s)

| # | Tiempo | Visual | Locución | Texto en pantalla | Animación | Sonido |
|---|---|---|---|---|---|---|
| **APERTURA** |||||||
| C1 | 0:00–0:05 (5 s) | CT1 → monitor 3D con `desk_01_login_consola.png` («Consola operativa — Supervisa. Gestiona. Resuelve.») | «Detrás de cada pedido hay un equipo. Esta es su consola.» (11) | **«Guía rápida · Consola de escritorio»** · «Windows · macOS · Linux» | Órbita única de 15° alrededor del monitor; el glow respira. | Pad grave; whoosh. |
| C2 | 0:05–0:11 (6 s) | `E2E/S_04_admin_escritorio_login.png` («Inicia sesión para continuar», «Entrar», «Conexión cifrada TLS 1.3 · Acceso solo con rol administrador · Sesión protegida») — campos con su placeholder, sin escribir credenciales | «Paso uno: inicia sesión. Solo entra quien tiene rol de administrador.» (11) | **Paso 1 · Inicia sesión** · «Acceso solo con rol administrador» | Zoom a la franja «Seguridad empresarial»; pulso en «Entrar». | Tap. |
| C3 [R] | 0:11–0:18 (7 s) | CT2 (1,5 s) → **[R]** pantalla «Confirma que eres el administrador» con campo de código de 6 dígitos (casilleros vacíos que se llenan con puntos, nunca dígitos reales) e indicación de app autenticadora; la primera vez, QR genérico **desenfocado** | «Paso dos: confirma con el código de tu app autenticadora. Sin el segundo factor, no hay consola.» (16) | **Paso 2 · Doble factor** · «Confirma que eres el administrador» · «Obligatorio para administradores» | Los casilleros se llenan uno a uno; candado navy se cierra → check verde. | Teclas; candado. |
| C4 [R] | 0:18–0:27 (9 s) | **[R] Panel ejecutivo**: tarjetas «GMV», «Comisión (5 % por pago)», «Ticket promedio», «CSAT», «Trabajos completados», «Trabajos activos», «Disputas abiertas» (todas «—»); selector «24 horas · 7 días · 30 días · 90 días»; bloques «Pagos en custodia» y «Cobros que requieren atención» | «Paso tres: el panel ejecutivo resume la operación por período: ventas, comisión, satisfacción, trabajos y disputas.» (16) | **Paso 3 · Panel ejecutivo** · «Datos de demostración» | Las tarjetas entran escalonadas (120 ms); clic que alterna 7 días → 30 días (los «—» no cambian). | Ticks suaves. |
| C5 [R] | 0:27–0:35 (8 s) | **[R] Trabajadores**: lista con nombres desenfocados; una fila con estado «En revisión» y botones **«Aprobar»** / **«Rechazar»**; leyenda de estados Pendiente / En revisión / Verificado / Rechazado | «Paso cuatro: revisa a los profesionales en revisión y apruébalos o recházalos. Sin verificación, no pueden cobrar.» (17) | **Paso 4 · Verifica profesionales** · «Sin verificación no se cobra» | Zoom a la fila; clic en «Aprobar» → el chip pasa a «Verificado» (verde). | Clic; ding. |
| C6 [R parcial] | 0:35–0:44 (9 s) | Inserto real 1,5 s: recorte de `E2E/C_36_disputa_abierta.png` («Disputa abierta. El pago sigue retenido.») en una tarjeta flotante → **[R] «Centro de Mediación»**: ticket con expediente y evidencia (miniaturas desenfocadas) | «Paso cinco: cuando un cliente abre una disputa, llega al Centro de Mediación con su expediente y la evidencia.» (18) | **Paso 5 · Media disputas** · «El pago sigue retenido» | La tarjeta real «vuela» desde la web hacia la bandeja del Centro de Mediación (match cut). | Whoosh; notificación suave. |
| C7 [R] | 0:44–0:52 (8 s) | **[R] «Resolución del pago retenido»** con dos opciones: liberar al profesional / devolver a la tarjeta → **[R] «Liquidación manual»** (modal; montos «—») | «Paso seis: resuelve el pago retenido, al profesional o de vuelta a la tarjeta, y registra la liquidación manual.» (18) | **Paso 6 · Resuelve y liquida** · «Liberado ≠ transferido» | La ficha naranja sale del cofre hacia una de las dos rutas; luego un sello «Liquidación manual». | Candado se abre; monedas suaves. |
| C8 [R] | 0:52–0:58 (6 s) | **[R] Seguridad (DevSecOps)**: salud del sistema, latencia de Supabase («— ms»), controles de calidad de GitHub Actions (íconos de check sin cifras) | «Paso siete: vigila la salud del sistema y los controles de calidad.» (11) | **Paso 7 · Seguridad** | Línea de latencia plana dibujándose (sin valores). | Pulso grave. |
| C9 [R] | 0:58–1:04 (6 s) | **[R] RRHH**: «Directorio de empleados» (nombres desenfocados), botón **«Invitar colaborador»**, chips de rol «soporte» / «QA» | «Paso ocho: invita a tu equipo de soporte o QA, cada uno con su rol.» (14) | **Paso 8 · Equipo** · «Roles: soporte · QA» | Clic en «Invitar colaborador»; aparece un chip de rol. | Tap. |
| **CIERRE** |||||||
| C10 | 1:04–1:12 (5 s + end card 3 s) | La ventana se minimiza al ícono `brand/app_icon_desktop.png` → logo → end card | «Supervisa, gestiona, resuelve. My Works App.» (6) | End card (slogan + URL + QR) | El ícono se transforma en el logo en el beat. | Resolución musical. |

**Locución:** ~138 palabras en 69 s (≈2,0 pal/s; ritmo pausado de consola).
**No mostrar en la consola:** el contrato digital (`DigitalContractModal`, DEMO), cifras reales del GMV ni nombres reales de personas.

### C.4 Locución completa

> **[C1]** Detrás de cada pedido hay un equipo. Esta es su consola.
> **[C2]** Paso uno: inicia sesión. Solo entra quien tiene rol de administrador.
> **[C3]** Paso dos: confirma con el código de tu app autenticadora. Sin el segundo factor, no hay consola.
> **[C4]** Paso tres: el panel ejecutivo resume la operación por período: ventas, comisión, satisfacción, trabajos y disputas.
> **[C5]** Paso cuatro: revisa a los profesionales en revisión y apruébalos o recházalos. Sin verificación, no pueden cobrar.
> **[C6]** Paso cinco: cuando un cliente abre una disputa, llega al Centro de Mediación con su expediente y la evidencia.
> **[C7]** Paso seis: resuelve el pago retenido, al profesional o de vuelta a la tarjeta, y registra la liquidación manual.
> **[C8]** Paso siete: vigila la salud del sistema y los controles de calidad.
> **[C9]** Paso ocho: invita a tu equipo de soporte o QA, cada uno con su rol.
> **[C10]** Supervisa, gestiona, resuelve. My Works App.

### C.5 Corte 9:16 (30 s)

| # | Tiempo | Visual | Locución | Texto |
|---|---|---|---|---|
| CV1 | 0:00–0:05 | Recorte vertical de `desk_01_login_consola.png` (bloque «Consola operativa») | «La consola de My Works App.» (5) | «Guía rápida · Escritorio» |
| CV2 | 0:05–0:10 | [R] «Confirma que eres el administrador» | «Entras con doble factor.» (4) | Paso 1 · Doble factor |
| CV3 | 0:10–0:16 | [R] Trabajadores «Aprobar / Rechazar» | «Verificas a los profesionales.» (4) | Paso 2 · Verifica |
| CV4 | 0:16–0:22 | Recorte real `E2E/C_36` → [R] «Centro de Mediación» | «Medias disputas con el pago retenido.» (6) | Paso 3 · Disputas |
| CV5 | 0:22–0:26 | [R] «Liquidación manual» | «Y registras la liquidación.» (4) | Paso 4 · Liquida |
| CV6 | 0:26–0:30 | End card vertical | «My Works App.» (3) | URL + QR |

---

## D. Capturas que faltan (hoy se recrean [R]) y cómo cerrarlas

| Plataforma | Pantalla sin captura real | Dónde se usa | Cómo obtenerla |
|---|---|---|---|
| App · cliente | Lista de profesionales («Búsqueda Inteligente / Lista Manual») con tarjetas | A4 (overlay) | Emulador Android con cuenta demo de cliente. |
| App · cliente | «Perfil del trabajador» y «Agendar visita» | A5 | Ídem. |
| App · cliente | Hoja «Pago Webpay — Confirmar pedido — Primera confirmación…» y «Pago retenido en garantía» | A6 | Ídem, en Transbank integración. |
| App · cliente | Tarjeta «PIN para iniciar» + «Ubicación en vivo» | A7 | Pedido de demo en estado Aceptado / En camino (**escribe en producción: requiere OK de Mathias**). |
| App · cliente | «Segunda confirmación: recibo conforme» → «Liberar fondos» | A8 | Pedido en Pendiente de aprobación (ídem, requiere OK). |
| App · profesional | «Completa tu perfil», verificación «Enviar a revisión», «Guardar tarifas», «Guardar horario» | A10 | Cuenta Especialista de prueba nueva (crea datos: requiere OK). |
| App · profesional | «Mis cobros / Liquidaciones» | A16 | Cuenta demo de Mateo (sin escribir). |
| Web | Recapturas `C_08`, `C_16`, `C_17` (ficha sin «0 trabajos») | B8, B9 | Bloqueado: falta `/workspace/mwa_post55/e2e/.demo_pw` y el pedido `7e70bdcd` ya está completado → hay que crear y pagar un pedido nuevo en producción (requiere OK de Mathias). Mientras tanto: capturas del 15-nov con la ficha «TRABAJADOR» desenfocada. |
| Web | Botón para cancelar (solo hay el resultado `C_34`) | B10 | Se muestra solo el resultado; opcional capturar el diálogo. |
| Web | Reagendar | — | **No se muestra**: `flujo_app.md` §2.7 dice que no existe. Si ya existe (CU-33 según el Programador), actualizar `flujo_app.md` y capturar antes de agregarlo. |
| Escritorio | Todo después del login: MFA, Panel ejecutivo, Trabajadores, Centro de Mediación, Resolución del pago retenido, Liquidación manual, DevSecOps, RRHH | C3–C9 | Grabar con cuenta admin + TOTP (Mathias), con datos de demo y sin credenciales a la vista. |

**Cifras de Mateo:** siguen bajo la regla (no zoom, no W_22, desenfocar W_05b). Hay inconsistencia viva: `W_05b` y `A_06` muestran ★ 4.9 (8 trabajos); `C_34` y un log local muestran ★ 5.0 (0 o 9 trabajos). El valor objetivo tras el seed es ★ 4.9; se levanta la regla cuando Mathias confirme merge + deploy + seed.

## E. Herramientas y flujo

Igual que el brief v2.1 (§7): animatic en Figma/Canva → aprobación de Mathias → locución → **Remotion** (`/workspace/mwa_video/remotion/`; un mismo proyecto renderiza 16:9 y 9:16, con composiciones `GuiaApp`, `GuiaWeb`, `GuiaEscritorio`) + tomas de **Higgsfield** → música/SFX/mezcla → subtítulos (**Descript**) → grade (**DaVinci Resolve**) → QA cuadro a cuadro contra `flujo_app.md` → entrega. **Antes del render final: liberar disco en el box.**
