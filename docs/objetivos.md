# Objetivos del proyecto — My Works App

**Institución:** Duoc UC, sede Puerto Montt · **Asignatura:** Capstone PTY4614 (APT)
**Equipo:** Mathias Alejandro Jara Alvarado, Nicolas Chiguay y Gabriel Valderas (según `README.md`, sección Equipo).
**Estado del documento:** 2026-11-17. Versión del código revisada: `main` en `8b18b3f` (repositorio canónico `nicoussj/Proyecto-Titulo-MyWorksApp`).

## Objetivo general

Desarrollar una plataforma multiplataforma (app móvil Flutter, web React/Vite y consola de escritorio Tauri sobre Supabase) para que una persona pueda elegir a un profesional de oficios según su precio y la calidad de su trabajo, reservar su visita y pagarla de forma segura con Transbank, con tiempos y pagos confiables para el cliente y para el profesional.

## Objetivos específicos

Las rutas que no indican otra cosa son relativas a `MyWorksAppProyect/` (el monorepo de software). `README.md` sin ruta es el de la raíz del repositorio.

Cada objetivo declara qué se mide, la meta y cómo se verifica. Los valores de «Estado actual medido» se obtuvieron el 2026-11-17, salvo que se indique otra fecha, y cada uno dice de dónde sale.

| N° | Objetivo específico | Indicador medible | Meta numérica | Cómo se verifica |
|----|---------------------|-------------------|---------------|------------------|
| 1 | Desarrollar un catálogo de búsqueda de profesionales por oficio, zona, precio y calificación, disponible en la app y en la web, para que el cliente compare y elija con información. | Latencia p95 de `listar_profesionales_catalogo` y de `horarios_libres_profesional` con 200 usuarios virtuales simultáneos, y peticiones fallidas. | p95 ≤ 800 ms y 0 peticiones fallidas con 200 usuarios simultáneos. | Prueba de carga k6 `docs/pruebas/k6/mwa_carga.js` (umbral `rpc_catalogo` y `rpc_horarios_libres` p95 < 800 ms), resultados en `docs/pruebas/resultados/`. Pruebas automáticas `shared/src/catalog.test.ts`, `shared/src/geo/distance.test.ts` y `myworksapp_app/test/zone_match_test.dart`. |
| 2 | Implementar la calificación bidireccional con peso de confianza y un ranking por reputación, para que la calidad real del trabajo ordene el listado después de la cercanía. | Porcentaje de trabajos completados que tienen la calificación del cliente al profesional. | ≥ 90 % de los trabajos completados calificados. | Consulta SQL de solo lectura: trabajos con `estado = 'completado'` que tienen una fila en `calificaciones` con `direccion = 'cliente_a_trabajador'`. Pruebas `myworksapp_app/test/rating_gate_test.dart`, `client_rating_label_test.dart`, `worker_public_stats_test.dart` y `shared/src/repositories/workers.stats.test.ts`. |
| 3 | Integrar el pago con Transbank Webpay Plus y Oneclick mediante Edge Functions, con el dinero retenido hasta la conformidad del cliente y sin capturar datos de tarjeta, para que el pago sea seguro y cómodo. | Porcentaje de pagos de ambiente `integration` que Transbank autoriza (`autorizado_en` con valor) sobre los iniciados. | ≥ 80 % de los pagos iniciados autorizados por Transbank. | Consulta SQL de solo lectura sobre la tabla `pagos`. Pruebas `shared/src/payments/webpay.test.ts`, `webpay.contract.test.ts`, `oneclick.test.ts`, `checkoutReturn.test.ts`, `myworksapp_app/test/payment_guard_test.dart` y `webpay_return_route_test.dart`. Revisión de columnas de `pagos`: no existe columna para el número de tarjeta. |
| 4 | Simplificar la reserva con horas libres del profesional y control de agenda, para que el cliente complete su pedido y su pago en pocos minutos y sin horas duplicadas. | Tiempo mediano entre la creación de la intención de pago y su autorización por Transbank; reservas activas del mismo profesional en el mismo minuto. | Mediana ≤ 120 s; 0 reservas activas duplicadas por profesional y minuto. | Consulta SQL de solo lectura (`pagos.creado_en` frente a `pagos.autorizado_en`). El índice único `trabajos_trabajador_minuto_activo_uidx` impide el duplicado. Pruebas `shared/src/jobs/bookingSlot.test.ts`, `shared/src/jobs/reschedule.test.ts`, `shared/src/scheduling/weeklyHours.test.ts`, `myworksapp_app/test/booking_schedule_test.dart` y `reschedule_rules_test.dart`. |
| 5 | Controlar el ciclo del trabajo con estados válidos, PIN de inicio, ubicación en vivo, cierre conforme y liquidación, para que los tiempos y la liberación del pago sean confiables. | Porcentaje de pagos liberados de ambiente `integration` con su fila de liquidación; transiciones de estado no permitidas aceptadas. | 100 % de los pagos liberados con liquidación; 0 transiciones inválidas en las pruebas. | Consulta SQL de solo lectura que cruza `pagos` y `liquidaciones`. Pruebas `myworksapp_app/test/job_transition_matrix_test.dart`, `job_actor_permission_test.dart`, `service_pin_dialog_logic_test.dart`, `shared/src/jobs/startPin.test.ts` y `shared/src/payments/payout.test.ts`. |
| 6 | Proteger los datos con roles (cliente, profesional, administrador y soporte) y políticas RLS en toda la base, para que ningún usuario lea ni modifique datos ajenos. | Porcentaje de tablas de `public` con RLS activo y porcentaje de casos de seguridad aplicables que pasan. | 100 % de las tablas con RLS y 100 % de los casos aplicables aprobados (0 fallas). | Consulta a `pg_tables.rowsecurity`. Batería `docs/pruebas/seguridad/pruebas_seguridad.py` (185 casos contra la API real) y `docs/pruebas/seguridad_base_datos.md`. Pruebas `shared/src/security/clientRpcGuard.test.ts` y `myworksapp_desktop/src/authAccess.test.ts`. |

## Estado actual medido

| N° | Valor medido | Fecha | Fuente |
|----|--------------|-------|--------|
| 1 | Con 200 usuarios simultáneos (perfil pico), p95 de `rpc_catalogo`: 135 ms y de `rpc_horarios_libres`: 135 ms; con 100 usuarios, 140 y 139 ms. En total 55.537 peticiones, 0 fallidas. En la base hay 45 profesionales con `estado_verificacion = 'verificado'`. | Carga: 2026-11-15, versión `b3d944e`. Profesionales: 2026-11-17. | `docs/pruebas/prueba_carga_rendimiento.md` §4.2 (medición ya documentada en el repositorio). Conteo: consulta de solo lectura a Supabase `wxqrfcqifkfgawrnqmnj`. |
| 2 | 196 de 201 trabajos completados con calificación del cliente: **97,5 %**. La base tiene 196 calificaciones (194 vigentes y 2 en revisión), con puntaje de 2 a 5 y promedio de 4,56. El conteo incluye todos los trabajos de la base, sin separar los de prueba. | 2026-11-17 | Consulta de solo lectura a Supabase `wxqrfcqifkfgawrnqmnj` (`trabajos`, `calificaciones`). |
| 3 | De 25 pagos de ambiente `integration`, 20 tienen `autorizado_en`: **80,0 %**. Los otros 5 están pendientes (3) o anulados (2). La tabla `pagos` no tiene ninguna columna para el número de tarjeta. | 2026-11-17 | Consulta de solo lectura a `pagos`. Columnas revisadas con `information_schema.columns`. |
| 4 | Mediana de 43,6 s entre intención y autorización, p90 de 238,4 s y máximo de 610,5 s, sobre 20 pagos autorizados (creados entre 2026-10-19 y 2026-11-17, incluidas pruebas manuales y automáticas). Duplicados por profesional y minuto: no pueden existir por el índice único. | 2026-11-17 | Consulta de solo lectura a `pagos`. Definición del índice en `docs/DICCIONARIO_BASE_DATOS.md`, tabla `trabajos`. |
| 5 | 5 de 5 pagos liberados de ambiente `integration` tienen liquidación: **100 %**. Las 92 liquidaciones registradas figuran como `transferido`. Pruebas automáticas del módulo compartido: **159 de 159 aprobadas**. | 2026-11-17 | Consulta de solo lectura a `pagos` y `liquidaciones`. Conteo de pruebas: `npm test` en `MyWorksAppProyect/shared`. |
| 6 | 53 tablas en `public`, 0 sin RLS y 110 políticas. Batería de seguridad: 181 de 181 casos aplicables aprobados (0 fallas, 4 no aplican). | Base: 2026-11-17. Batería: 2026-11-16. | Consulta de solo lectura a `pg_tables` y `pg_policies`. Batería: `docs/pruebas/seguridad_base_datos.md`. |

### Otras mediciones de la suite de pruebas (2026-11-17)

| Suite | Resultado | Cómo se midió |
|-------|-----------|---------------|
| Módulo compartido `MyWorksAppProyect/shared` (incluye las pruebas de Edge Functions de `supabase/functions/_shared`) | 159 aprobadas, 0 fallas | `npm test` ejecutado el 2026-11-17 |
| Consola de escritorio `MyWorksAppProyect/myworksapp_desktop` | 5 aprobadas, 0 fallas | `npm test` ejecutado el 2026-11-17 |
| App Flutter `MyWorksAppProyect/myworksapp_app` | CI «Flutter CI» (`flutter analyze` y `flutter test --concurrency=1`) en verde sobre `8b18b3f`. El código tiene 67 archivos `*_test.dart` con 225 declaraciones `test(` o `testWidgets(`. | Estado del workflow en GitHub Actions y conteo de declaraciones en el código. Este conteo no es un resultado de ejecución. |
| Web `MyWorksAppProyect/myworksapp_web` | 6 archivos de prueba Playwright en `e2e/` | Conteo de archivos. |

## Notas de medición

- Los pagos sin ambiente registrado (146 de 171 filas de `pagos`) no pasaron por Transbank, porque ninguno tiene `autorizado_en`. Por eso los indicadores 3, 4 y 5 usan solo los 25 pagos de ambiente `integration`.
- Webpay opera en el ambiente de integración de Transbank, sin cobro comercial real, según `README.md` y `MyWorksAppProyect/docs/RUNBOOK_TRANSBANK_PRODUCCION.md`.
- Las consultas a Supabase fueron agregados de solo lectura. No se leyeron ni se copiaron datos personales.
