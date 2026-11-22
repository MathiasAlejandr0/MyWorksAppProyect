# Consola premium

Rediseño de la consola de escritorio (`myworksapp_desktop`) sobre lo que ya está en `main` (#82 y #83). No se tocó producción, no se abrió un PR y no se aplicó ninguna migración en el proyecto `wxqrfcqifkfgawrnqmnj`.

## Qué quedó

El sistema visual usa tokens en CSS (claro `#F7F8FA` / oscuro `#0F1115`), Inter, radio de 8/12/16 y la marca naranja solo en la acción principal y la selección. No hay desenfoque de fondo, vidrio ni cursor personalizado.

La barra lateral agrupa General, Operación, Personas, Comunicación y Control. Se puede contraer. Arriba están la búsqueda (Ctrl+K), el rango 24 h / 7 / 30 / 90 días en la URL, el aviso de canal en vivo, el tema y la densidad cómoda o compacta. Atajos: `G` luego `P` (pedidos), `G` luego `D` (disputas), `/` busca en la tabla.

Cada sección parte con indicadores calculados en `consola_premium_kpis` y al menos dos gráficos (Recharts) con tabla alternativa para el lector de pantalla. Un número con filtro recorta la vista de abajo por la URL.

| Sección | Ruta | Qué hace |
|---|---|---|
| Inicio | `/resumen` | Ingresos, comisión, pedidos, finalización, satisfacción, disputas, embudo y lo que necesita atención |
| Pedidos | `/pedidos` | Totales, en curso, completados, cancelados, ticket, estados y día de la semana. La ficha sigue leyendo el pedido |
| Disputas | `/disputas` | Abiertas (incluye `abierta` y `en_revision`), SLA, sugerencia marcada como sugerencia, liberar o devolver con frase `LIBERAR` / `REEMBOLSAR` y TOTP contra `webpay-resolve-dispute` |
| Reseñas | `/resenas` | Positivas, negativas, estrellas, temas y comentarios. Fuente `reglas_estrellas`. Ocultar y marcar sospechosa siguen en `consola_moderar_resena` |
| Clientes | `/usuarios` | Altas, activos en 30 días y frecuencia |
| Trabajadores | `/profesionales` | Verificados, oficio y estado de la ficha |
| Verificaciones | `/verificaciones` | Cola pendiente o en revisión, con la misma ficha de aprobar o rechazar |
| Pagos | `/pagos` y pantallas de dinero | Ingresos, comisión, plata pendiente, reembolsos y fallidos. Liberar, liquidar y devolver exigen frase y llaman a las funciones `webpay-*` ya existentes |
| Soporte | `/tickets` | Tickets, reportes de abuso y primera respuesta cuando hay mensajes |
| Notificaciones | `/notificaciones` | Avisos del período y leídos dentro de la app |
| Seguridad | `/seguridad` | Se reestiló. Siguen las 6 pestañas, la defensa, los respaldos y el admin con AAL2 |
| Reportes | `/informes` | El mismo paquete de negocio, con imprimir para PDF |
| Auditoría | `/auditoria` | Hechos de la bitácora por acción y por rol |
| Configuración | `/ajustes` | `app_config` con la política de `is_admin()` que ya está en main |
| Sistema de diseño | `/sistema-diseno` | Componentes y tabla virtual de 10.000 filas |

La prioridad pedida (reseñas, pedidos y disputas) tiene lista, filtro, detalle y confirmación. El resto de las 13 secciones tiene la banda de indicadores y gráficos encima de la operación que ya existía.

## Verificación en Postgres de Supabase

Imagen `supabase/postgres:17.6.1.071` en la red host, PostgREST 14.3 y GoTrue v2.180.0. No se usó el proyecto `wxqrfcqifkfgawrnqmnj`.

Orden aplicado con `ON_ERROR_STOP`:

1. `auth.jwt()`, `auth.uid()` y las tablas `storage.buckets` y `storage.objects`, que el repo no crea.
2. Baseline en inglés `schema_remote_dump.sql`.
3. Las cinco migraciones anteriores a `20260322000001`.
4. El rename a español `20260914000001` a `20260914000006`, antes del archivo de Webpay.
5. El resto de las migraciones de `main`, y al final las dos de esta rama.

Las dos migraciones nuevas se volvieron a ejecutar y terminaron sin error.

Con datos sintéticos y `admin_requiere_aal2=1`:

- Admin con `aal2`: `is_admin()` verdadero. `consola_premium_kpis` de reseñas devolvió 6 indicadores. `consola_premium_clasificar` marcó positiva la reseña de puntualidad y alerta grave la de amenaza. `consola_premium_resenas` con filtro negativas devolvió una fila, fuente `reglas_estrellas`. Prioridad, asignación y reasignación se guardaron.
- Un cliente, aunque tenga `aal2`, recibe `forbidden` en `consola_premium_kpis`.
- El admin con `aal1` no es admin y recibe `forbidden` al cambiar la prioridad.

`origin/feat/ia-ml` se aplicó encima, sin pushear ese merge. Las nueve migraciones `20261122200000` a `20261122260000` corrieron con `ON_ERROR_STOP`. No comparten versión con `20261123010000` ni `20261123020000`. Después se volvieron a aplicar las dos de esta rama y los KPI y el listado de reseñas siguieron respondiendo. El valor de enum que agrega ia-ml es `revisar_moderacion`, distinto de los cuatro de esta rama.

El listado de reseñas falló la primera vez: `puntaje` es `integer` y la función lo devolvía sin casteo. Quedó `f.puntaje::numeric`.

## Qué no quedó

- `supabase start` completo no se usó. Postgres, PostgREST y GoTrue sí. Realtime no entra en esta verificación.
- No hay hora de aceptación ni de término del pedido, ni respuesta pública a una reseña, ni retención a 30/90 días. Esos indicadores quedan en «Sin dato».
- No hay tablero Kanban persistente ni mapa geográfico. La bandeja es lista con plazo, y el lugar se ve como ranking de comunas.
- `feat/ia-ml` sigue sin merge. La consola llama por nombre a `asistente-solicitud` y `moderar-mensaje`. Si no responden, lo dice y no decide. El texto que saldría se redacta: sin RUT, teléfono ni correo.
- Los pagos en vivo no se probaron contra Transbank. El E2E real confirma el diálogo de reembolso y comprueba que no aparece «Disputa actualizada», porque `webpay-resolve-dispute` no está en este entorno. No se movió dinero.
- `?captura=local` sigue solo para el servidor de desarrollo. Las capturas de esta pasada salen de la sesión real, sin ese parámetro.

## Migraciones para aprobar

No aplicar en el remoto hasta el visto bueno de Mathias.

1. `myworksapp_app/supabase/migrations/20261123010000_consola_premium_enum.sql`
   - Valores de bitácora: `asignar_disputa`, `prioridad_disputa`, `reasignar_pedido`, `marcar_resena`.
2. `myworksapp_app/supabase/migrations/20261123020000_consola_premium_analitica.sql`
   - Columnas `disputas.prioridad` y `disputas.asignado_a`.
   - `consola_premium_clasificar`, `consola_premium_kpis`, `consola_premium_resenas`.
   - `consola_premium_prioridad_disputa`, `consola_premium_asignar_disputa`, `consola_premium_reasignar_pedido`.
   - Vista `consola_premium_resenas_base` con `security_invoker`.

En el Postgres local, con datos sintéticos del 1 al 22 de noviembre de 2026, las 14 claves devolvieron indicadores y series. La clasificación de «Llegó puntual y dejó todo limpio» fue positiva, y la de «No llegó y hubo una amenaza» fue negativa con alerta grave. Fuente: `reglas_estrellas`.

## Pruebas

- Unitarias: `npm test` en `myworksapp_desktop`. 30 pruebas, 30 en verde. Incluyen clasificación, variación, redacción de RUT y la ventana virtual de 10.000 filas.
- Playwright de interfaz con `?captura=local`: `e2e/premium.spec.ts` y `e2e/recorrido.spec.ts`, 3 de 3 en verde.
- Playwright contra PostgREST y GoTrue locales, sin `?captura=local`: `e2e/real.spec.ts`, 1 de 1 en verde. Entra con TOTP (aal2), filtra reseñas negativas, busca un pedido, confirma el diálogo de reembolso sin que la disputa quede actualizada, y cancela «Liberar» en pagos.
- `npm run build`: correcto.
- `cargo check` en `src-tauri` con Rust 1.100: correcto.
- `npm run tauri:build -- --debug`: correcto. Binario de depuración y paquetes deb, rpm y AppImage. No se publican.
- Semgrep 1.186 `--config auto` sobre `myworksapp_desktop/src` y las dos migraciones nuevas: 0 hallazgos. El único aviso era un JWT de prueba; ahora se arma en el test y no queda escrito de corrido.

## Capturas

`docs/pruebas/consola-premium/capturas/`

Regeneradas desde la sesión real con aal2, en claro y oscuro: `inicio`, `pedidos`, `disputas`, `resenas`, `clientes`, `trabajadores`, `verificaciones`, `pagos`, `soporte`, `notificaciones`, `seguridad`, `reportes`, `auditoria`, `configuracion`, `sistema-diseno`.

Video corto del recorrido de desarrollo: `docs/pruebas/consola-premium/capturas/recorrido.webm`.

## Aprobaciones que necesita Mathias

1. Aplicar las dos migraciones en el proyecto remoto. Hoy no están aplicadas.
2. Abrir el PR de `feat/consola-premium` hacia `main`. No se abrió.
3. Decidir si `reasignar_pedido`, la prioridad y la asignación de disputas entran a producción. Quedan en bitácora y solo las puede un administrador.
4. Confirmar que el sentimiento siga en reglas de estrellas hasta que `feat/ia-ml` esté en el entorno. La IA, cuando exista, solo propone.
5. Aceptar que las capturas salen de la base local con datos sintéticos, no del historial de Puerto Montt.
