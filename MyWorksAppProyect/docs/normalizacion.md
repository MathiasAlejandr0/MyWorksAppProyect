# Normalización del modelo de datos (hasta la cuarta forma normal)

Este documento explica qué son las formas normales y muestra, con tablas reales de MyWorksApp, dónde se aplica la **cuarta forma normal (4FN)**. Se revisó el esquema `public` de la base viva (proyecto Supabase `wxqrfcqifkfgawrnqmnj`, 17-11-2026, 57 tablas, última migración `20261117223850`). La lista completa de tablas y sus diagramas está en [`modelo-datos.md`](modelo-datos.md).

Las 3 tablas agregadas el 20-11-2026 (`auditoria_consola`, `rate_limit_ventana` y `direcciones_cliente`) no se analizan aquí. Cada una tiene una clave propia y columnas que dependen solo de ella.

**Lectura del 23-11-2026.** `mensajes.id_destinatario` y las cifras de `trabajadores` las escribe solo un trigger desde el trabajo o la estadística, porque la expresión no cabe en `GENERATED ALWAYS`; `tickets_soporte` ya no guarda nombres ni monto; y `bloqueos_ip`, `cola_moderacion`, `eventos_acceso`, `ia_banderas`, `ia_cambios_banco`, `ia_cola_embeddings`, `ia_huellas`, `ia_pesos_busqueda`, `ia_resumen_resenas`, `ia_sugerencias_perfil`, `incidentes_seguridad`, `pruebas_seguridad`, `respaldos_consola`, `ticket_mensajes` y `umbrales_seguridad` quedan en BCNF.

**Lectura del 22-11-2026.** La base viva tiene 76 tablas en `public` (76 con RLS) y la última migración registrada es `20261123020000`. Quince de esas tablas no están en el diccionario del 17-11 ni en el anexo del 20-11: `bloqueos_ip`, `cola_moderacion`, `eventos_acceso`, `ia_banderas`, `ia_cambios_banco`, `ia_cola_embeddings`, `ia_huellas`, `ia_pesos_busqueda`, `ia_resumen_resenas`, `ia_sugerencias_perfil`, `incidentes_seguridad`, `pruebas_seguridad`, `respaldos_consola`, `ticket_mensajes` y `umbrales_seguridad`. Se miraron solo la clave primaria y las columnas: la clave es de una columna y el resto describe esa fila, así que no hay lista en una celda ni dependencia de una parte de una clave compuesta. La lectura del 23-11-2026 les asigna BCNF. El veredicto de la sección 4 sigue valiendo para las tablas que ese texto nombra, no para las 76.

## 1. Qué es normalizar

Normalizar es ordenar los datos en tablas para que cada hecho se guarde **una sola vez**. Así se evitan datos repetidos, contradicciones al actualizar y filas que no se pueden borrar sin perder otra información. Cada forma normal agrega una regla a la anterior.

| Forma normal | Regla en palabras simples | Ejemplo en MyWorksApp |
|---|---|---|
| **1FN** (primera) | Cada celda guarda un solo valor, no una lista, y la tabla tiene clave primaria. | En `trabajador_servicios` cada fila tiene un solo oficio; no hay una celda con «gasfitería, plomería». |
| **2FN** (segunda) | Cumple la 1FN y, si la clave tiene varias columnas, cada dato depende de **toda** la clave, no de una parte. | En `trabajador_precios` la clave es (`id_usuario`, `codigo`) y `monto_clp` depende de ambas: el precio es de ese profesional **y** de ese servicio. |
| **3FN** (tercera) | Cumple la 2FN y ningún dato depende de otro dato que no sea clave. | En `comunas` el nombre y la ubicación dependen solo de la comuna; la región se obtiene por `id_region`. |
| **BCNF** (Boyce-Codd) | Cumple la 3FN y todo lo que determina a otra columna es una clave candidata. | En `calificaciones` la combinación (`id_trabajo`, `direccion`) es única y determina el resto de la fila. |
| **4FN** (cuarta) | Cumple la BCNF y una tabla no mezcla **dos listas independientes** de un mismo dueño. | Los oficios y las fotos de portafolio de un profesional están en tablas distintas. |

## 2. La cuarta forma normal en detalle

### 2.1 Dependencia multivaluada

Un mismo dueño (por ejemplo, un profesional) puede tener **varios** valores de una cosa (varios oficios) y, a la vez, **varios** valores de otra cosa (varias fotos). Si las dos listas no tienen relación entre sí, se dice que hay una **dependencia multivaluada**: el profesional «determina un conjunto» de oficios y, por separado, un conjunto de fotos. Se escribe así:

`id_trabajador ↠ categoria_servicio` | `id_trabajador ↠ ruta_foto`

### 2.2 El problema que resuelve la 4FN

Si las dos listas se guardan en la misma tabla, hay que combinar cada oficio con cada foto, porque no hay forma de saber cuál va con cuál. Ejemplo ilustrativo (datos inventados, no de la base):

**Tabla única (sin 4FN):** `profesional_oficio_foto (id_trabajador, categoria_servicio, ruta_foto)`

| id_trabajador | categoria_servicio | ruta_foto |
|---|---|---|
| P1 | gasfiteria | foto_1.jpg |
| P1 | gasfiteria | foto_2.jpg |
| P1 | gasfiteria | foto_3.jpg |
| P1 | plomeria | foto_1.jpg |
| P1 | plomeria | foto_2.jpg |
| P1 | plomeria | foto_3.jpg |

2 oficios × 3 fotos = **6 filas**. Agregar un tercer oficio obliga a insertar 3 filas más, y borrar una foto obliga a borrar una fila por cada oficio. Se repite información y es fácil que quede inconsistente.

**Separadas (4FN):**

`trabajador_servicios (id_trabajador, categoria_servicio)`

| id_trabajador | categoria_servicio |
|---|---|
| P1 | gasfiteria |
| P1 | plomeria |

`portafolio_trabajador (id, id_trabajador, ruta_foto, …)`

| id | id_trabajador | ruta_foto |
|---|---|---|
| a1 | P1 | foto_1.jpg |
| a2 | P1 | foto_2.jpg |
| a3 | P1 | foto_3.jpg |

2 + 3 = **5 filas**, sin repetir nada. Agregar un oficio o una foto es una sola inserción y las dos listas cambian de forma independiente.

## 3. Dónde se aplica en MyWorksApp

La oferta del profesional se guarda en una tabla por cada lista independiente. Todas dependen del dueño (la clave foránea tiene `ON DELETE CASCADE`: si se elimina al profesional, se eliminan sus listas).

### 3.1 `trabajador_servicios`: los oficios del profesional

| Columna | Tipo | Clave |
|---|---|---|
| `id_trabajador` | uuid | PK, FK → `trabajadores.id_usuario` |
| `categoria_servicio` | text | PK, FK → `categorias_servicio.id` |

- La clave primaria es (`id_trabajador`, `categoria_servicio`): la tabla solo dice «este profesional atiende este oficio». No tiene otras columnas, así que no hay nada más que pueda depender de una parte de la clave.
- Un profesional puede tener muchos oficios sin repetir su ficha ni mezclarlos con precios, fotos o horarios.
- El oficio es siempre una categoría válida: `categorias_servicio` es la tabla de categorías y `servicios` y `trabajador_servicios` apuntan a ella.
- Datos de la base viva al 17-11-2026: 64 filas, una por cada uno de los 64 profesionales.

### 3.2 `portafolio_trabajador`: las fotos y videos del profesional

| Columna | Tipo | Clave |
|---|---|---|
| `id` | text | PK |
| `id_trabajador` | uuid | FK → `perfiles.id` |
| `ruta_foto` | text | |
| `descripcion` | text (opcional) | |
| `tipo_medio` | text | |
| `creado_en` | text | |

- Cada fila es una foto o video; todas las columnas describen esa foto. La lista de fotos no se mezcla con la de oficios (sección 2.2).
- Datos de la base viva al 17-11-2026: 87 filas que pertenecen a 31 profesionales; es decir, varios profesionales tienen varias fotos.

### 3.3 `trabajador_precios`: la lista de precios

| Columna | Tipo | Clave |
|---|---|---|
| `id_usuario` | uuid | PK, FK → `trabajadores.id_usuario` |
| `codigo` | text | PK |
| `monto_clp` | numeric | |

- Cada fila dice cuánto cobra un profesional por un código de servicio del catálogo. La clave (`id_usuario`, `codigo`) determina `monto_clp` y solo eso: cumple BCNF.
- La lista de precios se guarda aparte de la ficha `trabajadores`, igual que los oficios y las fotos, para que cada lista crezca por su cuenta.
- Datos de la base viva al 17-11-2026: 174 filas que pertenecen a 56 profesionales.

### 3.4 Otras listas independientes con su propia tabla

El mismo patrón se repite en las demás listas que dependen de un usuario. Cada una vive en su tabla en vez de ir como columnas o listas dentro de `perfiles` o `trabajadores`:

| Tabla | Lista que guarda | Clave primaria |
|---|---|---|
| `trabajador_servicios_extra` | Servicios adicionales con precio propio del profesional | (`id_usuario`, `id`) |
| `trabajador_horarios` | Ventana de atención de cada día de la semana (7 filas por profesional: `dia_semana`, `hora_inicio`, `hora_fin`) | `id`; única por (`id_usuario`, `dia_semana`) |
| `trabajador_horas_publicadas` | Horas reservables que el profesional publica en cada día | (`id_usuario`, `dia_semana`, `hora`) |
| `dispositivos_push` | Dispositivos del usuario para avisos push | `token` |
| `consentimientos_usuario` | Versiones de los términos aceptadas por el usuario | `id` |
| `bloqueos_usuario` | Usuarios bloqueados por un usuario (única por par bloqueador/bloqueado) | `id` |
| `impulsos` | Promociones de visibilidad de un profesional | `id` |

Un usuario puede tener dispositivos, consentimientos y bloqueos a la vez, sin relación entre ellos; al estar en tablas distintas no se combinan entre sí.

### 3.5 Listas que antes iban dentro de una columna

Tres listas se guardan como filas y no como un arreglo o un JSON dentro de otra tabla (1FN):

| Tabla | Lista que guarda | Clave primaria | Qué reemplaza |
|---|---|---|---|
| `propuesta_cotizacion_items` | Líneas de cada cotización: `concepto` y `monto` | (`id_propuesta`, `linea`) | El detalle ya no va como JSON dentro de `propuestas_cotizacion`; allí quedan el total y `horas_estimadas`. |
| `encuesta_testing_respuestas` | Las 10 respuestas SUS de cada encuesta (`item` de 1 a 10, `valor` de 1 a 5) | (`id_encuesta`, `item`) | Las respuestas ya no son una lista dentro de `encuestas_testing`. El puntaje SUS lo calculan la función `sus_puntaje` y la vista `encuestas_testing_con_puntaje`; no se guarda. |
| `trabajador_horarios` | Una ventana por día de la semana | `id`; única por (`id_usuario`, `dia_semana`) | Los horarios ya no son un JSON dentro de la fila. |

Cada dato depende de la clave completa de su tabla (2FN) y ninguna columna depende de otra que no sea clave (3FN). El precio, los oficios y los servicios adicionales del profesional se leen solo de `trabajador_precios`, `trabajador_servicios` y `trabajador_servicios_extra`: `trabajadores` ya no repite esos datos. La región de un profesional se obtiene desde la comuna (`comunas` → `regiones`).

`liquidaciones.id_trabajador` e `id_operador` son uuid con clave foránea a `perfiles`; la columna `liberada_por_sistema` indica las liberaciones automáticas, que no tienen operador.

## 4. Veredicto

- **La 4FN se cumple en la oferta del profesional**: sus oficios (`trabajador_servicios`), fotos (`portafolio_trabajador`), precios (`trabajador_precios`), servicios adicionales (`trabajador_servicios_extra`) y horarios (`trabajador_horarios`, `trabajador_horas_publicadas`) están en tablas separadas, cada una con una sola lista y una clave que determina todas sus columnas. Lo mismo ocurre con las listas de un usuario de la sección 3.4.
- Esas tablas cumplen además 1FN, 2FN, 3FN y BCNF, que son requisito de la 4FN.
- Este documento declara 4FN **solo para las tablas indicadas en las secciones 3.1 a 3.5**. No se afirma que las 57 tablas del modelo estén en 4FN.

## 5. Cómo se revisó

1. Se leyeron las columnas, claves primarias, claves únicas y claves foráneas de las 57 tablas en la base viva (consultas de solo lectura al catálogo de PostgreSQL).
2. Se buscaron tablas que pudieran mezclar dos listas independientes de un mismo dueño. Las tablas de la sección 3 guardan una sola lista cada una.
3. Se contaron las filas reales de las tablas de las secciones 3.1 a 3.3. En `trabajador_precios` y `portafolio_trabajador` hay varios valores por profesional; en `trabajador_servicios` hoy cada profesional tiene un oficio, pero la estructura permite varios sin cambios. `trabajador_horarios` tiene 448 filas (7 por cada uno de los 64 profesionales) y `trabajador_horas_publicadas` 1.600.
4. La revisión fue de solo lectura sobre el catálogo; los cambios de estructura están en las migraciones `20261117213633` a `20261117214622`.
