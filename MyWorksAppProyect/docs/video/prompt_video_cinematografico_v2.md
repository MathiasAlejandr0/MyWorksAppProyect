# My Works App: prompt de video cinematográfico v2. Un *speech* que presenta la app

> **Documento histórico.** Registra el estado del proyecto a la fecha de su última revisión (16-11-2026) y no se actualiza. Las cifras, URL y pantallas que nombra pueden haber cambiado. El estado vigente de la fase 3 (22-11-2026, 23:07 hora de Chile) está en [`ESTADO_DEL_PROYECTO.md`](../../ESTADO_DEL_PROYECTO.md).

> **Slogan oficial (Presentación final Capstone, 2026-11-15):** «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» — fuente `/workspace/mwa_video/Presentacion-final-MyWorksApp.pptx` slide 1 / Drive `1h3cdLBsipJknBam4FXpeHM8qLcpNOH6R`. Reemplaza el lema de la web en el end card.
**Para:** el diseñador gráfico / motion designer
**Versión:** v2.1 · 15-nov-2026, 22:00 (hora de Chile). **Es el brief vigente** y reemplaza a `prompt_video_cinematografico.md`, `prompt_video_v2.md` y `prompt_video.md`. Índice de archivos: `LEEME.md`.
**Formato:** 16:9 de **~123 s** (versión principal) y 9:16 de **45 s** (versión corta)
**Fuentes de verdad:** `flujo_app.md` y las capturas de `screens/` y `e2e_live_2026-11-15/` (en este documento, `E2E/`). Si una captura y `flujo_app.md` no coinciden, **manda la captura que se ve en pantalla**, y la diferencia se avisa (sección 6). Lo que no aparece en esas fuentes **no va en el video**.

### Estado al 15-nov-2026, 22:00 (léelo primero)

| Tema | Estado | Qué hace el diseñador |
|---|---|---|
| **Uso del video** | *Speech* profesional que presenta My Works App; coherente y divertido de ver; muestra cómo pedir un trabajador y el flujo completo, del cliente al profesional y al cierre (pago retenido → liberado). | Seguir este brief. |
| **CTA** | **Confirmado:** `myworksapp-cl.vercel.app`, verificado: responde 200. | End card con la URL + QR a https://myworksapp-cl.vercel.app |
| **Botón de pago** | **Confirmado:** con sesión «Confirmar pedido · CLP 32.000»; invitado «Continuar a Webpay · CLP 32.000». | Usar las capturas tal cual. |
| **«0 trabajos» en el seguimiento web** | **Ya corregido en producción** (commit `0fd5f44`: el seguimiento lee los trabajos completados reales y muestra «Nuevo» si la nota es 0). | **Recapturar `C_08`, `C_16` y `C_17`** desde producción con el mismo pedido de demostración (Andrés / Mateo, $32.000) y reemplazar las versiones del 15-nov. |
| **Nota de Mateo (4.9 vs 5.0) y contador de trabajos** | **PR pendiente** (seed de demostración con reseñas reales → nota 4.9 y un contador coherente en todas las pantallas). Falta merge + deploy + correr el seed. | Hasta entonces: **no hacer zoom ni callouts** a la nota ni a los trabajos de Mateo, y **no usar `W_22`** (muestra 5.0). |
| **«↑ 12 % vs. mes anterior»** (panel del profesional) | **Era un número fijo** en el código (`growthPercent = 12`). Va en el mismo PR (crecimiento real, o la línea oculta si no hay datos). | **No hacer zoom** a «Ganancias totales» ni al porcentaje; desenfocarlo en `W_05b`. |

Cuando Mathias avise «merge + deploy + seed listos», se recapturan el panel del profesional y la búsqueda, y se levanta la restricción (sección 5).

---

## 0. Qué es este video (léelo antes que todo)

- **Es un *speech*, no un comercial de marketing.** Una voz de presentador le habla a una audiencia (una comisión de auditoría o un público en sala) y le **presenta** My Works App contando **una sola historia de principio a fin**: Andrés tiene una llave que gotea, pide un gasfíter por la app, Mateo hace el trabajo y el pago se libera recién cuando Andrés queda conforme.
- **Coherente:** es un único pedido, en orden cronológico real (los estados de la app), con los mismos personajes, el mismo servicio y el mismo monto de principio a fin. Nada de pantallas sueltas «porque se ven bonitas».
- **Entretenido de ver:** la historia tiene un personaje secundario con humor (la **gota**), capítulos con título como en una charla, pantalla dividida «mientras tanto…», una ficha naranja que representa el pago y una barra de estados que avanza como un marcador. El humor vive **en la historia y en las tomas de vida real**; sobre la interfaz, la interfaz manda.
- **Cinematográfico:** tomas reales oscuras y cálidas, luz de borde naranja, cámara virtual con profundidad, música con arco dramático. Elegante, no ruidoso.
- **No es publicidad:** sin frases de vendedor («¡la mejor app!», «¡descárgala ya!»), sin promesas no medidas («en segundos») y sin cifras de negocio. Se explica **cómo funciona**, con la seguridad de quien lo construyó.

---

## 1. PROMPT MAESTRO (pegable)

> **Uso:** pégalo tal cual en el brief del diseñador o en un agente que arme el proyecto en Remotion. En los generadores de video con IA (Higgsfield, Veo, Kling, Runway) **no** pegues este prompt: inventan interfaces. Ahí usa solo los prompts de tomas de la sección 1.2.

### 1.1 Prompt maestro

```
Produce un video cinematográfico de ~123 segundos, 16:9 (máster 3840×2160, entrega 1920×1080, 30 fps), que funcione como un SPEECH profesional que presenta «My Works App»: un marketplace chileno de servicios para el hogar (gasfitería, electricidad, armado, limpieza, pintura, jardinería, cerrajería y más). Su idea central: «El pago queda retenido hasta que el cliente da la conformidad».

FORMATO Y TONO
- Una voz de presentador, cálida, segura y con humor sutil, le habla a una audiencia (comisión de auditoría o público en sala) en español de Chile neutro-profesional. Trata a la audiencia de «ustedes» y cuenta en tercera persona la historia de Andrés (cliente) y Mateo (gasfíter). Suena a charla bien preparada, no a comercial: nada de frases de vendedor, nada de promesas no medidas.
- La historia es UNA: la llave de Andrés gotea → pide un gasfíter en My Works App → paga y el pago queda retenido → Mateo acepta, va en camino, pide el PIN, repara y sube la evidencia → Andrés da la conformidad y el pago se libera → se califican → detrás, el equipo supervisa en una consola. Todo en el orden real de estados de la app: Pendiente → Aceptado → En camino → En Curso → Pendiente de aprobación → Completado.
- Entretenido de ver: (1) la GOTA es un personaje recurrente (cae al ritmo de la música, se agranda cuando hay dudas y en la escena de la reparación «se rinde»); (2) tarjetas de capítulo como en una charla: «Capítulo 1 · Pedir», «Capítulo 2 · El trabajo», «Capítulo 3 · El cierre»; (3) pantalla dividida «Mientras tanto…» entre el teléfono de Andrés y el de Mateo; (4) una ficha naranja que representa el pago: entra a un cofre navy con candado al pagar, espera en una esquina durante el trabajo y, con «Recibo conforme», se vuelve verde con la etiqueta «Liberado» (NO vuela al bolsillo de Mateo: la transferencia la registra un administrador); (5) una barra de estados que avanza como un marcador.

ESTILO VISUAL
- Dos capas: (a) tomas cinematográficas de vida real (macro de la gota, manos, la puerta, el gasfíter con herramientas), oscuras y cálidas, sin texto ni pantallas legibles; (b) la interfaz REAL de la app flotando en un espacio 3D oscuro, en dispositivos genéricos sin marca (teléfono Android, notebook, monitor), con profundidad de campo y luz de borde naranja.
- Fondo: degradado #070B12 → #0B1424, halo radial naranja suave arriba a la izquierda (glow rgba(255,94,3,0.32)).
- Paleta 60-30-10 (la regla del código de la app): 60 % canvas oscuro; 30 % navy #00205B y superficies #121A2A / #172033; 10 % naranja #FF5E03 (degradado a #FF7A18), usado solo en llamados a la acción, focos y la ficha del pago. Verde #2F9E64 = verificado o liberado; rojo #E23D35 = error; ámbar #C9A227 = pendiente; texto #F7F8FA / #A8B2C0.
- Tipografía agregada: DM Sans (títulos 700, tracking −1 %; cuerpo 500/600). Las capturas no se re-tipografían (la app móvil usa Roboto).
- Logo: «MW» blanco sobre dos rectángulos redondeados, navy adelante-izquierda y naranja atrás-derecha (mark.svg). Nombre siempre «My Works App». No redibujarlo ni deformarlo.
- Radios de 10/14/22 px, botones píldora, íconos lineales tipo Lucide de 2 px. Grano fílmico leve (2–3 %) solo en las tomas de vida real, nunca sobre la interfaz.

CÁMARA Y MOTION
- Dolly-in lentos, órbitas de 10–15° alrededor de los dispositivos, rack focus, match cuts (el botón de una pantalla se convierte en la siguiente) y whip pans cortos con desenfoque naranja entre capítulos.
- Legibilidad: plano general de 0,5–1 s y luego zoom al elemento que nombra la voz. El texto de la interfaz que se quiere leer mide ≥ 28 px en 1080p. El resto se oscurece al 40 %, sin flechas encima.
- Callouts: línea naranja de 2 px + etiqueta DM Sans 600 sobre caja #121A2A al 90 %, radio 14 px. Máximo 2 a la vez y ~7 palabras cada uno, sincronizados con la voz.
- Barra de estados persistente desde que Mateo acepta: Pendiente · Aceptado · En camino · En Curso · Pendiente de aprobación · Completado (lo hecho en verde con ✓, el actual en naranja pulsando, lo futuro en gris; siempre texto + ícono).
- Ease-out cúbico de 250–450 ms, sin rebotes exagerados en la interfaz. Toques con un anillo sutil. Nada de transiciones tipo PowerPoint. Máximo 3 destellos por segundo.

MÚSICA Y SONIDO
- Score instrumental cinematográfico-electrónico de 100–115 BPM: piano + sub-bass minimalista al inicio, pulso que crece por capítulo, drop suave en el pago, build durante la reparación, clímax cálido en «Recibo conforme» y resolución limpia en el logo. Con licencia comercial y comprobante guardado.
- La gota marca el tempo en el arranque. SFX: clic metálico del candado, teclas del PIN, buzz corto en el error, «ding» cálido y monedas suaves en la liberación, whooshes discretos. Ducking de −12 dB bajo la voz. Mezcla a −16 LUFS (sala) y −14 LUFS (web), picos ≤ −1 dBTP.

PRECISIÓN (obligatoria)
- Solo pantallas reales de screens/ y e2e_live_2026-11-15/. Se pueden recortar, ampliar, separar en capas o desenfocar, pero sin alterar textos, montos ni estados.
- Datos de demostración (Puerto Montt): cliente «Andrés P.», profesional «Mateo Oyarzo» (gasfíter), servicio «Reparación de fuga de agua y cambio de llaves o grifería», $32.000 por visita. Rótulo pequeño fijo: «Datos de demostración · Transbank en ambiente de integración».
- Botón de pago: con sesión «Confirmar pedido · CLP 32.000»; como invitado «Continuar a Webpay · CLP 32.000».
- Cifras de Mateo: el «0 trabajos» del seguimiento web ya está corregido en producción → usar las recapturas nuevas de C_08, C_16 y C_17. La nota (4.9 vs 5.0), el contador de trabajos y el «↑ 12 % vs. mes anterior» del panel siguen pendientes de un PR (merge + deploy + seed): NO hacer zoom, callout ni mención de voz sobre ellos, NO usar W_22, y desenfocar las ganancias y el porcentaje en W_05b. Si una escena los necesita, usar un chip placeholder «valores unificados pendientes».
- No mostrar: reprogramar pedidos, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, pago instantáneo al profesional, notificación push «Nueva solicitud», IA, videollamadas, seguros, contrato con validez legal, cifras de negocio inventadas, la lista «Cuentas demo», correos, contraseñas ni los mockups de brand/mockups_diseno/.

CIERRE / CTA: logo + lema real de la web «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» + URL «myworksapp-cl.vercel.app» con un QR a https://myworksapp-cl.vercel.app.

ENTREGABLES: MP4 H.264 16:9 1080p (y 4K), yuv420p, +faststart; 9:16 1080×1920 de 45 s con subtítulos quemados; versión 16:9 con subtítulos quemados (para sala) y versión sin voz; .srt; stems de voz, música y SFX; proyecto fuente.
```

### 1.2 Prompts de tomas de vida real (solo para IA de video: Higgsfield, Veo, Kling o Runway)

Bloque común que se agrega a cada toma: *«cinematic, 35mm anamorphic look, shallow depth of field, dark moody interior, warm orange rim light (#FF5E03) and deep navy shadows (#00205B), photorealistic, no text, no logos, no readable screens, no UI»*. Tomas de 3–5 s, sin miradas a cámara. Usar una referencia de personaje para que Andrés y Mateo sean consistentes.

| Toma | Prompt | Uso |
|---|---|---|
| T1 Gota | Extreme macro slow motion of a single water drop falling from a chrome kitchen faucet into a dark sink at night, the droplet catches an orange highlight. | Esc. 1 (frame 1) |
| T2 Gota insistente | Same faucet, three drops falling in rhythm, a small puddle forming, a kitchen towel thrown over the sink edge in mild frustration, slightly comedic timing. | Esc. 1–2 |
| T3 Andrés duda | Close-up of a man in his 30s at a kitchen counter at night holding a smartphone (screen facing away from camera), glancing at the dripping faucet, hesitant thumb. | Esc. 2 |
| T4 Ficha al cofre | Abstract 3D: a glowing orange coin slowly drops into a matte navy vault box that closes with a soft metallic lock, black studio background, volumetric light. | Esc. 3 y 8 (o hecho en Remotion/3D) |
| T5 En camino | Tracking shot from behind of a tradesman with a tool bag walking to a house door on a quiet residential street at golden hour, face not visible. | Esc. 10 |
| T6 La puerta | Over-the-shoulder shot: a front door opens, the tradesman stands outside, warm interior light spills out, faces out of focus. | Esc. 11 |
| T7 La gota se rinde | Close-up of hands with a wrench tightening a new chrome faucet; the last drop hangs, wobbles and does not fall; satisfying, slightly comedic beat. | Esc. 12 |
| T8 Silencio | Clean, dry kitchen faucet, a hand turns it on and off smoothly, warm calm light. | Esc. 13 / cierre |

⚠️ Revisar manos, herramientas y caras. Si un teléfono muestra algo legible, se descarta la toma.

---

## 2. Guion por escenas: versión principal 16:9 (~123 s)

Las rutas sin prefijo están en `screens/` y las rutas `E2E/…` en `e2e_live_2026-11-15/`. «pal/s» = palabras de la locución por segundo de escena (objetivo de 2,0–2,4).

| # | Tiempo | Visual (captura real / toma) | Locución (speech) | Texto en pantalla | Animación / transición | Sonido |
|---|---|---|---|---|---|---|
| **APERTURA** |||||||
| 1 | 0:00–0:06 (6 s) | T1 → T2. La gota cae desde el frame 1, en movimiento. | «Esta es la cocina de Andrés. Y esa gota no piensa detenerse.» (11 pal · 1,8) | — | Sin fundido desde negro. Cada gota cae en el beat; con la tercera, la cámara hace un push-in. | Gotas en el tempo; piano + sub-bass. |
| 2 | 0:06–0:13 (7 s) | T3: Andrés con el teléfono, la gota detrás. | «Andrés necesita un gasfíter, pero tiene una duda muy razonable: ¿pagar antes de ver el trabajo terminado?» (17 pal · 2,4) | «¿Pagar antes de verlo terminado?» | Rack focus del teléfono a la gota, que se agranda (gag). | Una gota más fuerte en «terminado». |
| 3 | 0:13–0:21 (8 s) | T4: la ficha naranja cae al cofre navy y se cierra; el cofre se desarma en los dos rectángulos del logo → `brand/mark_2048.png` + «My Works App». | «Les presento My Works App: el pago queda retenido hasta que el cliente da la conformidad.» (16 pal · 2,0) | «Pago retenido hasta la conformidad» → «My Works App» | Ensamble del logo con overshoot suave; el glow respira una vez. | Clic del candado; whoosh grave. |
| 4 | 0:21–0:27 (6 s) | Tres dispositivos en órbita: teléfono `app_02_bienvenida.png`, notebook `web16x9_01_portada.png`, monitor `desk_01_login_consola.png`. | «Tres piezas: app para clientes y profesionales, web para clientes y consola de administración.» (13 pal · 2,2) | «App móvil · clientes y profesionales» · «Web · solo clientes» · «Escritorio · administración» | Entrada escalonada de 120 ms; líneas finas hacia dos chips: «Supabase» y «Transbank Webpay». | 3 whooshes suaves. |
| **CAPÍTULO 1 · PEDIR** (tarjeta de 0,8 s, dentro de la escena 5) |||||||
| 5 | 0:27–0:33 (6 s) | Teléfono: `E2E/S_05_app_registro.png` («Crea tu cuenta», **Cliente** seleccionado). Inserto de 1,5 s en el notebook: `web16x9_07_checkout_invitado.png` («Pedido sin sesión · Datos para la visita»). | «Andrés crea su cuenta como cliente. También podría pedir desde la web, sin registrarse.» (14 pal · 2,3) | «Cliente: busco servicios profesionales» · «Web: pedido sin sesión» | Zoom al selector Cliente / Especialista; «Registrarse» hace match cut al notebook. | Tap; whoosh. |
| 6 | 0:33–0:41 (8 s) | Notebook: `web16x9_04_busqueda_mapa.png` («Resultados para "plomería"» + mapa de Puerto Montt) → `web16x9_05_filtro_calificacion.png`. | «Escribe "plomería" y el mapa le muestra profesionales cercanos, con su nota y el precio de la visita.» (18 pal · 2,3) | «Desde $32.000 / visita» · «Filtro: 4.5 y más» | Pines con rebote escalonado; clic en «4.5 y más». Zoom a la tarjeta de Mateo encuadrado en **nombre + precio + «Disponible ahora»**, sin la nota ni los trabajos (ver la regla de cifras). | Pops en los pines; clic. |
| 7 | 0:41–0:48 (7 s) | `web16x9_06_profesional_reserva_rapida.png`: círculo de cobertura + barra «RESERVA RÁPIDA». | «Elige a Mateo, revisa su cobertura y toma una hora publicada que sigue libre.» (14 pal · 2,0) | «Hasta 12 km sin extra de traslado» · «Solo horas publicadas y libres» | El círculo escala 0→1; zoom al selector «lunes \| 16 de noviembre, 09:00»; pulso en «Continuar con la reserva →». El globo del mapa se desenfoca (trae cifras). | Whoosh del círculo; clic. |
| 8 ★ | 0:48–1:00 (12 s) | `E2E/A_01_checkout_resumen.png` («Confirmar pedido · 32.000 CLP», «El pago queda retenido», botón **«Confirmar pedido · CLP 32.000»**) → `E2E/A_02_webpay_inicio.png` (Webpay, $32.000) → `web_e2e_11_webpay_tarjeta_prueba.png` (1 s) → la ficha entra al cofre. | «Paga en Webpay de Transbank. La app no pide ni guarda la tarjeta, y los treinta y dos mil pesos quedan retenidos en garantía.» (24 pal · 2,0) | «Pago en Transbank Webpay» · **«Pago RETENIDO»** · chip fijo «Transbank · ambiente de integración (pruebas)» | Rack focus al recuadro «El pago queda retenido»; se presiona el botón; la ficha entra al cofre, se cierra el candado y el cofre queda en miniatura en la esquina hasta la escena 13. | **Drop musical**; clic del candado. |
| **CAPÍTULO 2 · EL TRABAJO** |||||||
| 9 | 1:00–1:09 (9 s) | Whip pan → «Mientras tanto…»: teléfono de Mateo, `E2E/W_05b_panel_ocupado.png` («¡Hola de nuevo, Mateo!»; desenfocar las tarjetas de nota y ganancias) → `E2E/W_04_pro_detalle_pendiente.png` («Aceptar Trabajo» / «Rechazar» + «Reputación como cliente») → `E2E/W_05a_tras_aceptar.png`. Aparece la barra de estados. | «Del otro lado, Mateo ve el pedido y la reputación de Andrés. Acepta. Si rechazara, el pago volvería a la tarjeta.» (20 pal · 2,2) | «Mientras tanto…» · «Si rechaza: reembolso a la tarjeta» | Zoom a «Reputación como cliente»; el dedo toca «Aceptar Trabajo»; la barra pasa a **Aceptado**. | Tap; ding corto. |
| 10 | 1:09–1:16 (7 s) | T5 (1,5 s) → pantalla dividida: `E2E/W_07a_tras_en_camino.png` («En camino», «Ubicación compartida con el cliente de este pedido.») + `E2E/C_08_cliente_en_camino_eta.png` («Llegada 1 min», «A 0.5 km. Estimación a 28 km/h, sin tráfico en vivo.»). | «Marca "voy en camino", y Andrés lo sigue en el mapa con una llegada estimada.» (15 pal · 2,1) | «Ubicación solo con la app abierta» · «Estimación a 28 km/h, sin tráfico en vivo» | Split con máscara de 22 px; el pin avanza **a saltos** (publica cada 20 s o 40 m); la barra pasa a **En camino**. Usar la **recaptura de producción** de `C_08` (ya sin «0 trabajos»); aun así, no hacer zoom a la nota de la ficha «TRABAJADOR». | Whoosh; blip por salto. |
| 11 ★ | 1:16–1:27 (11 s) | T6 (1 s, la puerta) → recorte de la tarjeta «PIN PARA INICIAR» de `E2E/C_08` (PIN 7083) → `E2E/W_09_pro_pin_dialogo.png` → inserto `E2E/W_10_pro_pin_incorrecto.png` («PIN incorrecto. Te quedan 4 intentos.») → inserto de 1 s `E2E/W_26_pro_pin_bloqueado.png` → `E2E/W_11_pro_pin_correcto_en_curso.png`. | «En la puerta, Mateo pide el PIN que solo ve Andrés. Sin ese PIN, el trabajo no parte; cinco intentos fallidos lo bloquean quince minutos.» (25 pal · 2,3) | «Sin el PIN del cliente, no se inicia» · «5 intentos fallidos → 15 min de bloqueo» | Pop en los casilleros; error = shake de 3 ciclos en rojo (gag: la gota «se ríe» con un rebote); acierto = check verde; el PIN desaparece del lado de Andrés; la barra pasa a **En Curso**. | Teclas; buzz; ding. |
| 12 | 1:27–1:36 (9 s) | T7 (2 s: la última gota no cae) → `E2E/W_12a_finalizar_sin_evidencia.png` («Evidencia requerida») → `E2E/W_13_pro_menu_evidencia.png` («Tomar foto · Elegir foto de galería · Elegir video») → `E2E/W_15a_confirmar_finalizar.png` (**Pendiente de aprobación**). | «La gota, por fin, se rinde. Pero Mateo no puede finalizar sin subir fotos o video del trabajo.» (18 pal · 2,0) | «Sin evidencia no se puede finalizar» · «Chat por cada trabajo» | La gota tiembla y se queda arriba (beat cómico de 0,5 s de silencio musical). Zoom al diálogo; el menú sube; la barra pasa a **Pendiente de aprobación** (ámbar). | Silencio de 0,5 s → obturador; **build** musical. |
| **CAPÍTULO 3 · EL CIERRE** |||||||
| 13 ★ | 1:36–1:47 (11 s) | `E2E/C_16_cliente_ve_evidencia.png` («Esperando tu conformidad», «Recibo conforme») → `E2E/C_17_cliente_pago_liberado.png` (toast «Recibiste conforme. El pago retenido quedó liberado.», **Completado**). Inserto de 1,5 s: `E2E/C_36_disputa_abierta.png` («Disputa abierta. El pago sigue retenido.»). | «Andrés revisa la evidencia y toca "Recibo conforme". Recién ahí se libera el pago. Si algo hubiera salido mal, abre una disputa y el pago sigue retenido.» (27 pal · 2,5) | **«Él da la conformidad»** · «Sin respuesta en 48 h y con evidencia: se libera solo» · «Disputa: el pago sigue retenido» | Clic; el candado se abre y la ficha se vuelve verde con la etiqueta **«Liberado»**; la barra se completa en verde. Usar las **recapturas de producción** de `C_16`/`C_17`; no hacer zoom a la ficha «TRABAJADOR»; desenfocar la miniatura de evidencia de prueba. | **Clímax**; ding + monedas suaves. |
| 14 | 1:47–1:52 (5 s) | Dos teléfonos: `E2E/A_21b_calificacion_llena.png` («Calificar Trabajo», 5 ★) y `E2E/W_24b_form_lleno.png` («Calificar al cliente — … No mueve el pago.»). | «Al final, se califican mutuamente, y eso alimenta el ranking.» (10 pal · 2,0) | «Calificación mutua → ranking» | Las estrellas se llenan una a una. Recortar los comentarios «(prueba E2E)». | Ding ascendente ×5. |
| 15 | 1:52–1:59 (7 s) | Monitor: `desk_01_login_consola.png` («Consola operativa — Supervisa. Gestiona. Resuelve.») → tarjetas [R] con los textos exactos: «Confirma que eres el administrador» (doble factor), Trabajadores «Aprobar / Rechazar», «Centro de Mediación». KPI con «—». | «Detrás, el equipo verifica profesionales y media en disputas, desde una consola con doble factor.» (15 pal · 2,1) | «Verificación · Disputas · Doble factor» · «Datos de demostración» | Tarjetas apiladas en 3D leve; la cámara retrocede. | La música baja. |
| **CIERRE** |||||||
| 16 | 1:59–2:03 (4 s) + end card de 3 s | T8 (la llave seca, 1 s) → los tres dispositivos se juntan → logo al centro → lema + URL + QR. | «My Works App: profesionales de confianza y el pago protegido hasta la conformidad. Gracias.» (14 pal · 3,5 en 4 s; la voz sigue 1 s sobre el end card → ~2,8) | Lema «Multiplataforma que conecta hogares con profesionales de oficios, con trazabilidad del trabajo y pago protegido.» · **myworksapp-cl.vercel.app** + QR · pie opcional «Proyecto de título · Duoc UC» | El logo se asienta en el beat; el end card queda quieto 3 s (para escanear el QR). | Resolución musical; última gota… que no cae (remate). |

**Duración:** 123 s + 3 s de end card. **Locución:** 274 palabras, ~2,2 pal/s promedio; ninguna escena pasa de 2,5, salvo el remate de la 16. La escena 16 se lee pausada: la frase continúa sobre el end card.

### 2.1 Locución completa (para grabar)

Un WAV por escena (`vo_01.wav` … `vo_16.wav`), 48 kHz / 24 bit, con 0,3 s de aire.

> **[1]** Esta es la cocina de Andrés. Y esa gota no piensa detenerse.
> **[2]** Andrés necesita un gasfíter, pero tiene una duda muy razonable: ¿pagar antes de ver el trabajo terminado?
> **[3]** Les presento My Works App: el pago queda retenido hasta que el cliente da la conformidad.
> **[4]** Tres piezas: app para clientes y profesionales, web para clientes y consola de administración.
> **[5]** Andrés crea su cuenta como cliente. También podría pedir desde la web, sin registrarse.
> **[6]** Escribe «plomería» y el mapa le muestra profesionales cercanos, con su nota y el precio de la visita.
> **[7]** Elige a Mateo, revisa su cobertura y toma una hora publicada que sigue libre.
> **[8]** Paga en Webpay de Transbank. La app no pide ni guarda la tarjeta, y los treinta y dos mil pesos quedan retenidos en garantía.
> **[9]** Del otro lado, Mateo ve el pedido y la reputación de Andrés. Acepta. Si rechazara, el pago volvería a la tarjeta.
> **[10]** Marca «voy en camino», y Andrés lo sigue en el mapa con una llegada estimada.
> **[11]** En la puerta, Mateo pide el PIN que solo ve Andrés. Sin ese PIN, el trabajo no parte; cinco intentos fallidos lo bloquean quince minutos.
> **[12]** La gota, por fin, se rinde. Pero Mateo no puede finalizar sin subir fotos o video del trabajo.
> **[13]** Andrés revisa la evidencia y toca «Recibo conforme». Recién ahí se libera el pago. Si algo hubiera salido mal, abre una disputa y el pago sigue retenido.
> **[14]** Al final, se califican mutuamente, y eso alimenta el ranking.
> **[15]** Detrás, el equipo verifica profesionales y media en disputas, desde una consola con doble factor.
> **[16]** My Works App: profesionales de confianza y el pago protegido hasta la conformidad. Gracias.

**Dirección de voz:** presentador de 30–45 años, chileno neutro, cálido y seguro, con humor seco en las líneas de la gota (1, 2 y 12): media sonrisa, sin exagerar. Pausa de 0,4 s después de la pregunta de la escena 2 y antes de «Gracias». Énfasis en «retenido», «PIN» y «conformidad». Pronunciación: My Works App /mái uórks ap/, Webpay /uébpei/, Transbank /tránsbank/.
**Variante en vivo (opcional):** si Mathias presenta en sala, se exporta la versión sin voz con subtítulos y él lee el mismo guion. Los tiempos de la tabla ya dejan aire para la lectura humana.

---

## 3. Versión corta 9:16 (45 s, 1080×1920)

Subtítulos quemados obligatorios. Zona segura: 250 px arriba y 300 px abajo. Las capturas web se **recortan** al elemento clave. El primer frame es la gota + el texto del gancho (sirve de miniatura). Mismo tono de *speech*, misma historia.

| # | Tiempo | Visual | Locución | Texto en pantalla |
|---|---|---|---|---|
| V1 | 0:00–0:05 | T1/T2 en vertical | «Andrés tiene una gota que no para y una duda: ¿pagar antes?» (12 pal) | «¿Pagar antes de verlo terminado?» |
| V2 | 0:05–0:10 | Ficha al cofre → logo | «En My Works App, el pago queda retenido.» (8) | «Pago retenido hasta la conformidad» |
| V3 | 0:10–0:17 | `mob_04_busqueda_mapa.png` → `mob_06_profesional_reserva_rapida.png` (encuadre sin la nota ni los trabajos) | «Elige un gasfíter cercano y una hora libre.» (8) | «Desde $32.000 / visita» |
| V4 | 0:17–0:23 | Recorte de `E2E/A_01` («Confirmar pedido · CLP 32.000», «El pago queda retenido») → cofre | «Paga en Webpay, y el monto queda en garantía.» (9) | «Pago RETENIDO» · «Transbank · integración» |
| V5 | 0:23–0:31 | Recorte del PIN de `E2E/C_08` → `E2E/W_10` → `W_11` | «En la puerta, sin el PIN de Andrés, no se parte.» (11) | «Sin PIN, no se inicia» |
| V6 | 0:31–0:36 | T7 (la gota se rinde) → `E2E/W_12a` | «Y sin evidencia, no se termina.» (6) | «Sin evidencia no se finaliza» |
| V7 | 0:36–0:41 | Recorte del toast de `E2E/C_17` + el cofre se abre en verde | «"Recibo conforme": recién ahí se libera el pago.» (8) | «Él da la conformidad» |
| V8 | 0:41–0:45 | Logo + URL + QR | «My Works App.» (3) | «myworksapp-cl.vercel.app» |

---

## 4. Duraciones

- **Principal 16:9:** ~123 s + 3 s de end card (rango aceptable de 118–128 s).
- **Corta 9:16:** 45 s.

---

## 5. Notas de precisión (deben coincidir exactamente)

**Datos y textos:**
- **Nombres:** «My Works App» (con espacios); cliente «Andrés P. · Cuenta de cliente»; profesional «Mateo Oyarzo · Gasfíter»; servicio «Reparación de fuga de agua y cambio de llaves o grifería».
- **Montos:** «$32.000 / visita», «32.000 CLP», Webpay «$32.000». Punto de miles, sin decimales. Locución: «treinta y dos mil pesos».
- **Botón de pago:**
  - Con sesión: **«Confirmar pedido · CLP 32.000»** (`E2E/A_01`, `web_e2e_09`).
  - Invitado: **«Continuar a Webpay · CLP 32.000»** (`web16x9_07_checkout_invitado.png`, `mob_07`).
  - ⚠️ No usar `E2E/G_02_form_invitado.png` como pantalla del pedido de Andrés: es de otra profesional (Juana Coll) por **31.000 CLP**.
- **Botones (texto literal):** «Buscar servicio →», «Continuar con la reserva →», «Aceptar Trabajo», «Rechazar», «Voy en camino», «Iniciar trabajo», «Confirmar PIN», «Subir evidencia», «Finalizar Trabajo», «Recibo conforme», «Abrir disputa», «Enviar Calificación», «Calificar al cliente», «Registrarse».
- **Estados de la app:** Pendiente → Aceptado → En camino → En Curso → Pendiente de aprobación → Completado. En la web, el paso de aprobación se ve como **«Esperando tu conformidad»** (`C_16`): no cambiarlo.
- **PIN:** 4 dígitos; solo lo ve el cliente y solo en Aceptado o En camino; desaparece al iniciar; «PIN incorrecto. Te quedan 4 intentos.»; 5 intentos fallidos = 15 min de bloqueo; el profesional no puede leerlo. Usar solo el PIN **7083** de `C_08`; no mezclarlo con el 3633 de `web_e2e_13`.
- **Llegada:** «Llegada 1 min · A 0.5 km. Estimación a 28 km/h, sin tráfico en vivo.» No decir «tráfico en tiempo real».
- **Pago:** Transbank Webpay en ambiente de integración. Retenido al pagar, liberado con «Recibo conforme» (no es un segundo cargo); liberación automática a las 48 h si no hay respuesta y hay evidencia. «Liberado» ≠ «transferido».
- **GPS:** solo con la app en primer plano, cada 20 s o 40 m.
- **Roles:** la web es solo para clientes; el profesional usa solo la app móvil; la administración usa la consola de escritorio con doble factor.

**🔶 Regla de cifras de Mateo (actualizada 15-nov, 22:00)**

| Dato | Situación | Regla para el video |
|---|---|---|
| «(0 trabajos)» en el seguimiento web (`C_08`, `C_16`, `C_17`) | **Corregido en producción** (`0fd5f44`). | **Recapturar `C_08`, `C_16` y `C_17`** en producción con el mismo pedido de demostración. Las versiones del 15-nov no se usan para la ficha «TRABAJADOR». |
| Nota 4.9 (búsqueda, `W_05b`) vs 5.0 (`W_22`) | Datos de demostración sin reseñas reales detrás; **PR pendiente** para el seed (Mateo quedaría en 4.9 con reseñas reales). | Sin zoom, callout ni voz sobre la nota. **No usar `W_22`.** |
| Contador de trabajos (8 en la búsqueda vs el panel «Finalizados») | Mismo PR del seed. | Sin zoom ni callout. |
| «32.000 $ ↑ 12 % vs. mes anterior» (panel del profesional) | **Era un valor fijo** en el código; el PR lo cambia por el crecimiento real (o lo oculta si no hay datos). | Sin zoom; desenfocar el porcentaje en `W_05b`. |

Mientras el PR no tenga **merge + deploy + seed**:
1. Recortar o desenfocar esas cifras en todo plano donde se lean (≥ 16 px en 1080p).
2. Si una escena las necesita, usar un chip placeholder **«valores unificados pendientes»** (DM Sans 600, ámbar `#C9A227` sobre `#121A2A`).
3. La locución dice «con su nota» sin decir el número.

Cuando se confirme el deploy, recapturar la búsqueda (`web16x9_04/05/06`, `mob_04/06`) y el panel (`W_05b`) y quitar los placeholders.

**Ocultar artefactos de prueba:**
- Los comentarios «(prueba E2E)».
- El botón «Feedback de la prueba» (`A_18`).
- El globo «Guía profesional» (`W_02`; usar `W_05b`).
- La miniatura gris de evidencia de prueba.
- El estado crudo «esperando_pago» (`A_19`).
- La lista «Cuentas demo» (`W_01`, `app_03b`).
- Los mapas con la marca de agua CARTO («API KEY REQUIRED», en `web_e2e_13/14`): usar `C_08`/`C_17`/`web16x9_*` con la atribución «© OpenStreetMap contributors» visible.

**No inventar:** reprogramar pedidos, calificar desde la web, efectivo, propinas, cuotas, tráfico en vivo, rastreo en segundo plano, transferencia automática al profesional, push «Nueva solicitud», IA, videollamadas, seguros, contrato con validez legal, cifras de negocio, afirmaciones de tiempo no medidas.

---

## 6. Pendientes / inconsistencias abiertas

1. **Cifras de Mateo:** el «0 trabajos» ya está corregido en producción, así que hay que recapturar `C_08`, `C_16` y `C_17`. La nota, el contador y el «↑ 12 %» esperan el PR (merge + deploy + seed); hasta entonces rige la regla de la sección 5. Mathias avisa cuando esté listo para recapturar la búsqueda y el panel.
2. **Consola de administración después del doble factor:** no hay capturas reales (Panel ejecutivo, Trabajadores, Mediación). Por ahora van recreadas con los textos exactos y los KPI en «—». Ideal: grabarlas con una cuenta admin + TOTP.
3. **Onboarding del profesional** (registro como Especialista, verificación de RUT, tarifas, horario): existe en el código pero no tiene capturas. No aparece en esta versión.
4. **Fotos repetidas en la búsqueda:** los tres profesionales comparten la misma foto. Encuadrar solo la tarjeta de Mateo, o recapturar.
5. **Locución:** para un nivel premium se recomienda un locutor humano (la voz sintética anterior solo sirve como guía de tiempos).
6. **Pie «Proyecto de título · Duoc UC»:** decidir si va en el end card.

---

## 7. Herramientas recomendadas

| Etapa | Herramienta | Para qué |
|---|---|---|
| Animatic | **Figma** o **Canva** | Un frame por escena con las capturas reales y una voz temporal, para aprobar el ritmo y el humor antes de animar. |
| Motion de interfaz (núcleo) | **Remotion** (proyecto existente en `/workspace/mwa_video/remotion/`, con el pipeline de audio y subtítulos en `build/`) | Dispositivos 3D (`@remotion/three`), zooms, callouts, barra de estados, PIN, ficha/cofre, split «Mientras tanto…», tarjetas de capítulo, chips placeholder y el QR del CTA. El mismo proyecto renderiza 16:9 y 9:16. Alternativa: After Effects. |
| Tomas de vida real | **Higgsfield** (Veo/Kling con control de cámara) | T1–T8 (la gota y sus gags, Andrés, Mateo, la puerta, la reparación). **Nunca generar interfaz con IA.** |
| Recaptura | Navegador en `myworksapp-cl.vercel.app` (cuenta demo de cliente, sin mostrar credenciales) | `C_08`, `C_16` y `C_17` a 1280×900 o más, mismo encuadre que las originales. |
| Retoque de capturas | **Picsart** | Desenfocar o recortar las cifras de Mateo y los artefactos de prueba, recortes verticales, upscale de las capturas de 1280×900. Sin editar textos ni montos. |
| Voz | **Locutor humano chileno** (recomendado) o **ElevenLabs** | Un WAV por escena, con la pronunciación fijada. |
| Música | **Artlist / Epidemic Sound** | Score cinematográfico de 100–115 BPM con stems para cortar en el drop (0:48) y el clímax (1:36). Guardar la licencia. |
| Subtítulos y mezcla | **Descript** + **DaVinci Resolve (Fairlight)** | .srt exacto contra el guion, Studio Sound, versiones con subtítulos quemados y sin voz. |
| Color y finishing | **DaVinci Resolve** | Grade del b-roll a la paleta, export H.264 yuv420p +faststart. |
| QR | Generador estático (p. ej. `qrencode`) | QR a https://myworksapp-cl.vercel.app (verificada: responde 200, 15-nov-2026). |
| QA | Sección 5 + `flujo_app.md` lado a lado | Revisión cuadro a cuadro de textos, estados, montos y la regla de cifras. |

**Flujo:** animatic → aprobación de Mathias → voz → Remotion + tomas de Higgsfield → música/SFX/mezcla → subtítulos → grade → QA → entrega.
