# Auditoría integral — 2026-10-05

Rama: `fix/auditoria-integral` (desde `main` d0086de). BD de la demo: `wxqrfcqifkfgawrnqmnj`.
Alcance: funcionalidad, seguridad y calidad. Partió revisando lo que ya se había pedido
(`docs/CHECKLIST_REPARACIONES.md`, `docs/REMEDIACION_AUDITORIA.md`, `docs/AUDITORIA_2026-09.md`,
`DEMO.md`, PRs de este repo y de `nicoussj/Proyecto-Titulo-MyWorksApp`) para ver si de verdad
estaba resuelto.

Fuera de alcance (otra rama en paralelo): la tarjeta «Ganancias totales», el build sentry/Kotlin,
el fallback de ubicación y cercanía en `worker_repository`, el error «jardinera» y el README raíz.

## Resultado de las herramientas

| Área | Resultado |
|------|-----------|
| `flutter analyze` | sin problemas |
| `flutter test` | todas pasan (65 en d0086de; 84 tras rebase sobre main 109dad7, incluida la prueba nueva de credenciales) |
| Web `npm run lint` | 0 errores, 4 avisos de oxlint ya existentes |
| Web `npm run build` | OK |
| Playwright | antes: 13 pasan, 1 omitida, 2 fallan (seguimiento a 1280/390). La falla era del arnés: el mock esperaba `example.supabase.co` y el build tomaba la URL real de `.env.local`. Además la prueba a 390 era intermitente: el clic en «Abrir chat» podía dejar el mapa fuera de pantalla. Corregido en `e2e/layout-viewports.spec.ts` (llave de sesión y mocks según la URL del build, y el mapa se trae a la vista antes de medir). Después: 15 pasan y 1 omitida en cada corrida (`--repeat-each 2`: 30/30) |
| Semgrep (p/default, p/secrets, p/typescript, p/react) | 6 hallazgos, ninguno real: llave pública de integración de Transbank en `tbk.ts` (documentada), regex no literales y `spawn shell:true` en scripts locales |
| Advisors de seguridad | `rls_enabled_no_policy` en `app_config` y `metodos_pago_oneclick` (corregido); protección de contraseñas filtradas apagada; 3 SECURITY DEFINER para anon (catálogo y acceso demo, intencionales) y 28 para authenticated (revisadas, validan dentro) |
| Advisors de rendimiento | 8 índices sin uso; políticas permisivas múltiples en 8 tablas |
| Secretos | árbol actual limpio (solo `.env.example`). Las llaves de Google Maps del commit `4e1e735` siguen en el historial (se quitaron en `9f9e0c2`) |

## Backlog priorizado

### P0

| # | Hallazgo | Evidencia | Estado |
|---|----------|-----------|--------|
| P0-1 | `admin@demo.com` era `administrador` activo con la contraseña `demo123` publicada en el repo, y `admin_requiere_aal2=0`. Cualquiera podía entrar como admin a la BD de la demo. El arreglo pedido antes («demo123 no entra») solo se había hecho en el cliente | antes: `is_admin()` como ese usuario = `true`, último ingreso registrado | **Corregido**: `20261008000012_suspender_admin_legado.sql` (antes `20261009000001`) (perfil `suspendido` y `banned_until`). Login por Auth ahora responde `user_banned` |

### P1

| # | Hallazgo | Evidencia | Estado |
|---|----------|-----------|--------|
| P1-1 | Las transiciones de estado validaban la matriz y el pago en la BD, pero no **quién** las pedía (eso vivía solo en `JobStateMachine` de Dart). El cliente podía pasar su trabajo a `en_curso`/`esperando_aprobacion_cliente`, y cualquiera de las partes podía marcar `no_asistio` con el dinero retenido | antes: Camila → `en_curso` en `demo-job-en-camino` = «PASO» | **Corregido**: `20261009000002_transiciones_por_actor.sql` |
| P1-2 | `perfiles_publicos_por_ids` devolvía nombre y foto de cualquier perfil a cualquier usuario autenticado | antes: perfil de un usuario sin relación = 1 fila | **Corregido**: `20261009000003_perfiles_publicos_restringidos.sql` (propio, admin, profesionales, autores de reseñas y contraparte de un trabajo compartido) |
| P1-3 | Flujo de liquidaciones: 87 pagos `liberado` del seed sin `liberado_en` y 0 filas en `liquidaciones`; la auditoría del escritorio salía vacía | `count(liquidaciones)=0`, `liberado_en IS NULL` en 87 pagos | **Corregido**: `20261009000005_liquidaciones_demo.sql` (solo filas `demo-%`, aditiva) y `scripts/demo/seed_demo.sql` |
| P1-4 | El autocompletado de login en depuración usaba `usuario@demo.com`/`admin@demo.com`/`trabajador@demo.com` con `demo123`; con el selector de profesionales rellenaba `demo123` para cuentas que usan `Demo2026!`, así que el login fallaba | `lib/core/config/demo_credentials.dart` | **Corregido** (sigue tras `kDebugMode`) + `test/demo_credentials_test.dart` |
| P1-5 | `app_config` y `metodos_pago_oneclick` con RLS y sin políticas (advisor) | advisor `rls_enabled_no_policy` | **Corregido**: `20261009000004_rls_explicita_config_oneclick.sql` (deniega explícito a anon y authenticated; las RPC y funciones edge siguen operando) |
| P1-6 | 17 cuentas `@demo.com` no administradoras siguen activas con `demo123` | `auth.users` | **Corregido** el 2026-10-05, después de la grabación: 17 cuentas baneadas (`banned_until = 2999-12-31`). Ver «Cierre post-demo» |
| P1-7 | Protección de contraseñas filtradas (HIBP) apagada | advisor `auth_leaked_password_protection` | **Acción del dueño**: Dashboard → Auth → Password security (requiere plan Pro) |
| P1-8 | Llaves de Google Maps en el historial (`4e1e735`) | `git show 4e1e735` | **Acción del dueño**: rotar o restringir por referrer/paquete en GCP |

### P2

- `demo_modo=1` y `admin_requiere_aal2=0`: correctos para la demo, se deben revertir después. Con `demo_modo=1`, `listar_cuentas_demo_acceso` expone a anon los correos de la demo.
- `vincular_trabajador_solicitud` no revisa `trabajador_reservable` (el pago sí exige profesional verificado).
- El PIN de servicio en `metadatos_servicio` lo podría leer y editar el profesional. Hoy no se usa (0 trabajos con PIN; `ServicePinDialog` es código muerto).
- El cliente puede editar `metadatos_servicio` (tier, m²) antes de pagar.
- `webpay-handoff` devuelve el mensaje de error crudo en un 500.
- `JobStateMachine._validatePermission` en Dart quedó distinto de la BD (para el cliente incluye `aceptado`/`en_curso`). La BD manda; conviene alinearlo para no mostrar botones que fallan.
- 8 índices sin uso y políticas permisivas múltiples en 8 tablas.
- PRs de dependabot abiertas en ambos repos.
- Falta el código de comercio productivo de Transbank (ya estaba en el checklist).

## Reglas nuevas de transición (20261009000002)

- Solo el profesional: `aceptado`, `en_camino`, `en_curso`, `esperando_aprobacion_cliente`, `pausado_orden_cambio`, `no_asistio`.
- El cliente también puede volver a `en_curso`, pero solo desde `pausado_orden_cambio` (aprueba la orden de cambio).
- Solo el cliente: `cotizacion_seleccionada`, `esperando_pago`.
- Ambas partes: `pendiente`, `expirado`, `cancelado` (con los controles de pago y disputa que ya existían).
- `no_asistio` se bloquea si hay pago retenido; se cierra con una disputa.
- El admin no tiene restricción de actor.

## Verificación

- Las 5 migraciones están aplicadas en la demo (`list_migrations`, versiones `20261005034318`–`20261005034340`).
- `docs/PRUEBAS_AUDITORIA_20261009.sql` contra la BD en vivo (transacción con rollback forzado):
  `admin@demo.com is_admin=false y baneado; admin.ops is_admin=true | Camila->en_curso: solo el profesional del trabajo puede pasar a en_curso | pro->no_asistio: hay un pago retenido; abre una disputa para cerrar por inasistencia | guion Pedro en_curso->esperando_aprobacion->Camila conforme: completado | perfil ajeno visible: 0 | liquidaciones=88 pagos_liberados=88`
  (88 dentro de la prueba porque cierra un trabajo más; en la BD real quedan 87/87).
- Login por Auth con `Demo2026!`: Camila Soto, Carmen Lagos y admin.ops responden 200; `admin@demo.com`/`demo123` responde 400 `user_banned`.
- Estados de los trabajos del guion sin cambios: pendiente, aceptado, en_camino, en_curso, esperando_aprobacion_cliente, completado, en_curso (disputa).
- Advisors después de aplicar: ya no aparece `rls_enabled_no_policy`.
- El bloque nuevo del seed, probado con rollback: antes 0 liquidaciones demo, después 87, 0 pagos sin `liberado_en`.

## Pendiente para el dueño

1. Activar la protección de contraseñas filtradas.
2. Rotar o restringir las llaves de Google Maps del historial.
3. ~~Después de la grabación: banear las cuentas `@demo.com`, poner `demo_modo=0` y `admin_requiere_aal2=1`.~~ Hecho el 2026-10-05 (ver «Cierre post-demo»).
4. Código de comercio productivo de Transbank.

Revertir (si hiciera falta): `20261008000012` trae el SQL de reversa en sus comentarios; 000002 y 000003 redefinen funciones (se revierten reaplicando la versión anterior: `20261001000001_reembolso_una_vez_y_cancelacion.sql` y `20261008000002_perfiles_publicos_rpc.sql`); 000004 se revierte con `DROP POLICY`; 000005 solo agrega filas `demo-liq-%`.

## Cierre post-demo (2026-10-05)

Hecho después de terminar la grabación de los videos. Antes se comprobó que no quedaran datos de grabación a medias: 0 trabajos, pagos, cotizaciones, mensajes, disputas o reseñas creados o tocados en los últimos 4 días.

**Repositorio**

- `20261009000001_suspender_admin_legado.sql` pasó a `20261008000012_suspender_admin_legado.sql`. La versión `20261009000001` queda solo para `catalogo_geografico`; la CLI de Supabase no acepta dos archivos con la misma versión. El contenido no cambió y sigue corriendo antes de `20261009000002`–`000005`.

**BD de la demo (`wxqrfcqifkfgawrnqmnj`)**

- `auth.users`: 17 cuentas `@demo.com` baneadas (`banned_until = 2999-12-31`). Las 18 `@demo.com` quedan bloqueadas. Las cuentas `@demo.myworksapp.cl` no se tocaron.
- `app_config`: `demo_modo` 1 → 0 y `admin_requiere_aal2` 0 → 1. `admin.ops@demo.myworksapp.cl` no tiene factor MFA inscrito: para entrar al panel tendrá que inscribir TOTP primero.
- `supabase_migrations.schema_migrations` (solo metadatos, no se volvió a ejecutar nada): las filas que el MCP registró con marca de tiempo pasaron a la versión del archivo: `20260930061852` → `20261008000009`, `20260930070618` → `20261008000010`, `20261005034318` → `20261008000012`, `20261005034334` → `20261009000002`, `20261005034336` → `20261009000003`, `20261005034338` → `20261009000004`, `20261005034340` → `20261009000005`. Se registró `20261008000011_categoria_jardineria`, que ya estaba aplicada a mano (0 filas `jardinera`).
- Sin registrar a propósito:
  - `20261009000001_catalogo_geografico`: no está aplicada (no existen `paises`, `regiones` ni `comunas`).
  - `20261010000001_ranking_y_resenas`: aplicada a mano casi entera, pero faltan la función `_evaluar_resena_trigger()` y el trigger `calificaciones_evaluar_resena`.
  - Las dos las decide su autor antes de registrarlas.
- Las filas anteriores a `20261008000009` siguen con versiones de marca de tiempo (fuera de este cierre).

Revertir lo de la BD:

```sql
UPDATE auth.users SET banned_until = NULL WHERE email ILIKE '%@demo.com' AND email <> 'admin@demo.com';
UPDATE public.app_config SET valor = '1' WHERE clave = 'demo_modo';
UPDATE public.app_config SET valor = '0' WHERE clave = 'admin_requiere_aal2';
```

Sigue pendiente para el dueño (no se resuelve desde el código):

1. Protección de contraseñas filtradas en Supabase Auth (requiere plan Pro).
2. Rotar o restringir las llaves de Google Maps que quedaron en el historial.
3. Código de comercio productivo de Transbank.
