# Consola de escritorio MyWorksApp

Back office de la empresa: clientes, profesionales, pedidos, pagos en garantía, disputas, equipo y salud del sistema. Es una app Tauri 2 con interfaz React. La autorización de verdad está en Postgres (`is_admin()`, `rol_consola()`) y en las Edge Functions, no en la pantalla.

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

Esquema `myworksapp-admin`, ruta `auth/callback`. Sirve para definir la contraseña después de una invitación o de recuperar la clave, sin depender de que el servidor de desarrollo esté encendido.

## Roles

Entran `administrador`, `soporte` y `qa`, con cuenta activa y segundo factor. Si `admin_requiere_aal2` es 1, `is_admin()` y `rol_consola()` rechazan una sesión `aal1`. Soporte no mueve dinero ni ve los KPI financieros. QA lee colas, pedidos y errores, sin evidencia de disputas.

## Publicación

La clave privada del actualizador no está en el repositorio. Hay que generarla con `npx tauri signer generate` y guardarla como secreto de CI. La clave pública va en `src-tauri/tauri.conf.json` (`plugins.updater.pubkey`). Este cambio no publica el instalador.

## Comisión

`comision_servicio_clp` cobra 5 % con un mínimo de $1.000. El caso de uso CU-30 dice 15 %. No se cambió el cálculo.

## Bitácora

La migración `20261120120000_auditoria_consola.sql` crea `auditoria_consola`. No está aplicada en la base remota. Las funciones `webpay-release`, `webpay-resolve-dispute`, `webpay-refund` e `invitar-colaborador` tampoco están redesplegadas.
