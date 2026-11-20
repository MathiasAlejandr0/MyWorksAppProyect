# Registro de pruebas — 15 de noviembre de 2026

> **Documento histórico.** Registra el estado del proyecto a la fecha de su última revisión (15-11-2026) y no se actualiza. Las cifras, URL y pantallas que nombra pueden haber cambiado. El estado vigente (20-11-2026, `main` `08154dfc`) está en [`ESTADO_DEL_PROYECTO.md`](../../../ESTADO_DEL_PROYECTO.md).

Corrida en esta máquina, hora de Chile. El proyecto medido es `wxqrfcqifkfgawrnqmnj`. Los JSON de k6 están en `k6/` y los de latencia y de la web en `rendimiento/`. No se usó la clave `service_role`. No se llamó a Webpay ni a `guest-checkout` en la carga.

Commit de referencia del código medido: `8fa913e`, más el ajuste del test de GPS para soltar el temporizador del mapa. Después de esa corrida, `main` avanzó hasta `2f3925c`. Esos commits no se volvieron a medir aquí.

## 1. Pruebas automatizadas

| Tipo | Comando | Resultado |
|---|---|---|
| Flutter, unitarias y de widgets | `flutter test` en `myworksapp_app` | 174 aprobadas, 0 fallas. La primera pasada dio 173 y 1 falla: el mapa del selector de ubicación dejaba un temporizador de baldosas. Tras soltarlo, la suite completa quedó en verde. |
| Módulo compartido y funciones | `npm test` en `shared` | 110 aprobadas, 39 suites, 0 fallas. Incluye Webpay, filtro de contacto del chat, estados y payout manual. |
| Escritorio | `npm test` en `myworksapp_desktop` | 2 aprobadas: el hub solo deja entrar al administrador. |
| Web, extremo a extremo | `npm run test:e2e` (Playwright, Chromium, preview local) | 17 aprobadas y 1 omitida. La omitida es la invitación de RRHH: pide el preview del escritorio y no estaba levantado. |
| Latencia de un cliente | `node scripts/load/rendimiento-latencia.mjs`, 30 muestras | Ver la tabla de abajo. |
| Bundle y LCP | `node scripts/load/rendimiento-web.mjs`, preview `127.0.0.1:4174`, viewport 1366×768 | JS gzip 211451 bytes (206,5 KB). CSS gzip 16217 bytes (15,8 KB). LCP 424 ms. TTFB 2,5 ms. |

La suite de Flutter cubre el caso de GPS colgado: si no hay posición, la solicitud usa Puerto Montt y no se queda en «Obteniendo…».

## 2. Latencia de lectura, un usuario

Medido de 12:13 a 12:15. p95 en milisegundos. Error 0 salvo la fila marcada.

| Endpoint | p95 | Lectura |
|---|---:|---|
| REST servicios activos | 247 | 200, 13 filas |
| REST trabajadores (columnas públicas, anon) | 228 | 200, 0 filas |
| REST `SELECT *` de un trabajador | 231 | 401 en las 30 muestras |
| RPC `categorias_con_disponibles` | 222 | 200, 12 oficios |
| RPC catálogo gasfitería | 233 | 200, con filas |
| RPC catálogo plomería | 383 | 200, con filas |
| RPC huecos de dos profesionales, 14 días | 228 y 232 | 200 |

El `SELECT *` responde 401 porque anon ya no puede leer `latitud_base`, `longitud_base` ni la nota. El listado con columnas públicas sigue en 200 y sin filas: la política de fila no abre la tabla al visitante. El catálogo visible es el RPC, y ese sí devuelve profesionales.

## 3. Carga (k6), solo lecturas

De 12:16 a 12:52. Las nueve corridas terminaron con código 0 y checks sin fallas. El porcentaje de error HTTP fue 0. El RPS es el promedio de todo el escenario, rampa incluida.

| Prueba | VUs máx | p95 (ms) | RPS | Peticiones | Recibido |
|---|---:|---:|---:|---:|---:|
| Catálogo smoke | 5 | 244 | 6,7 | 208 | 0,2 MB |
| Catálogo baseline | 50 | 232 | 47,5 | 8.608 | 7,9 MB |
| Catálogo stress | 200 | 235 | 175 | 63.002 | 57,6 MB |
| Reserva smoke | 5 | 286 | 8,9 | 270 | 0,7 MB |
| Reserva baseline | 30 | 237 | 35,9 | 6.522 | 17,5 MB |
| Reserva stress | 80 | 247 | 95,1 | 24.369 | 65,2 MB |
| Techo Free, 100 a 300 VUs | 300 | 236 | 308 | 92.542 | 84,8 MB |
| Techo de llegadas | 63 | 224 | 58 | 13.857 | 6,5 MB |
| Soak, 40 VUs × 10 min | 40 | 229 | 56 | 33.706 | 30,5 MB |

En la reserva a 80 VUs el máximo del RPC de huecos fue 1381 ms. Queda bajo el umbral de 2000 ms (RNF-04). El techo Free cumple p95 menor a 500 ms y error menor a 1 %.

No se corrió `mixed-read.js`: hace falta un JWT de un usuario de prueba y no se fabricó uno. La corrida del 8 de noviembre, con la sesión de Camila, sigue siendo la última de ese perfil.

## 4. Scripts SQL de RLS

Corridos contra el proyecto en vivo, con transacción que hace `ROLLBACK` cuando el script la trae. No dejaron filas.

| Script | Resultado |
|---|---|
| `PRUEBAS_RLS_20261010.sql` | `RLS 20261010 ok` |
| `PRUEBAS_RLS_20261011.sql` | Las afirmaciones de privilegios, catálogo verificado, `FOR UPDATE` y tarifa publicada pasan. La frase literal «no está verificado» ya no está dentro de `monto_esperado_trabajo`, así que el archivo, copiado tal cual, se detiene ahí. |
| `PRUEBAS_RLS_20261009.sql` | Se detiene en el índice `calificaciones_trabajo_usuario_uidx`. El índice único vigente es `calificaciones_trabajo_direccion_uidx` sobre `(id_trabajo, direccion)`. Las afirmaciones anteriores (token de pago, `SELECT` de tabla para anon, y que el cliente no actualice calificación ni verificación) pasan. Si se salta el nombre viejo del índice, el script vuelve a parar porque el catálogo ahora redondea la base: esa afirmación es del 9 de octubre y contradice el cierre del 15 de noviembre. El resto (nota fuera del catálogo, profesional verificado al crear el trabajo, cotizaciones, `is_admin` y `demo_modo`) pasa. |
| `PRUEBAS_RLS_20261008.sql` | No se volvió a ejecutar entero. La afirmación que exige `EXECUTE` de `listar_cuentas_demo_acceso` para anon queda en falso a propósito: esa función ya no es ejecutable por anon ni por authenticated. |

Medición directa de privilegios, la misma hora: anon y authenticated no pueden hacer `SELECT` de `latitud_base`. Anon no puede ejecutar el listado demo.

`PRUEBAS_AUDITORIA_20261009.sql` no se corrió en esta pasada. Ese archivo se hace pasar por usuarios de la demo y queda para una corrida aparte.

## 5. Matriz del flujo crítico

La guía pide la matriz en las tres interfaces. Hoy se recorrió la web automática y una búsqueda real. No se repitió el cobro con tarjeta ni el recorrido en el teléfono ni en el hub.

| ID | Caso | Dónde | Esperado | Estado |
|---|---|---|---|---|
| P-01 | Portada con buscador | Playwright | Se ve «My Works App» y «Buscar servicio» | OK |
| P-02 | Ingresar abre el modal vacío | Playwright | Modal de inicio de sesión | OK |
| P-03 | Oficio sin profesionales | Playwright | La categoría se oculta y la búsqueda vacía se explica | OK |
| P-04 | Catálogo y pedido sin pedir el número de tarjeta en el sitio | Playwright | El modal de pago y el invitado no piden el PAN | OK |
| P-05 | Barras y chat a 1280 y a 390 | Playwright | El ingreso, la reserva, el monto y el chat quedan dentro de la ventana | OK |
| P-06 | Política de contraseña y correo sin confirmar | Playwright | 8 caracteres, letra y número; el login ofrece reenviar la confirmación | OK |
| P-07 | Buscar plomería en la web en marcha | Navegador, `127.0.0.1:5173` | Lista y mapa del oficio | OK. Se vieron 3 profesionales y el mapa CARTO |
| P-08 | Cobro Webpay de integración, de punta a punta | App, web y escritorio | Pago retenido y luego liberado | No repetido hoy. La última pasada viva sigue descrita en `DEMO.md` |
| P-09 | Mismo flujo en el teléfono | App Flutter | Solicitud, estados, evidencia y cobro | No corrido en un dispositivo hoy |
| P-10 | Hub de escritorio | Tauri | Soporte y liquidación | No se abrió el hub. El test de rol sí pasó, y el e2e de invitación quedó omitido |

## 6. Cómo queda cada requisito no funcional del informe

| ID | Meta del informe | Esta corrida |
|---|---|---|
| RNF-01 | Pantalla bajo 2 s | LCP local 424 ms en el preview de hoy. El 8 de noviembre el mismo script midió 3.192 ms, con otras imágenes. Esta cifra es del preview local, no de una CDN. |
| RNF-02 | RLS por rol | 20261010 ok. Privilegios de la base y del listado demo medidos. Falta la pasada que se hace pasar por Camila, Pedro y el admin (`PRUEBAS_AUDITORIA_20261009.sql`). |
| RNF-03 | Español de Chile en agenda, detalle y pagos | No se recorrieron esas pantallas a mano hoy. El formato `es_CL` sigue en el código que cita el informe. |
| RNF-04 | p95 de reserva bajo 2 s a 80 VUs | 247 ms. Cumple. |
| RNF-05 | Error de lecturas bajo 5 %, y soak | Error 0 en todas las corridas, soak de 10 minutos incluido. Cumple para lecturas. |
| RNF-06 | Dirección exacta solo después de aceptar | No se verificó en la API con dos sesiones hoy. |
| RNF-07 | El chat bloquea contacto externo | Cubierto por `containsContactData` en los 110 tests del módulo compartido: bloquea correo, teléfono, enlace y evasión, y deja pasar el texto del trabajo. |
| RNF-08 | Misma base en la app y en la web, varios tamaños | Playwright cubre 1280 y 390. No hay matriz de navegadores ni de teléfonos físicos. |
| RNF-09 | Regresión automatizada | Flutter 174, web 17, shared 110, escritorio 2. Todas en verde, con la omisión ya dicha. |
| RNF-10 | La carga se puede repetir | Mismos scripts del runbook. Resultados en esta carpeta. |

## 7. Qué no entra en esta corrida

Escrituras masivas, pagos y `guest-checkout` no se estresaron. El runbook los deja fuera para no crear cobros ni cuentas. El techo de 300 usuarios es de gente mirando el catálogo, no de gente pagando.
