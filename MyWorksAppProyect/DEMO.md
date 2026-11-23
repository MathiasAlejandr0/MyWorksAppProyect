# Demo en vivo — MyWorksApp

Guion para mostrar MyWorksApp con las cuentas de demostración del proyecto Supabase `wxqrfcqifkfgawrnqmnj`. Los pagos van por Transbank en **ambiente de integración**: no hay cobros reales.

## 1. Dónde está cada parte

| Parte | Dónde |
|---|---|
| Web (clientes) | https://myworksapp.cl (también `www.myworksapp.cl` y https://myworksapp-cl.vercel.app) |
| App Android (clientes y profesionales) | APK release construido desde `main`; la versión del código es 1.0.15+16 (`myworksapp_app/pubspec.yaml`). Esa versión no muestra la carta de boleta del SII en Mi Perfil |
| Consola de escritorio (administración) | `myworksapp_desktop/` (sección 6) |
| Encuesta de prueba con usuarios (SUS) | https://myworksapp.cl/encuesta; en la app, inicio del cliente → **Encuesta de la prueba**, y perfil del profesional → **Encuesta de la prueba** |
| Migraciones de la base | `myworksapp_app/supabase/MIGRATIONS_INVENTORY.md` (cada versión de la base tiene su archivo) |

Configuración vigente en `public.app_config` (informada el 20-nov-2026): `demo_modo = 1` y `admin_requiere_aal2 = 1` (la consola exige el segundo factor).

Con `demo_modo = 1` las cuentas demo aparecen en el catálogo con el aviso «Datos de demostración» y el invitado queda con la cuenta confirmada sin correo (`_shared/guest_ticket.ts`). Con otro valor, las cuentas `@demo.myworksapp.cl` y `@demo.com` se ocultan del catálogo y no se pueden reservar ni cobrar (migración `20261120140000_ocultar_profesionales_demo.sql`).

## 2. Cuentas (misma contraseña en todas; la entrega el equipo, no se publica)

Todas las cuentas de demostración terminan en `@demo.myworksapp.cl` y trabajan en Puerto Montt y alrededores. Estas son las del guion:

| Quién | Correo | Rol |
|---|---|---|
| Cliente | `andres.pizarro@demo.myworksapp.cl` | usuario |
| Cliente | `camila.soto@demo.myworksapp.cl` | usuario |
| Mateo Oyarzo, plomería, Puerto Montt (visita $32.000) | `mateo.oyarzo@demo.myworksapp.cl` | trabajador verificado |
| Elsa Caicheo, electricidad (visita $38.000) | `elsa.caicheo@demo.myworksapp.cl` | trabajador verificado |
| Bruno Levio, pintura, Pelluco (visita $27.000) | `bruno.levio@demo.myworksapp.cl` | trabajador verificado |
| Nora Huenchun, construcción, Alerce (visita $30.000) | `nora.huenchun@demo.myworksapp.cl` | trabajador verificado |
| Sofía Alvarado, limpieza, Angelmó (visita $20.000) | `sofia.alvarado@demo.myworksapp.cl` | trabajador verificado |
| Luis Contreras, en revisión | `luis.contreras@demo.myworksapp.cl` | trabajador, no disponible |
| Administración | `admin.ops@demo.myworksapp.cl` | administrador |

El resto de los profesionales de demostración aparece en el catálogo y en el selector de cuentas del inicio de sesión de la app.

El escritorio pide el segundo factor: el primer ingreso de `admin.ops` muestra un QR para una app de códigos (Authenticator o similar). Usa en la demo el mismo dispositivo que ya lo escaneó.

Registro (web y app) y cambio de clave piden al menos 8 caracteres, con una letra y un número.

## 3. Tarjetas Transbank (integración)

En `https://webpay3gint.transbank.cl` cualquier fecha futura sirve. CVV `123` (American Express `1234`).

| Resultado | Marca | Número |
|---|---|---|
| Aprobada | Visa | `4051885600446623` |
| Aprobada | Mastercard | `5186059559590568` |
| Aprobada | Redcompra | `4051884239937763` |
| Aprobada | American Express | `370000000002032` |

En la página de autenticación de prueba: RUT `11.111.111-1`, clave `123`.

Si la persona cancela en Webpay, el pago queda `anulado` y el pedido `cancelado`; hay que volver a elegir al profesional. Los pedidos en `esperando_pago` sin pago se cierran solos a los 30 minutos (`expirar_pagos_abandonados`, con `pg_cron` cada 10 minutos) y no aparecen en la lista del profesional.

## 4. Cómo se cobra

- **Web.** El pedido a un profesional cobra su tarifa de visita (`trabajadores.tarifa_visita`), más el recargo de traslado si la dirección está fuera de su radio.
- **App.** El formulario «¿Qué trabajo necesitas?» muestra solo las variantes que el profesional publicó en `trabajador_precios` y sus servicios extra (`trabajador_servicios_extra`). Si no publicó ninguna, ofrece **Visita del profesional** con su tarifa de visita, igual que la web. El servidor (`monto_esperado_trabajo`) valida el mismo monto antes de cobrar.
- **Medios de pago.** Con sesión y sin tarjeta inscrita, se abre Webpay Plus. Con una tarjeta inscrita en Oneclick, se cobra sin volver a escribirla; **Cambiar tarjeta** la reemplaza. Sin sesión (web), el formulario de invitado pide nombre, correo, teléfono y dirección, nunca el número de la tarjeta.
- **Garantía.** El pago autorizado queda `retenido`. **Recibo conforme** (web o app) cierra el trabajo y deja el pago `liberado` en un solo paso; no es un segundo cargo. Si hay disputa, la resuelve el administrador desde la consola (reembolso con `webpay-resolve-dispute`).

## 5. Guion (unos 20 minutos)

### Cliente — pedido nuevo

1. Entra como Andrés en la web o en la app.
2. **Buscar servicio → Plomería.** El catálogo ordena por cercanía (bandas de 1 km), luego nota y luego precio. Elige a Mateo Oyarzo.
3. Elige fecha y hora entre las horas libres del profesional y escribe la dirección.
4. En la app, elige **Visita del profesional** ($32.000). En la web, la barra muestra **$32.000 / visita**.
5. Paga con la Visa de prueba (sección 3). El pedido queda pagado con el dinero retenido y aparece en la lista de pedidos de Mateo.

### Profesional — aceptar, ir y cerrar

1. En el teléfono, entra como Mateo y acepta el pedido.
2. **Voy en camino.** El cliente ve el pin en vivo en el seguimiento (web o app).
3. Al llegar, el cliente le dicta el **PIN de inicio** y el trabajo pasa a **en curso**.
4. Al terminar, Mateo sube la **evidencia** (cámara o galería) y marca el trabajo como terminado.

### Conformidad y calificación

1. El cliente toca **Recibo conforme**: el trabajo queda completado y el pago `liberado`.
2. El cliente califica al profesional. Si ya calificó desde la web, la app no vuelve a mostrar **Calificar Trabajo**.

### Escritorio

1. Entra como `admin.ops@demo.myworksapp.cl` y completa el segundo factor.
2. **Trabajadores:** Luis Contreras está **En revisión**, con **Aprobar** y **Rechazar**.
3. **Soporte y disputas:** el pedido `demo-job-disputa` tiene una disputa abierta para mostrar la mediación.
4. **Resumen:** GMV, comisión, trabajos completados, ticket promedio y satisfacción del período.

### Pedidos de demostración ya avanzados

Sirven para mostrar estados sin esperar el flujo completo.

| Id | Estado | Cliente y profesional |
|---|---|---|
| `demo-job-pendiente` | pendiente, pago retenido | Camila Soto y Pedro Rojas |
| `demo-job-aceptado` | aceptado, pago retenido | Andrés Pizarro y María Fuentes |
| `demo-job-en-camino` | en curso, con GPS | Camila Soto y Pedro Rojas |
| `demo-job-en-curso` | en curso, con chat | Andrés Pizarro y José Muñoz |
| `demo-job-conforme` | esperando conformidad | Camila Soto y Ana Vidal |
| `demo-job-cerrado` | completado, pago liberado | Andrés Pizarro y Tomás Herrera |
| `demo-job-disputa` | en curso, disputa abierta | Camila Soto y María Fuentes |

## 6. Cómo levantar cada cliente en local

Clave publicable (no es la `service_role`): la misma que ya usa la app en debug. En release hay que pasarla con `--dart-define`. No la copies a un ticket.

Web, en bash:

```bash
cd myworksapp_web
cp .env.example .env.local
npm install
npm run dev
```

Web, en Windows PowerShell (el retorno de Webpay tiene que ser el puerto **5173**):

```powershell
cd myworksapp_web
Copy-Item .env.example .env.local
npm install
npm run dev
```

Abre `http://localhost:5173`. `.env.example` ya trae la URL del proyecto y la clave publicable.

Escritorio, en bash (hace falta Rust estable; el Cargo 1.83 del sistema no compila crates `edition2024`):

```bash
cd myworksapp_desktop
cp .env.example .env.local
npm install
npm run dev
```

Escritorio, en Windows PowerShell. El panel en el navegador queda en `http://127.0.0.1:3001`. `npm run tauri:dev` abre la ventana nativa en el mismo origen.

```powershell
cd myworksapp_desktop
Copy-Item .env.example .env.local
npm install
npm run dev
# o, con la ventana de escritorio:
npm run tauri:dev
```

Android (emulador o dispositivo con depuración USB):

```bash
cd myworksapp_app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<clave-publicable>
```

En debug, si omites los `dart-define`, la app usa el proyecto de demo y la clave publicable que ya está en `lib/core/config/supabase_config.dart`. Un release sin esos defines se detiene a propósito.

## 7. Funciones del servidor

Los pagos pasan por Edge Functions de Supabase; las claves de Transbank viven solo ahí, nunca en la web, el escritorio ni la app.

| Función | Para qué |
|---|---|
| `webpay-create`, `webpay-handoff`, `webpay-commit`, `webpay-status` | Pago con Webpay Plus y vuelta del banco |
| `oneclick-handoff`, `oneclick-return`, `oneclick-charge` | Inscripción de la tarjeta y cobro Oneclick |
| `guest-checkout`, `definir-clave-invitado` | Pedido sin sesión desde la web y creación de la clave del invitado |
| `webpay-release`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-refund-rejection`, `webpay-resolve-dispute`, `webpay-reconcile` | Liberación, reembolsos, disputas y conciliación |
| `invitar-colaborador` | Invitación de soporte y QA desde la consola |
| `soporte-automatico` | Devolución automática del soporte. Desplegada el 20-nov; ninguna tarea del repositorio la llama todavía |
| `send-push` | Push FCM. Está en el repositorio, pero no está desplegada en vivo |

`webpay-release`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-resolve-dispute` e `invitar-colaborador` llaman `is_admin()` con el JWT del usuario antes de mover dinero o invitar; cada acción queda en la bitácora `auditoria_consola`. `guest-checkout`, `definir-clave-invitado`, `webpay-create` y `oneclick-charge` usan el límite de tasa global en Postgres (`rate_limit_consumir`).

Con `TBK_ENV=integration` y sin `TBK_COMMERCE_CODE` ni `TBK_API_KEY`, las funciones usan el comercio público de integración de Transbank. En `production` exigen los secretos del comercio real (`docs/RUNBOOK_TRANSBANK_PRODUCCION.md`).

## 8. Antes de pasar a producción

1. Secretos de Transbank de producción: `TBK_ENV=production`, `TBK_COMMERCE_CODE` y `TBK_API_KEY` del comercio real.
2. `CORS_ALLOWED_ORIGINS` con el origen real de la web (y el del escritorio, si se publica).
3. `TURNSTILE_SECRET_KEY` en las funciones y `VITE_TURNSTILE_SITE_KEY` al construir la web (ya configurados para `myworksapp.cl`). Sin el secreto, el checkout de invitado responde 503.
4. En el plan Pro de Supabase, activar la protección de contraseñas filtradas.

## 9. Plan B

| Qué falló | Qué hacer |
|---|---|
| Transbank no responde o el pago se traba | Muestra el pedido `demo-job-aceptado` o `demo-job-conforme`, que ya tienen el pago retenido. No improvises con producción. |
| Al volver del banco queda una página en blanco | Abre **Mis pedidos**: el pago queda registrado igual. El checkout tiene que abrirse desde la web publicada o desde `http://localhost:5173`. |
| Pagar a Luis Contreras dice «Este profesional todavía no está verificado para cobrar» | Es lo esperado: Luis está en revisión. |
| El GPS del salón no funciona | Abre `demo-job-en-camino`, que ya tiene la ubicación del profesional. |
| El segundo factor del escritorio no está a mano | Usa el dispositivo que ya escaneó el QR. No desactives el segundo factor en la demo. |
