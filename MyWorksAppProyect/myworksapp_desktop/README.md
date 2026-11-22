# Consola de escritorio MyWorksApp

Back office de la empresa: clientes, profesionales, pedidos, pagos en garantía, disputas, equipo y salud del sistema. Es una app Tauri 2 con interfaz React. La autorización de verdad está en Postgres (`is_admin()`, `rol_consola()`) y en las Edge Functions, no en la pantalla.

Es parte del monorepo [`MyWorksAppProyect/`](../README.md); el índice de toda la documentación está en [`docs/INDICE.md`](../../docs/INDICE.md).

## Contenido

- [Cómo correrla](#cómo-correrla)
- [Variables](#variables)
- [Deep link](#deep-link)
- [Roles](#roles)
- [Publicación](#publicación)
- [Módulos](#módulos)
- [Seguridad de las acciones](#seguridad-de-las-acciones)
- [Comisión](#comisión)
- [Bitácora](#bitácora)
- [Estado conocido](#estado-conocido)

## Cómo correrla

Desde `MyWorksAppProyect/myworksapp_desktop`, con las dependencias de `shared/` instaladas:

```bash
npm run dev
```

Eso abre Vite en `http://127.0.0.1:3001`. La app instalada se arma con `npm run tauri:dev` o `npm run tauri:build`.

## Variables

| Variable | Uso |
|---|---|
| `VITE_SUPABASE_URL` | URL del proyecto. Sin ella la consola no entra. |
| `VITE_SUPABASE_ANON_KEY` | Clave publicable. Nunca la `service_role`. |
| `VITE_AUTH_REDIRECT_URL` | A dónde vuelve el correo de recuperación. En la app instalada, si no se define, se usa `myworksapp-admin://auth/callback`. |
| `INVITE_REDIRECT_URL` | Secreto de la función `invitar-colaborador`. La consola también puede pedir el deep link, que la función acepta junto con `http://127.0.0.1:3001` y `http://localhost:3001`. |

Transbank está en integración. Khipu y Fintoc no están conectados.

## Deep link

Esquema `myworksapp-admin`, ruta `auth/callback`. Sirve para definir la contraseña después de una invitación o de recuperar la clave, sin depender de que el servidor de desarrollo esté encendido. Desde el PR #82 la consola lee el retorno con `code`, `token_hash` o el fragmento (`src/lib/authCallback.ts`) y, si es una invitación o una recuperación, abre «Define tu contraseña». Las consolas ya instaladas lo reciben con la próxima versión publicada.

## Roles

Entran `administrador`, `soporte` y `qa`, con cuenta activa y segundo factor. Si `admin_requiere_aal2` es 1, `is_admin()` y `rol_consola()` rechazan una sesión `aal1`. Soporte no mueve dinero ni ve los KPI financieros. QA lee colas, pedidos y errores, sin evidencia de disputas.

## Publicación

La clave pública del actualizador está en `src-tauri/tauri.conf.json` (`plugins.updater.pubkey`) y el manifiesto se busca en `https://myworksapp-cl.vercel.app/desktop/update.json`. La clave privada nueva y su contraseña no están en el repositorio: hay que cargarlas como secrets `TAURI_SIGNING_PRIVATE_KEY` y `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`. Las instalaciones hechas con la clave anterior no pueden actualizarse solas; hay que reinstalar una vez. Este cambio no publica el instalador.

## Módulos

20 módulos de menú (`src/shell/nav.ts`) más «Mi cuenta», en el orden del trabajo: Inicio; Operación (Pedidos, Disputas, Tickets de soporte, Reportes y abuso); Personas (Clientes, Profesionales); Dinero (Pagos y escrow, Conciliación Transbank, Liquidaciones, Reembolsos, Finanzas); Contenido (Reseñas, Catálogo, Notificaciones); Empresa (Equipo y roles, Auditoría, Ajustes); Sistema (Salud y monitoreo, Errores de la app). Tickets y Catálogo son de solo lectura.

## Seguridad de las acciones

- Liberar, devolver, rechazar o suspender piden un motivo (las Edge Functions exigen entre 10 y 2.000 caracteres).
- Las acciones con dinero piden otra vez el código TOTP si el último tiene más de 5 minutos (`src/lib/totp.ts`).
- `webpay-release`, `webpay-refund`, `webpay-refund-cancellation`, `webpay-resolve-dispute` e `invitar-colaborador` llaman `is_admin()` con el JWT del usuario (`_shared/require_admin.ts`); una sesión que no es de administrador recibe 403.
- Rechazar a un profesional exige una nota de al menos 10 caracteres (`fijar_verificacion_profesional`). Los documentos se abren con un enlace temporal.
- La sesión se cierra tras 15 minutos sin uso, con aviso a los 13 (`src/lib/idle.ts`).

## Comisión

`comision_servicio_clp` cobra 5 % con un mínimo de $1.000, nunca más que el pago, y la descuenta al profesional. Es lo que muestran Pagos, Liquidaciones y Finanzas. Una orden de cambio cobra al cliente el monto más 8 %.

## Bitácora

La migración `20261120130000_auditoria_consola.sql` crea `auditoria_consola`, el tipo `accion_auditoria_consola` (27 acciones) y 17 RPC `consola_*`. La tabla solo se escribe con `registrar_auditoria()`: el trigger `auditoria_consola_solo_rpc` rechaza UPDATE y DELETE, y solo `is_admin()` la lee. Según el reporte del 20-nov está aplicada en vivo, y las 5 funciones de administrador están redesplegadas.

Las pruebas de permisos `docs/PRUEBAS_RLS_CONSOLA_20261120.sql` están escritas, pero no se han corrido contra Supabase.

## Estado conocido

La prueba de la consola del 20-nov sobre `08154df` encontró 24 errores (1 crítico, 2 altos, 8 medios y 13 bajos). El crítico: el módulo Profesionales responde 403 al leer `trabajadores`, así que hoy no se puede verificar ni rechazar a nadie desde la consola. Ajustes aparece en blanco (403 en `app_config`). El arreglo está en la rama `cursor/consola-bugs`, **sin merge**, junto con la migración `20261120210000_consola_lectura_config_y_disputas.sql`, que no está aplicada.

La invitación por Resend no está activa: falta el secreto `INVITE_PROVIDER=resend` en `invitar-colaborador`. Mientras tanto la invitación sale por Supabase Auth con el SMTP de Resend.
