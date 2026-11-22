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

## Qué no quedó

- No hay Docker ni CLI de Supabase en esta máquina, así que no se levantó el stack completo (`supabase start`). Las funciones se ejecutaron en PostgreSQL 16 local con un arnés que imita `rol_consola`, `is_admin`, `texto_a_timestamptz`, `disputa_esta_activa` y `comision_servicio_clp`, y con filas sintéticas. El arnés está en `myworksapp_desktop/scripts/validar-premium.sql`. No es una migración.
- Las capturas y el video usan `?captura=local`, que solo existe con el servidor de desarrollo. Muestran datos sintéticos y un cartel de que no es producción y no mueve dinero. No hay una réplica con el historial real.
- La rama `feat/ia-ml` no está en este entorno. La consola llama por nombre a `asistente-solicitud` y `moderar-mensaje`. Si no responden, lo dice y no decide. El sentimiento de reseñas sale de estrellas y reglas de texto (`reglas_estrellas`). No se envía RUT, teléfono ni correo: el texto se redacta antes.
- No hay fecha de aceptación ni de término del pedido. Esos dos indicadores quedan en «Sin dato» a propósito. La retención a 30/90 días tampoco se inventa.
- No hay columna de respuesta pública a una reseña. La tasa de respuesta queda en «Sin dato».
- No hay tablero Kanban persistente ni mapa geográfico. La bandeja es lista con plazo, y el lugar se ve como ranking de comunas.
- `cargo` de esta máquina es 1.83 y no puede resolver dependencias que piden la edición 2024 de Rust. El código Rust no se modificó. `npm run build` (el paso de interfaz que usa Tauri antes de empaquetar) sí compiló.
- El servidor MCP de Semgrep no estaba disponible y no hay CLI de Semgrep instalada. No se pudo correr el análisis sobre el diff.
- Los pagos en vivo no se probaron contra Transbank. Las pruebas confirman el diálogo y se detienen. En la captura, el aviso es «no se envió dinero».

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
- Fin de extremo: `npx playwright test e2e/premium.spec.ts e2e/recorrido.spec.ts`. 3 pruebas, 3 en verde. Cada sección carga en claro y oscuro, axe sin hallazgos de impacto crítico, pedidos filtra, disputas confirma `REEMBOLSAR` sin llamar a Transbank, reseñas filtra negativas y abre el detalle, y la tabla virtual pinta menos de 40 filas de 10.000 y llega a la fila 10000.
- `npm run build`: correcto.

## Capturas

`docs/pruebas/consola-premium/capturas/`

Claro y oscuro: `inicio`, `pedidos`, `disputas`, `resenas`, `clientes`, `trabajadores`, `verificaciones`, `pagos`, `soporte`, `notificaciones`, `seguridad`, `reportes`, `auditoria`, `configuracion`, `sistema-diseno`.

Video: `docs/pruebas/consola-premium/capturas/recorrido.webm`.

## Aprobaciones que necesita Mathias

1. Aplicar las dos migraciones en el proyecto remoto. Hoy no están aplicadas.
2. Abrir el PR de `feat/consola-premium` hacia `main`. No se abrió.
3. Decidir si `reasignar_pedido`, la prioridad y la asignación de disputas entran a producción. Quedan en bitácora y solo las puede un administrador.
4. Confirmar que el sentimiento siga en reglas de estrellas hasta que `feat/ia-ml` esté en el entorno. La IA, cuando exista, solo propone.
5. Aceptar que las capturas son de la captura local de desarrollo, no de la base de Puerto Montt.
