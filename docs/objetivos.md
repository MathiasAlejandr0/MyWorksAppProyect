# Objetivos del proyecto — MyWorksApp

**Institución:** Duoc UC, sede Puerto Montt · **Asignatura:** Capstone PTY4614
**Equipo:** Mathias Jara Alvarado (Product Owner y Scrum Master), Nicolás Chiguay y Gabriel Valderas.
**Fuente oficial:** `Fase 2/Myworksapp_Informe_Final_PTY4614.docx`, sección 1.6 «Objetivos» (tabla 2) y capítulo de Resultados (tabla 29). Este documento repite esos objetivos y dice dónde se verifica cada uno en el repositorio.

## Objetivo general

Desarrollar y validar, entre agosto y diciembre de 2026, una plataforma multiplataforma (aplicación móvil, sitio web y consola de escritorio) que permita a clientes de Puerto Montt elegir trabajadores de oficio según precio y calificación y contratarlos con pago protegido, de modo que en las pruebas con usuarios al menos el 80 % complete la contratación en menos de 10 minutos y el 100 % de los pagos de prueba quede retenido hasta la conformidad del cliente.

## Objetivos específicos

- **OE1.** Diseñar e implementar un modelo de datos relacional en Supabase/PostgreSQL, en tercera forma normal y protegido con seguridad a nivel de fila (RLS), medido por la proporción de tablas con RLS activo y por el resultado de las pruebas de acceso por rol.
- **OE2.** Implementar en la aplicación móvil y en la web la búsqueda y comparación de profesionales por oficio, comuna, precio y calificación, con orden común en la web y la app por cercanía (en bandas de 1 km), luego calificación y luego precio, medida por el tiempo que tarda un cliente en encontrar y reservar un profesional.
- **OE3.** Integrar el pago con Transbank Webpay Plus y Oneclick, en ambiente de integración, con retención del dinero en garantía hasta la conformidad del cliente, medido por la proporción de pagos de prueba que siguen correctamente el ciclo retenido → liberado o reembolsado.
- **OE4.** Implementar el control del ciclo de vida del trabajo (PIN de inicio, evidencia fotográfica, conformidad y reagendamiento) mediante una máquina de estados en la base de datos, medido por la proporción de trabajos cerrados con evidencia y conformidad y por el rechazo de transiciones inválidas.
- **OE5.** Implementar una consola de escritorio para verificar profesionales y mediar disputas, medida por el número de profesionales verificados en Puerto Montt durante el piloto y por el tiempo de resolución de las disputas.
- **OE6.** Validar la calidad técnica y la aceptación de la plataforma mediante pruebas automatizadas, de carga y con usuarios, medida por la tasa de pruebas aprobadas, la latencia bajo carga y la satisfacción de los participantes.

## Indicadores, metas y verificación

Las rutas que no indican otra cosa son relativas a `MyWorksAppProyect/`.

| OE | Indicador | Meta | Cómo se mide | Dónde se verifica en el repositorio |
|----|-----------|------|--------------|-------------------------------------|
| OE1 | Tablas con RLS activo; accesos indebidos en las pruebas de acceso por rol. | 100 % de las tablas con RLS; 0 accesos indebidos. | Consulta al catálogo de PostgreSQL (`pg_class`, `pg_policies`), suite de pruebas de RLS y auditoría de la base. | `docs/normalizacion.md`, `docs/DICCIONARIO_BASE_DATOS.md`, `docs/pruebas/seguridad/pruebas_seguridad.py`, `docs/pruebas/seguridad_base_datos.md`, `Fase 2/Auditoria_BD_MyWorksApp.docx`. |
| OE2 | Tiempo mediano desde abrir la plataforma hasta confirmar la reserva; profesionales del catálogo con tarifa y nota visibles. | Mediana ≤ 5 minutos; 100 % de los profesionales publicados con tarifa y nota visibles. | Prueba con usuarios cronometrada con tareas guiadas, contrastada con las marcas de tiempo de trabajos y pagos; revisión del catálogo público. | RPC `listar_profesionales_catalogo`; `shared/src/catalog.test.ts`, `myworksapp_app/test/catalog_order_test.dart`, `myworksapp_web/e2e/catalog-order.spec.ts`. |
| OE3 | Pagos de prueba con ciclo correcto; datos de tarjeta almacenados; pedidos pagados con una tarjeta inscrita sin reingresarla. | 100 % con ciclo correcto; 0 datos de tarjeta almacenados; al menos 3 pedidos consecutivos con la misma tarjeta inscrita. | Recorridos de extremo a extremo en vivo; estados y marcas de tiempo de la tabla `pagos` (`autorizado_en`, `liberado_en`, `reembolsado_en`); revisión del esquema. | `shared/src/payments/webpay.test.ts`, `webpay.contract.test.ts`, `oneclick.test.ts`, `checkoutReturn.test.ts`; `docs/RUNBOOK_TRANSBANK_PRODUCCION.md`. |
| OE4 | Trabajos completados con evidencia y conformidad registradas; transiciones inválidas rechazadas. | 100 % y 100 %. | Pruebas automatizadas de la función `transicionar_trabajo` y consulta a las tablas `trabajos` y `fotos_trabajo`. | `myworksapp_app/test/job_transition_matrix_test.dart`, `shared/src/jobs/startPin.test.ts`, `shared/src/jobs/reschedule.test.ts`, `shared/src/evidence/save.test.ts`. |
| OE5 | Profesionales verificados y oficios cubiertos en Puerto Montt; tiempo de resolución de disputas. | Al menos 10 profesionales verificados en 5 o más oficios; disputas resueltas en ≤ 48 h. | Estados de verificación (`trabajadores.estado_verificacion` y `verificacion_eventos`) y diferencia entre `creado_en` y `resuelta_en` en la tabla `disputas`. | `myworksapp_desktop/` (consola) y `myworksapp_desktop/src/authAccess.test.ts`. |
| OE6 | Pruebas automatizadas fallidas; latencia p95 con 200 usuarios virtuales; puntaje Lighthouse; satisfacción (1 a 5) y escala SUS. | 0 fallidas; p95 < 800 ms; Lighthouse ≥ 90; satisfacción ≥ 4,0/5 y SUS ≥ 68, con al menos 5 clientes y 3 profesionales. | Integración continua (GitHub Actions), k6, Lighthouse y la encuesta de prueba con usuarios registrada en la base (`encuestas_testing`, `encuesta_testing_respuestas` y la vista `encuestas_testing_con_puntaje`). | `.github/workflows/`, `docs/pruebas/k6/mwa_carga.js`, `docs/pruebas/prueba_carga_rendimiento.md`; encuesta en la web (`/encuesta`) y en la app (inicio del cliente, «Encuesta de la prueba»). |

## Cumplimiento

Resultados de la tabla 29 del informe final (mediciones al 17-nov-2026).

| OE | Resultado medido | Estado |
|----|------------------|--------|
| OE1 | 57 de 57 tablas con RLS; 6.077 de 6.077 lecturas anónimas de trabajos negadas bajo carga; auditoría de seguridad de la base del 16-nov-2026 con 181 casos aplicables aprobados y 0 fallas. | Cumplido |
| OE2 | Búsqueda por oficio y comuna con tarifa y nota visibles en la app y la web publicada. El tiempo de contratación se mide en la prueba con usuarios del piloto. | Implementado; medición en el piloto |
| OE3 | Retención, liberación, reembolso y disputa con estados correctos en web, app y base en los recorridos en vivo; la plataforma no almacena datos de tarjeta. La tarjeta inscrita en Oneclick sirve para pedidos consecutivos sin reingresarla y se puede reemplazar con «Cambiar tarjeta»; 2 cobros Oneclick autorizados en integración (16-nov-2026). El conteo de 3 pedidos seguidos se registra en el piloto. | Cumplido en integración; conteo en el piloto |
| OE4 | PIN, evidencia, conformidad y liberación recorridos en vivo; las transiciones se aplican solo mediante la función `transicionar_trabajo` y están cubiertas por pruebas automatizadas. | Cumplido |
| OE5 | Consola con segundo factor, verificación de profesionales, mediación, liquidación y roles soporte y QA. El número de profesionales verificados del piloto se informa al cierre del piloto. | Implementado; meta del piloto |
| OE6 | 303 pruebas automatizadas aprobadas y 0 fallidas; p95 de 283 ms con 200 usuarios virtuales (0 de 55.537 peticiones fallidas); Lighthouse 94 (móvil) y 99 (escritorio). La encuesta de satisfacción y SUS está disponible en la plataforma para el piloto. | Técnico cumplido; aceptación en el piloto |

## Estado de la base al 18-nov-2026

Consulta agregada de solo lectura a Supabase (`wxqrfcqifkfgawrnqmnj`), sin datos personales.

| Dato | Valor |
|------|-------|
| Tablas de `public` con RLS | 57 de 57; 129 políticas |
| Profesionales con `estado_verificacion = 'verificado'` | 45, en 12 oficios (incluye las cuentas de demostración) |
| Disputas | 2 registradas, 1 resuelta |
| Respuestas de la encuesta de prueba (SUS) | 0; se responde en https://myworksapp.cl/encuesta |

Después de esa consulta, las migraciones del 20-nov agregaron 3 tablas (`auditoria_consola`, `rate_limit_ventana` y `direcciones_cliente`), todas con `ENABLE ROW LEVEL SECURITY` en su migración. El esquema queda en 60 tablas; el conteo de políticas en vivo no se volvió a medir. `app_config.demo_modo` está en 1 (reporte del 20-nov), así que el conteo de verificados incluye las cuentas demo visibles.
