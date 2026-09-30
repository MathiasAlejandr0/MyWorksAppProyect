# Auditoría MyWorksApp — 30 de septiembre de 2026

Auditoría del monorepo completo (app Flutter, sitio web, escritorio Tauri y paquete `shared`) y de lo que se cerró en la rama `cursor/finish-ecosystem-fa99`.

El producto es un marketplace de oficios del hogar para Chile (cliente y especialista), con un panel de administración en escritorio. El backend es **Supabase** (Auth, PostgreSQL, PostgREST, RLS, Storage y Edge Functions). No hay un API propio ni Firebase.

## 1. Arquitectura

| Pieza | Qué es | Cómo habla con el resto |
|---|---|---|
| `myworksapp_app` | App Flutter (Android, iOS y carpeta `windows/`). Roles cliente, especialista y un admin móvil reducido. | `supabase_flutter`. Capas: `features/*/presentation` → `core/services` → `core/database/repositories` → Postgres. |
| `myworksapp_web` | Sitio Vite + React. Landing, catálogo, reserva y checkout del **cliente**. | Importa `@myworksapp/shared` por alias de Vite. Misma base. |
| `myworksapp_desktop` | Hub operativo. La UI es React; Tauri la empaqueta. Es el **back-office** (administrador). | El mismo `shared` y el mismo Supabase. El acceso exige rol `administrador`. |
| `shared` | Tipos, dominio (estados en español), repositorios y pagos (Webpay / Oneclick). | Lo consumen web y escritorio. Flutter tiene un espejo generado del dominio. |
| `myworksapp_app/supabase` | Migraciones SQL, RLS y Edge Functions (Deno). | Pagos, disputas, invitados y liquidación. |

### Backend, auth, pagos, mapas, push y archivos

- **Base y auth:** Supabase Auth (correo y OAuth Google/Apple preparados) + tabla `perfiles`. El rol vive en la base (`usuario`, `trabajador`, `administrador`), no solo en la pantalla.
- **Pagos:** Transbank Webpay Plus y Oneclick (tarjeta guardada). El número de tarjeta no pasa por la app. El commit deja el cobro `retenido` hasta la conformidad del cliente. La liquidación al profesional es manual (`liquidaciones`). Las claves de comercio van en secretos de las Edge Functions (`TBK_COMMERCE_CODE`, `TBK_API_KEY`, `TBK_ENV`).
- **Mapas:** Leaflet + OpenStreetMap en la web. Flutter usa `google_maps_flutter` y `flutter_map`. El GPS en vivo del especialista se publica solo en primer plano cuando el trabajo está `en_camino` o `en_curso`, en `ubicacion_en_vivo`, y lo leen el cliente de ese pedido y un administrador. La base del profesional (`latitud_base`, `longitud_base`, `radio_servicio_km`) alimenta el mapa y el matching.
- **Push:** notificaciones locales en el teléfono (`flutter_local_notifications`). FCM está como puerto sin implementar (`UnimplementedFcmPushNotifications`). No hay correo transaccional de producto (Resend no está cableado al flujo).
- **Archivos:** fotos de perfil y evidencia siguen rutas locales o URLs. La verificación nueva sube el documento al bucket privado `verificacion-profesional` cuando la migración está aplicada.

### Cómo se comparten los datos

Los tres clientes leen y escriben las mismas tablas (`perfiles`, `trabajadores`, `trabajos`, `pagos`, `mensajes`, `disputas`, `notificaciones`). Las transiciones de trabajo y el dinero pasan por RPC y Edge Functions, no por un `UPDATE` libre del cliente. `shared/src/domain.ts` es la fuente de los códigos de estado; Flutter los regenera.

## 2. Rama `origin/cursor/auth-roles-views-d56a`

**Ya está superada por `main`. No hay que integrarla.**

El merge-base es `7a7b5d3`. La rama aporta dos commits (roles Cliente/Especialista y las vistas de registro, login y perfil). Ese trabajo entró a `main` en `8fcce70` (*Sistema de autenticación por roles Cliente y Especialista*). Después, `main` avanzó 25 commits (Webpay, retención hasta la conformidad, disputas, catálogo y mapa). En `main` ya están `user_role.dart`, `auth_service.dart`, el medidor de contraseña, los chips de rol, la migración de alias `cliente`/`especialista` y los tests. Fusionar la rama ahora pisaría pagos y seguridad.

Las ramas `dependabot/*` no se tocaron.

## 3. Build y pruebas

Herramientas de esta pasada: Flutter 3.47.5 (Dart 3.13.4, canal stable), Node 22, Rust 1.98.1 (el Cargo 1.83 del entorno no compilaba dependencias `edition2024`).

| Comando | Resultado |
|---|---|
| `shared` `npm test` | 40 pruebas, 0 fallos (incluye que el cliente no llama RPCs de `service_role`) |
| `myworksapp_web` `npm run lint` | 0 errores. 4 avisos previos de oxlint (fast refresh y un ref en `PremiumSearchMap` / `AuthContext`) |
| `myworksapp_web` `tsc -b` y `vite build` | OK |
| `myworksapp_desktop` `npm test` | 2 pruebas, 0 fallos |
| `myworksapp_desktop` `npm run lint` | 0 errores. 2 avisos previos (`AuthContext`, `SupportWorkspace`) |
| `myworksapp_desktop` `tsc -b` y `vite build` | OK |
| `flutter analyze` | Sin avisos (exit 0). Antes de este arreglo había 8 avisos: `setState` en extensiones, `anonKey` deprecado, un `BuildContext` tras un `await` y un `FormatException` sin `const`. |
| `flutter test` | 61 pruebas, 0 fallos (zona, distancia, GPS, línea de tiempo y la bienvenida). La captura PNG de la bienvenida está en los artefactos; el test no escribe archivos. |
| `myworksapp_web` `npm run test:e2e` | 5 pruebas Playwright (humo + catálogo con Supabase simulado, pin real y pedido sin número de tarjeta) |
| `cargo check` y `cargo clippy` | OK con Rust 1.98.1. El Cargo 1.83 del entorno no lee crates `edition2024`. Hizo falta `libgtk-3-dev` y `libwebkit2gtk-4.1-dev` para compilar Tauri en Linux. Clippy no reportó avisos. |

La web en release y el hub de escritorio compilan. El build web de Flutter también compila; en Chromium headless el canvas queda negro (WebGL) y el arranque registra un error minificado, así que la captura de la app móvil es la pantalla de bienvenida pintada por el test de widgets, no el binario web.

## 4. Seguridad

- No hay `service_role` en los clientes. Los `.env` reales no están en el repositorio. Web y escritorio arrancan con un URL de ejemplo (`example.supabase.co`) y una clave ficticia `public-anon-placeholder` si faltan variables, para que el smoke de Playwright no reviente.
- Flutter trae en el código la URL del proyecto de demo y la **clave publicable** (`sb_publishable_…`). Es la clave de cliente, no la secreta. Un release sin `--dart-define` de URL y clave falla a propósito (`SupabaseConfig.validateForCurrentBuild`). Aun así, la clave publicable queda en el historial del repo: conviene rotarla si el proyecto deja de ser demo.
- Las Edge Functions usan la clave pública de **integración** de Transbank solo si `TBK_ENV=integration` (o si la variable no está definida). En producción, si faltan los secretos o si alguien deja esa clave, el servidor rechaza el cobro.
- RLS: mensajes solo entre las partes del trabajo (o admin); el profesional no puede autoaprobarse (`proteger_verificacion_profesional`); pagos y liberación de escrow van por `service_role` / RPC. El commit de Webpay lo hace el servidor con el token de Transbank, no un webhook sin firma pegado en el cliente.
- Validación: registro con validadores, mensajes recortados a 2000 caracteres, rol web limitado a `usuario` (un trabajador o admin que entre al sitio es deslogueado).
- Huecos que siguen: no hay verificación de antecedentes (registro civil / causas); el documento es una foto que revisa un humano; no hay WAF ni rate limit de aplicación fuera de las funciones de pago; el chat usa Realtime si la publicación está activa y, si no, un refresco cada 12 segundos.

## 5. Pantallas

Estados: **terminada** (flujo real y estados de carga/vacío/error), **falta pulir**, **incompleta**, **placeholder**, **rota**.

### App Flutter

| Ruta | Antes | Después | Por qué |
|---|---|---|---|
| `/welcome`, `/onboarding`, `/role-selector` | terminada | terminada | Bienvenida, tour y elección de rol. |
| `/login`, `/register`, `/forgot-password`, `/reset-password` | terminada | terminada | Auth por rol ya estaba en `main`. |
| `/profile` | terminada | terminada | Perfil según cliente o especialista. |
| `/user/home`, `/user/worker-list`, `/user/worker-detail/:id` | terminada | terminada | Catálogo y ficha del profesional. |
| `/user/service-request`, `/user/quick-booking` | terminada | terminada | Crean el trabajo en Supabase. |
| `/user/profile`, `/user/profile/edit` | terminada | terminada | Datos del cliente. |
| `/worker/home`, `/worker/register`, `/worker/pricing-setup` | terminada | terminada | Alta, zona y tarifas. |
| `/worker/profile`, `/worker/profile/manage` | incompleta | falta pulir | Verificación, ubicación base en el mapa, radio y estados de carga/error. Sigue sin antecedentes automáticos. |
| `/job/detail/:id` | falta pulir | terminada | Línea de tiempo, «Voy en camino», GPS en primer plano para el especialista y pin en vivo para el cliente. |
| `/job/history`, `/job/photos/:id`, `/job/schedule` | terminada | terminada | Historial, evidencia y calendario del especialista. |
| `/rating/:id` | terminada | terminada | Calificación al cerrar. |
| `/chat/:id` | incompleta | terminada | Guardaba en `mensajes` pero se quedaba cargando si faltaba la otra parte y no se actualizaba solo. Ahora hay error visible, Realtime y refresco. |
| `/notifications`, `/settings` | terminada | terminada | Centro local y ajustes. |
| `/statistics` | terminada | terminada | Cifras del especialista desde sus trabajos. |
| `/privacy-policy`, `/terms`, `/user-rights`, `/help-center`, `/maintenance` | terminada | terminada | Textos legales y ayuda. El contacto de soporte de mantenimiento sigue como nota interna. |
| Permisos de cámara, ubicación y almacenamiento; Webpay WebView | terminada | terminada | Pasos del sistema y el handoff de pago. |
| `/admin` y subrutas (usuarios, trabajadores, trabajos, disputas, reportes, errores, servicios, banderas) | terminada | terminada | Operan contra Supabase. El admin de teléfono no reemplaza al escritorio. |
| `/admin/desktop-hub` | terminada | terminada | Explica que la operación vive en el programa de escritorio. No es un panel falso. |

El matching usa la base del profesional: fuera del radio no entra, y la distancia suma puntaje. Sin coordenadas sigue valiendo la zona escrita.

### Sitio web (vistas, no hay router)

| Vista | Antes | Después | Por qué |
|---|---|---|---|
| Landing | terminada | terminada | Hero, buscador y acceso. |
| Catálogo de categorías | terminada | terminada | Oficios con foto. |
| Resultados y mapa Leaflet | falta pulir | terminada | El pin sale de `latitud_base` / `longitud_base`. Quien no la tiene no aparece en el mapa. |
| Checkout y vuelta de pago | terminada | terminada | Webpay / tarjeta guardada. Sin claves de comercio el cobro no sale. |
| Seguimiento | rota | terminada | Estado real, pago, domicilio y pin del profesional por Realtime, con llegada estimada a 28 km/h. |
| Chat del seguimiento | placeholder | terminada | Los mensajes se quedaban en el navegador y se marcaban como enviados. Ahora se escriben en `mensajes` si hay sesión y pedido. |
| Modal de auth e invitado | terminada | terminada | Sin campo de número de tarjeta. |
| Búsqueda sin oficio reconocible | rota | terminada | Cualquier texto caía en electricistas y decía «profesional verificado». Ahora pide elegir una categoría. |

### Escritorio

| Pantalla | Antes | Después | Por qué |
|---|---|---|---|
| Login y MFA | terminada | terminada | Solo entra `administrador`. |
| Panel ejecutivo | falta pulir | terminada | GMV, comisión 15%, completados, ticket y CSAT por 24 h / 7 / 30 / 90 días. En cero dice «sin cobros» o «sin calificaciones». |
| Trabajadores del panel | incompleta | terminada | La columna «precio» mostraba «verificado» si tenía tarifas. Ahora muestra la visita en pesos y la verificación, con aprobar o rechazar. |
| Soporte y disputas | terminada | terminada | Lista disputas reales y permite cerrarlas. |
| DevSecOps | placeholder | falta pulir | El runner decía 28/28 y un usuario `researcher@myworks.edu`. Ahora mide la latencia real y deja claro que las suites corren en CI. No ejecuta las pruebas. |
| RRHH | placeholder | falta pulir | La invitación llama a `invitar-colaborador` y muestra el error o el envío. El directorio de ejemplo sigue solo en desarrollo. |
| Campana y ajustes | rota | terminada | No hacían nada. Abren las notificaciones de la cuenta y el estado de las variables de Supabase. |
| Perfil | terminada | terminada | Nombre, correo y rol. |

## 6. Completitud frente a un marketplace tipo Uber de oficios

| Capacidad | Cliente | Especialista | Admin | Estado |
|---|---|---|---|---|
| Alta y sesión | App y web | App | Escritorio (+ MFA) | Hecho |
| Verificación de identidad y antecedentes | — | Nota + foto; un admin aprueba | Aprueba o rechaza en el escritorio | Parcial. La migración de verificación ya está en la base. No hay consulta a un registro de antecedentes. |
| Ubicación base y GPS | Ve el pin en la web y en el detalle | Publica en primer plano en camino/en curso y fija su base | Lee el punto por RLS | Hecho en código. `20261006000001` conserva las transiciones de pago y suma `en_camino`. Hay que aplicarla. |
| Catálogo | Web y app | Oficios y tarifas | Servicios en el admin móvil | Hecho |
| Pedido con lugar | Dirección y coordenadas en el trabajo | La ve al aceptar | La ve en el trabajo | Hecho. Fotos del problema al crear el pedido: la evidencia fuerte es la del profesional al terminar. |
| Matching cercano | Elige en el catálogo; la app excluye fuera del radio y puntúa por distancia | Recibe el pendiente | — | Parcial. No hay dispatch automático. Sin base, sigue la zona de texto. |
| Cotizaciones y precio fijo | Los dos modos existen | Propone o publica tarifa | — | Hecho |
| Aceptar o rechazar | — | App | — | Hecho |
| Seguimiento en vivo | Pin y ETA en la web y en el detalle | Publica GPS en primer plano | Puede leerlo | Hecho. Se detiene al cerrar el trabajo o al pasar la app a segundo plano. |
| Chat | Web (con sesión) y app | App | — | Hecho sobre `mensajes` |
| Avisos | In-app | Locales en el teléfono | Bandeja del escritorio | Parcial. Sin push remoto ni correo de producto. |
| Cobro retenido, liberación, reembolso | Webpay / Oneclick | Ve el estado | Liquidación manual | Hecho en código. Producción exige comercio Transbank real. |
| Comisión y payout automático | — | — | Transferencia manual | Falta. Khipu/Fintoc están como stub. |
| Disputas | Puede abrirlas | Las ve | Las cierra en soporte | Hecho |
| Calificaciones e historial | App | App | — | Hecho |
| Perfil | App y web | App | Escritorio | Hecho |
| Métricas | — | Estadísticas propias | GMV, comisión, ticket, CSAT y completados por período | Hecho. La comisión es 15% sobre el GMV cobrado o retenido. |

Quién usa qué: el **cliente** usa la web para buscar y pagar, y la app para el ciclo completo. El **especialista** usa la app. El **admin** opera en el escritorio; el admin del teléfono es un complemento, no el back-office.

## 7. Plan (lo que se hizo y lo que queda)

Hecho en esta rama, en este orden:

1. Corregir avisos de `flutter analyze` que esta versión del SDK marca (constructor `const`, `publishableKey`, `setState` en extensiones, contexto tras un `await`).
2. Chat web real, seguimiento honesto y búsqueda que no inventa un electricista.
3. Bandeja, ajustes y panel de calidad del escritorio; conteos que no se sustituyen por cifras de ejemplo; verificación aprobar/rechazar.
4. Tarjeta de verificación en el perfil del especialista, migración y trigger para que no se autoapruebe.
5. Matching por zona, sincronización de banderas ya leídas desde Supabase, y pruebas de estados, mensajes y verificación.
6. GPS en vivo (`en_camino` / `en_curso`), ubicación base, métricas reales del escritorio e invitación por Edge Function.
7. La matriz de `transicion_trabajo_permitida` en `20261006000001` vuelve a ser la de producción (`esperando_pago` → `pendiente` → `aceptado`, y `en_curso` → `esperando_aprobacion_cliente`) y solo agrega `aceptado` → `en_camino` → `en_curso`.
8. Migración `20261007000001_rls_indices_asesores.sql`: `(select auth.uid())`, políticas inglesas duplicadas, índices duplicados y FKs sin índice.
9. Seed de demo (`scripts/demo/seed_demo.sql`) y guion en `DEMO.md`. En la web, el seguimiento ofrece **Recibo conforme** y se refresca solo.
10. Playwright del catálogo con Supabase simulado. Los clientes no llaman `liberar_escrow_manual` ni los otros RPC de `service_role`.
11. `20261005000002_security_lockdown_rpc.sql` deja en el repo el cierre ya aplicado: `liberar_escrow_manual` solo para `service_role`, admin o conexión sin JWT. `20261006000002` saca la clave `pin` de los listados abiertos.
12. Política de contraseña en registro y cambio de clave (app, web y aceptación de invitación en escritorio): 8 caracteres, una letra y un número, mensajes en español. `config.toml` repite el mínimo; hay que guardarlo también en Authentication → Password del proyecto.
13. El repo queda alineado con lo ya aplicado en vivo hasta `20261008000010` (`definir-clave-invitado` v5 y `guest-checkout` v16). Antes de la demo hay que volver a correr el seed: arregla el `JOIN` de `niveles_precio` y archiva los pendientes que no son `@demo`. El guion y el checklist de lanzamiento están en `DEMO.md`. Un pago con tarjeta de prueba y la liberación del escrow ya se probaron en vivo.

Sigue fuera de este código, porque depende del dueño:

- Volver a correr `scripts/demo/seed_demo.sql` (el `JOIN` de `niveles_precio` y el archivo de pendientes ajenos a la demo). No hay migración ni función nueva en esta ronda. Si `pg_cron` no quedó programado, corre `SELECT public.expirar_pagos_abandonados();` cada 10 minutos.
- SMTP de Supabase Auth, o `RESEND_API_KEY`, `RESEND_FROM` e `INVITE_PROVIDER=resend`, para que el correo de RRHH salga. `INVITE_REDIRECT_URL=http://127.0.0.1:3001`.
- Guardar en el proyecto la política de contraseña (mínimo 8, letras y dígitos). El `config.toml` solo la deja escrita para el CLI.
- Comercio Transbank de producción y secretos `TBK_*` cuando exista la empresa.
- Cuenta de Firebase / APNs para push, y un proveedor de correo si se quieren avisos fuera de la app.
- Payout automático (cuenta de payout).
- Publicar en Play Store, App Store y firmar el instalador de Tauri.
- Antecedentes distintos de la revisión humana del documento.
- GPS en segundo plano. Hoy se corta al minimizar la app, a propósito, para cuidar batería y privacidad.

No se inventaron credenciales. No se hizo push a `main` y no se abrió un pull request.
